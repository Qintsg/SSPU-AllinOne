/*
 * 学工报表页面解析器 — 定位第二课堂入口并提取学分明细
 * @Project : SSPU-AllinOne
 * @File : student_report_page_parser.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'student_report_service.dart';

/// 第二课堂学分页面解析器，逐项提取得分明细。
class StudentReportPageParser {
  StudentReportPageParser._();

  /// 从候选页面中提取第二课堂学分汇总。
  static SecondClassroomCreditSummary? parse(
    List<StudentReportHttpSnapshot> snapshots,
  ) {
    final records = <SecondClassroomCreditRecord>[];
    for (final snapshot in snapshots) {
      for (final fragment in _extractHtmlFragments(snapshot.body)) {
        final document = html_parser.parse(fragment);
        records.addAll(_parseRecords(document));
      }
    }

    final uniqueRecords = _deduplicateRecords(records);
    if (uniqueRecords.isEmpty) return null;

    return SecondClassroomCreditSummary(
      records: List.unmodifiable(uniqueRecords),
      fetchedAt: DateTime.now(),
      sourceUri: snapshots.last.finalUri,
    );
  }

  static List<String> _extractHtmlFragments(String body) {
    final fragments = <String>[body];
    final cdataPattern = RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true);
    for (final match in cdataPattern.allMatches(body)) {
      final fragment = match.group(1);
      if (fragment != null && fragment.trim().isNotEmpty) {
        fragments.add(fragment);
      }
    }
    return fragments;
  }

  static List<SecondClassroomCreditRecord> _parseRecords(
    html_dom.Document document,
  ) {
    final records = <SecondClassroomCreditRecord>[];
    for (final table in document.querySelectorAll('table')) {
      final rows = table.querySelectorAll('tr');
      var header = const <String>[];
      String? inheritedCategory;
      for (final row in rows) {
        final cells = row
            .querySelectorAll('th,td')
            .map((cell) => _cleanText(cell.text))
            .toList();
        if (cells.where((cellText) => cellText.isNotEmpty).length < 2) {
          continue;
        }
        if (_looksLikeHeader(cells)) {
          header = cells;
          continue;
        }

        final record = _recordFromCells(
          header: header,
          cells: cells,
          inheritedCategory: inheritedCategory,
        );
        if (record != null) {
          records.add(record);
          if (record.category != '未分类') inheritedCategory = record.category;
        }
      }
    }
    return records;
  }

  static bool _looksLikeHeader(List<String> cells) {
    final joinedCells = cells.join(' ');
    return _containsAny(joinedCells, const ['学分', '分值', '得分', '分数', '认定分']) &&
        _containsAny(joinedCells, const [
          '类别',
          '类型',
          '模块',
          '项目',
          '名称',
          '活动',
          '课程',
        ]);
  }

  static SecondClassroomCreditRecord? _recordFromCells({
    required List<String> header,
    required List<String> cells,
    required String? inheritedCategory,
  }) {
    final creditIndex = _indexOfAny(header, const [
      '认定学分',
      '学分',
      '分值',
      '得分',
      '分数',
      '认定分',
      '获得分',
    ]);
    final fallbackCreditIndex = _lastCreditIndex(cells);
    var resolvedCreditIndex = creditIndex >= 0
        ? creditIndex
        : fallbackCreditIndex;
    if (resolvedCreditIndex < 0 || resolvedCreditIndex >= cells.length) {
      return null;
    }

    var credit = _parseCredit(cells[resolvedCreditIndex]);
    if (credit == null && fallbackCreditIndex >= 0) {
      resolvedCreditIndex = fallbackCreditIndex;
      credit = _parseCredit(cells[resolvedCreditIndex]);
    }
    if (credit == null) return null;

    final semester = _resolveSemester(header: header, cells: cells);
    final status = _resolveStatus(header: header, cells: cells);
    final category = _resolveCategory(
      header: header,
      cells: cells,
      creditIndex: resolvedCreditIndex,
      semester: semester,
      status: status,
      inheritedCategory: inheritedCategory,
    );
    final itemName = _resolveItemName(
      header: header,
      cells: cells,
      creditIndex: resolvedCreditIndex,
      semester: semester,
      status: status,
      category: category,
    );
    if (itemName.isEmpty) return null;

    return SecondClassroomCreditRecord(
      category: category.isEmpty ? '未分类' : category,
      itemName: itemName,
      credit: credit,
      semester: semester,
      occurredAt: _nullableCell(
        cells,
        _indexOfAny(header, const ['认定时间', '获得时间', '时间', '日期']),
      ),
      status: status,
      rawCells: List.unmodifiable(cells),
    );
  }

  static String? _resolveSemester({
    required List<String> header,
    required List<String> cells,
  }) {
    final headerValue = _nullableCell(
      cells,
      _indexOfAny(header, const ['学期', '学年']),
    );
    if (_looksLikeSemester(headerValue ?? '')) return headerValue;
    return cells.cast<String?>().firstWhere(
      (cell) => _looksLikeSemester(cell ?? ''),
      orElse: () => null,
    );
  }

  static String? _resolveStatus({
    required List<String> header,
    required List<String> cells,
  }) {
    final headerStatus = _normalizeStatus(
      _nullableCell(cells, _indexOfAny(header, const ['状态', '审核状态', '认定状态'])),
    );
    if (headerStatus != null) return headerStatus;
    for (final cell in cells) {
      final status = _normalizeStatus(cell);
      if (status != null) return status;
    }
    return null;
  }

  static String _resolveCategory({
    required List<String> header,
    required List<String> cells,
    required int creditIndex,
    required String? semester,
    required String? status,
    required String? inheritedCategory,
  }) {
    final categoryFromHeader = _cellAt(
      cells,
      _indexOfAny(header, const ['类别', '类型', '模块']),
      fallback: '',
    );
    if (categoryFromHeader.isNotEmpty) return categoryFromHeader;
    final candidates = _nonCreditCells(cells, creditIndex, semester, status);
    if (candidates.length < 2) return inheritedCategory ?? '未分类';
    return candidates.first;
  }

  static String _resolveItemName({
    required List<String> header,
    required List<String> cells,
    required int creditIndex,
    required String? semester,
    required String? status,
    required String category,
  }) {
    final itemName = _cellAt(
      cells,
      _indexOfAny(header, const ['项目名称', '活动名称', '课程名称', '项目', '名称']),
      fallback: '',
    );
    if (itemName.isNotEmpty) return itemName;
    for (final cell in _nonCreditCells(cells, creditIndex, semester, status)) {
      if (category != '未分类' && cell == category) continue;
      return cell;
    }
    return '';
  }

  static int _indexOfAny(List<String> header, List<String> labels) {
    for (var index = 0; index < header.length; index++) {
      final cell = header[index];
      if (labels.any(cell.contains)) return index;
    }
    return -1;
  }

  static int _lastCreditIndex(List<String> cells) {
    for (var index = cells.length - 1; index >= 0; index--) {
      if (_looksLikeCreditValue(cells[index])) return index;
    }
    return -1;
  }

  static String _cellAt(
    List<String> cells,
    int index, {
    required String fallback,
  }) {
    if (index >= 0 && index < cells.length && cells[index].isNotEmpty) {
      return cells[index];
    }
    return fallback;
  }

  static String? _nullableCell(List<String> cells, int index) {
    if (index < 0 || index >= cells.length || cells[index].isEmpty) return null;
    return cells[index];
  }

  static List<String> _nonCreditCells(
    List<String> cells,
    int creditIndex,
    String? semester,
    String? status,
  ) {
    final values = <String>[];
    for (var index = 0; index < cells.length; index++) {
      if (index == creditIndex) continue;
      final cell = cells[index];
      if (cell.isEmpty || _looksLikeCreditValue(cell)) continue;
      if (semester != null && cell == semester) continue;
      if (status != null && _normalizeStatus(cell) == status) continue;
      if (_looksLikeDateOrStatus(cell)) continue;
      values.add(cell);
    }
    return values;
  }

  static List<SecondClassroomCreditRecord> _deduplicateRecords(
    List<SecondClassroomCreditRecord> records,
  ) {
    final seen = <String>{};
    final uniqueRecords = <SecondClassroomCreditRecord>[];
    for (final record in records) {
      final key =
          '${record.category}|${record.itemName}|${record.credit}|${record.rawCells.join('|')}';
      if (!seen.add(key)) continue;
      uniqueRecords.add(record);
    }
    return uniqueRecords;
  }

  static double? _parseCredit(String text) {
    final normalizedText = text.replaceAll(',', '').replaceAll('学分', '');
    final match = RegExp(r'([+\-]?\d+(?:\.\d+)?)').firstMatch(normalizedText);
    return double.tryParse(match?.group(1) ?? '');
  }

  static bool _looksLikeCreditValue(String text) {
    final normalizedText = _cleanText(text);
    if (normalizedText.isEmpty) return false;
    if (RegExp(r'^\d{4}[-/.年]\d{1,2}').hasMatch(normalizedText)) return false;
    final credit = _parseCredit(normalizedText);
    if (credit == null) return false;
    return normalizedText.contains('学分') ||
        normalizedText.contains('分') ||
        RegExp(r'^[+\-]?\d+(?:\.\d+)?$').hasMatch(normalizedText);
  }

  static bool _looksLikeSemester(String text) {
    return RegExp(r'^\d{4}\s*[-/]\s*\d{4}\s*[-/]\s*[1-3]$').hasMatch(text);
  }

  static String? _normalizeStatus(String? text) {
    if (text == null) return null;
    final statusKey = text.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
    const validStatusByKey = {
      '通过': '通过',
      '合格': '合格',
      '已通过': '已通过',
      '完成': '完成',
      '已完成': '已完成',
      'pass': 'Pass',
      '不通过': '不通过',
      '不合格': '不合格',
      '未通过': '未通过',
      '失败': '失败',
      'fail': 'Fail',
      '已认定': '已认定',
      '认定': '认定',
      '审核通过': '审核通过',
      '审核不通过': '审核不通过',
    };
    return validStatusByKey[statusKey];
  }

  static bool _looksLikeDateOrStatus(String text) {
    final normalizedText = _cleanText(text);
    return RegExp(r'^\d{4}[-/.年]\d{1,2}').hasMatch(normalizedText) ||
        _looksLikeSemester(normalizedText) ||
        _normalizeStatus(normalizedText) != null ||
        normalizedText.contains('审核') ||
        normalizedText.contains('状态');
  }

  static bool _containsAny(String text, List<String> labels) {
    return labels.any(text.contains);
  }

  static String _cleanText(String text) {
    return text
        .replaceAll('\u00a0', ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
