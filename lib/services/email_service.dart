/*
 * 学校邮箱服务 — 通过 IMAP / POP 只读收信，并用 SMTP 主动发信
 * @Project : SSPU-AllinOne
 * @File : email_service.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

import 'dart:async';
import 'dart:io';

import 'package:enough_mail/enough_mail.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/academic_credentials.dart';
import '../models/email_mailbox.dart';
import 'academic_credentials_service.dart';
import 'authenticated_data_cache_service.dart';
import 'data_auto_refresh_preferences.dart';
import 'data_module_preferences.dart';
import 'storage_service.dart';

part 'email_gateway.dart';
part 'email_support.dart';

/// 邮箱页面依赖的查询与发信接口，便于 widget 测试替换。
abstract class EmailMailboxClient {
  /// 读取最近一次指定协议的本地邮箱缓存。
  Future<EmailMailboxQueryResult?> readLatestCachedMessages(
    EmailProtocol protocol,
  );

  /// 通过 IMAP 或 POP 读取最近邮件；SMTP 不允许用于收信。
  Future<EmailMailboxQueryResult> fetchMessages({
    required EmailProtocol protocol,
    int messageCount = 10,
  });

  /// 校验指定协议的登录状态。
  Future<EmailLoginValidationResult> validateLogin(EmailProtocol protocol);

  /// 通过 SMTP 主动发送一封普通文本邮件。
  Future<EmailSendResult> sendMessage(EmailComposeRequest request);
}

/// 可选的邮箱高级能力，避免破坏已有测试 fake 与第三方实现。
abstract interface class AdvancedEmailMailboxClient {
  Future<EmailMailboxQueryResult> markMessageAsRead(
    EmailMessageSnapshot message,
  );

  Future<EmailAttachmentDownloadResult> downloadAttachment(
    EmailMessageSnapshot message,
    EmailAttachmentSnapshot attachment,
  );
}

/// 可替换的邮箱协议网关。
abstract class EmailGateway {
  /// 使用 IMAP 只读读取最近邮件。
  Future<List<EmailMessageSnapshot>> fetchImapMessages({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required int messageCount,
    required Duration timeout,
  });

  /// 使用 POP 只读读取最近邮件。
  Future<List<EmailMessageSnapshot>> fetchPopMessages({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required int messageCount,
    required Duration timeout,
  });

  /// 仅校验 IMAP 登录状态，不读取邮件正文。
  Future<void> validateImapLogin({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required Duration timeout,
  });

  /// 仅校验 POP 登录状态，不读取邮件正文。
  Future<void> validatePopLogin({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required Duration timeout,
  });

  /// 仅校验 SMTP 认证。
  Future<void> validateSmtpLogin({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required Duration timeout,
  });

  /// 使用 SMTP 发送普通文本邮件。
  Future<void> sendSmtpMessage({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required EmailComposeRequest request,
    required Duration timeout,
  });
}

/// 可选的协议高级能力，避免破坏已有 EmailGateway fake。
abstract interface class AdvancedEmailGateway {
  Future<void> markImapMessageSeen({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required String serverUid,
    required Duration timeout,
  });

  Future<EmailAttachmentDownload?> fetchImapAttachment({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required String serverUid,
    required String fetchId,
    required String fileName,
    required String mediaType,
    required Duration timeout,
  });
}

/// 学校邮箱服务。
class EmailService implements EmailMailboxClient, AdvancedEmailMailboxClient {
  EmailService({
    AcademicCredentialsService? credentialsService,
    EmailGateway? gateway,
    Future<bool> Function()? isFetchEnabled,
    EmailServerEndpoint? imapEndpoint,
    EmailServerEndpoint? popEndpoint,
    EmailServerEndpoint? smtpEndpoint,
    Duration? timeout,
  }) : _credentialsService =
           credentialsService ?? AcademicCredentialsService.instance,
       _gateway = gateway ?? EnoughMailGateway(),
       _isFetchEnabled =
           isFetchEnabled ??
           (() => DataModulePreferences.instance.isFetchEnabled(
             CampusDataModule.email,
           )),
       imapEndpoint = imapEndpoint ?? defaultImapEndpoint,
       popEndpoint = popEndpoint ?? defaultPopEndpoint,
       smtpEndpoint = smtpEndpoint ?? defaultSmtpEndpoint,
       timeout = timeout ?? const Duration(seconds: 20);

  /// 全局单例。
  static final EmailService instance = EmailService();

  /// 学校邮箱默认域名。
  static const String defaultDomain = 'sspu.edu.cn';

  /// 腾讯企业邮箱 IMAP SSL 端点。
  static const EmailServerEndpoint defaultImapEndpoint = EmailServerEndpoint(
    host: 'imap.exmail.qq.com',
    port: 993,
    isSecure: true,
  );

  /// 腾讯企业邮箱 POP SSL 端点。
  static const EmailServerEndpoint defaultPopEndpoint = EmailServerEndpoint(
    host: 'pop.exmail.qq.com',
    port: 995,
    isSecure: true,
  );

  /// 腾讯企业邮箱 SMTP SSL 端点；用于 AUTH 校验与用户主动发信。
  static const EmailServerEndpoint defaultSmtpEndpoint = EmailServerEndpoint(
    host: 'smtp.exmail.qq.com',
    port: 465,
    isSecure: true,
  );

  /// 学校邮箱默认自动刷新间隔，单位分钟。
  static const int defaultAutoRefreshIntervalMinutes = 30;

  /// 单次 SMTP 发信允许的最大收件人数量。
  static const int maxSendRecipients = 50;

  /// 单次 SMTP 发信允许的最大主题长度。
  static const int maxSendSubjectLength = 200;

  /// 单次 SMTP 发信允许的最大纯文本正文长度。
  static const int maxSendBodyLength = 20000;

  /// 单封邮件允许的附件数量上限。
  static const int maxAttachmentCount = 25;

  /// 单封邮件附件总大小上限（100 MiB）。
  static const int maxAttachmentBytes = 100 * 1024 * 1024;

  /// 在已经加载到本地的邮件中匹配主题、发件人、摘要和正文。
  ///
  /// 该纯函数不读取凭据或访问邮箱网关，供页面即时筛选与性能契约测试复用。
  static List<EmailMessageSnapshot> filterLocalMessages(
    List<EmailMessageSnapshot> messages,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return messages;
    return messages
        .where((message) {
          final haystack = [
            message.subject,
            message.senderName,
            message.senderAddress,
            message.preview,
            message.body,
          ].join('\n').toLowerCase();
          return haystack.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  final AcademicCredentialsService _credentialsService;
  final EmailGateway _gateway;
  final Future<bool> Function() _isFetchEnabled;

  /// IMAP 只读收信端点。
  final EmailServerEndpoint imapEndpoint;

  /// POP 只读收信端点。
  final EmailServerEndpoint popEndpoint;

  /// SMTP 登录校验端点。
  final EmailServerEndpoint smtpEndpoint;

  /// 单次协议步骤超时时间。
  final Duration timeout;

  /// 读取学校邮箱自动刷新开关。
  Future<bool> isAutoRefreshEnabled() async {
    return StorageService.getBool(StorageKeys.emailAutoRefreshEnabled);
  }

  /// 保存学校邮箱自动刷新开关。
  Future<void> setAutoRefreshEnabled(bool enabled) async {
    await StorageService.setBool(StorageKeys.emailAutoRefreshEnabled, enabled);
  }

  /// 读取学校邮箱自动刷新间隔。
  Future<int> getAutoRefreshIntervalMinutes() async {
    return DataAutoRefreshPreferences.instance.getIntervalMinutes();
  }

  /// 保存学校邮箱自动刷新间隔。
  Future<void> setAutoRefreshIntervalMinutes(int minutes) async {
    await DataAutoRefreshPreferences.instance.setIntervalMinutes(minutes);
  }

  /// 读取最近一次指定协议的本地邮箱缓存。
  @override
  Future<EmailMailboxQueryResult?> readLatestCachedMessages(
    EmailProtocol protocol,
  ) async {
    final accountKey = normalizeEmailAccount(
      (await _credentialsService.getStatus()).oaAccount,
    );
    if (accountKey.isEmpty) return null;
    final entry = await AuthenticatedDataCacheService.readLatest(
      _mailboxCacheCollection(protocol),
      accountKey: accountKey,
    );
    if (entry == null) return null;
    final snapshot = EmailMailboxSnapshot.fromJson(entry.data);
    return _buildMailboxResult(
      status: EmailQueryStatus.success,
      protocol: snapshot.protocol,
      endpoint: snapshot.endpoint,
      message: '已显示本地邮箱缓存',
      detail: '显示最近一次成功读取并保存的 ${snapshot.protocol.label} 邮件快照。',
      checkedAt: snapshot.fetchedAt,
      snapshot: snapshot,
    );
  }

  /// 将学工号规范化为固定学校邮箱地址。
  static String normalizeEmailAccount(String studentId) {
    final trimmedStudentId = studentId.trim();
    if (trimmedStudentId.isEmpty || trimmedStudentId.contains('@')) {
      return trimmedStudentId;
    }

    return '$trimmedStudentId@$defaultDomain';
  }

  @override
  Future<EmailMailboxQueryResult> fetchMessages({
    required EmailProtocol protocol,
    int messageCount = 10,
  }) async {
    final endpoint = endpointFor(protocol);
    if (protocol != EmailProtocol.smtp && !await _isFetchEnabled()) {
      return _buildMailboxResult(
        status: EmailQueryStatus.fetchDisabled,
        protocol: protocol,
        endpoint: endpoint,
        message: '邮箱已停止获取',
        detail: '本地缓存会继续保留；如需收取新邮件，请在设置中重新开启邮箱联网获取。',
      );
    }
    if (protocol == EmailProtocol.smtp) {
      return _buildMailboxResult(
        status: EmailQueryStatus.loginRejected,
        protocol: protocol,
        endpoint: endpoint,
        message: 'SMTP 不支持收信',
        detail: 'SMTP 仅用于登录校验和用户主动发信，不能读取邮箱内容。',
      );
    }

    final credentials = await _readCredentials();
    if (!credentials.isSuccess) {
      return _buildMailboxResult(
        status: credentials.status!,
        protocol: protocol,
        endpoint: endpoint,
        message: credentials.message!,
        detail: credentials.detail!,
      );
    }

    try {
      final safeMessageCount = messageCount.clamp(1, 100);
      final cachedEntry = await AuthenticatedDataCacheService.readLatest(
        _mailboxCacheCollection(protocol),
        accountKey: credentials.account,
      );
      final cachedMessages = cachedEntry == null
          ? const <EmailMessageSnapshot>[]
          : EmailMailboxSnapshot.fromJson(cachedEntry.data).messages;
      final messages = switch (protocol) {
        EmailProtocol.imap => await _gateway.fetchImapMessages(
          endpoint: endpoint,
          account: credentials.account,
          password: credentials.password,
          messageCount: safeMessageCount,
          timeout: timeout,
        ),
        EmailProtocol.pop => await _gateway.fetchPopMessages(
          endpoint: endpoint,
          account: credentials.account,
          password: credentials.password,
          messageCount: safeMessageCount,
          timeout: timeout,
        ),
        EmailProtocol.smtp => const <EmailMessageSnapshot>[],
      };
      final mergedById = <String, EmailMessageSnapshot>{
        for (final message in cachedMessages) message.id: message,
        for (final message in messages) message.id: message,
      };
      final mergedMessages = mergedById.values.toList()
        ..sort((left, right) {
          final leftDate = left.receivedAt;
          final rightDate = right.receivedAt;
          if (leftDate == null && rightDate == null) return 0;
          if (leftDate == null) return 1;
          if (rightDate == null) return -1;
          return rightDate.compareTo(leftDate);
        });
      final fetchedAt = DateTime.now();
      final snapshot = EmailMailboxSnapshot(
        protocol: protocol,
        account: credentials.account,
        messages: mergedMessages.take(safeMessageCount).toList(),
        fetchedAt: fetchedAt,
        endpoint: endpoint,
      );
      final result = _buildMailboxResult(
        status: EmailQueryStatus.success,
        protocol: protocol,
        endpoint: endpoint,
        message: '${protocol.label} 邮件读取完成',
        detail: '已通过只读协议读取并合并最近 ${snapshot.messages.length} 封邮件。',
        checkedAt: fetchedAt,
        snapshot: snapshot,
      );
      final currentAccount = normalizeEmailAccount(
        (await _credentialsService.getStatus()).oaAccount,
      );
      final currentPassword = await _credentialsService.readSecret(
        AcademicCredentialSecret.emailPassword,
      );
      if (currentAccount != credentials.account ||
          currentPassword != credentials.password) {
        return _buildMailboxResult(
          status: EmailQueryStatus.unexpectedError,
          protocol: protocol,
          endpoint: endpoint,
          message: '邮箱读取已取消',
          detail: '邮箱凭据已在读取过程中变更，已丢弃本次邮箱结果。',
        );
      }
      await AuthenticatedDataCacheService.saveLatest(
        collection: _mailboxCacheCollection(protocol),
        accountKey: credentials.account,
        fetchedAt: snapshot.fetchedAt,
        data: snapshot.toJson(),
      );
      return result;
    } on TimeoutException {
      return _networkFailure(protocol, endpoint, '邮箱服务器响应超时');
    } on SocketException {
      return _networkFailure(protocol, endpoint, '邮箱服务器网络连接失败');
    } on HandshakeException {
      return _networkFailure(protocol, endpoint, '邮箱服务器 TLS 握手失败');
    } on ImapException {
      return _loginRejected(protocol, endpoint);
    } on PopException {
      return _loginRejected(protocol, endpoint);
    } on FormatException {
      return _buildMailboxResult(
        status: EmailQueryStatus.parseFailed,
        protocol: protocol,
        endpoint: endpoint,
        message: '邮件内容解析失败',
        detail: '邮箱服务器返回了无法解析为 MIME 邮件的内容。',
      );
    } catch (error) {
      return _buildMailboxResult(
        status: EmailQueryStatus.unexpectedError,
        protocol: protocol,
        endpoint: endpoint,
        message: '邮箱读取失败',
        detail: '未归类异常类型：${error.runtimeType}',
      );
    }
  }

  @override
  Future<EmailLoginValidationResult> validateLogin(
    EmailProtocol protocol,
  ) async {
    final endpoint = endpointFor(protocol);
    if (protocol != EmailProtocol.smtp && !await _isFetchEnabled()) {
      return _buildValidationResult(
        status: EmailQueryStatus.fetchDisabled,
        protocol: protocol,
        endpoint: endpoint,
        message: '邮箱已停止获取',
        detail: '本地缓存会继续保留；如需校验收信协议，请在设置中重新开启邮箱联网获取。',
      );
    }
    final credentials = await _readCredentials();
    if (!credentials.isSuccess) {
      return _buildValidationResult(
        status: credentials.status!,
        protocol: protocol,
        endpoint: endpoint,
        message: credentials.message!,
        detail: credentials.detail!,
      );
    }

    try {
      switch (protocol) {
        case EmailProtocol.imap:
          await _gateway.validateImapLogin(
            endpoint: endpoint,
            account: credentials.account,
            password: credentials.password,
            timeout: timeout,
          );
          break;
        case EmailProtocol.pop:
          await _gateway.validatePopLogin(
            endpoint: endpoint,
            account: credentials.account,
            password: credentials.password,
            timeout: timeout,
          );
          break;
        case EmailProtocol.smtp:
          await _gateway.validateSmtpLogin(
            endpoint: endpoint,
            account: credentials.account,
            password: credentials.password,
            timeout: timeout,
          );
          break;
      }

      return _buildValidationResult(
        status: EmailQueryStatus.success,
        protocol: protocol,
        endpoint: endpoint,
        message: '${protocol.label} 登录校验通过',
        detail: protocol == EmailProtocol.smtp
            ? 'SMTP 仅完成认证与连通性校验，未发送邮件。'
            : '${protocol.label} 已完成登录校验，未修改邮件状态。',
      );
    } on TimeoutException {
      return _validationNetworkFailure(protocol, endpoint, '邮箱服务器响应超时');
    } on SocketException {
      return _validationNetworkFailure(protocol, endpoint, '邮箱服务器网络连接失败');
    } on HandshakeException {
      return _validationNetworkFailure(protocol, endpoint, '邮箱服务器 TLS 握手失败');
    } on ImapException {
      return _validationLoginRejected(protocol, endpoint);
    } on PopException {
      return _validationLoginRejected(protocol, endpoint);
    } on SmtpException {
      return _validationLoginRejected(protocol, endpoint);
    } catch (error) {
      return _buildValidationResult(
        status: EmailQueryStatus.unexpectedError,
        protocol: protocol,
        endpoint: endpoint,
        message: '邮箱登录校验失败',
        detail: '未归类异常类型：${error.runtimeType}',
      );
    }
  }

  @override
  Future<EmailSendResult> sendMessage(EmailComposeRequest request) async {
    final validation = _validateComposeRequest(request);
    if (validation != null) {
      return _buildSendResult(
        status: EmailQueryStatus.invalidInput,
        message: validation.$1,
        detail: validation.$2,
      );
    }
    final attachmentValidation = await _validateAttachmentFiles(request);
    if (attachmentValidation != null) {
      return _buildSendResult(
        status: EmailQueryStatus.invalidInput,
        message: attachmentValidation.$1,
        detail: attachmentValidation.$2,
      );
    }

    final credentials = await _readCredentials();
    if (!credentials.isSuccess) {
      return _buildSendResult(
        status: credentials.status!,
        message: credentials.message!,
        detail: credentials.detail!,
      );
    }

    try {
      await _gateway.sendSmtpMessage(
        endpoint: smtpEndpoint,
        account: credentials.account,
        password: credentials.password,
        request: request,
        timeout: timeout,
      );
      return _buildSendResult(
        status: EmailQueryStatus.success,
        message: '邮件已提交发送',
        detail: '已通过 SMTP 提交普通文本邮件。请以学校邮箱服务端状态为准。',
        recipientsCount: request.recipientCount,
      );
    } on TimeoutException {
      return _sendNetworkFailure('邮箱服务器响应超时');
    } on SocketException {
      return _sendNetworkFailure('邮箱服务器网络连接失败');
    } on HandshakeException {
      return _sendNetworkFailure('邮箱服务器 TLS 握手失败');
    } on SmtpException {
      return _buildSendResult(
        status: EmailQueryStatus.loginRejected,
        message: 'SMTP 发件被拒绝',
        detail: '请确认邮箱账号、邮箱密码、SMTP 客户端协议和收件服务器策略。',
      );
    } catch (error) {
      return _buildSendResult(
        status: EmailQueryStatus.unexpectedError,
        message: '邮件发送失败',
        detail: '未归类异常类型：${error.runtimeType}',
      );
    }
  }

  @override
  Future<EmailMailboxQueryResult> markMessageAsRead(
    EmailMessageSnapshot message,
  ) async {
    final endpoint = endpointFor(EmailProtocol.imap);
    if (!await _isFetchEnabled()) {
      return _buildMailboxResult(
        status: EmailQueryStatus.fetchDisabled,
        protocol: EmailProtocol.imap,
        endpoint: endpoint,
        message: '邮箱已停止获取',
        detail: '已保留当前页面的本地已读状态，不会访问邮箱服务器。',
      );
    }
    if (message.serverUid == null || message.serverUid!.isEmpty) {
      return _buildMailboxResult(
        status: EmailQueryStatus.parseFailed,
        protocol: EmailProtocol.imap,
        endpoint: endpoint,
        message: '邮件缺少服务器标识',
        detail: '当前缓存无法定位到服务器 UID，已保留本地已读状态。',
      );
    }
    final credentials = await _readCredentials();
    if (!credentials.isSuccess) {
      return _buildMailboxResult(
        status: credentials.status!,
        protocol: EmailProtocol.imap,
        endpoint: endpoint,
        message: credentials.message!,
        detail: credentials.detail!,
      );
    }
    try {
      final advancedGateway = _gateway is AdvancedEmailGateway
          ? _gateway as AdvancedEmailGateway
          : null;
      if (advancedGateway == null) {
        throw UnsupportedError('当前邮箱网关不支持已读回写');
      }
      await advancedGateway.markImapMessageSeen(
        endpoint: endpoint,
        account: credentials.account,
        password: credentials.password,
        serverUid: message.serverUid!,
        timeout: timeout,
      );
      return _buildMailboxResult(
        status: EmailQueryStatus.success,
        protocol: EmailProtocol.imap,
        endpoint: endpoint,
        message: '邮件已标记为已读',
        detail: 'IMAP \\Seen 状态已回写服务器。',
      );
    } on TimeoutException {
      return _networkFailure(EmailProtocol.imap, endpoint, '邮箱服务器响应超时');
    } on SocketException {
      return _networkFailure(EmailProtocol.imap, endpoint, '邮箱服务器网络连接失败');
    } on ImapException {
      return _loginRejected(EmailProtocol.imap, endpoint);
    } catch (error) {
      return _buildMailboxResult(
        status: EmailQueryStatus.unexpectedError,
        protocol: EmailProtocol.imap,
        endpoint: endpoint,
        message: '邮件已在本地标记为已读',
        detail: '服务器已读回写失败：${error.runtimeType}。',
      );
    }
  }

  @override
  Future<EmailAttachmentDownloadResult> downloadAttachment(
    EmailMessageSnapshot message,
    EmailAttachmentSnapshot attachment,
  ) async {
    if (!await _isFetchEnabled()) {
      return const EmailAttachmentDownloadResult(
        status: EmailQueryStatus.fetchDisabled,
        message: '邮箱已停止获取',
        detail: '如需下载附件，请先在设置中重新开启邮箱联网获取。',
      );
    }
    if (attachment.id.isEmpty ||
        !_validImapFetchId.hasMatch(attachment.id) ||
        attachment.fileName.trim().isEmpty ||
        attachment.size != null && attachment.size! < 0) {
      return const EmailAttachmentDownloadResult(
        status: EmailQueryStatus.invalidInput,
        message: '附件信息无效',
        detail: '附件定位、名称或大小元数据不完整，已停止下载。',
      );
    }
    final credentials = await _readCredentials();
    if (!credentials.isSuccess) {
      return EmailAttachmentDownloadResult(
        status: credentials.status!,
        message: credentials.message!,
        detail: credentials.detail!,
      );
    }
    if (message.serverUid == null || message.serverUid!.isEmpty) {
      return const EmailAttachmentDownloadResult(
        status: EmailQueryStatus.parseFailed,
        message: '邮件缺少服务器标识',
        detail: '当前缓存无法定位服务器邮件，不能按需下载附件。',
      );
    }
    final advancedGateway = _gateway is AdvancedEmailGateway
        ? _gateway as AdvancedEmailGateway
        : null;
    if (advancedGateway == null) {
      return const EmailAttachmentDownloadResult(
        status: EmailQueryStatus.parseFailed,
        message: '当前协议不支持附件按需下载',
        detail: '请切换到支持 MIME part 读取的 IMAP 协议。',
      );
    }
    try {
      final download = await advancedGateway.fetchImapAttachment(
        endpoint: imapEndpoint,
        account: credentials.account,
        password: credentials.password,
        serverUid: message.serverUid!,
        fetchId: attachment.id,
        fileName: attachment.fileName,
        mediaType: attachment.mediaType,
        timeout: timeout,
      );
      if (download == null) {
        return const EmailAttachmentDownloadResult(
          status: EmailQueryStatus.parseFailed,
          message: '附件内容不可用',
          detail: '服务器未返回对应 MIME part，附件可能已移动或协议不支持分段读取。',
        );
      }
      return EmailAttachmentDownloadResult(
        status: EmailQueryStatus.success,
        message: '附件下载完成',
        detail: '附件已按需读取并通过本地元数据校验。',
        download: download,
      );
    } on TimeoutException {
      return const EmailAttachmentDownloadResult(
        status: EmailQueryStatus.networkError,
        message: '附件下载超时',
        detail: '邮箱服务器未在规定时间内返回附件内容。',
      );
    } on SocketException {
      return const EmailAttachmentDownloadResult(
        status: EmailQueryStatus.networkError,
        message: '附件下载网络连接失败',
        detail: '请检查网络、校园网或 VPN 状态后重试。',
      );
    } on HandshakeException {
      return const EmailAttachmentDownloadResult(
        status: EmailQueryStatus.networkError,
        message: '附件下载安全连接失败',
        detail: '邮箱服务器 TLS 握手未完成。',
      );
    } on ImapException {
      return const EmailAttachmentDownloadResult(
        status: EmailQueryStatus.loginRejected,
        message: '附件下载被邮箱服务器拒绝',
        detail: '请检查邮箱密码与 IMAP 客户端协议是否已启用。',
      );
    } catch (error) {
      return EmailAttachmentDownloadResult(
        status: EmailQueryStatus.unexpectedError,
        message: '附件下载失败',
        detail: '未归类异常类型：${error.runtimeType}',
      );
    }
  }

  static final RegExp _validImapFetchId = RegExp(r'^\d+(?:\.\d+)*(?:\.TEXT)?$');

  /// 返回协议对应的默认服务端点。
  EmailServerEndpoint endpointFor(EmailProtocol protocol) {
    return switch (protocol) {
      EmailProtocol.imap => imapEndpoint,
      EmailProtocol.pop => popEndpoint,
      EmailProtocol.smtp => smtpEndpoint,
    };
  }

  String _mailboxCacheCollection(EmailProtocol protocol) {
    return '${StorageKeys.emailMailboxCacheCollection}_${protocol.name}';
  }

  (String, String)? _validateComposeRequest(EmailComposeRequest request) {
    if (request.to.isEmpty) {
      return ('请填写收件人', '至少需要填写一个 To 收件人。');
    }
    if (request.recipientCount > maxSendRecipients) {
      return ('收件人过多', '单次发送最多支持 $maxSendRecipients 个收件人。');
    }
    if (request.subject.trim().isEmpty) {
      return ('请填写邮件主题', '主题不能为空。');
    }
    if (request.subject.trim().length > maxSendSubjectLength) {
      return ('邮件主题过长', '主题最多 $maxSendSubjectLength 个字符。');
    }
    if (request.body.trim().isEmpty) {
      return ('请填写邮件正文', '正文不能为空。');
    }
    if (request.body.length > maxSendBodyLength) {
      return ('邮件正文过长', '正文最多 $maxSendBodyLength 个字符。');
    }
    if (request.attachments.length > maxAttachmentCount) {
      return ('附件过多', '单次发送最多支持 $maxAttachmentCount 个附件。');
    }

    for (final address in [...request.to, ...request.cc, ...request.bcc]) {
      if (!_looksLikeEmailAddress(address)) {
        return ('收件人格式不正确', '请检查 To / Cc / Bcc 中的邮箱地址格式。');
      }
    }
    return null;
  }

  Future<(String, String)?> _validateAttachmentFiles(
    EmailComposeRequest request,
  ) async {
    var totalBytes = 0;
    for (final attachment in request.attachments) {
      final file = File(attachment.path);
      if (!await file.exists()) {
        return ('附件不可用', '附件“${attachment.fileName}”已移动或删除，请重新选择。');
      }
      totalBytes += await file.length();
      if (totalBytes > maxAttachmentBytes) {
        return ('附件总大小过大', '单次发送的附件总大小不能超过 100 MB。');
      }
    }
    return null;
  }

  bool _looksLikeEmailAddress(String raw) {
    final address = raw.trim();
    if (address.isEmpty || address.length > 254) return false;
    final atIndex = address.indexOf('@');
    return atIndex > 0 &&
        atIndex == address.lastIndexOf('@') &&
        atIndex < address.length - 1 &&
        address.substring(atIndex + 1).contains('.') &&
        !address.contains(RegExp(r'\s'));
  }

  Future<_EmailCredentials> _readCredentials() async {
    final status = await _credentialsService.getStatus();
    final account = normalizeEmailAccount(status.oaAccount);
    if (account.isEmpty) {
      return const _EmailCredentials.failure(
        status: EmailQueryStatus.missingEmailAccount,
        message: '请先保存学工号',
        detail: '学校邮箱账号固定为“学工号@sspu.edu.cn”，需先保存学工号。',
      );
    }

    final password = await _credentialsService.readSecret(
      AcademicCredentialSecret.emailPassword,
    );
    if (password == null || password.isEmpty) {
      return const _EmailCredentials.failure(
        status: EmailQueryStatus.missingEmailPassword,
        message: '请先保存邮箱密码',
        detail: '邮箱系统使用邮箱密码，不要求 OA 密码。',
      );
    }

    return _EmailCredentials.success(account: account, password: password);
  }

  EmailMailboxQueryResult _networkFailure(
    EmailProtocol protocol,
    EmailServerEndpoint endpoint,
    String message,
  ) {
    return _buildMailboxResult(
      status: EmailQueryStatus.networkError,
      protocol: protocol,
      endpoint: endpoint,
      message: message,
      detail: '${protocol.label} 端点 ${endpoint.host}:${endpoint.port} 无法完成连接。',
    );
  }

  EmailMailboxQueryResult _loginRejected(
    EmailProtocol protocol,
    EmailServerEndpoint endpoint,
  ) {
    return _buildMailboxResult(
      status: EmailQueryStatus.loginRejected,
      protocol: protocol,
      endpoint: endpoint,
      message: '${protocol.label} 登录或只读查询被拒绝',
      detail: '请确认邮箱账号、邮箱密码和 ${protocol.label} 客户端协议已启用。',
    );
  }

  EmailLoginValidationResult _validationNetworkFailure(
    EmailProtocol protocol,
    EmailServerEndpoint endpoint,
    String message,
  ) {
    return _buildValidationResult(
      status: EmailQueryStatus.networkError,
      protocol: protocol,
      endpoint: endpoint,
      message: message,
      detail: '${protocol.label} 端点 ${endpoint.host}:${endpoint.port} 无法完成连接。',
    );
  }

  EmailLoginValidationResult _validationLoginRejected(
    EmailProtocol protocol,
    EmailServerEndpoint endpoint,
  ) {
    return _buildValidationResult(
      status: EmailQueryStatus.loginRejected,
      protocol: protocol,
      endpoint: endpoint,
      message: '${protocol.label} 登录校验未通过',
      detail: '请确认邮箱账号、邮箱密码和 ${protocol.label} 客户端协议已启用。',
    );
  }

  EmailSendResult _sendNetworkFailure(String message) {
    return _buildSendResult(
      status: EmailQueryStatus.networkError,
      message: message,
      detail: 'SMTP 端点 ${smtpEndpoint.host}:${smtpEndpoint.port} 无法完成连接。',
    );
  }

  EmailMailboxQueryResult _buildMailboxResult({
    required EmailQueryStatus status,
    required EmailProtocol protocol,
    required EmailServerEndpoint endpoint,
    required String message,
    required String detail,
    DateTime? checkedAt,
    EmailMailboxSnapshot? snapshot,
  }) {
    return EmailMailboxQueryResult(
      status: status,
      protocol: protocol,
      message: message,
      detail: detail,
      checkedAt: checkedAt ?? DateTime.now(),
      endpoint: endpoint,
      snapshot: snapshot,
    );
  }

  EmailLoginValidationResult _buildValidationResult({
    required EmailQueryStatus status,
    required EmailProtocol protocol,
    required EmailServerEndpoint endpoint,
    required String message,
    required String detail,
  }) {
    return EmailLoginValidationResult(
      status: status,
      protocol: protocol,
      message: message,
      detail: detail,
      checkedAt: DateTime.now(),
      endpoint: endpoint,
    );
  }

  EmailSendResult _buildSendResult({
    required EmailQueryStatus status,
    required String message,
    required String detail,
    int recipientsCount = 0,
  }) {
    return EmailSendResult(
      status: status,
      message: message,
      detail: detail,
      checkedAt: DateTime.now(),
      endpoint: smtpEndpoint,
      recipientsCount: recipientsCount,
    );
  }
}
