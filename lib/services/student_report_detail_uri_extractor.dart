/*
 * 学工报表详情入口提取器 — 解析已获积分弹窗接口地址
 * @Project : SSPU-AllinOne
 * @File : student_report_detail_uri_extractor.dart
 * @Author : Qintsg
 * @Date : 2026-06-10
 */

part of 'student_report_service.dart';

/// 从第二课堂规则矩阵单元格中构造“已获积分”详情接口地址。
class _StudentReportDetailUriExtractor {
  _StudentReportDetailUriExtractor._();

  /// 解析页面隐藏学号字段。
  static String studentNumberFromDocument(html_dom.Document document) {
    final element =
        document.querySelector('#xh') ??
        document.querySelector('input[name="xh"]') ??
        document.querySelector('input[name="stuno"]');
    final value = element?.attributes['value'];
    return StudentReportPageParser._cleanText(value ?? '');
  }

  /// 从已获积分单元格构造同目录 `detail.do` 只读接口地址。
  static Uri? detailUriFromEarnedCell({
    required Uri baseUri,
    required html_dom.Element element,
    required String studentNumber,
  }) {
    final hasDetailHandler = element.outerHtml.toLowerCase().contains(
      'detail(',
    );
    if (!hasDetailHandler) return null;
    final proid = _detailProidFromElement(element);
    if (proid.isEmpty || studentNumber.isEmpty) return null;
    final detailUri = _studentXfDetailBaseUri(baseUri);
    return detailUri.replace(
      queryParameters: {'proid': proid, 'xh': studentNumber},
    );
  }

  static String _detailProidFromElement(html_dom.Element element) {
    final inputs = element.querySelectorAll('input');
    for (final input in inputs) {
      final id = input.attributes['id']?.trim();
      final name = input.attributes['name']?.trim();
      if (id != 'value' && name != 'value' && inputs.length > 1) continue;
      final value = input.attributes['value'];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static Uri _studentXfDetailBaseUri(Uri baseUri) {
    final lowerPath = baseUri.path.toLowerCase();
    final marker = '/studentxfform/';
    final markerIndex = lowerPath.indexOf(marker);
    if (markerIndex >= 0) {
      final prefix = baseUri.path.substring(0, markerIndex + marker.length);
      return baseUri.replace(path: '${prefix}detail.do', query: '');
    }
    return StudentReportPageParser._resolveBusinessUri(
      baseUri,
      'dc/studentxfform/detail.do',
    );
  }
}
