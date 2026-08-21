/*
 * 学工报表 URI 提取 — 从已获分单元格与页面元素中提取详情页入口
 * @Project : SSPU-AllinOne
 * @File : student_report_page_parser_uri.dart
 * @Author : Qintsg
 * @Date : 2026-08-21
 */

part of 'student_report_service.dart';

/// 从页面元素中提取 URI 列表。
///
/// :param baseUri: 基准 URI。
/// :param element: HTML 元素。
/// :returns: 提取出的去重 URI 列表。
List<Uri> _urisFromElement(Uri baseUri, html_dom.Element element) {
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

/// 从文本中解析单个 URI。
///
/// :param baseUri: 基准 URI。
/// :param text: 包含 URI 的原始文本。
/// :returns: 解析出的 URI，无法解析时返回 null。
Uri? _uriFromText(Uri baseUri, String text) {
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

/// 判断文本是否看起来像标准 URI 前缀。
///
/// :param value: 待判断的文本。
/// :returns: 是否为 URI 形式。
bool _looksLikeUri(String value) {
  return value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.startsWith('//') ||
      value.startsWith('/') ||
      value.startsWith('../') ||
      value.startsWith('./');
}

/// 判断文本是否为直接的 .do 路径。
///
/// :param value: 待判断的文本。
/// :returns: 是否为 .do 路径。
bool _looksLikeDirectDoPath(String value) {
  return RegExp(r'''^[^\s<>"']+\.do(?:\?[^\s<>"']*)?$''').hasMatch(value);
}

/// 解析业务 URI，处理 sharedc 路径前缀。
///
/// :param baseUri: 基准 URI。
/// :param rawUri: 原始 URI 字符串。
/// :returns: 解析后的 URI。
Uri _resolveBusinessUri(Uri baseUri, String rawUri) {
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
    return baseUri.replace(path: sharedcRoot, query: '').resolve(normalizedUri);
  }
  return baseUri.resolve(normalizedUri);
}

/// 对 URI 列表去重。
///
/// :param uris: 待去重的 URI 列表。
/// :returns: 去重后的 URI 列表。
List<Uri> _deduplicateUris(List<Uri> uris) {
  final seen = <String>{};
  final uniqueUris = <Uri>[];
  for (final uri in uris) {
    final key = uri.toString();
    if (!seen.add(key)) continue;
    uniqueUris.add(uri);
  }
  return uniqueUris;
}
