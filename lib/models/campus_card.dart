/*
 * 校园卡查询模型 — 描述余额、卡状态和交易记录只读查询结果
 * @Project : SSPU-AllinOne
 * @File : campus_card.dart
 * @Author : Qintsg
 * @Date : 2026-04-30
 */

import 'campus_network_status.dart';

/// 校园卡查询状态。
enum CampusCardQueryStatus {
  /// 查询成功，至少读取到余额或交易记录。
  success,

  /// 未保存学工号 / OA 账号。
  missingOaAccount,

  /// 未保存 OA 密码，无法刷新 CAS 登录状态。
  missingOaPassword,

  /// 校园网 / VPN 前置检测不可达。
  campusNetworkUnavailable,

  /// OA/CAS 登录状态不可用，无法进入校园卡系统。
  oaLoginRequired,

  /// 校园卡系统业务页不可用。
  cardSystemUnavailable,

  /// 页面结构无法解析为余额、状态或交易记录。
  parseFailed,

  /// 网络请求失败或超时。
  networkError,

  /// 未归类异常。
  unexpectedError,
}

/// 校园卡单条交易记录。
class CampusCardTransactionRecord {
  const CampusCardTransactionRecord({
    required this.occurredAt,
    required this.amount,
    required this.rawCells,
    this.merchant,
    this.type,
    this.balanceAfter,
    this.title,
    this.transactionId,
    this.counterparty,
    this.paymentMethod,
    this.status,
  });

  /// 交易发生时间，保持页面原始格式以避免误转换时区。
  final String occurredAt;

  /// 交易金额，消费通常为负数，充值或补助通常为正数。
  final double amount;

  /// 页面展示的商户、地点或摘要。
  final String? merchant;

  /// 交易类型，例如消费、充值、补助等。
  final String? type;

  /// 交易后余额；页面未提供时为空。
  final double? balanceAfter;

  /// 交易名称，对应 epay 表格的“名称”列。
  final String? title;

  /// 交易号或流水号。
  final String? transactionId;

  /// 交易对方、商户或收付款方。
  final String? counterparty;

  /// 付款方式，例如校园卡、钱包或其它页面原始文案。
  final String? paymentMethod;

  /// 单条交易状态，例如成功、失败或处理中。
  final String? status;

  /// 原始表格单元格文本，页面结构变化时用于兜底展示。
  final List<String> rawCells;

  /// 从 JSON 恢复校园卡交易记录。
  factory CampusCardTransactionRecord.fromJson(Map<String, dynamic> json) {
    return CampusCardTransactionRecord(
      occurredAt: json['occurredAt'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      merchant: json['merchant'] as String?,
      type: json['type'] as String?,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
      title: json['title'] as String?,
      transactionId: json['transactionId'] as String?,
      counterparty: json['counterparty'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      status: json['status'] as String?,
      rawCells: (json['rawCells'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'occurredAt': occurredAt,
      'amount': amount,
      'merchant': merchant,
      'type': type,
      'balanceAfter': balanceAfter,
      'title': title,
      'transactionId': transactionId,
      'counterparty': counterparty,
      'paymentMethod': paymentMethod,
      'status': status,
      'rawCells': rawCells,
    };
  }
}

/// 校园卡余额与交易记录快照。
class CampusCardSnapshot {
  const CampusCardSnapshot({
    required this.balance,
    required this.status,
    required this.records,
    required this.fetchedAt,
    required this.sourceUri,
  });

  /// 当前账户余额；页面未提供余额但提供交易记录时为空。
  final double? balance;

  /// 卡状态；页面未提供时为空字符串。
  final String status;

  /// 最近或查询得到的交易记录。
  final List<CampusCardTransactionRecord> records;

  /// 本地解析完成时间。
  final DateTime fetchedAt;

  /// 产生该快照的最后一个业务页面地址。
  final Uri sourceUri;

  /// 从 JSON 恢复校园卡快照。
  factory CampusCardSnapshot.fromJson(Map<String, dynamic> json) {
    return CampusCardSnapshot(
      balance: (json['balance'] as num?)?.toDouble(),
      status: json['status'] as String? ?? '',
      records: (json['records'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CampusCardTransactionRecord.fromJson)
          .toList(),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sourceUri: Uri.parse(json['sourceUri'] as String? ?? ''),
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'status': status,
      'records': records.map((record) => record.toJson()).toList(),
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'sourceUri': sourceUri.toString(),
    };
  }

  /// 页面是否明确显示非正常状态。
  bool get hasAbnormalStatus {
    final normalizedStatus = status.trim();
    if (normalizedStatus.isEmpty) return false;
    return normalizedStatus != '正常' &&
        normalizedStatus != '有效' &&
        normalizedStatus != '可用';
  }
}

/// 校园卡只读查询结果。
class CampusCardQueryResult {
  const CampusCardQueryResult({
    required this.status,
    required this.message,
    required this.detail,
    required this.checkedAt,
    required this.entranceUri,
    this.finalUri,
    this.campusNetworkStatus,
    this.snapshot,
  });

  /// 结构化状态，用于 UI 判断展示级别。
  final CampusCardQueryStatus status;

  /// 面向用户的简短说明，不包含 Cookie、Ticket 等敏感值。
  final String message;

  /// 面向排查的安全详情，不包含凭据原文。
  final String detail;

  /// 本次查询完成时间。
  final DateTime checkedAt;

  /// 校园卡 OA 入口地址。
  final Uri entranceUri;

  /// 查询结束时的最终地址。
  final Uri? finalUri;

  /// 校园网 / VPN 前置检测结果。
  final CampusNetworkStatus? campusNetworkStatus;

  /// 成功时的余额、状态与交易记录快照。
  final CampusCardSnapshot? snapshot;

  /// 是否查询成功。
  bool get isSuccess => status == CampusCardQueryStatus.success;
}
