/*
 * 学工报表页面导航器 — 定位学工报表与第二课堂只读入口
 * @Project : SSPU-AllinOne
 * @File : student_report_page_navigator.dart
 * @Author : Qintsg
 * @Date : 2026-05-09
 */

part of 'student_report_service.dart';

/// 学工报表页面导航辅助，仅返回可 GET 打开的只读查询入口。
class StudentReportPageNavigator {
  StudentReportPageNavigator._();

  /// 在 OA 门户页中定位学工报表 SSO 入口。
  static Uri? findReportSystemUri(StudentReportHttpSnapshot snapshot) {
    final document = html_parser.parse(snapshot.body);
    const attributeNames = ['href', 'src', 'action', 'data-url', 'data-href'];
    for (final element in document.querySelectorAll('*')) {
      for (final attributeName in attributeNames) {
        final rawValue = element.attributes[attributeName]?.trim();
        final uri = _reportSystemUriFromText(snapshot.finalUri, rawValue ?? '');
        if (uri != null) return uri;
      }
    }

    return _reportSystemUriFromText(snapshot.finalUri, snapshot.body);
  }

  /// 在首页中定位“第二课堂学分查询”入口。
  static Uri? findSecondClassroomUri(StudentReportHttpSnapshot snapshot) {
    final document = html_parser.parse(snapshot.body);
    final anchors = document.querySelectorAll('a[href], area[href]');
    for (final anchor in anchors) {
      final href = anchor.attributes['href']?.trim();
      if (href == null || href.isEmpty) continue;
      final linkText = _cleanText(anchor.text);
      final lowerHref = href.toLowerCase();
      if (_hasSecondClassroomCreditHint(linkText) ||
          lowerHref.contains('secondclassroom') ||
          lowerHref.contains('second_classroom')) {
        if (!lowerHref.startsWith('javascript:')) {
          return _resolveBusinessUri(snapshot.finalUri, href);
        }
        final uri = _uriFromElementAttributes(snapshot.finalUri, anchor);
        if (uri != null) return uri;
      }
    }

    for (final element in document.querySelectorAll('*')) {
      final elementText = _cleanText(element.text);
      if (!_hasSecondClassroomCreditHint(elementText)) continue;
      final uri = _uriFromElementAttributes(snapshot.finalUri, element);
      if (uri != null) return uri;
    }

    return _uriFromInlineScript(snapshot.finalUri, snapshot.body);
  }

  /// 判断文本中是否出现第二课堂学分入口线索。
  static bool hasSecondClassroomCreditHint(String text) {
    return _hasSecondClassroomCreditHint(_cleanText(text));
  }

  static Uri? _uriFromElementAttributes(Uri baseUri, html_dom.Element element) {
    const candidateAttributes = [
      'href',
      'data-url',
      'data-href',
      'url',
      'onclick',
    ];
    for (final attributeName in candidateAttributes) {
      final value = element.attributes[attributeName]?.trim();
      if (value == null || value.isEmpty) continue;
      final uri = _uriFromText(baseUri, value);
      if (uri != null) return uri;
    }
    return null;
  }

  static Uri? _uriFromInlineScript(Uri baseUri, String body) {
    final normalizedBody = body.replaceAll('&amp;', '&');
    for (final pattern in _secondClassroomPatterns) {
      final match = pattern.firstMatch(normalizedBody);
      final rawUri = match?.group(1)?.trim();
      if (rawUri != null && rawUri.isNotEmpty) {
        return _resolveBusinessUri(baseUri, rawUri);
      }
    }
    return null;
  }

  static Uri? _uriFromText(Uri baseUri, String text) {
    final normalizedText = text.replaceAll('&amp;', '&');
    for (final pattern in _secondClassroomPatterns) {
      final match = pattern.firstMatch(normalizedText);
      final rawUri = match?.group(1)?.trim();
      if (rawUri != null && rawUri.isNotEmpty) {
        return _resolveBusinessUri(baseUri, rawUri);
      }
    }
    return null;
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

  static bool _hasSecondClassroomCreditHint(String text) {
    return text.contains('第二课堂学分') ||
        text.contains('第二学堂学分') ||
        (text.contains('学分') && text.contains('查询'));
  }

  static Uri? _reportSystemUriFromText(Uri baseUri, String text) {
    if (text.isEmpty) return null;
    final normalizedText = text.replaceAll('&amp;', '&');
    for (final pattern in _reportSystemPatterns) {
      final match = pattern.firstMatch(normalizedText);
      final rawUri = match?.group(1)?.trim();
      if (rawUri == null || rawUri.isEmpty) continue;
      final uri = baseUri.resolve(rawUri);
      if (_isReportSystemSsoUri(uri)) return uri;
    }
    return null;
  }

  static bool _isReportSystemSsoUri(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    return host == 'xgbb.sspu.edu.cn' &&
        path.contains('/sharedc/sso/') &&
        !path.contains('/core/login/');
  }

  static String _cleanText(String text) {
    return text
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static final List<RegExp> _secondClassroomPatterns = [
    RegExp(r'''['"]([^'"]*secondClassroom[^'"]*)['"]''', caseSensitive: false),
    RegExp(r'''['"]([^'"]*second_classroom[^'"]*)['"]''', caseSensitive: false),
    RegExp(
      r'''['"]?((?:/?(?:sharedc/)?dc/)?studentxfform/[^'"\s),]+)['"]?''',
      caseSensitive: false,
    ),
    RegExp(
      r'''(?:location\.href|window\.open)\s*\(?\s*['"]([^'"]+)['"]''',
      caseSensitive: false,
    ),
    RegExp(r'''toMain\s*\(\s*['"]([^'"]+)['"]''', caseSensitive: false),
  ];

  static final List<RegExp> _reportSystemPatterns = [
    RegExp(
      r'''['"]([^'"]*xgbb\.sspu\.edu\.cn/sharedc/sso/[^'"]*)['"]''',
      caseSensitive: false,
    ),
    RegExp(
      r'''(https?://xgbb\.sspu\.edu\.cn/sharedc/sso/[^\s"'<>]+)''',
      caseSensitive: false,
    ),
  ];
}
