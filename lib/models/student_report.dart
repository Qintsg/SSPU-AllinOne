/*
 * 学工报表模型 — 描述第二课堂学分只读查询结果
 * @Project : SSPU-AllinOne
 * @File : student_report.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

import 'campus_network_status.dart';

/// 学工报表系统查询状态。
enum StudentReportQueryStatus {
  /// 查询或登录校验成功。
  success,

  /// 未保存学工号 / OA 账号。
  missingOaAccount,

  /// 未保存 OA 密码。
  missingOaPassword,

  /// 校园网 / VPN 前置检测不可达。
  campusNetworkUnavailable,

  /// OA/CAS 登录状态不可用，无法进入学工报表系统。
  oaLoginRequired,

  /// 学工报表系统页面不可用或仍停留本地登录页。
  reportSystemUnavailable,

  /// 未找到第二课堂学分查询入口。
  secondClassroomEntryUnavailable,

  /// 页面结构无法解析为第二课堂学分。
  parseFailed,

  /// 网络请求失败或超时。
  networkError,

  /// 未归类异常。
  unexpectedError,
}

/// 第二课堂学分明细记录。
class SecondClassroomCreditRecord {
  const SecondClassroomCreditRecord({
    required this.category,
    required this.itemName,
    required this.credit,
    required this.rawCells,
    this.semester,
    this.occurredAt,
    this.status,
  });

  /// 学分类别或模块名称。
  final String category;

  /// 活动、项目或课程名称。
  final String itemName;

  /// 认定学分。
  final double credit;

  /// 成绩归属学期，保持页面原始格式。
  final String? semester;

  /// 发生或认定时间，保持页面原始格式。
  final String? occurredAt;

  /// 审核、认定或记录状态。
  final String? status;

  /// 原始表格单元格，页面变化时用于兜底展示。
  final List<String> rawCells;

  /// 从 JSON 恢复第二课堂学分记录。
  factory SecondClassroomCreditRecord.fromJson(Map<String, dynamic> json) {
    return SecondClassroomCreditRecord(
      category: json['category'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      credit: (json['credit'] as num?)?.toDouble() ?? 0,
      rawCells: (json['rawCells'] as List<dynamic>? ?? const []).cast<String>(),
      semester: json['semester'] as String?,
      occurredAt: json['occurredAt'] as String?,
      status: json['status'] as String?,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'itemName': itemName,
      'credit': credit,
      'rawCells': rawCells,
      'semester': semester,
      'occurredAt': occurredAt,
      'status': status,
    };
  }
}

/// 第二课堂学分规则矩阵行。
class SecondClassroomCreditRuleRow {
  const SecondClassroomCreditRuleRow({
    required this.category,
    required this.item,
    required this.level,
    required this.participation,
    required this.credit,
    required this.earnedCredit,
    required this.requiredCredit,
    required this.passStatus,
  });

  /// 类别。
  final String category;

  /// 项目。
  final String item;

  /// 等级。
  final String level;

  /// 参与情况。
  final String participation;

  /// 积分。
  final double? credit;

  /// 已获分数。
  final double? earnedCredit;

  /// 必修积分。
  final double? requiredCredit;

  /// 通过情况。
  final String passStatus;

  /// 从 JSON 恢复规则矩阵行。
  factory SecondClassroomCreditRuleRow.fromJson(Map<String, dynamic> json) {
    return SecondClassroomCreditRuleRow(
      category: json['category'] as String? ?? '',
      item: json['item'] as String? ?? '',
      level: json['level'] as String? ?? '',
      participation: json['participation'] as String? ?? '',
      credit: (json['credit'] as num?)?.toDouble(),
      earnedCredit: (json['earnedCredit'] as num?)?.toDouble(),
      requiredCredit: (json['requiredCredit'] as num?)?.toDouble(),
      passStatus: json['passStatus'] as String? ?? '',
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'item': item,
      'level': level,
      'participation': participation,
      'credit': credit,
      'earnedCredit': earnedCredit,
      'requiredCredit': requiredCredit,
      'passStatus': passStatus,
    };
  }
}

/// 第二课堂学分总计行。
class SecondClassroomCreditTotals {
  const SecondClassroomCreditTotals({
    this.totalCredit,
    this.totalEarnedCredit,
    this.totalRequiredCredit,
    this.passStatus,
  });

  /// 总积分。
  final double? totalCredit;

  /// 总已获分数。
  final double? totalEarnedCredit;

  /// 总必修积分。
  final double? totalRequiredCredit;

  /// 总体通过情况。
  final String? passStatus;

  /// 从 JSON 恢复总计。
  factory SecondClassroomCreditTotals.fromJson(Map<String, dynamic> json) {
    return SecondClassroomCreditTotals(
      totalCredit: (json['totalCredit'] as num?)?.toDouble(),
      totalEarnedCredit: (json['totalEarnedCredit'] as num?)?.toDouble(),
      totalRequiredCredit: (json['totalRequiredCredit'] as num?)?.toDouble(),
      passStatus: json['passStatus'] as String?,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'totalCredit': totalCredit,
      'totalEarnedCredit': totalEarnedCredit,
      'totalRequiredCredit': totalRequiredCredit,
      'passStatus': passStatus,
    };
  }
}

/// 第二课堂已获分数详情记录。
class SecondClassroomCreditDetailRecord {
  const SecondClassroomCreditDetailRecord({
    required this.name,
    required this.category,
    required this.item,
    required this.level,
    required this.participation,
    required this.earnedCredit,
  });

  /// 名称。
  final String name;

  /// 类别。
  final String category;

  /// 项目。
  final String item;

  /// 等级。
  final String level;

  /// 参与情况。
  final String participation;

  /// 获得积分。
  final double? earnedCredit;

  /// 从 JSON 恢复详情记录。
  factory SecondClassroomCreditDetailRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return SecondClassroomCreditDetailRecord(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      item: json['item'] as String? ?? '',
      level: json['level'] as String? ?? '',
      participation: json['participation'] as String? ?? '',
      earnedCredit: (json['earnedCredit'] as num?)?.toDouble(),
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'item': item,
      'level': level,
      'participation': participation,
      'earnedCredit': earnedCredit,
    };
  }
}

/// 第二课堂学分统计快照。
class SecondClassroomCreditSummary {
  const SecondClassroomCreditSummary({
    required this.records,
    required this.fetchedAt,
    required this.sourceUri,
    this.rules = const [],
    this.totals,
    this.detailRecords = const [],
    this.warning,
  });

  /// 第二课堂逐项得分明细；不将明细分值相加作为官方总学分。
  final List<SecondClassroomCreditRecord> records;

  /// 第二课堂规则矩阵。
  final List<SecondClassroomCreditRuleRow> rules;

  /// 页面总计行。
  final SecondClassroomCreditTotals? totals;

  /// “已获分数”详情记录。
  final List<SecondClassroomCreditDetailRecord> detailRecords;

  /// 部分详情读取或解析失败时的安全提示。
  final String? warning;

  /// 本地解析完成时间。
  final DateTime fetchedAt;

  /// 产生该快照的最后一个业务页面地址。
  final Uri sourceUri;

  /// 从 JSON 恢复第二课堂学分统计。
  factory SecondClassroomCreditSummary.fromJson(Map<String, dynamic> json) {
    final legacyRecords = (json['records'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SecondClassroomCreditRecord.fromJson)
        .toList();
    return SecondClassroomCreditSummary(
      records: legacyRecords,
      rules: (json['rules'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SecondClassroomCreditRuleRow.fromJson)
          .toList(),
      totals: json['totals'] is Map<String, dynamic>
          ? SecondClassroomCreditTotals.fromJson(
              json['totals'] as Map<String, dynamic>,
            )
          : null,
      detailRecords: (json['detailRecords'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SecondClassroomCreditDetailRecord.fromJson)
          .toList(),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sourceUri: Uri.parse(json['sourceUri'] as String? ?? ''),
      warning: json['warning'] as String?,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'records': records.map((record) => record.toJson()).toList(),
      'rules': rules.map((rule) => rule.toJson()).toList(),
      'totals': totals?.toJson(),
      'detailRecords': detailRecords.map((record) => record.toJson()).toList(),
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'sourceUri': sourceUri.toString(),
      'warning': warning,
    };
  }
}

/// 学工报表只读查询或登录校验结果。
class StudentReportQueryResult {
  const StudentReportQueryResult({
    required this.status,
    required this.message,
    required this.detail,
    required this.checkedAt,
    required this.entranceUri,
    this.finalUri,
    this.campusNetworkStatus,
    this.summary,
  });

  /// 结构化状态，用于 UI 判断展示级别。
  final StudentReportQueryStatus status;

  /// 面向用户的简短说明，不包含 Cookie、Ticket 等敏感值。
  final String message;

  /// 面向排查的安全详情，不包含凭据原文。
  final String detail;

  /// 本次查询完成时间。
  final DateTime checkedAt;

  /// 学工报表 OA 入口地址。
  final Uri entranceUri;

  /// 查询结束时的最终地址。
  final Uri? finalUri;

  /// 校园网 / VPN 前置检测结果。
  final CampusNetworkStatus? campusNetworkStatus;

  /// 成功读取时的第二课堂学分统计。
  final SecondClassroomCreditSummary? summary;

  /// 是否操作成功。
  bool get isSuccess => status == StudentReportQueryStatus.success;
}
