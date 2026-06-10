/*
 * 学工报表页面解析器 — 解析第二课堂规则矩阵和已获分详情
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
    List<StudentReportHttpSnapshot> snapshots, {
    String? warning,
    Uri? sourceUri,
  }) {
    final rules = <SecondClassroomCreditRuleRow>[];
    final detailRecords = <SecondClassroomCreditDetailRecord>[];
    final legacyRecords = <SecondClassroomCreditRecord>[];
    SecondClassroomCreditTotals? totals;

    for (final snapshot in snapshots) {
      detailRecords.addAll(_StudentReportDetailJsonParser.parse(snapshot.body));
      for (final fragment in _extractHtmlFragments(snapshot.body)) {
        final document = html_parser.parse(fragment);
        final parsedMatrix = _parseRuleMatrix(document);
        rules.addAll(parsedMatrix.rules);
        totals ??= parsedMatrix.totals;
        final parsedDetails = _parseDetailRecords(document);
        detailRecords.addAll(parsedDetails);
        if (parsedMatrix.rules.isEmpty && parsedDetails.isEmpty) {
          legacyRecords.addAll(_parseLegacyRecords(document));
        }
      }
    }

    final uniqueRules = _deduplicateRules(rules);
    final uniqueDetailRecords = _deduplicateDetailRecords(detailRecords);
    final records = uniqueDetailRecords.isNotEmpty
        ? uniqueDetailRecords.map(_legacyRecordFromDetail).toList()
        : _deduplicateLegacyRecords(legacyRecords);
    if (uniqueRules.isEmpty &&
        totals == null &&
        uniqueDetailRecords.isEmpty &&
        records.isEmpty) {
      return null;
    }

    return SecondClassroomCreditSummary(
      records: List.unmodifiable(records),
      rules: List.unmodifiable(uniqueRules),
      totals: totals,
      detailRecords: List.unmodifiable(uniqueDetailRecords),
      fetchedAt: DateTime.now(),
      sourceUri: sourceUri ?? snapshots.last.finalUri,
      warning: warning,
    );
  }

  /// 从“已获分数”单元格中提取详情页只读入口。
  static List<Uri> findEarnedCreditDetailUris(
    StudentReportHttpSnapshot snapshot,
  ) {
    final uris = <Uri>[];
    for (final fragment in _extractHtmlFragments(snapshot.body)) {
      final document = html_parser.parse(fragment);
      final studentNumber =
          _StudentReportDetailUriExtractor.studentNumberFromDocument(document);
      for (final table in document.querySelectorAll('table')) {
        final rows = _expandTable(table);
        final headerIndex = rows.indexWhere(
          (row) => _looksLikeRuleHeader(row.texts),
        );
        if (headerIndex < 0) continue;
        final header = rows[headerIndex].texts;
        final earnedIndex = _indexOfAny(header, const ['已获分数', '已获积分']);
        if (earnedIndex < 0) continue;
        for (final row in rows.skip(headerIndex + 1)) {
          if (_looksLikeRuleHeader(row.texts) || _isTotalRow(row.texts)) {
            continue;
          }
          final cell = row.cellAt(earnedIndex);
          if (cell == null || _parseNumber(cell.text) == null) continue;
          final detailUri =
              _StudentReportDetailUriExtractor.detailUriFromEarnedCell(
                baseUri: snapshot.finalUri,
                element: cell.element,
                studentNumber: studentNumber,
              );
          if (detailUri != null) uris.add(detailUri);
          uris.addAll(_urisFromElement(snapshot.finalUri, cell.element));
        }
      }
    }
    return _deduplicateUris(uris);
  }

  static _ParsedRuleMatrix _parseRuleMatrix(html_dom.Document document) {
    final rules = <SecondClassroomCreditRuleRow>[];
    SecondClassroomCreditTotals? totals;
    for (final table in document.querySelectorAll('table')) {
      final rows = _expandTable(table);
      final headerIndex = rows.indexWhere(
        (row) => _looksLikeRuleHeader(row.texts),
      );
      if (headerIndex < 0) continue;
      final header = rows[headerIndex].texts;
      for (final row in rows.skip(headerIndex + 1)) {
        final cells = row.texts;
        if (cells.where((text) => text.isNotEmpty).length < 2) continue;
        if (_looksLikeRuleHeader(cells)) continue;
        if (_isTotalRow(cells)) {
          totals ??= _totalsFromCells(header, cells);
          continue;
        }
        final rule = _ruleFromCells(header, cells);
        if (rule != null) rules.add(rule);
      }
    }
    return _ParsedRuleMatrix(rules: rules, totals: totals);
  }

  static List<SecondClassroomCreditDetailRecord> _parseDetailRecords(
    html_dom.Document document,
  ) {
    final records = <SecondClassroomCreditDetailRecord>[];
    for (final table in document.querySelectorAll('table')) {
      final rows = _expandTable(table);
      final headerIndex = rows.indexWhere(
        (row) => _looksLikeDetailHeader(row.texts),
      );
      if (headerIndex < 0) continue;
      final header = rows[headerIndex].texts;
      for (final row in rows.skip(headerIndex + 1)) {
        final cells = row.texts;
        if (cells.where((text) => text.isNotEmpty).length < 2) continue;
        if (_looksLikeDetailHeader(cells)) continue;
        final record = _detailRecordFromCells(header, cells);
        if (record != null) records.add(record);
      }
    }
    return records;
  }

  static List<SecondClassroomCreditRecord> _parseLegacyRecords(
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
        if (_looksLikeLegacyHeader(cells)) {
          header = cells;
          continue;
        }

        final record = _legacyRecordFromCells(
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

  static List<String> _extractHtmlFragments(String body) {
    final fragments = <String>[body];
    final cdataPattern = RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true);
    for (final match in cdataPattern.allMatches(body)) {
      final fragment = match.group(1);
      if (fragment != null && fragment.trim().isNotEmpty) {
        fragments.add(fragment);
      }
    }
    try {
      _extractHtmlFragmentsFromJson(jsonDecode(body), fragments);
    } catch (_) {
      // 非 JSON 响应按普通 HTML 处理。
    }
    return fragments.where((fragment) => fragment.trim().isNotEmpty).toList();
  }

  static void _extractHtmlFragmentsFromJson(Object? value, List<String> out) {
    if (value is String) {
      final normalized = value.replaceAll(r'\"', '"');
      if (normalized.contains('<table') || normalized.contains('<tr')) {
        out.add(normalized);
      }
      return;
    }
    if (value is List) {
      for (final item in value) {
        _extractHtmlFragmentsFromJson(item, out);
      }
      return;
    }
    if (value is Map) {
      for (final item in value.values) {
        _extractHtmlFragmentsFromJson(item, out);
      }
    }
  }

  static List<_ExpandedTableRow> _expandTable(html_dom.Element table) {
    final rows = <_ExpandedTableRow>[];
    final pending = <int, _PendingTableCell>{};
    for (final tr in table.querySelectorAll('tr')) {
      final rowCells = <_ExpandedTableCell>[];
      var column = 0;

      void consumePending() {
        while (pending.containsKey(column)) {
          final pendingCell = pending[column]!;
          rowCells.add(pendingCell.cell);
          pendingCell.remainingRows--;
          if (pendingCell.remainingRows <= 0) pending.remove(column);
          column++;
        }
      }

      for (final element in tr.querySelectorAll('th,td')) {
        consumePending();
        final cell = _ExpandedTableCell(
          text: _cleanText(element.text),
          element: element,
        );
        final rowspan = _parseSpan(element.attributes['rowspan']);
        final colspan = _parseSpan(element.attributes['colspan']);
        for (var offset = 0; offset < colspan; offset++) {
          rowCells.add(cell);
          if (rowspan > 1) {
            pending[column] = _PendingTableCell(cell, rowspan - 1);
          }
          column++;
        }
      }
      consumePending();
      rows.add(_ExpandedTableRow(rowCells));
    }
    return rows;
  }

  static int _parseSpan(String? value) {
    final span = int.tryParse(value ?? '') ?? 1;
    return span <= 0 ? 1 : span;
  }

  static bool _looksLikeRuleHeader(List<String> cells) {
    final joined = cells.join(' ');
    return _containsAny(joined, const ['类别']) &&
        _containsAny(joined, const ['项目']) &&
        _containsAny(joined, const ['等级']) &&
        _containsAny(joined, const ['参与情况']) &&
        _containsAny(joined, const ['积分']) &&
        _containsAny(joined, const ['已获分数', '已获积分']) &&
        _containsAny(joined, const ['必修积分']) &&
        _containsAny(joined, const ['通过情况']);
  }

  static bool _looksLikeDetailHeader(List<String> cells) {
    final joined = cells.join(' ');
    return _containsAny(joined, const ['名称']) &&
        _containsAny(joined, const ['类别']) &&
        _containsAny(joined, const ['项目']) &&
        _containsAny(joined, const ['等级']) &&
        _containsAny(joined, const ['参与情况']) &&
        _containsAny(joined, const ['获得积分', '获得分数']);
  }

  static bool _looksLikeLegacyHeader(List<String> cells) {
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

  static bool _isTotalRow(List<String> cells) {
    return cells.any((cell) => cell == '总计' || cell == '合计');
  }

  static SecondClassroomCreditRuleRow? _ruleFromCells(
    List<String> header,
    List<String> cells,
  ) {
    final category = _cellAt(cells, _indexOfAny(header, const ['类别']));
    final item = _cellAt(cells, _indexOfAny(header, const ['项目']));
    final level = _cellAt(cells, _indexOfAny(header, const ['等级']));
    final participation = _cellAt(cells, _indexOfAny(header, const ['参与情况']));
    final credit = _parseNumber(
      _cellAt(cells, _indexOfExactAny(header, const ['积分'])),
    );
    final earnedCredit = _parseNumber(
      _cellAt(cells, _indexOfAny(header, const ['已获分数', '已获积分'])),
    );
    final requiredCredit = _parseNumber(
      _cellAt(cells, _indexOfAny(header, const ['必修积分'])),
    );
    final passStatus = _cellAt(cells, _indexOfAny(header, const ['通过情况']));
    if ([
          category,
          item,
          level,
          participation,
          passStatus,
        ].every((value) => value.isEmpty) &&
        credit == null &&
        earnedCredit == null &&
        requiredCredit == null) {
      return null;
    }
    return SecondClassroomCreditRuleRow(
      category: category,
      item: item,
      level: level,
      participation: participation,
      credit: credit,
      earnedCredit: earnedCredit,
      requiredCredit: requiredCredit,
      passStatus: passStatus,
    );
  }

  static SecondClassroomCreditTotals? _totalsFromCells(
    List<String> header,
    List<String> cells,
  ) {
    final totalCredit = _parseNumber(
      _cellAt(cells, _indexOfExactAny(header, const ['积分'])),
    );
    final totalEarnedCredit = _parseNumber(
      _cellAt(cells, _indexOfAny(header, const ['已获分数', '已获积分'])),
    );
    final totalRequiredCredit = _parseNumber(
      _cellAt(cells, _indexOfAny(header, const ['必修积分'])),
    );
    final passStatus = _cellAt(cells, _indexOfAny(header, const ['通过情况']));
    if (totalCredit == null &&
        totalEarnedCredit == null &&
        totalRequiredCredit == null &&
        passStatus.isEmpty) {
      return null;
    }
    return SecondClassroomCreditTotals(
      totalCredit: totalCredit,
      totalEarnedCredit: totalEarnedCredit,
      totalRequiredCredit: totalRequiredCredit,
      passStatus: passStatus.isEmpty ? null : passStatus,
    );
  }

  static SecondClassroomCreditDetailRecord? _detailRecordFromCells(
    List<String> header,
    List<String> cells,
  ) {
    final name = _cellAt(cells, _indexOfAny(header, const ['名称']));
    final category = _cellAt(cells, _indexOfAny(header, const ['类别']));
    final item = _cellAt(cells, _indexOfAny(header, const ['项目']));
    final level = _cellAt(cells, _indexOfAny(header, const ['等级']));
    final participation = _cellAt(cells, _indexOfAny(header, const ['参与情况']));
    final earnedCredit = _parseNumber(
      _cellAt(cells, _indexOfAny(header, const ['获得积分', '获得分数'])),
    );
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

  static SecondClassroomCreditRecord? _legacyRecordFromCells({
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

    var credit = _parseNumber(cells[resolvedCreditIndex]);
    if (credit == null && fallbackCreditIndex >= 0) {
      resolvedCreditIndex = fallbackCreditIndex;
      credit = _parseNumber(cells[resolvedCreditIndex]);
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

  static SecondClassroomCreditRecord _legacyRecordFromDetail(
    SecondClassroomCreditDetailRecord detail,
  ) {
    return SecondClassroomCreditRecord(
      category: detail.category.isEmpty ? '未分类' : detail.category,
      itemName: detail.name.isEmpty ? detail.item : detail.name,
      credit: detail.earnedCredit ?? 0,
      rawCells: [
        detail.name,
        detail.category,
        detail.item,
        detail.level,
        detail.participation,
        _formatNumber(detail.earnedCredit),
      ],
    );
  }

  static List<Uri> _urisFromElement(Uri baseUri, html_dom.Element element) {
    final values = <String>[];
    const attributeNames = [
      'href',
      'data-url',
      'data-href',
      'url',
      'onclick',
      'data-options',
    ];
    for (final attributeName in attributeNames) {
      final value = element.attributes[attributeName]?.trim();
      if (value != null && value.isNotEmpty) values.add(value);
    }
    for (final child in element.querySelectorAll(
      '[href],[data-url],[data-href],[onclick]',
    )) {
      for (final attributeName in attributeNames) {
        final value = child.attributes[attributeName]?.trim();
        if (value != null && value.isNotEmpty) values.add(value);
      }
    }
    final inlineMarkup = element.outerHtml.trim();
    if (inlineMarkup.isNotEmpty) values.add(inlineMarkup);
    return values
        .map((value) => _uriFromText(baseUri, value))
        .whereType<Uri>()
        .toList();
  }

  static Uri? _uriFromText(Uri baseUri, String text) {
    final normalized = text.replaceAll('&amp;', '&').trim();
    if (normalized.isEmpty ||
        normalized == '#' ||
        normalized.toLowerCase() == 'javascript:void(0)') {
      return null;
    }
    if (!normalized.toLowerCase().startsWith('javascript:') &&
        (_looksLikeUri(normalized) || _looksLikeDirectDoPath(normalized))) {
      return _resolveBusinessUri(baseUri, normalized);
    }
    final patterns = [
      RegExp(
        r'''(?:location(?:\.href)?|window\.open)\s*\(?\s*['"]([^'"]+)['"]''',
      ),
      RegExp(r'''toMainUrl\s*\(\s*['"]([^'"]+)['"]'''),
      RegExp(r'''toMain\s*\(\s*['"]([^'"]+)['"]'''),
      RegExp(
        r'''['"]([^'"]*(?:studentxfform|detail|score|credit|xf)[^'"]*\.do[^'"]*)['"]''',
        caseSensitive: false,
      ),
      RegExp(r'''['"]([^'"]*studentxfform[^'"]*)['"]''', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(normalized);
      final rawUri = match?.group(1)?.trim();
      if (rawUri != null && rawUri.isNotEmpty) {
        return _resolveBusinessUri(baseUri, rawUri);
      }
    }
    return null;
  }

  static bool _looksLikeUri(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('//') ||
        value.startsWith('/') ||
        value.startsWith('../') ||
        value.startsWith('./');
  }

  static bool _looksLikeDirectDoPath(String value) {
    return RegExp(r'''^[^\s<>"']+\.do(?:\?[^\s<>"']*)?$''').hasMatch(value);
  }

  static Uri _resolveBusinessUri(Uri baseUri, String rawUri) {
    final normalizedUri = rawUri.replaceAll('&amp;', '&').trim();
    final lowerPath = baseUri.path.toLowerCase();
    final sharedcIndex = lowerPath.indexOf('/sharedc/');
    if (normalizedUri.startsWith('/') &&
        sharedcIndex >= 0 &&
        !normalizedUri.toLowerCase().startsWith('/sharedc/')) {
      return baseUri.replace(path: '/sharedc$normalizedUri', query: '');
    }
    if (normalizedUri.startsWith('http://') ||
        normalizedUri.startsWith('https://') ||
        normalizedUri.startsWith('//') ||
        normalizedUri.startsWith('/')) {
      return baseUri.resolve(normalizedUri);
    }
    if (sharedcIndex >= 0) {
      final sharedcRoot = baseUri.path.substring(
        0,
        sharedcIndex + '/sharedc/'.length,
      );
      return baseUri
          .replace(path: sharedcRoot, query: '')
          .resolve(normalizedUri);
    }
    return baseUri.resolve(normalizedUri);
  }

  static int _indexOfAny(List<String> header, List<String> labels) {
    for (var index = 0; index < header.length; index++) {
      final cell = header[index];
      if (labels.any(cell.contains)) return index;
    }
    return -1;
  }

  static int _indexOfExactAny(List<String> header, List<String> labels) {
    for (var index = 0; index < header.length; index++) {
      final normalized = header[index].replaceAll(RegExp(r'\s+'), '');
      if (labels.any((label) => normalized == label)) return index;
    }
    return _indexOfAny(header, labels);
  }

  static int _lastCreditIndex(List<String> cells) {
    for (var index = cells.length - 1; index >= 0; index--) {
      if (_looksLikeCreditValue(cells[index])) return index;
    }
    return -1;
  }

  static String _cellAt(List<String> cells, int index) {
    if (index >= 0 && index < cells.length) return cells[index];
    return '';
  }

  static String? _nullableCell(List<String> cells, int index) {
    if (index < 0 || index >= cells.length || cells[index].isEmpty) return null;
    return cells[index];
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
    );
    if (itemName.isNotEmpty) return itemName;
    for (final cell in _nonCreditCells(cells, creditIndex, semester, status)) {
      if (category != '未分类' && cell == category) continue;
      return cell;
    }
    return '';
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

  static List<SecondClassroomCreditRuleRow> _deduplicateRules(
    List<SecondClassroomCreditRuleRow> rules,
  ) {
    final seen = <String>{};
    final uniqueRules = <SecondClassroomCreditRuleRow>[];
    for (final rule in rules) {
      final key =
          '${rule.category}|${rule.item}|${rule.level}|${rule.participation}|${rule.credit}|${rule.earnedCredit}|${rule.requiredCredit}|${rule.passStatus}';
      if (!seen.add(key)) continue;
      uniqueRules.add(rule);
    }
    return uniqueRules;
  }

  static List<SecondClassroomCreditDetailRecord> _deduplicateDetailRecords(
    List<SecondClassroomCreditDetailRecord> records,
  ) {
    final seen = <String>{};
    final uniqueRecords = <SecondClassroomCreditDetailRecord>[];
    for (final record in records) {
      final key =
          '${record.name}|${record.category}|${record.item}|${record.level}|${record.participation}|${record.earnedCredit}';
      if (!seen.add(key)) continue;
      uniqueRecords.add(record);
    }
    return uniqueRecords;
  }

  static List<SecondClassroomCreditRecord> _deduplicateLegacyRecords(
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

  static List<Uri> _deduplicateUris(List<Uri> uris) {
    final seen = <String>{};
    final uniqueUris = <Uri>[];
    for (final uri in uris) {
      final key = uri.toString();
      if (!seen.add(key)) continue;
      uniqueUris.add(uri);
    }
    return uniqueUris;
  }

  static double? _parseNumber(String text) {
    final normalizedText = text
        .replaceAll(',', '')
        .replaceAll('学分', '')
        .replaceAll('积分', '')
        .replaceAll('分', '');
    final match = RegExp(
      r'([+\-]?(?:\d+(?:\.\d+)?|\.\d+))',
    ).firstMatch(normalizedText);
    var value = match?.group(1);
    if (value != null && value.startsWith('.')) value = '0$value';
    if (value != null && value.startsWith('-.')) {
      value = value.replaceFirst('-.', '-0.');
    }
    return double.tryParse(value ?? '');
  }

  static bool _looksLikeCreditValue(String text) {
    final normalizedText = _cleanText(text);
    if (normalizedText.isEmpty) return false;
    if (RegExp(r'^\d{4}[-/.年]\d{1,2}').hasMatch(normalizedText)) return false;
    final credit = _parseNumber(normalizedText);
    if (credit == null) return false;
    return normalizedText.contains('学分') ||
        normalizedText.contains('积分') ||
        normalizedText.contains('分') ||
        RegExp(r'^[+\-]?(?:\d+(?:\.\d+)?|\.\d+)$').hasMatch(normalizedText);
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

  static String _formatNumber(double? value) {
    if (value == null) return '';
    final text = value.toStringAsFixed(2);
    return text
        .replaceFirst(RegExp(r'\.0+$'), '')
        .replaceFirst(RegExp(r'0$'), '');
  }

  static String _cleanText(String text) {
    return text
        .replaceAll('\u00a0', ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _ParsedRuleMatrix {
  const _ParsedRuleMatrix({required this.rules, required this.totals});

  final List<SecondClassroomCreditRuleRow> rules;
  final SecondClassroomCreditTotals? totals;
}

class _ExpandedTableRow {
  const _ExpandedTableRow(this.cells);

  final List<_ExpandedTableCell> cells;

  List<String> get texts => cells.map((cell) => cell.text).toList();

  _ExpandedTableCell? cellAt(int index) {
    if (index < 0 || index >= cells.length) return null;
    return cells[index];
  }
}

class _ExpandedTableCell {
  const _ExpandedTableCell({required this.text, required this.element});

  final String text;
  final html_dom.Element element;
}

class _PendingTableCell {
  _PendingTableCell(this.cell, this.remainingRows);

  final _ExpandedTableCell cell;
  int remainingRows;
}
