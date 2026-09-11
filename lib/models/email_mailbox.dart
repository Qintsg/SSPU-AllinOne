/*
 * 学校邮箱模型 — 描述收信、发信与协议登录校验结果
 * @Project : SSPU-AllinOne
 * @File : email_mailbox.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

/// 学校邮箱支持的协议类型。
enum EmailProtocol {
  /// IMAP 只读收信协议。
  imap,

  /// POP 只读收信协议。
  pop,

  /// SMTP 发信协议；收信仍不可使用。
  smtp,
}

/// 邮箱协议展示名称。
extension EmailProtocolLabel on EmailProtocol {
  /// 用户可读的协议名称。
  String get label {
    return switch (this) {
      EmailProtocol.imap => 'IMAP',
      EmailProtocol.pop => 'POP',
      EmailProtocol.smtp => 'SMTP',
    };
  }
}

/// 邮箱查询、发信或协议校验状态。
enum EmailQueryStatus {
  /// 操作成功。
  success,

  /// 用户已在设置中停止邮箱联网获取。
  fetchDisabled,

  /// 未保存用于派生学校邮箱账号的学工号。
  missingEmailAccount,

  /// 未保存学校邮箱密码。
  missingEmailPassword,

  /// 表单输入不完整或格式不合法。
  invalidInput,

  /// 邮箱服务器拒绝登录或协议未启用。
  loginRejected,

  /// 邮箱内容解析失败。
  parseFailed,

  /// 网络连接、TLS 握手或超时失败。
  networkError,

  /// 未归类异常。
  unexpectedError,
}

/// 邮箱撰写请求，仅保留用户主动输入的发信字段。
class EmailComposeRequest {
  const EmailComposeRequest({
    required this.to,
    required this.subject,
    required this.body,
    this.cc = const [],
    this.bcc = const [],
    this.attachments = const [],
  });

  /// 收件人地址列表，至少一个。
  final List<String> to;

  /// 抄送地址列表。
  final List<String> cc;

  /// 密送地址列表。
  final List<String> bcc;

  /// 邮件主题。
  final String subject;

  /// 纯文本正文。
  final String body;

  /// 用户主动选择、随 SMTP 邮件发送的本地附件。
  final List<EmailAttachmentRequest> attachments;

  /// 所有收件人数量。
  int get recipientCount => to.length + cc.length + bcc.length;
}

/// 本地待发送附件的最小描述，不把二进制内容放入普通缓存。
class EmailAttachmentRequest {
  const EmailAttachmentRequest({
    required this.path,
    required this.fileName,
    this.mediaType = 'application/octet-stream',
    this.size,
  });

  final String path;
  final String fileName;
  final String mediaType;
  final int? size;
}

/// 收件箱附件元数据；下载时才读取正文二进制。
class EmailAttachmentSnapshot {
  const EmailAttachmentSnapshot({
    required this.id,
    required this.fileName,
    required this.mediaType,
    this.size,
  });

  final String id;
  final String fileName;
  final String mediaType;
  final int? size;

  factory EmailAttachmentSnapshot.fromJson(Map<String, dynamic> json) {
    return EmailAttachmentSnapshot(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '附件',
      mediaType: json['mediaType'] as String? ?? 'application/octet-stream',
      size: (json['size'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'mediaType': mediaType,
    'size': size,
  };
}

/// 按需下载附件的结果。
class EmailAttachmentDownload {
  const EmailAttachmentDownload({
    required this.fileName,
    required this.mediaType,
    required this.bytes,
  });

  final String fileName;
  final String mediaType;
  final List<int> bytes;
}

/// 附件按需下载结果；失败时不携带二进制内容。
class EmailAttachmentDownloadResult {
  const EmailAttachmentDownloadResult({
    required this.status,
    required this.message,
    required this.detail,
    this.download,
  });

  final EmailQueryStatus status;
  final String message;
  final String detail;
  final EmailAttachmentDownload? download;

  bool get isSuccess => status == EmailQueryStatus.success && download != null;
}

/// SMTP 主动发件结果。
class EmailSendResult {
  const EmailSendResult({
    required this.status,
    required this.message,
    required this.detail,
    required this.checkedAt,
    required this.endpoint,
    this.recipientsCount = 0,
  });

  /// 结构化状态，用于 UI 判断提示等级。
  final EmailQueryStatus status;

  /// 面向用户的简短说明，不包含收件人、正文或密码。
  final String message;

  /// 安全排查详情，不包含收件人、正文或密码。
  final String detail;

  /// 本次操作完成时间。
  final DateTime checkedAt;

  /// 本次操作使用的 SMTP 服务端点。
  final EmailServerEndpoint endpoint;

  /// 本次发送涉及的收件人数量。
  final int recipientsCount;

  /// 是否发送成功。
  bool get isSuccess => status == EmailQueryStatus.success;
}

/// 邮箱服务端点配置。
class EmailServerEndpoint {
  const EmailServerEndpoint({
    required this.host,
    required this.port,
    required this.isSecure,
  });

  /// 邮箱服务器域名。
  final String host;

  /// 邮箱服务端口。
  final int port;

  /// 是否从连接建立时即使用 TLS。
  final bool isSecure;

  /// 从 JSON 恢复邮箱服务端点。
  factory EmailServerEndpoint.fromJson(Map<String, dynamic> json) {
    return EmailServerEndpoint(
      host: json['host'] as String? ?? '',
      port: (json['port'] as num?)?.toInt() ?? 0,
      isSecure: json['isSecure'] as bool? ?? true,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {'host': host, 'port': port, 'isSecure': isSecure};
  }
}

/// 单封邮件的只读展示快照。
class EmailMessageSnapshot {
  const EmailMessageSnapshot({
    required this.id,
    required this.subject,
    required this.senderName,
    required this.senderAddress,
    required this.preview,
    required this.body,
    this.receivedAt,
    this.isRead = true,
    this.serverUid,
    this.attachments = const [],
  });

  /// 邮件在当前协议结果中的稳定展示标识，不用于服务器写操作。
  final String id;

  /// 邮件标题，缺失时由服务层填充兜底文案。
  final String subject;

  /// 发件人显示名。
  final String senderName;

  /// 发件人邮箱地址。
  final String senderAddress;

  /// 正文摘要，便于列表快速浏览。
  final String preview;

  /// 已解析的正文文本，可能为空字符串。
  final String body;

  /// 邮件头中的发送时间。
  final DateTime? receivedAt;

  /// 服务器返回的已读状态；POP 协议通常没有可靠状态。
  final bool isRead;

  /// IMAP UID，用于已读回写和按需下载附件。
  final String? serverUid;

  /// 附件元数据，不包含附件二进制。
  final List<EmailAttachmentSnapshot> attachments;

  EmailMessageSnapshot copyWith({
    bool? isRead,
    String? serverUid,
    List<EmailAttachmentSnapshot>? attachments,
  }) {
    return EmailMessageSnapshot(
      id: id,
      subject: subject,
      senderName: senderName,
      senderAddress: senderAddress,
      preview: preview,
      body: body,
      receivedAt: receivedAt,
      isRead: isRead ?? this.isRead,
      serverUid: serverUid ?? this.serverUid,
      attachments: attachments ?? this.attachments,
    );
  }

  /// 从 JSON 恢复邮件快照。
  factory EmailMessageSnapshot.fromJson(Map<String, dynamic> json) {
    return EmailMessageSnapshot(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      senderAddress: json['senderAddress'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      body: json['body'] as String? ?? '',
      receivedAt: DateTime.tryParse(
        json['receivedAt'] as String? ?? '',
      )?.toLocal(),
      isRead: json['isRead'] as bool? ?? true,
      serverUid: json['serverUid'] as String?,
      attachments: (json['attachments'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(EmailAttachmentSnapshot.fromJson)
          .toList(),
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'senderName': senderName,
      'senderAddress': senderAddress,
      'preview': preview,
      'body': body,
      'receivedAt': receivedAt?.toUtc().toIso8601String(),
      'isRead': isRead,
      'serverUid': serverUid,
      'attachments': attachments
          .map((attachment) => attachment.toJson())
          .toList(),
    };
  }
}

/// 邮箱一次只读收信快照。
class EmailMailboxSnapshot {
  const EmailMailboxSnapshot({
    required this.protocol,
    required this.account,
    required this.messages,
    required this.fetchedAt,
    required this.endpoint,
  });

  /// 本次读取使用的协议。
  final EmailProtocol protocol;

  /// 规范化后的邮箱账号。
  final String account;

  /// 最近邮件列表，按新到旧展示。
  final List<EmailMessageSnapshot> messages;

  /// 本地读取完成时间。
  final DateTime fetchedAt;

  /// 本次读取使用的服务端点。
  final EmailServerEndpoint endpoint;

  /// 从 JSON 恢复邮箱快照。
  factory EmailMailboxSnapshot.fromJson(Map<String, dynamic> json) {
    final protocolName = json['protocol'] as String?;
    final protocol = EmailProtocol.values.firstWhere(
      (value) => value.name == protocolName,
      orElse: () => EmailProtocol.imap,
    );
    return EmailMailboxSnapshot(
      protocol: protocol,
      account: '',
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(EmailMessageSnapshot.fromJson)
          .toList(),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endpoint: EmailServerEndpoint.fromJson(
        json['endpoint'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'protocol': protocol.name,
      'messages': messages.map((message) => message.toJson()).toList(),
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'endpoint': endpoint.toJson(),
    };
  }
}

/// 邮箱只读收信结果。
class EmailMailboxQueryResult {
  const EmailMailboxQueryResult({
    required this.status,
    required this.protocol,
    required this.message,
    required this.detail,
    required this.checkedAt,
    required this.endpoint,
    this.snapshot,
  });

  /// 结构化状态，用于 UI 判断提示等级。
  final EmailQueryStatus status;

  /// 本次操作使用的协议。
  final EmailProtocol protocol;

  /// 面向用户的简短说明，不包含邮箱密码。
  final String message;

  /// 安全排查详情，不包含账号密码原文。
  final String detail;

  /// 本次操作完成时间。
  final DateTime checkedAt;

  /// 本次操作使用的服务端点。
  final EmailServerEndpoint endpoint;

  /// 成功读取时的邮件快照。
  final EmailMailboxSnapshot? snapshot;

  /// 是否操作成功。
  bool get isSuccess => status == EmailQueryStatus.success;
}

/// 邮箱协议登录校验结果。
class EmailLoginValidationResult {
  const EmailLoginValidationResult({
    required this.status,
    required this.protocol,
    required this.message,
    required this.detail,
    required this.checkedAt,
    required this.endpoint,
  });

  /// 结构化状态，用于 UI 判断提示等级。
  final EmailQueryStatus status;

  /// 本次校验使用的协议。
  final EmailProtocol protocol;

  /// 面向用户的简短说明，不包含邮箱密码。
  final String message;

  /// 安全排查详情，不包含账号密码原文。
  final String detail;

  /// 本次校验完成时间。
  final DateTime checkedAt;

  /// 本次校验使用的服务端点。
  final EmailServerEndpoint endpoint;

  /// 是否校验成功。
  bool get isSuccess => status == EmailQueryStatus.success;
}
