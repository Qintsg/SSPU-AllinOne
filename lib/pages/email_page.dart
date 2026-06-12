/*
 * 学校邮箱页面 — 查看最近邮件并通过 SMTP 主动发信
 * @Project : SSPU-AllinOne
 * @File : email_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

import 'dart:async';

import '../design/fluent_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/email_mailbox.dart';
import '../services/academic_credentials_service.dart';
import '../services/email_service.dart';
import '../theme/fluent_tokens.dart';
import '../widgets/app_feedback.dart';

part 'email_compose_panel.dart';
part 'email_page_layout.dart';
part 'email_message_detail_page.dart';
part 'email_mailbox_widgets.dart';

/// 学校邮箱页面。
class EmailPage extends StatefulWidget {
  /// 邮箱服务，测试中可替换为 fake。
  final EmailMailboxClient? emailService;

  /// 测试专用：覆盖学校邮箱自动刷新开关，避免读取真实本地设置。
  final bool? emailAutoRefreshEnabledOverride;

  /// 测试专用：覆盖学校邮箱自动刷新间隔。
  final int? emailAutoRefreshIntervalOverride;

  const EmailPage({
    super.key,
    this.emailService,
    this.emailAutoRefreshEnabledOverride,
    this.emailAutoRefreshIntervalOverride,
  });

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  EmailProtocol _selectedProtocol = EmailProtocol.imap;
  EmailProtocol? _validatingProtocol;
  EmailMailboxQueryResult? _mailboxResult;
  EmailLoginValidationResult? _validationResult;
  EmailSendResult? _sendResult;
  String? _selectedMessageId;
  bool _isFetchingMessages = false;
  bool _isSendingMessage = false;
  bool _showComposePane = false;
  bool _emailAutoRefreshEnabled = false;
  Timer? _emailAutoRefreshTimer;
  StreamSubscription<int>? _credentialChangeSubscription;
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _bccController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  EmailMailboxClient get _emailService {
    return widget.emailService ?? EmailService.instance;
  }

  @override
  void initState() {
    super.initState();
    _credentialChangeSubscription = AcademicCredentialsService.instance.changes
        .listen((_) => _clearAuthenticatedState());
    _loadMailboxCacheAndSettings();
  }

  void _clearAuthenticatedState() {
    if (!mounted) return;
    setState(() {
      _mailboxResult = null;
      _validationResult = null;
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
    if (!mounted) return;
    setState(() => _emailAutoRefreshEnabled = enabled);
    _restartEmailAutoRefreshTimer(enabled, interval);
    if (enabled && _shouldAutoRefresh(_mailboxResult?.checkedAt, interval)) {
      unawaited(_fetchMessages(silent: true));
    }
  }

  void _restartEmailAutoRefreshTimer(bool enabled, int intervalMinutes) {
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

  /// 先显示当前协议的本地邮箱缓存，再按间隔决定是否静默刷新。
  Future<void> _loadMailboxCacheAndSettings() async {
    await _loadCachedMessagesForSelectedProtocol();
    await _loadEmailAutoRefreshSettings();
  }

  Future<void> _loadCachedMessagesForSelectedProtocol() async {
    final cachedResult = await _emailService.readLatestCachedMessages(
      _selectedProtocol,
    );
    if (!mounted) return;
    setState(() {
      _mailboxResult = cachedResult;
      _selectedMessageId = cachedResult?.snapshot?.messages.isNotEmpty == true
          ? cachedResult!.snapshot!.messages.first.id
          : null;
    });
  }

  /// 使用当前选择的只读协议读取最近邮件。
  Future<void> _fetchMessages({bool silent = false}) async {
    if (_isFetchingMessages || _selectedProtocol == EmailProtocol.smtp) return;
    if (!silent) setState(() => _isFetchingMessages = true);

    final result = await _emailService.fetchMessages(
      protocol: _selectedProtocol,
      messageCount: 10,
    );
    if (!mounted) return;
    if (silent && !result.isSuccess) return;
    setState(() {
      _mailboxResult = result;
      _selectedMessageId = result.snapshot?.messages.isNotEmpty == true
          ? result.snapshot!.messages.first.id
          : null;
      if (!silent) _isFetchingMessages = false;
    });
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
    if (inline) {
      setState(() {
        _selectedMessageId = message.id;
        _showComposePane = false;
      });
      return;
    }
    _openMessageDetail(message);
  }

  void _selectFirstMessageIfNeeded(List<EmailMessageSnapshot> messages) {
    if (messages.isEmpty || _selectedMessage(messages) != null) return;
    _selectedMessageId = messages.first.id;
  }

  bool _shouldAutoRefresh(DateTime? fetchedAt, int intervalMinutes) {
    if (intervalMinutes <= 0) return false;
    if (fetchedAt == null) return true;
    return DateTime.now().difference(fetchedAt) >=
        Duration(minutes: intervalMinutes);
  }

  @override
  void dispose() {
    _credentialChangeSubscription?.cancel();
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
    setState(() => _validatingProtocol = protocol);

    final result = await _emailService.validateLogin(protocol);
    if (!mounted) return;
    setState(() {
      _validationResult = result;
      _validatingProtocol = null;
    });
  }

  /// 通过 SMTP 主动发送当前撰写的普通文本邮件。
  Future<void> _sendEmail() async {
    if (_isSendingMessage ||
        _isFetchingMessages ||
        _validatingProtocol != null) {
      return;
    }

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
    );
    final result = await _emailService.sendMessage(request);
    if (!mounted) return;
    setState(() {
      _sendResult = result;
      _isSendingMessage = false;
    });
    showAppFeedback(
      context,
      message: result.message,
      severity: result.isSuccess
          ? AppFeedbackSeverity.success
          : AppFeedbackSeverity.error,
    );
    if (result.isSuccess) {
      _toController.clear();
      _ccController.clear();
      _bccController.clear();
      _subjectController.clear();
      _bodyController.clear();
      _showComposePane = false;
    }
  }

  void _startCompose() {
    setState(() => _showComposePane = true);
  }

  void _closeCompose() {
    setState(() => _showComposePane = false);
  }

  void _selectProtocol(EmailProtocol protocol) {
    setState(() => _selectedProtocol = protocol);
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
    return FluentPage.scrollable(
      header: const FluentPageHeader(title: Text('学校邮箱')),
      children: [
        FluentContentWidth(maxWidth: 1440, child: _buildEmailContent(context)),
      ],
    );
  }

  /// 打开邮件正文详情页；详情页仍只展示本地快照。
  void _openMessageDetail(EmailMessageSnapshot message) {
    Navigator.of(context).push(
      FluentPageRoute(builder: (_) => EmailMessageDetailPage(message: message)),
    );
  }

  FluentInfoSeverity _severityOf(EmailQueryStatus status) {
    return switch (status) {
      EmailQueryStatus.success => FluentInfoSeverity.success,
      EmailQueryStatus.missingEmailAccount ||
      EmailQueryStatus.missingEmailPassword ||
      EmailQueryStatus.invalidInput => FluentInfoSeverity.warning,
      EmailQueryStatus.loginRejected ||
      EmailQueryStatus.parseFailed ||
      EmailQueryStatus.networkError ||
      EmailQueryStatus.unexpectedError => FluentInfoSeverity.error,
    };
  }

  String _senderLabel(EmailMessageSnapshot message) {
    if (message.senderName.isEmpty) return message.senderAddress;
    return '${message.senderName} <${message.senderAddress}>';
  }

  String _formatOptionalDateTime(DateTime? dateTime) {
    if (dateTime == null) return '时间未知';
    return _formatDateTime(dateTime);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
