/*
 * 学校邮箱页面 — 查看最近邮件并通过 SMTP 主动发信
 * @Project : SSPU-AllinOne
 * @File : email_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../design/qingyuan/qingyuan_ui.dart';
import '../models/email_mailbox.dart';
import '../services/academic_credentials_service.dart';
import '../services/data_auto_refresh_preferences.dart';
import '../services/data_module_preferences.dart';
import '../services/email_service.dart';
import '../services/app_data_directory_service.dart';

part 'email_compose_panel.dart';
part 'email_page_layout.dart';
part 'email_message_detail_page.dart';
part 'email_mailbox_widgets.dart';

typedef EmailAttachmentPicker = Future<List<EmailAttachmentRequest>> Function();

/// 学校邮箱页面。
class EmailPage extends StatefulWidget {
  /// 邮箱服务，测试中可替换为 fake。
  final EmailMailboxClient? emailService;

  /// 测试专用：覆盖学校邮箱自动刷新开关，避免读取真实本地设置。
  final bool? emailAutoRefreshEnabledOverride;

  /// 测试专用：覆盖学校邮箱自动刷新间隔。
  final int? emailAutoRefreshIntervalOverride;

  /// 测试专用：覆盖邮箱模块联网获取门禁。
  final bool? emailFetchEnabledOverride;

  /// 测试专用：锁定当前时间，确保缓存新鲜度判定可重现。
  final DateTime? nowOverride;

  /// 测试可替换的本地附件选择器；生产环境仍由 file_picker 提供。
  final EmailAttachmentPicker? attachmentPicker;

  const EmailPage({
    super.key,
    this.emailService,
    this.emailAutoRefreshEnabledOverride,
    this.emailAutoRefreshIntervalOverride,
    this.emailFetchEnabledOverride,
    this.nowOverride,
    this.attachmentPicker,
  });

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  final ScrollController _mailboxScrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();
  EmailProtocol _selectedProtocol = EmailProtocol.imap;
  EmailProtocol? _validatingProtocol;
  EmailMailboxQueryResult? _mailboxResult;
  EmailSendResult? _sendResult;
  String? _selectedMessageId;
  bool _isFetchingMessages = false;
  bool _isSendingMessage = false;
  bool _showComposePane = false;
  int _emailAutoRefreshIntervalMinutes =
      EmailService.defaultAutoRefreshIntervalMinutes;
  Timer? _emailAutoRefreshTimer;
  StreamSubscription<int>? _credentialChangeSubscription;
  StreamSubscription<int>? _dataAutoRefreshSubscription;
  StreamSubscription<CampusDataModule>? _dataModuleSubscription;
  bool _emailAutoRefreshEnabled = false;
  int _credentialGeneration = 0;
  int _mailboxGeneration = 0;
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _bccController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final List<EmailAttachmentRequest> _composeAttachments = [];
  int _messageFetchCount = 10;
  bool _isLoadingMoreMessages = false;
  bool _canLoadMoreMessages = true;
  final Set<String> _downloadingAttachmentIds = <String>{};

  EmailMailboxClient get _emailService {
    return widget.emailService ?? EmailService.instance;
  }

  DateTime get _now => widget.nowOverride ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _credentialChangeSubscription = AcademicCredentialsService.instance.changes
        .listen((_) => _clearAuthenticatedState());
    _dataAutoRefreshSubscription = DataAutoRefreshPreferences.instance.changes
        .listen(_handleDataAutoRefreshIntervalChanged);
    _dataModuleSubscription = DataModulePreferences.instance.changes.listen((
      module,
    ) {
      if (module == CampusDataModule.email) {
        unawaited(_loadEmailAutoRefreshSettings());
      }
    });
    _loadMailboxCacheAndSettings();
  }

  void _clearAuthenticatedState() {
    if (!mounted) return;
    _credentialGeneration++;
    _mailboxGeneration++;
    _clearComposeInputs();
    setState(() {
      _mailboxResult = null;
      _sendResult = null;
      _selectedMessageId = null;
      _isFetchingMessages = false;
      _isSendingMessage = false;
      _showComposePane = false;
      _validatingProtocol = null;
    });
  }

  /// 读取邮箱自动刷新设置；默认不主动访问邮箱系统。
  Future<void> _loadEmailAutoRefreshSettings() async {
    final enabled =
        widget.emailAutoRefreshEnabledOverride ??
        await EmailService.instance.isAutoRefreshEnabled();
    final interval =
        widget.emailAutoRefreshIntervalOverride ??
        await EmailService.instance.getAutoRefreshIntervalMinutes();
    final fetchEnabled =
        widget.emailFetchEnabledOverride ??
        await DataModulePreferences.instance.isFetchEnabled(
          CampusDataModule.email,
        );
    if (!mounted) return;
    setState(() {
      _emailAutoRefreshIntervalMinutes = interval;
    });
    final shouldEnable = enabled && fetchEnabled;
    _restartEmailAutoRefreshTimer(shouldEnable, interval);
    if (shouldEnable &&
        _shouldAutoRefresh(_mailboxResult?.checkedAt, interval)) {
      unawaited(_fetchMessages(silent: true));
    }
  }

  void _restartEmailAutoRefreshTimer(bool enabled, int intervalMinutes) {
    _emailAutoRefreshEnabled = enabled;
    _emailAutoRefreshTimer?.cancel();
    _emailAutoRefreshTimer = null;
    if (!enabled || intervalMinutes <= 0) return;
    _emailAutoRefreshTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) {
        if (_shouldAutoRefresh(_mailboxResult?.checkedAt, intervalMinutes)) {
          unawaited(_fetchMessages(silent: true));
        }
      },
    );
  }

  /// 共享刷新时长变化后重启邮箱定时器并更新陈旧状态判断。
  ///
  /// :param minutes: 新的共享刷新间隔分钟数。
  /// :returns: 无返回值。
  void _handleDataAutoRefreshIntervalChanged(int minutes) {
    if (widget.emailAutoRefreshIntervalOverride != null || !mounted) return;
    setState(() => _emailAutoRefreshIntervalMinutes = minutes);
    _restartEmailAutoRefreshTimer(_emailAutoRefreshEnabled, minutes);
  }

  /// 先显示当前协议的本地邮箱缓存，再按间隔决定是否静默刷新。
  Future<void> _loadMailboxCacheAndSettings() async {
    await _loadCachedMessagesForSelectedProtocol();
    await _loadEmailAutoRefreshSettings();
  }

  Future<void> _loadCachedMessagesForSelectedProtocol() async {
    final credentialGeneration = _credentialGeneration;
    final mailboxGeneration = _mailboxGeneration;
    final cachedResult = await _emailService.readLatestCachedMessages(
      _selectedProtocol,
    );
    if (!mounted ||
        credentialGeneration != _credentialGeneration ||
        mailboxGeneration != _mailboxGeneration) {
      return;
    }
    setState(() {
      _mailboxResult = cachedResult;
      _selectedMessageId = cachedResult?.snapshot?.messages.isNotEmpty == true
          ? cachedResult!.snapshot!.messages.first.id
          : null;
    });
  }

  /// 使用当前选择的只读协议读取最近邮件。
  Future<void> _fetchMessages({
    bool silent = false,
    int? messageCount,
    bool allowWhileLoadingMore = false,
  }) async {
    if (_isFetchingMessages ||
        (_isLoadingMoreMessages && !allowWhileLoadingMore) ||
        _selectedProtocol == EmailProtocol.smtp) {
      return;
    }
    final credentialGeneration = _credentialGeneration;
    final mailboxGeneration = _mailboxGeneration;
    final requestedCount = (messageCount ?? _messageFetchCount).clamp(1, 100);
    if (!silent) setState(() => _isFetchingMessages = true);

    final result = await _emailService.fetchMessages(
      protocol: _selectedProtocol,
      messageCount: requestedCount,
    );
    if (!mounted ||
        credentialGeneration != _credentialGeneration ||
        mailboxGeneration != _mailboxGeneration) {
      return;
    }
    if (silent && !result.isSuccess) return;
    setState(() {
      _mailboxResult = result;
      final messages =
          result.snapshot?.messages ?? const <EmailMessageSnapshot>[];
      if (_selectedMessageId == null ||
          !messages.any((message) => message.id == _selectedMessageId)) {
        _selectedMessageId = messages.isNotEmpty ? messages.first.id : null;
      }
      _messageFetchCount = requestedCount;
      _canLoadMoreMessages =
          messages.length >= requestedCount && requestedCount < 100;
      if (!silent) _isFetchingMessages = false;
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_isFetchingMessages ||
        _isLoadingMoreMessages ||
        !_canLoadMoreMessages) {
      return;
    }
    final nextCount = (_messageFetchCount + 10).clamp(1, 100);
    final beforeCount = _mailboxResult?.snapshot?.messages.length ?? 0;
    setState(() => _isLoadingMoreMessages = true);
    try {
      await _fetchMessages(
        messageCount: nextCount,
        allowWhileLoadingMore: true,
      );
      if (!mounted) return;
      final afterCount = _mailboxResult?.snapshot?.messages.length ?? 0;
      if (afterCount <= beforeCount || afterCount < nextCount) {
        setState(() => _canLoadMoreMessages = false);
      }
    } finally {
      if (mounted) setState(() => _isLoadingMoreMessages = false);
    }
  }

  EmailMessageSnapshot? _selectedMessage(List<EmailMessageSnapshot> messages) {
    if (messages.isEmpty) return null;
    for (final message in messages) {
      if (message.id == _selectedMessageId) return message;
    }
    return messages.first;
  }

  void _openOrSelectMessage(
    EmailMessageSnapshot message, {
    required bool inline,
  }) {
    unawaited(_markMessageAsReadIfNeeded(message));
    if (inline) {
      setState(() {
        _selectedMessageId = message.id;
        _showComposePane = false;
      });
      return;
    }
    _openMessageDetail(message);
  }

  Future<void> _markMessageAsReadIfNeeded(EmailMessageSnapshot message) async {
    if (message.isRead) return;
    final result = _mailboxResult;
    final snapshot = result?.snapshot;
    if (result == null || snapshot == null) return;
    final updatedMessage = message.copyWith(isRead: true);
    final updatedSnapshot = EmailMailboxSnapshot(
      protocol: snapshot.protocol,
      account: snapshot.account,
      messages: snapshot.messages
          .map((item) => item.id == message.id ? updatedMessage : item)
          .toList(growable: false),
      fetchedAt: snapshot.fetchedAt,
      endpoint: snapshot.endpoint,
    );
    if (mounted) {
      setState(
        () => _mailboxResult = EmailMailboxQueryResult(
          status: result.status,
          protocol: result.protocol,
          message: result.message,
          detail: result.detail,
          checkedAt: result.checkedAt,
          endpoint: result.endpoint,
          snapshot: updatedSnapshot,
        ),
      );
    }
    if (_selectedProtocol != EmailProtocol.imap ||
        _emailService is! AdvancedEmailMailboxClient) {
      return;
    }
    final writeResult = await (_emailService as AdvancedEmailMailboxClient)
        .markMessageAsRead(message);
    if (!mounted || writeResult.isSuccess) return;
    showYhFeedback(
      context,
      message: writeResult.message,
      severity: AppFeedbackSeverity.warning,
    );
  }

  void _focusMessage(EmailMessageSnapshot message) {
    if (_selectedMessageId == message.id) return;
    setState(() => _selectedMessageId = message.id);
  }

  void _selectFirstMessageIfNeeded(List<EmailMessageSnapshot> messages) {
    if (messages.isEmpty || _selectedMessage(messages) != null) return;
    _selectedMessageId = messages.first.id;
  }

  bool _shouldAutoRefresh(DateTime? fetchedAt, int intervalMinutes) {
    if (intervalMinutes <= 0) return false;
    if (fetchedAt == null) return true;
    return _now.difference(fetchedAt) >= Duration(minutes: intervalMinutes);
  }

  bool _isMailboxSnapshotStale(EmailMailboxSnapshot snapshot) {
    return _shouldAutoRefresh(
      snapshot.fetchedAt,
      _emailAutoRefreshIntervalMinutes,
    );
  }

  @override
  void dispose() {
    _mailboxScrollController.dispose();
    _detailScrollController.dispose();
    _credentialChangeSubscription?.cancel();
    _dataAutoRefreshSubscription?.cancel();
    _dataModuleSubscription?.cancel();
    _emailAutoRefreshTimer?.cancel();
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  /// 校验指定协议登录状态。
  Future<void> _validateLogin(EmailProtocol protocol) async {
    if (_validatingProtocol != null ||
        _isFetchingMessages ||
        _isSendingMessage) {
      return;
    }
    final generation = _credentialGeneration;
    setState(() => _validatingProtocol = protocol);

    final result = await _emailService.validateLogin(protocol);
    if (!mounted || generation != _credentialGeneration) return;
    setState(() => _validatingProtocol = null);
    showYhFeedback(
      context,
      message: result.message,
      severity: result.isSuccess
          ? AppFeedbackSeverity.success
          : AppFeedbackSeverity.error,
    );
  }

  /// 通过 SMTP 主动发送当前撰写的普通文本邮件。
  Future<void> _sendEmail() async {
    if (_isSendingMessage ||
        _isFetchingMessages ||
        _validatingProtocol != null) {
      return;
    }

    final generation = _credentialGeneration;
    setState(() {
      _isSendingMessage = true;
      _sendResult = null;
    });
    final request = EmailComposeRequest(
      to: _parseAddressInput(_toController.text),
      cc: _parseAddressInput(_ccController.text),
      bcc: _parseAddressInput(_bccController.text),
      subject: _subjectController.text.trim(),
      body: _bodyController.text,
      attachments: List.unmodifiable(_composeAttachments),
    );
    final result = await _emailService.sendMessage(request);
    if (!mounted || generation != _credentialGeneration) return;
    setState(() {
      _sendResult = result;
      _isSendingMessage = false;
      if (result.isSuccess) {
        _clearComposeInputs();
        _showComposePane = false;
      }
    });
    showYhFeedback(
      context,
      message: result.message,
      severity: result.isSuccess
          ? AppFeedbackSeverity.success
          : AppFeedbackSeverity.error,
    );
  }

  void _startCompose() {
    setState(() => _showComposePane = true);
  }

  void _closeCompose() {
    _clearComposeInputs();
    setState(() => _showComposePane = false);
  }

  void _selectProtocol(EmailProtocol protocol) {
    setState(() {
      _mailboxGeneration++;
      _selectedProtocol = protocol;
      _mailboxResult = null;
      _selectedMessageId = null;
      _isFetchingMessages = false;
      _messageFetchCount = 10;
      _canLoadMoreMessages = true;
    });
  }

  void _clearComposeInputs() {
    _toController.clear();
    _ccController.clear();
    _bccController.clear();
    _subjectController.clear();
    _bodyController.clear();
    _composeAttachments.clear();
  }

  Future<void> _pickAttachments() async {
    final pickedFiles =
        await (widget.attachmentPicker?.call() ?? _pickLocalAttachments());
    if (!mounted || pickedFiles.isEmpty) return;
    var totalBytes = _composeAttachments.fold<int>(
      0,
      (sum, attachment) => sum + (attachment.size ?? 0),
    );
    var invalidCount = 0;
    var duplicateCount = 0;
    var countLimitedCount = 0;
    var sizeLimitedCount = 0;
    for (final file in pickedFiles) {
      final path = file.path;
      if (path.trim().isEmpty || file.fileName.trim().isEmpty) {
        invalidCount++;
        continue;
      }
      if (_composeAttachments.any((attachment) => attachment.path == path)) {
        duplicateCount++;
        continue;
      }
      if (_composeAttachments.length >= EmailService.maxAttachmentCount) {
        countLimitedCount++;
        continue;
      }
      final size = file.size;
      if (size == null || size < 0) {
        invalidCount++;
        continue;
      }
      if (totalBytes + size > EmailService.maxAttachmentBytes) {
        sizeLimitedCount++;
        continue;
      }
      _composeAttachments.add(file);
      totalBytes += size;
    }
    setState(() {});
    final rejectedCount =
        invalidCount + duplicateCount + countLimitedCount + sizeLimitedCount;
    if (rejectedCount > 0) {
      final reasons = <String>[
        if (invalidCount > 0) '$invalidCount 个文件不可用',
        if (duplicateCount > 0) '$duplicateCount 个文件已添加',
        if (countLimitedCount > 0)
          '$countLimitedCount 个文件超过 ${EmailService.maxAttachmentCount} 个上限',
        if (sizeLimitedCount > 0) '$sizeLimitedCount 个文件使总大小超过 100 MB',
      ];
      showYhFeedback(
        context,
        message: '未添加 $rejectedCount 个附件：${reasons.join('，')}。',
        severity: AppFeedbackSeverity.warning,
      );
    }
  }

  static Future<List<EmailAttachmentRequest>> _pickLocalAttachments() async {
    final files = await FilePicker.pickFiles();
    final result = <EmailAttachmentRequest>[];
    for (final file in files) {
      int? size;
      try {
        size = await file.length();
      } catch (_) {
        // 由统一的选择结果校验反馈“文件不可用”。
      }
      result.add(
        EmailAttachmentRequest(
          path: file.path ?? '',
          fileName: file.name,
          size: size,
        ),
      );
    }
    return result;
  }

  void _removeComposeAttachment(EmailAttachmentRequest attachment) {
    setState(() => _composeAttachments.remove(attachment));
  }

  Future<void> _downloadAttachment(
    EmailMessageSnapshot message,
    EmailAttachmentSnapshot attachment,
  ) async {
    if (_emailService is! AdvancedEmailMailboxClient ||
        _downloadingAttachmentIds.contains(attachment.id)) {
      return;
    }
    setState(() => _downloadingAttachmentIds.add(attachment.id));
    try {
      final result = await (_emailService as AdvancedEmailMailboxClient)
          .downloadAttachment(message, attachment);
      if (!mounted) return;
      final download = result.download;
      if (!result.isSuccess || download == null) {
        showYhFeedback(
          context,
          message: result.message,
          severity: AppFeedbackSeverity.error,
        );
        return;
      }
      final directory = await AppDataDirectoryService.ensureDirectoryPath(
        'email/attachments',
      );
      final safeName = download.fileName.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      final file = File(
        '$directory${Platform.pathSeparator}${safeName.isEmpty ? '附件' : safeName}',
      );
      await file.writeAsBytes(download.bytes, flush: true);
      await OpenFilex.open(file.path, type: download.mediaType);
    } finally {
      if (mounted) {
        setState(() => _downloadingAttachmentIds.remove(attachment.id));
      }
    }
  }

  List<String> _parseAddressInput(String input) {
    return input
        .split(RegExp(r'[,;，；\n\r]+'))
        .map((address) => address.trim())
        .where((address) => address.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final canPop = Navigator.of(context).canPop();
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final fluidPaddingProgress =
        ((viewportWidth - theme.breakpoint.medium) /
                (theme.breakpoint.expanded - theme.breakpoint.medium))
            .clamp(0.0, 1.0);
    final horizontalPadding = viewportWidth < theme.breakpoint.medium
        ? theme.spacing.m
        : theme.spacing.xl +
              (theme.spacing.xl2 - theme.spacing.xl) * fluidPaddingProgress;
    // Flutter 的 MiSans 顶部字面比 Chromium 更紧，使用语义 token
    // 补偿首行原点，保证 compact 冻结像素而非 CSS 盒值逐字相等。
    final verticalPadding = viewportWidth < theme.breakpoint.medium
        ? theme.spacing.l + theme.spacing.s + theme.layout.divider * 3
        : theme.spacing.xl + theme.spacing.s;
    final compactCompose =
        _showComposePane && viewportWidth < theme.breakpoint.medium;
    return YhPageScaffold(
      appBar: canPop
          ? YhAppBar(
              title: '学校邮箱',
              leading: YhIconButton(
                icon: YhIcons.back,
                semanticLabel: '返回',
                variant: YhIconButtonVariant.ghost,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      bottomBar: compactCompose
          ? EmailComposeActionDock(
              isSending: _isSendingMessage,
              onCancel: _closeCompose,
              onSend: _sendEmail,
            )
          : null,
      body: SingleChildScrollView(
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: theme.layout.pageContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMailPageHeader(context, viewportWidth),
                  SizedBox(
                    height: viewportWidth < theme.breakpoint.medium
                        ? _showComposePane
                              ? theme.spacing.l + theme.layout.divider * 2
                              : theme.spacing.l +
                                    theme.spacing.xs +
                                    theme.layout.divider * 2
                        : theme.spacing.l,
                  ),
                  _buildEmailContent(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMailPageHeader(BuildContext context, double viewportWidth) {
    final theme = context.yhTheme;
    final compact = viewportWidth < theme.breakpoint.medium;
    final composing = _showComposePane;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '学校邮箱',
                style: theme.typography.caption.copyWith(
                  color: theme.color.brandInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: theme.spacing.xs),
              Semantics(
                header: true,
                child: Text(
                  composing ? '撰写邮件' : '收件箱',
                  style: theme.typography.h1,
                ),
              ),
              SizedBox(height: theme.spacing.s),
              Text(
                composing ? '填写收件人、主题与普通文本正文；发送前仍可取消。' : '本机快照 · 只读邮件',
                style:
                    (compact ? theme.typography.small : theme.typography.body)
                        .copyWith(color: theme.color.muted),
              ),
            ],
          ),
        ),
        if (!composing) ...[
          SizedBox(width: theme.spacing.l),
          Transform.translate(
            offset: Offset(0, -theme.spacing.s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (compact)
                  YhIconButton(
                    key: const Key('email-compose-open'),
                    icon: YhIcons.edit,
                    semanticLabel: '写邮件',
                    onTap: _startCompose,
                  )
                else
                  YhButton(
                    key: const Key('email-compose-open'),
                    label: '写邮件',
                    variant: YhButtonVariant.secondary,
                    onTap: _startCompose,
                  ),
                SizedBox(width: theme.spacing.s),
                YhIconButton(
                  icon: YhIcons.refresh,
                  semanticLabel: _isFetchingMessages ? '正在刷新邮箱' : '刷新邮箱',
                  onTap: _isFetchingMessages ? null : _fetchMessages,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 打开邮件正文详情页；详情页仍只展示本地快照。
  void _openMessageDetail(EmailMessageSnapshot message) {
    Navigator.of(context).push(
      YhPageRoute(
        builder: (_) => EmailMessageDetailPage(
          message: message.copyWith(isRead: true),
          nowOverride: _now,
          downloadingAttachmentIds: _downloadingAttachmentIds,
          onDownloadAttachment: (attachment) =>
              _downloadAttachment(message, attachment),
        ),
      ),
    );
  }

  YhBannerKind _severityOf(EmailQueryStatus status) {
    return switch (status) {
      EmailQueryStatus.success => YhBannerKind.success,
      EmailQueryStatus.fetchDisabled ||
      EmailQueryStatus.missingEmailAccount ||
      EmailQueryStatus.missingEmailPassword ||
      EmailQueryStatus.invalidInput => YhBannerKind.warn,
      EmailQueryStatus.loginRejected ||
      EmailQueryStatus.parseFailed ||
      EmailQueryStatus.networkError ||
      EmailQueryStatus.unexpectedError => YhBannerKind.danger,
    };
  }

  String _senderDisplayName(EmailMessageSnapshot message) {
    return message.senderName.isEmpty
        ? message.senderAddress
        : message.senderName;
  }

  String _formatOptionalDateTime(DateTime? dateTime) {
    if (dateTime == null) return '时间未知';
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final today = DateTime(_now.year, _now.month, _now.day);
    final days = today.difference(date).inDays;
    final clock = _formatClockTime(dateTime);
    if (days == 0) return '今天 $clock';
    if (days == 1) return '昨天 $clock';
    if (dateTime.year == _now.year) {
      return '${dateTime.month} 月 ${dateTime.day} 日';
    }
    return '${dateTime.year} 年 ${dateTime.month} 月 ${dateTime.day} 日';
  }

  String _formatClockTime(DateTime dateTime) =>
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
