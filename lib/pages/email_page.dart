/*
 * 学校邮箱页面 — 只读查看最近邮件并校验协议登录状态
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

part 'email_message_detail_page.dart';

/// 学校邮箱只读页面。
class EmailPage extends StatefulWidget {
  /// 邮箱只读服务，测试中可替换为 fake。
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
  String? _selectedMessageId;
  bool _isFetchingMessages = false;
  bool _emailAutoRefreshEnabled = false;
  Timer? _emailAutoRefreshTimer;
  StreamSubscription<int>? _credentialChangeSubscription;

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
      _selectedMessageId = null;
      _isFetchingMessages = false;
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
      setState(() => _selectedMessageId = message.id);
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
    super.dispose();
  }

  /// 校验指定协议登录状态；SMTP 只认证，不发送邮件。
  Future<void> _validateLogin(EmailProtocol protocol) async {
    if (_validatingProtocol != null || _isFetchingMessages) return;
    setState(() => _validatingProtocol = protocol);

    final result = await _emailService.validateLogin(protocol);
    if (!mounted) return;
    setState(() {
      _validationResult = result;
      _validatingProtocol = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FluentPage.scrollable(
      header: const FluentPageHeader(title: Text('学校邮箱')),
      children: [FluentContentWidth(child: _buildEmailContent(context))],
    );
  }

  Widget _buildEmailContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoPane = constraints.maxWidth >= 900;
        if (useTwoPane) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 340,
                child: Column(
                  children: [
                    _buildOverviewCard(context),
                    const SizedBox(height: FluentSpacing.m),
                    _buildProtocolCard(context),
                  ],
                ),
              ),
              const SizedBox(width: FluentSpacing.m),
              Expanded(
                child: _buildMailboxSection(context, inlineDetail: true),
              ),
            ],
          );
        }

        return Column(
          children: [
            _animateEmailSection(_buildOverviewCard(context), 0),
            const SizedBox(height: FluentSpacing.m),
            _animateEmailSection(_buildProtocolCard(context), 1),
            const SizedBox(height: FluentSpacing.m),
            _animateEmailSection(
              _buildMailboxSection(context, inlineDetail: false),
              2,
            ),
          ],
        );
      },
    );
  }

  Widget _animateEmailSection(Widget child, int index) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return child
        .animate(delay: FluentDuration.stagger * index)
        .fadeIn(duration: FluentDuration.slow, curve: FluentEasing.decelerate)
        .slideY(begin: 0.05, end: 0);
  }

  /// 构建页面说明，强调只读边界。
  Widget _buildOverviewCard(BuildContext context) {
    return const FluentSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluentSectionHeader(
            title: 'SSPU 邮箱只读收件箱',
            subtitle: '在设置页保存学工号和邮箱密码后，可通过 IMAP 或 POP 读取最近邮件。',
            icon: FluentIcons.mail,
          ),
          SizedBox(height: FluentSpacing.l),
          FluentInfoBar(
            title: Text('只读访问边界'),
            content: Text('本页面不会发送邮件、删除邮件、移动邮件或主动标记已读；SMTP 仅用于认证与连通性校验。'),
            severity: FluentInfoSeverity.info,
          ),
        ],
      ),
    );
  }

  /// 构建协议选择与登录校验操作区。
  Widget _buildProtocolCard(BuildContext context) {
    final theme = FluentTheme.of(context);
    return FluentSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('协议操作', style: theme.typography.bodyStrong),
          const SizedBox(height: FluentSpacing.xs),
          Text(
            'IMAP 使用 BODY.PEEK[] 读取，POP 仅 RETR 最近邮件；SMTP 不提供发送入口。',
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
          const SizedBox(height: FluentSpacing.m),
          Wrap(
            spacing: FluentSpacing.s,
            runSpacing: FluentSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 160,
                child: FluentSelect<EmailProtocol>(
                  value: _selectedProtocol,
                  items: const [
                    FluentSelectItem(
                      value: EmailProtocol.imap,
                      child: Text('IMAP 收信'),
                    ),
                    FluentSelectItem(
                      value: EmailProtocol.pop,
                      child: Text('POP 收信'),
                    ),
                  ],
                  onChanged: _isFetchingMessages
                      ? null
                      : (protocol) {
                          if (protocol == null) return;
                          setState(() => _selectedProtocol = protocol);
                          unawaited(_loadCachedMessagesForSelectedProtocol());
                        },
                ),
              ),
              FluentButton.primary(
                onPressed: _isFetchingMessages ? null : _fetchMessages,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isFetchingMessages) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: FluentProgressRing(strokeWidth: 2),
                      ),
                    ] else ...[
                      const Icon(FluentIcons.refresh, size: 14),
                    ],
                    const SizedBox(width: 6),
                    const Text('读取最近邮件'),
                  ],
                ),
              ),
              for (final protocol in EmailProtocol.values)
                FluentButton.outline(
                  onPressed: _validatingProtocol == null && !_isFetchingMessages
                      ? () => _validateLogin(protocol)
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_validatingProtocol == protocol) ...[
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: FluentProgressRing(strokeWidth: 2),
                        ),
                      ] else ...[
                        const Icon(FluentIcons.plugConnected, size: 14),
                      ],
                      const SizedBox(width: 6),
                      Text('校验 ${protocol.label}'),
                    ],
                  ),
                ),
            ],
          ),
          if (_validationResult != null) ...[
            const SizedBox(height: FluentSpacing.m),
            FluentInfoBar(
              title: Text(_validationResult!.message),
              content: Text(_validationResult!.detail),
              severity: _severityOf(_validationResult!.status),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建邮件读取结果和列表。
  Widget _buildMailboxSection(
    BuildContext context, {
    required bool inlineDetail,
  }) {
    final result = _mailboxResult;
    if (_isFetchingMessages) {
      return const FluentSurface(
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: FluentProgressRing(strokeWidth: 2),
            ),
            SizedBox(width: FluentSpacing.s),
            Text('正在读取最近邮件...'),
          ],
        ),
      );
    }

    if (result == null) {
      return FluentInfoBar(
        title: const Text('尚未读取邮箱'),
        content: Text(
          _emailAutoRefreshEnabled
              ? '邮箱自动刷新已开启，等待下一次读取；也可点击“读取最近邮件”立即刷新。'
              : '选择 IMAP 或 POP 后点击“读取最近邮件”，也可以先校验各协议登录状态。',
        ),
        severity: FluentInfoSeverity.info,
      );
    }

    if (!result.isSuccess || result.snapshot == null) {
      return FluentInfoBar(
        title: Text(result.message),
        content: Text(result.detail),
        severity: _severityOf(result.status),
      );
    }

    final snapshot = result.snapshot!;
    final messages = snapshot.messages;
    _selectFirstMessageIfNeeded(messages);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluentSurface(
          padding: const EdgeInsets.all(FluentSpacing.l),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${snapshot.protocol.label} 最近邮件：${messages.length} 封',
                ),
              ),
              Text('上次刷新：${_formatDateTime(snapshot.fetchedAt)}'),
            ],
          ),
        ),
        const SizedBox(height: FluentSpacing.m),
        if (messages.isEmpty)
          const FluentInfoBar(
            title: Text('暂无可展示邮件'),
            content: Text('邮箱协议登录成功，但最近邮件列表为空。'),
            severity: FluentInfoSeverity.info,
          )
        else if (inlineDetail)
          _buildMailboxTwoPane(context, snapshot, messages)
        else
          ...messages.map(
            (message) => _buildMessageCard(message, inlineDetail: false),
          ),
      ],
    );
  }

  Widget _buildMailboxTwoPane(
    BuildContext context,
    EmailMailboxSnapshot snapshot,
    List<EmailMessageSnapshot> messages,
  ) {
    final selectedMessage = _selectedMessage(messages);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 360,
          child: FluentSurface(
            padding: const EdgeInsets.symmetric(vertical: FluentSpacing.xxs),
            child: Column(
              children: [
                for (var index = 0; index < messages.length; index++) ...[
                  _EmailListRow(
                    message: messages[index],
                    selected: messages[index].id == selectedMessage?.id,
                    senderLabel: _senderLabel,
                    formatDateTime: _formatOptionalDateTime,
                    onPressed: () =>
                        _openOrSelectMessage(messages[index], inline: true),
                  ),
                  if (index != messages.length - 1) const Divider(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: FluentSpacing.m),
        Expanded(
          child: _EmailInlineDetailPanel(
            message: selectedMessage,
            protocolLabel: snapshot.protocol.label,
            fetchedAtLabel: _formatDateTime(snapshot.fetchedAt),
            senderLabel: _senderLabel,
            formatDateTime: _formatOptionalDateTime,
          ),
        ),
      ],
    );
  }

  /// 构建单封邮件摘要卡片。
  Widget _buildMessageCard(
    EmailMessageSnapshot message, {
    required bool inlineDetail,
  }) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: FluentSpacing.s),
      child: FluentSurface(
        padding: const EdgeInsets.all(FluentSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    message.subject,
                    style: theme.typography.bodyStrong,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: FluentSpacing.s),
                Text(_formatOptionalDateTime(message.receivedAt)),
              ],
            ),
            const SizedBox(height: FluentSpacing.xs),
            Text(
              _senderLabel(message),
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
            const SizedBox(height: FluentSpacing.s),
            Text(message.preview, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: FluentSpacing.m),
            Align(
              alignment: Alignment.centerRight,
              child: FluentButton.outline(
                onPressed: () =>
                    _openOrSelectMessage(message, inline: inlineDetail),
                child: const Text('查看正文'),
              ),
            ),
          ],
        ),
      ),
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
      EmailQueryStatus.missingEmailPassword => FluentInfoSeverity.warning,
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

class _EmailListRow extends StatelessWidget {
  const _EmailListRow({
    required this.message,
    required this.selected,
    required this.senderLabel,
    required this.formatDateTime,
    required this.onPressed,
  });

  final EmailMessageSnapshot message;
  final bool selected;
  final String Function(EmailMessageSnapshot message) senderLabel;
  final String Function(DateTime? dateTime) formatDateTime;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final theme = FluentTheme.of(context);
    return HoverButton(
      onPressed: onPressed,
      builder: (context, states) {
        final background = selected
            ? colors.brandStroke2.withValues(alpha: 0.16)
            : states.isHovered || states.isFocused
            ? colors.subtleBackgroundHover
            : null;
        return Container(
          color: background,
          padding: const EdgeInsets.all(FluentSpacing.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EmailSenderAnchor(label: senderLabel(message)),
              const SizedBox(width: FluentSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.bodyStrong,
                          ),
                        ),
                        const SizedBox(width: FluentSpacing.s),
                        Text(
                          formatDateTime(message.receivedAt),
                          style: theme.typography.caption?.copyWith(
                            color: colors.neutralForeground3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FluentSpacing.xxs),
                    Text(
                      senderLabel(message),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.caption?.copyWith(
                        color: colors.neutralForeground3,
                      ),
                    ),
                    const SizedBox(height: FluentSpacing.xxs),
                    Text(
                      message.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmailSenderAnchor extends StatelessWidget {
  const _EmailSenderAnchor({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = context.fluentAccents.mail;
    final initial = label.trim().isEmpty ? '邮' : label.trim().characters.first;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: context.fluentRadii.mediumBorder,
      ),
      child: Text(
        initial,
        style: FluentTheme.of(context).typography.bodyStrong?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmailInlineDetailPanel extends StatelessWidget {
  const _EmailInlineDetailPanel({
    required this.message,
    required this.protocolLabel,
    required this.fetchedAtLabel,
    required this.senderLabel,
    required this.formatDateTime,
  });

  final EmailMessageSnapshot? message;
  final String protocolLabel;
  final String fetchedAtLabel;
  final String Function(EmailMessageSnapshot message) senderLabel;
  final String Function(DateTime? dateTime) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final colors = context.fluentColors;
    final current = message;
    if (current == null) {
      return const FluentSurface(
        minHeight: 320,
        child: Center(child: Text('选择一封邮件查看正文快照')),
      );
    }

    return FluentSurface(
      minHeight: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: FluentSpacing.s,
            runSpacing: FluentSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FluentStatusChip(
                label: '$protocolLabel 只读快照',
                icon: FluentIcons.mail,
                tone: FluentStatusChipTone.brand,
              ),
              FluentStatusChip(
                label: '刷新 $fetchedAtLabel',
                icon: FluentIcons.clock,
              ),
            ],
          ),
          const SizedBox(height: FluentSpacing.m),
          Text(current.subject, style: theme.typography.subtitle),
          const SizedBox(height: FluentSpacing.s),
          Text(
            senderLabel(current),
            style: theme.typography.caption?.copyWith(
              color: colors.neutralForeground3,
            ),
          ),
          Text(
            formatDateTime(current.receivedAt),
            style: theme.typography.caption?.copyWith(
              color: colors.neutralForeground3,
            ),
          ),
          const SizedBox(height: FluentSpacing.m),
          const FluentInfoBar(
            title: Text('只读正文快照'),
            content: Text('不会执行回复、转发、删除、移动或标记已读操作。'),
            severity: FluentInfoSeverity.info,
          ),
          const SizedBox(height: FluentSpacing.m),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 180),
            child: SingleChildScrollView(
              primary: false,
              child: SelectableText(
                current.body.isEmpty ? '无可展示正文。' : current.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
