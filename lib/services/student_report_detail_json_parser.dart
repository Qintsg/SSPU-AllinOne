/*
 * 学工报表详情 JSON 解析器 — 解析已获积分弹窗接口返回
 * @Project : SSPU-AllinOne
 * @File : student_report_detail_json_parser.dart
 * @Author : Qintsg
 * @Date : 2026-06-10
 */

part of 'student_report_service.dart';

/// 解析第二课堂“已获积分”弹窗接口返回的 JSON 数据。
class _StudentReportDetailJsonParser {
  _StudentReportDetailJsonParser._();

  /// 从 JSON 响应中提取只需本地加密保存的详情字段。
  static List<SecondClassroomCreditDetailRecord> parse(String body) {
    Object? value;
    try {
      value = jsonDecode(body);
    } catch (_) {
      return const [];
    }
    final records = <SecondClassroomCreditDetailRecord>[];
    _collectRecords(value, records);
    return records;
  }

  static void _collectRecords(
    Object? value,
    List<SecondClassroomCreditDetailRecord> records,
  ) {
    if (value is List) {
      for (final item in value) {
        _collectRecords(item, records);
      }
      return;
    }
    if (value is! Map) return;

    final normalized = <String, Object?>{};
    for (final entry in value.entries) {
      normalized[_normalizeKey(entry.key.toString())] = entry.value;
    }

    final record = _recordFromMap(normalized);
    if (record != null) records.add(record);

    for (final key in const ['rows', 'data', 'list', 'records', 'result']) {
      final nested = normalized[_normalizeKey(key)];
      if (nested is List || nested is Map) _collectRecords(nested, records);
    }
  }

  static SecondClassroomCreditDetailRecord? _recordFromMap(
    Map<String, Object?> value,
  ) {
    final name = _stringValue(value, const [
      '名称',
      'name',
      'activityname',
      'projectname',
      'title',
    ]);
    final category = _stringValue(value, const [
      '类别',
      'category',
      'type',
      'lb',
      'sort',
      'xiangmuleibie',
    ]);
    final item = _stringValue(value, const [
      '项目',
      'project',
      'item',
      'xm',
      'itemname',
      'xingzhi',
    ]);
    final level = _stringValue(value, const [
      '等级',
      'level',
      'rank',
      'dj',
      'grade',
      'jibie',
    ]);
    final participation = _stringValue(value, const [
      '参与情况',
      '参与情况h',
      'participation',
      'hours',
      'hour',
      'h',
      'cyqk',
      'shichang',
    ]);
    final earnedCredit = _numberValue(value, const [
      '获得积分',
      '获得分数',
      'earnedcredit',
      'score',
      'integral',
      'credit',
      'point',
      'xf',
      'jifen',
    ]);
    if (name.isEmpty &&
        category.isEmpty &&
        item.isEmpty &&
        level.isEmpty &&
        participation.isEmpty &&
        earnedCredit == null) {
      return null;
    }
    return SecondClassroomCreditDetailRecord(
      name: name,
      category: category,
      item: item,
      level: level,
      participation: participation,
      earnedCredit: earnedCredit,
    );
  }

  static String _stringValue(Map<String, Object?> value, List<String> keys) {
    for (final key in keys.map(_normalizeKey)) {
      final rawValue = value[key];
      if (rawValue == null) continue;
      final text = StudentReportPageParser._cleanText(rawValue.toString());
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static double? _numberValue(Map<String, Object?> value, List<String> keys) {
    for (final key in keys.map(_normalizeKey)) {
      final rawValue = value[key];
      if (rawValue == null) continue;
      if (rawValue is num) return rawValue.toDouble();
      final parsed = StudentReportPageParser._parseNumber(rawValue.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String _normalizeKey(String key) {
    return key
        .replaceAll(RegExp(r'[\s_()（）]+'), '')
        .replaceAll('（h）', 'h')
        .replaceAll('(h)', 'h')
        .toLowerCase();
  }
}
