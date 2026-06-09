/*
 * 校园卡页面解析器 — 提取余额、状态与交易记录
 * @Project : SSPU-AllinOne
 * @File : campus_card_page_parser.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'campus_card_service.dart';

/// 校园卡页面解析器；支持普通 HTML 和同类 epay 系统的 XML/CDATA 表格。
class CampusCardPageParser {
  CampusCardPageParser._();

  /// 从多个候选页面中提取余额、状态和交易记录。
  static CampusCardSnapshot? parse(List<CampusCardHttpSnapshot> snapshots) {
    double? balance;
    var status = '';
    final records = <CampusCardTransactionRecord>[];

    for (final snapshot in snapshots) {
      for (final fragment in _extractHtmlFragments(snapshot.body)) {
        final document = html_parser.parse(fragment);
        balance ??= _parseBalance(document);
        if (status.isEmpty) status = _parseStatus(document) ?? '';
        records.addAll(_parseRecords(document));
      }
    }

    final uniqueRecords = _deduplicateRecords(records);
    if (balance == null && status.isEmpty && uniqueRecords.isEmpty) return null;

    return CampusCardSnapshot(
      balance: balance,
      status: status,
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

  static double? _parseBalance(html_dom.Document document) {
    final tableValue = _labelValue(document, const [
      '账户余额',
      '卡余额',
      '当前余额',
      '余额',
    ]);
    final tableBalance = _parseMoney(tableValue ?? '');
    if (tableBalance != null) return tableBalance;

    final text = _cleanText(document.body?.text ?? document.outerHtml);
    final patterns = [
      RegExp(r'(?:账户余额|卡余额|当前余额|余额)[^0-9+\-]{0,16}([+\-]?\d+(?:\.\d{1,2})?)'),
      RegExp(r'([+\-]?\d+(?:\.\d{1,2})?)\s*元[^，。；;]{0,8}(?:余额|账户余额|卡余额)'),
    ];
    for (final pattern in patterns) {
      final value = _parseMoney(pattern.firstMatch(text)?.group(1) ?? '');
      if (value != null) return value;
    }
    return null;
  }

  static String? _parseStatus(html_dom.Document document) {
    final tableValue = _strictLabelValue(document, const ['卡状态', '账户状态']);
    if (tableValue != null && tableValue.isNotEmpty) return tableValue;

    final text = _cleanText(document.body?.text ?? document.outerHtml);
    final match = RegExp(
      r'(?:卡状态|账户状态)\s*[:：]\s*([^，。；;\s]{1,20})',
    ).firstMatch(text);
    final value = match?.group(1)?.trim();
    return _isPlausibleCardStatus(value) ? value : null;
  }

  static String? _labelValue(html_dom.Document document, List<String> labels) {
    for (final row in document.querySelectorAll('tr')) {
      final cells = row
          .querySelectorAll('th,td')
          .map((cell) => _cleanText(cell.text))
          .toList();
      for (var index = 0; index < cells.length; index++) {
        if (!labels.any(cells[index].contains)) continue;
        if (index + 1 < cells.length && cells[index + 1].isNotEmpty) {
          return cells[index + 1];
        }
      }
    }
    return null;
  }

  static String? _strictLabelValue(
    html_dom.Document document,
    List<String> labels,
  ) {
    final normalizedLabels = labels.map(_normalizeLabel).toSet();
    for (final row in document.querySelectorAll('tr')) {
      final cells = row
          .querySelectorAll('th,td')
          .map((cell) => _cleanText(cell.text))
          .where((cellText) => cellText.isNotEmpty)
          .toList();
      for (var index = 0; index < cells.length; index++) {
        final inlineValue = _parseInlineLabelValue(
          cells[index],
          normalizedLabels,
        );
        if (_isPlausibleCardStatus(inlineValue)) return inlineValue;

        if (!normalizedLabels.contains(_normalizeLabel(cells[index]))) {
          continue;
        }
        if (index + 1 >= cells.length) continue;
        final value = cells[index + 1].trim();
        if (_isPlausibleCardStatus(value)) return value;
      }
    }
    return null;
  }

  static String? _parseInlineLabelValue(
    String text,
    Set<String> normalizedLabels,
  ) {
    final match = RegExp(r'^([^:：]+)[:：]\s*(.+)$').firstMatch(text);
    if (match == null) return null;
    if (!normalizedLabels.contains(_normalizeLabel(match.group(1) ?? ''))) {
      return null;
    }
    return match.group(2)?.trim();
  }

  static bool _isPlausibleCardStatus(String? value) {
    if (value == null) return false;
    final text = value.trim();
    if (text.isEmpty || text.length > 20) return false;
    if (text == '操作' || text == '详情' || text == '明细') return false;
    return !text.contains('创建时间') && !text.contains('交易号');
  }

  static List<CampusCardTransactionRecord> _parseRecords(
    html_dom.Document document,
  ) {
    final records = <CampusCardTransactionRecord>[];
    for (final table in document.querySelectorAll('table')) {
      Map<_CampusCardTransactionColumn, int>? headerIndexes;
      for (final row in table.querySelectorAll('tr')) {
        final cells = _rowCells(row);
        if (cells.length < 3) continue;

        final candidateHeaders = _transactionHeaderIndexes(cells);
        if (_isTransactionHeader(candidateHeaders)) {
          headerIndexes = candidateHeaders;
          continue;
        }

        final columnRecord = headerIndexes == null
            ? null
            : _parseRecordWithHeaders(cells, headerIndexes);
        if (columnRecord != null) {
          records.add(columnRecord);
          continue;
        }

        final fallbackRecord = _parseRecordWithoutHeaders(cells);
        if (fallbackRecord != null) records.add(fallbackRecord);
      }
    }
    return records;
  }

  static List<String> _rowCells(html_dom.Element row) {
    return row
        .querySelectorAll('th,td')
        .map((cell) => _cleanText(cell.text))
        .where((cellText) => cellText.isNotEmpty)
        .toList();
  }

  static Map<_CampusCardTransactionColumn, int> _transactionHeaderIndexes(
    List<String> cells,
  ) {
    final indexes = <_CampusCardTransactionColumn, int>{};
    for (var index = 0; index < cells.length; index++) {
      final column = _transactionColumnFor(cells[index]);
      if (column != null) indexes[column] = index;
    }
    return indexes;
  }

  static bool _isTransactionHeader(
    Map<_CampusCardTransactionColumn, int> indexes,
  ) {
    return indexes.containsKey(_CampusCardTransactionColumn.occurredAt) &&
        indexes.containsKey(_CampusCardTransactionColumn.amount);
  }

  static _CampusCardTransactionColumn? _transactionColumnFor(String text) {
    final label = _normalizeLabel(text);
    if (label == '创建时间' || label == '交易时间' || label == '时间') {
      return _CampusCardTransactionColumn.occurredAt;
    }
    if (label == '名称' || label == '交易名称' || label.contains('名称')) {
      return _CampusCardTransactionColumn.title;
    }
    if (label == '交易号' || label == '流水号' || label == '订单号') {
      return _CampusCardTransactionColumn.transactionId;
    }
    if (label == '对方' || label == '商户' || label == '商家') {
      return _CampusCardTransactionColumn.counterparty;
    }
    if (label == '金额' || label == '交易金额' || label.contains('金额')) {
      return _CampusCardTransactionColumn.amount;
    }
    if (label == '明细' || label == '详情') {
      return _CampusCardTransactionColumn.detail;
    }
    if (label == '付款方式' || label == '支付方式') {
      return _CampusCardTransactionColumn.paymentMethod;
    }
    if (label == '状态' || label == '交易状态') {
      return _CampusCardTransactionColumn.status;
    }
    if (label == '操作') return _CampusCardTransactionColumn.operation;
    return null;
  }

  static CampusCardTransactionRecord? _parseRecordWithHeaders(
    List<String> cells,
    Map<_CampusCardTransactionColumn, int> indexes,
  ) {
    final occurredAt = _parseOccurredAt(
      _cellAt(cells, indexes[_CampusCardTransactionColumn.occurredAt]) ??
          cells.join(' '),
    );
    if (occurredAt == null || occurredAt.isEmpty) return null;

    final titleCell = _cellAt(
      cells,
      indexes[_CampusCardTransactionColumn.title],
    );
    final title = _parseTitle(titleCell);
    final transactionId =
        _cellAt(cells, indexes[_CampusCardTransactionColumn.transactionId]) ??
        _parseTransactionId(titleCell);
    final counterparty = _cellAt(
      cells,
      indexes[_CampusCardTransactionColumn.counterparty],
    );
    final amountText = _cellAt(
      cells,
      indexes[_CampusCardTransactionColumn.amount],
    );
    final detail = _cellAt(cells, indexes[_CampusCardTransactionColumn.detail]);
    final paymentMethod = _cellAt(
      cells,
      indexes[_CampusCardTransactionColumn.paymentMethod],
    );
    final status = _cellAt(cells, indexes[_CampusCardTransactionColumn.status]);
    final contextText = [
      title,
      counterparty,
      detail,
      paymentMethod,
      status,
      cells.join(' '),
    ].whereType<String>().join(' ');
    final amount = _parseRecordAmount(
      cells,
      preferredAmountText: amountText,
      contextText: contextText,
    );
    if (amount == null || !_hasTransactionHint(contextText)) return null;
    final direction = _parseDirection(contextText, amount);

    return CampusCardTransactionRecord(
      occurredAt: occurredAt,
      amount: amount,
      merchant: counterparty ?? detail ?? title,
      type: _parseType(contextText),
      title: title,
      transactionId: transactionId,
      counterparty: counterparty,
      paymentMethod: paymentMethod,
      status: status,
      direction: direction,
      rawCells: List.unmodifiable(cells),
    );
  }

  static CampusCardTransactionRecord? _parseRecordWithoutHeaders(
    List<String> cells,
  ) {
    final joinedCells = cells.join(' ');
    final occurredAt = _parseOccurredAt(joinedCells);
    if (occurredAt == null || !_hasTransactionHint(joinedCells)) return null;

    final amount = _parseRecordAmount(cells, contextText: joinedCells);
    if (amount == null) return null;
    return CampusCardTransactionRecord(
      occurredAt: occurredAt,
      amount: amount,
      merchant: _parseMerchant(cells),
      type: _parseType(joinedCells),
      balanceAfter: _parseBalanceAfter(cells),
      direction: _parseDirection(joinedCells, amount),
      rawCells: List.unmodifiable(cells),
    );
  }

  static bool _hasTransactionHint(String text) {
    return text.contains('消费') ||
        text.contains('充值') ||
        text.contains('补助') ||
        text.contains('圈存') ||
        text.contains('退款') ||
        text.contains('退费') ||
        text.contains('交易') ||
        text.contains('交易号') ||
        text.contains('扣款') ||
        text.contains('收入') ||
        text.contains('支出') ||
        text.toUpperCase().contains('POS');
  }

  static double? _parseRecordAmount(
    List<String> cells, {
    String? preferredAmountText,
    String? contextText,
  }) {
    final context = contextText ?? cells.join(' ');
    if (preferredAmountText != null && preferredAmountText.trim().isNotEmpty) {
      final amount = _parseMoney(preferredAmountText);
      if (amount != null) {
        return _applyInferredSign(
          amount,
          context,
          hasExplicitSign: _hasExplicitSign(preferredAmountText),
        );
      }
    }
    for (final cell in cells.reversed) {
      if (_datePattern.hasMatch(cell)) continue;
      final amount = _parseMoney(cell);
      if (amount != null && (cell.contains('+') || cell.contains('-'))) {
        return amount;
      }
    }
    for (final cell in cells) {
      if (_datePattern.hasMatch(cell)) continue;
      final amount = _parseMoney(cell);
      if (amount != null) {
        return _applyInferredSign(
          amount,
          context,
          hasExplicitSign: _hasExplicitSign(cell),
        );
      }
    }
    return null;
  }

  static double? _parseBalanceAfter(List<String> cells) {
    for (final cell in cells.reversed) {
      if (_datePattern.hasMatch(cell)) continue;
      if (cell.contains('+') || cell.contains('-')) continue;
      final amount = _parseMoney(cell);
      if (amount != null) return amount;
    }
    return null;
  }

  static String? _parseMerchant(List<String> cells) {
    for (final cell in cells) {
      if (_datePattern.hasMatch(cell)) continue;
      if (_parseMoney(cell) != null) continue;
      if (_parseType(cell) != null) continue;
      if (cell.contains('余额') || cell.contains('状态')) continue;
      return cell;
    }
    return null;
  }

  static String? _parseOccurredAt(String text) {
    final compactMatch = _compactDateTimePattern.firstMatch(text);
    if (compactMatch != null) {
      final date = compactMatch.group(1)?.replaceAll('.', '-');
      final time = compactMatch.group(2);
      if (date != null && time != null && time.length == 6) {
        return '$date ${time.substring(0, 2)}:${time.substring(2, 4)}:${time.substring(4, 6)}';
      }
    }

    final match = _datePattern.firstMatch(text);
    if (match == null) return null;
    final value = match.group(0)?.trim();
    if (value == null || value.isEmpty) return null;
    return value
        .replaceAll('.', '-')
        .replaceFirstMapped(
          RegExp(r'\s+(\d{2})(\d{2})(\d{2})$'),
          (match) => ' ${match.group(1)}:${match.group(2)}:${match.group(3)}',
        );
  }

  static String? _parseTitle(String? text) {
    final value = text?.trim();
    if (value == null || value.isEmpty) return null;
    final withoutTransactionId = value
        .replaceAll(RegExp(r'交易号[:：]?\s*\S+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return withoutTransactionId.isEmpty ? value : withoutTransactionId;
  }

  static String? _parseTransactionId(String? text) {
    final value = text?.trim();
    if (value == null || value.isEmpty) return null;
    final match = RegExp(r'(?:交易号|流水号|订单号)[:：]?\s*(\S+)').firstMatch(value);
    return match?.group(1)?.trim();
  }

  static String? _parseType(String text) {
    const types = ['消费', '充值', '补助', '圈存', '退款', '退费', '扣款', '收入', '支出'];
    for (final type in types) {
      if (text.contains(type)) return type;
    }
    if (text.toUpperCase().contains('POS')) return '消费';
    return null;
  }

  static String _parseDirection(String text, double amount) {
    if (_containsAny(text, const [
      '收入',
      '充值',
      '补助',
      '退款',
      '退费',
      '返还',
      '发放',
    ])) {
      return 'income';
    }
    if (_containsAny(text, const ['支出', '消费', '扣款', '付款', '支付']) ||
        text.toUpperCase().contains('POS')) {
      return 'expense';
    }
    if (amount > 0) return 'income';
    if (amount < 0) return 'expense';
    return 'unknown';
  }

  static double _applyInferredSign(
    double amount,
    String context, {
    required bool hasExplicitSign,
  }) {
    if (hasExplicitSign || amount == 0) return amount;
    final absoluteAmount = amount.abs();
    if (_containsAny(context, const [
      '充值',
      '补助',
      '退款',
      '退费',
      '收入',
      '返还',
      '发放',
    ])) {
      return absoluteAmount;
    }
    if (_containsAny(context, const ['消费', '支出', '扣款', '付款', '支付']) ||
        context.toUpperCase().contains('POS')) {
      return -absoluteAmount;
    }
    return amount;
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  static bool _hasExplicitSign(String text) {
    return RegExp(r'[+\-]\s*\d').hasMatch(text);
  }

  static List<CampusCardTransactionRecord> _deduplicateRecords(
    List<CampusCardTransactionRecord> records,
  ) {
    final seen = <String>{};
    final uniqueRecords = <CampusCardTransactionRecord>[];
    for (final record in records) {
      final key =
          '${record.occurredAt}|${record.amount}|${record.rawCells.join('|')}';
      if (!seen.add(key)) continue;
      uniqueRecords.add(record);
    }
    return uniqueRecords;
  }

  static double? _parseMoney(String text) {
    final normalizedText = text.replaceAll(',', '').replaceAll('￥', '');
    final match = RegExp(
      r'([+\-]?\d+(?:\.\d{1,2})?)',
    ).firstMatch(normalizedText);
    return double.tryParse(match?.group(1) ?? '');
  }

  static String _cleanText(String text) {
    return text
        .replaceAll('\u00a0', ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normalizeLabel(String text) {
    return _cleanText(
      text,
    ).replaceAll(RegExp(r'[：:]+$'), '').replaceAll(RegExp(r'\s+'), '').trim();
  }

  static String? _cellAt(List<String> cells, int? index) {
    if (index == null || index < 0 || index >= cells.length) return null;
    final value = cells[index].trim();
    return value.isEmpty ? null : value;
  }

  static final RegExp _datePattern = RegExp(
    r'\d{4}[-/.]\d{1,2}[-/.]\d{1,2}(?:\s+\d{1,2}:?\d{2}(?::?\d{2})?)?',
  );

  static final RegExp _compactDateTimePattern = RegExp(
    r'(\d{4}[-/.]\d{1,2}[-/.]\d{2})\s*(\d{6})',
  );
}

enum _CampusCardTransactionColumn {
  occurredAt,
  title,
  transactionId,
  counterparty,
  amount,
  detail,
  paymentMethod,
  status,
  operation,
}
