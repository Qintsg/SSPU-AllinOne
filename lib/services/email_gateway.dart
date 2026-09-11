/*
 * 学校邮箱协议网关 — 封装 IMAP / POP 收信与 SMTP 发信
 * @Project : SSPU-AllinOne
 * @File : email_gateway.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'email_service.dart';

/// enough_mail 低层协议适配器，封装收信、认证和用户主动发信。
class EnoughMailGateway implements EmailGateway, AdvancedEmailGateway {
  /// 列表读取只请求邮件头与 MIME 结构，绝不请求整封正文或附件。
  static const String imapSummaryFetchCriteria =
      '(UID FLAGS RFC822.SIZE BODYSTRUCTURE BODY.PEEK[HEADER])';

  /// 构造单个 MIME part 的安全读取条件。
  static String imapPartFetchCriteria(String fetchId) {
    if (!RegExp(r'^\d+(?:\.\d+)*(?:\.TEXT)?$').hasMatch(fetchId)) {
      throw const FormatException('无效的 IMAP MIME part 标识');
    }
    return '(BODY.PEEK[$fetchId])';
  }

  @override
  Future<List<EmailMessageSnapshot>> fetchImapMessages({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required int messageCount,
    required Duration timeout,
  }) async {
    final client = ImapClient(defaultResponseTimeout: timeout);
    try {
      await client.connectToServer(
        endpoint.host,
        endpoint.port,
        isSecure: endpoint.isSecure,
        timeout: timeout,
      );
      await client.login(account, password).timeout(timeout);
      final inbox = await _findInboxMailbox(client, timeout);
      await client.examineMailbox(inbox).timeout(timeout);
      final fetchResult = await client.fetchRecentMessages(
        messageCount: messageCount,
        // 先取信封头与 MIME 结构，不读取附件 part；随后仅补取可搜索的
        // text/plain、text/html 正文。附件始终留到用户点击后再按 fetchId 读取。
        criteria: imapSummaryFetchCriteria,
        responseTimeout: timeout,
      );
      for (final message in fetchResult.messages) {
        await _fetchInlineTextParts(client, message, timeout);
      }

      return _buildSnapshots(
        protocol: EmailProtocol.imap,
        messages: fetchResult.messages.reversed.take(messageCount),
      );
    } finally {
      await _logoutImapSilently(client);
    }
  }

  @override
  Future<List<EmailMessageSnapshot>> fetchPopMessages({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required int messageCount,
    required Duration timeout,
  }) async {
    final client = PopClient();
    try {
      await client.connectToServer(
        endpoint.host,
        endpoint.port,
        isSecure: endpoint.isSecure,
        timeout: timeout,
      );
      await client.login(account, password).timeout(timeout);
      final listings = await client.list().timeout(timeout);
      final recentListings = listings.reversed.take(messageCount).toList();
      final messages = <MimeMessage>[];
      for (final listing in recentListings) {
        messages.add(await client.retrieve(listing.id).timeout(timeout));
      }

      return _buildSnapshots(protocol: EmailProtocol.pop, messages: messages);
    } finally {
      await _quitPopSilently(client);
    }
  }

  @override
  Future<void> validateImapLogin({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required Duration timeout,
  }) async {
    final client = ImapClient(defaultResponseTimeout: timeout);
    try {
      await client.connectToServer(
        endpoint.host,
        endpoint.port,
        isSecure: endpoint.isSecure,
        timeout: timeout,
      );
      await client.login(account, password).timeout(timeout);
    } finally {
      await _logoutImapSilently(client);
    }
  }

  @override
  Future<void> validatePopLogin({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required Duration timeout,
  }) async {
    final client = PopClient();
    try {
      await client.connectToServer(
        endpoint.host,
        endpoint.port,
        isSecure: endpoint.isSecure,
        timeout: timeout,
      );
      await client.login(account, password).timeout(timeout);
    } finally {
      await _quitPopSilently(client);
    }
  }

  @override
  Future<void> validateSmtpLogin({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required Duration timeout,
  }) async {
    final client = SmtpClient(EmailService.defaultDomain);
    try {
      await client.connectToServer(
        endpoint.host,
        endpoint.port,
        isSecure: endpoint.isSecure,
        timeout: timeout,
      );
      await client.ehlo().timeout(timeout);
      await client
          .authenticate(account, password, _preferredSmtpAuthMechanism(client))
          .timeout(timeout);
    } finally {
      await _quitSmtpSilently(client);
    }
  }

  @override
  Future<void> sendSmtpMessage({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required EmailComposeRequest request,
    required Duration timeout,
  }) async {
    final client = SmtpClient(EmailService.defaultDomain);
    try {
      await client.connectToServer(
        endpoint.host,
        endpoint.port,
        isSecure: endpoint.isSecure,
        timeout: timeout,
      );
      await client.ehlo().timeout(timeout);
      await client
          .authenticate(account, password, _preferredSmtpAuthMechanism(client))
          .timeout(timeout);
      if (request.attachments.isEmpty) {
        final message = MessageBuilder.buildSimpleTextMessage(
          MailAddress(null, account),
          _mailAddresses(request.to),
          request.body,
          cc: _optionalMailAddresses(request.cc),
          bcc: _optionalMailAddresses(request.bcc),
          subject: request.subject,
        );
        await client.sendMessage(message).timeout(timeout);
        return;
      }
      final builder = MessageBuilder.prepareMultipartMixedMessage()
        ..from = [MailAddress(null, account)]
        ..to = _mailAddresses(request.to)
        ..cc = _optionalMailAddresses(request.cc)
        ..bcc = _optionalMailAddresses(request.bcc)
        ..subject = request.subject;
      builder.addTextPlain(request.body);
      for (final attachment in request.attachments) {
        await builder.addFile(
          File(attachment.path),
          MediaType.fromText(attachment.mediaType),
          disposition: ContentDispositionHeader.from(
            ContentDisposition.attachment,
          )..filename = attachment.fileName,
        );
      }
      await client.sendMessage(builder.buildMimeMessage()).timeout(timeout);
    } finally {
      await _quitSmtpSilently(client);
    }
  }

  @override
  Future<void> markImapMessageSeen({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required String serverUid,
    required Duration timeout,
  }) async {
    final client = ImapClient(defaultResponseTimeout: timeout);
    try {
      await client.connectToServer(
        endpoint.host,
        endpoint.port,
        isSecure: endpoint.isSecure,
        timeout: timeout,
      );
      await client.login(account, password).timeout(timeout);
      final inbox = await _findInboxMailbox(client, timeout);
      await client.examineMailbox(inbox).timeout(timeout);
      final uid = int.tryParse(serverUid);
      if (uid == null) throw const FormatException('无效的 IMAP UID');
      await client
          .uidMarkSeen(MessageSequence.fromId(uid), silent: true)
          .timeout(timeout);
    } finally {
      await _logoutImapSilently(client);
    }
  }

  @override
  Future<EmailAttachmentDownload?> fetchImapAttachment({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required String serverUid,
    required String fetchId,
    required String fileName,
    required String mediaType,
    required Duration timeout,
  }) async {
    final client = ImapClient(defaultResponseTimeout: timeout);
    try {
      await client.connectToServer(
        endpoint.host,
        endpoint.port,
        isSecure: endpoint.isSecure,
        timeout: timeout,
      );
      await client.login(account, password).timeout(timeout);
      final inbox = await _findInboxMailbox(client, timeout);
      await client.examineMailbox(inbox).timeout(timeout);
      final uid = int.tryParse(serverUid);
      if (uid == null) throw const FormatException('无效的 IMAP UID');
      final fetched = await client.uidFetchMessage(
        uid,
        imapPartFetchCriteria(fetchId),
        responseTimeout: timeout,
      );
      if (fetched.messages.isEmpty) return null;
      final part = fetched.messages.first.getPart(fetchId);
      final bytes = part?.decodeContentBinary();
      if (bytes == null) return null;
      return EmailAttachmentDownload(
        fileName: fileName,
        mediaType: mediaType,
        bytes: bytes,
      );
    } finally {
      await _logoutImapSilently(client);
    }
  }

  Future<void> _fetchInlineTextParts(
    ImapClient client,
    MimeMessage message,
    Duration timeout,
  ) async {
    final body = message.body;
    if (body == null) return;
    final inlineParts = <ContentInfo>[];
    body.collectContentInfo(
      ContentDisposition.attachment,
      inlineParts,
      reverse: true,
    );
    final fetchIds = inlineParts
        .where((part) => part.isText && _isValidFetchId(part.fetchId))
        .map((part) => part.fetchId)
        .toSet()
        .toList(growable: false);
    if (fetchIds.isEmpty) return;
    final criteria = '(${fetchIds.map((id) => 'BODY.PEEK[$id]').join(' ')})';
    final uid = message.uid;
    final fetched = uid != null
        ? await client.uidFetchMessage(uid, criteria, responseTimeout: timeout)
        : await client.fetchMessage(
            message.sequenceId ?? (throw const FormatException('邮件缺少 IMAP 序号')),
            criteria,
            responseTimeout: timeout,
          );
    if (fetched.messages.isNotEmpty) {
      message.copyIndividualParts(fetched.messages.first);
    }
  }

  bool _isValidFetchId(String value) =>
      RegExp(r'^\d+(?:\.\d+)*(?:\.TEXT)?$').hasMatch(value);

  Future<Mailbox> _findInboxMailbox(ImapClient client, Duration timeout) async {
    final mailboxes = await client.listMailboxes().timeout(timeout);
    for (final mailbox in mailboxes) {
      if (mailbox.isInbox || mailbox.path.toUpperCase() == 'INBOX') {
        return mailbox;
      }
    }

    return Mailbox(
      encodedName: 'INBOX',
      encodedPath: 'INBOX',
      pathSeparator: client.serverInfo.pathSeparator ?? '/',
      flags: [MailboxFlag.inbox],
    );
  }

  AuthMechanism _preferredSmtpAuthMechanism(SmtpClient client) {
    final serverInfo = client.serverInfo;
    if (serverInfo.supportsAuth(AuthMechanism.plain)) {
      return AuthMechanism.plain;
    }
    if (serverInfo.supportsAuth(AuthMechanism.login)) {
      return AuthMechanism.login;
    }
    if (serverInfo.supportsAuth(AuthMechanism.cramMd5)) {
      return AuthMechanism.cramMd5;
    }
    return AuthMechanism.plain;
  }

  List<EmailMessageSnapshot> _buildSnapshots({
    required EmailProtocol protocol,
    required Iterable<MimeMessage> messages,
  }) {
    var index = 0;
    return messages.map((message) {
      final snapshot = _buildSnapshot(protocol, message, index);
      index++;
      return snapshot;
    }).toList();
  }

  EmailMessageSnapshot _buildSnapshot(
    EmailProtocol protocol,
    MimeMessage message,
    int index,
  ) {
    final sender = message.from?.isNotEmpty == true
        ? message.from!.first
        : null;
    final body = _extractBodyText(message);
    final contentInfos = message.findContentInfo(complete: true);
    return EmailMessageSnapshot(
      id: _messageId(protocol, message, index),
      subject: _normalizeText(message.decodeSubject() ?? '').ifEmpty('无主题'),
      senderName: _normalizeText(sender?.personalName ?? ''),
      senderAddress: _normalizeText(sender?.email ?? '未知发件人'),
      receivedAt: message.decodeDate(),
      preview: _buildPreview(body),
      body: body,
      isRead: message.isSeen,
      serverUid: (message.uid ?? message.sequenceId)?.toString(),
      attachments: [
        for (final info in contentInfos)
          EmailAttachmentSnapshot(
            id: info.fetchId,
            fileName: info.fileName ?? '附件',
            mediaType: info.mediaType?.text ?? 'application/octet-stream',
            size: info.size,
          ),
      ],
    );
  }

  String _messageId(EmailProtocol protocol, MimeMessage message, int index) {
    final headerMessageId = message.getHeaderValue('message-id')?.trim();
    if (headerMessageId != null && headerMessageId.isNotEmpty) {
      return '${protocol.label}:$headerMessageId';
    }
    final uid = message.uid ?? message.sequenceId;
    return '${protocol.label}:${uid ?? index}';
  }

  String _extractBodyText(MimeMessage message) {
    final plainText = message.decodeTextPlainPart();
    if (plainText != null && plainText.trim().isNotEmpty) {
      return _normalizeBodyText(plainText);
    }

    final htmlText = message.decodeTextHtmlPart();
    if (htmlText == null || htmlText.trim().isEmpty) return '';
    return _normalizeBodyText(
      html_parser.parse(htmlText).body?.text ?? htmlText,
    );
  }

  String _buildPreview(String body) {
    if (body.isEmpty) return '无正文摘要';
    if (body.length <= 140) return body;
    return '${body.substring(0, 140)}...';
  }

  List<MailAddress> _mailAddresses(List<String> addresses) {
    return addresses
        .map((address) => MailAddress.parse(address.trim()))
        .toList();
  }

  List<MailAddress>? _optionalMailAddresses(List<String> addresses) {
    if (addresses.isEmpty) return null;
    return _mailAddresses(addresses);
  }

  String _normalizeText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeBodyText(String value) {
    return value
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trimRight())
        .join('\n')
        .trim();
  }

  Future<void> _logoutImapSilently(ImapClient client) async {
    try {
      if (client.isLoggedIn) await client.logout();
    } catch (_) {
      // 登出失败不改变主操作结果；随后仍会关闭 socket。
    }
    await client.disconnect();
  }

  Future<void> _quitPopSilently(PopClient client) async {
    try {
      if (client.isLoggedIn) await client.quit();
    } catch (_) {
      // POP 未执行 delete，quit 仅结束会话；失败后直接关闭连接。
    }
    await client.disconnect();
  }

  Future<void> _quitSmtpSilently(SmtpClient client) async {
    try {
      if (client.isLoggedIn) await client.quit();
    } catch (_) {
      // 退出失败不改变认证或发信主结果；随后仍会关闭 socket。
    }
    await client.disconnect();
  }
}
