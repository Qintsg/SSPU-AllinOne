/*
 * 学工报表表格展开 — rowspan/colspan 展开与行单元格数据结构
 * @Project : SSPU-AllinOne
 * @File : student_report_page_parser_table.dart
 * @Author : Qintsg
 * @Date : 2026-08-21
 */

part of 'student_report_service.dart';

/// 将 HTML 表格中的 rowspan/colspan 展开为平铺行列表。
///
/// :param table: HTML 表格元素。
/// :returns: 展开后的行列表。
List<_ExpandedTableRow> _expandTable(html_dom.Element table) {
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

/// 解析 rowspan/colspan 属性值。
///
/// :param value: 属性原始值。
/// :returns: 合法的跨行/跨列数，最小为 1。
int _parseSpan(String? value) {
  final span = int.tryParse(value ?? '') ?? 1;
  return span <= 0 ? 1 : span;
}

/// 规则矩阵解析中间结果。
class _ParsedRuleMatrix {
  const _ParsedRuleMatrix({required this.rules, required this.totals});

  final List<SecondClassroomCreditRuleRow> rules;
  final SecondClassroomCreditTotals? totals;
}

/// 展开后的表格行。
class _ExpandedTableRow {
  const _ExpandedTableRow(this.cells);

  final List<_ExpandedTableCell> cells;

  List<String> get texts => cells.map((cell) => cell.text).toList();

  _ExpandedTableCell? cellAt(int index) {
    if (index < 0 || index >= cells.length) return null;
    return cells[index];
  }
}

/// 展开后的表格单元格。
class _ExpandedTableCell {
  const _ExpandedTableCell({required this.text, required this.element});

  final String text;
  final html_dom.Element element;
}

/// 等待在后续行中填充的待消费单元格。
class _PendingTableCell {
  _PendingTableCell(this.cell, this.remainingRows);

  final _ExpandedTableCell cell;
  int remainingRows;
}

/// 清理文本中的特殊空白字符。
///
/// :param text: 原始文本。
/// :returns: 清理后的文本。
String _cleanText(String text) {
  return text
      .replaceAll('\u00a0', ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// 从文本中解析数值。
///
/// :param text: 包含数值的文本。
/// :returns: 解析出的数值，无法解析时返回 null。
double? _parseNumber(String text) {
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
