/*
 * 本专科教务个人信息解析器 — 解析 EAMS 页面中的学生基础信息
 * @Project : SSPU-AllinOne
 * @File : academic_eams_page_parser_profile.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

part of 'academic_eams_service.dart';

AcademicEamsProfile? _parseProfile(List<AcademicEamsHttpSnapshot> snapshots) {
  final rawFields = <String, String>{};
  for (final snapshot in snapshots) {
    final document = html_parser.parse(snapshot.body);
    for (final row in document.querySelectorAll('tr')) {
      final cells = row
          .querySelectorAll('th,td')
          .map((cell) => _cleanText(cell.text))
          .where((text) => text.isNotEmpty)
          .toList();
      if (cells.length < 2) continue;
      for (var index = 0; index < cells.length - 1; index++) {
        final label = _normalizeProfileLabel(cells[index]);
        final value = cells[index + 1].trim();
        if (_looksLikeProfileLabel(label) &&
            value.isNotEmpty &&
            !_looksLikeProfileLabel(_normalizeProfileLabel(value))) {
          rawFields.putIfAbsent(label, () => value);
        }
      }
    }
    _captureProfileFromTables(rawFields, document);

    final bodyText = _cleanText(document.body?.text ?? snapshot.body);
    _captureProfileByRegex(rawFields, bodyText, '姓名');
    _captureProfileByRegex(rawFields, bodyText, '学号');
    _captureProfileByRegex(rawFields, bodyText, '院系');
    _captureProfileByRegex(rawFields, bodyText, '学院');
    _captureProfileByRegex(rawFields, bodyText, '专业');
    _captureProfileByRegex(rawFields, bodyText, '行政班级');
    _captureProfileByRegex(rawFields, bodyText, '班级');
    _captureProfileByRegex(rawFields, bodyText, '性别');
    _captureProfileByRegex(rawFields, bodyText, '学制');
    _captureProfileByRegex(rawFields, bodyText, '学历层次');
  }

  if (rawFields.isEmpty) return null;
  final profile = AcademicEamsProfile(
    name: rawFields['姓名'] ?? rawFields['学生姓名'],
    studentId: rawFields['学号'] ?? rawFields['学工号'],
    department: rawFields['院系'] ?? rawFields['学院'],
    major: rawFields['专业'],
    className: rawFields['行政班级'] ?? rawFields['班级'],
    gender: rawFields['性别'],
    studyLength: rawFields['学制'],
    educationLevel: rawFields['学历层次'] ?? rawFields['培养层次'],
    rawFields: Map.unmodifiable(rawFields),
  );
  return profile.hasAnyValue ? profile : null;
}

void _captureProfileFromTables(
  Map<String, String> rawFields,
  html_dom.Document document,
) {
  for (final table in document.querySelectorAll('table')) {
    final rows = table.querySelectorAll('tr');
    if (rows.length < 2) continue;
    final headers = rows.first
        .querySelectorAll('th,td')
        .map((cell) => _normalizeProfileLabel(_cleanText(cell.text)))
        .toList();
    if (headers.where(_looksLikeProfileLabel).length < 2) continue;
    for (final row in rows.skip(1)) {
      final values = row
          .querySelectorAll('th,td')
          .map((cell) => _cleanText(cell.text))
          .toList();
      if (values.length < 2) continue;
      for (
        var index = 0;
        index < headers.length && index < values.length;
        index++
      ) {
        final label = headers[index];
        final value = values[index];
        if (_looksLikeProfileLabel(label) && value.isNotEmpty) {
          rawFields.putIfAbsent(label, () => value);
        }
      }
      break;
    }
  }
}

String _normalizeProfileLabel(String value) {
  return _cleanText(value)
      .replaceAll(RegExp(r'[:：]$'), '')
      .replaceAll('所在', '')
      .replaceAll('名称', '')
      .trim();
}
