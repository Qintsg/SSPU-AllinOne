/*
 * 校园卡读取流程与入口分类辅助
 * @Project : SSPU-AllinOne
 * @File : campus_card_flow.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

part of 'campus_card_service.dart';

extension _CampusCardFlow on CampusCardService {
  Future<CampusCardHttpSnapshot> _resolveBusinessEntrySnapshot(
    CampusCardHttpSnapshot entrySnapshot,
  ) async {
    if (entrySnapshot.finalUri.host.toLowerCase() ==
        homeUri.host.toLowerCase()) {
      return entrySnapshot;
    }

    final jumpUris = _findPossibleJumpUris(entrySnapshot);
    for (final jumpUri in jumpUris) {
      try {
        final snapshot = await _gateway.fetchPage(jumpUri, timeout);
        if (!_isAuthenticationRequired(snapshot) && !_isUnavailable(snapshot)) {
          return snapshot;
        }
      } on DioException catch (_) {
        continue;
      } on TimeoutException catch (_) {
        continue;
      }
    }
    return entrySnapshot;
  }

  Future<CampusCardHttpSnapshot> _openEntryWithSession(
    AcademicLoginSessionSnapshot? sessionSnapshot,
  ) async {
    await _gateway.resetSession(sessionSnapshot?.cookieHeadersByHost ?? {});
    return _gateway.openEntryPage(entranceUri, timeout);
  }

  Future<void> _appendPageIfAvailable(
    List<CampusCardHttpSnapshot> snapshots,
    Uri pageUri,
  ) async {
    try {
      final snapshot = await _gateway.fetchPage(pageUri, timeout);
      if (_isAuthenticationRequired(snapshot) || _isUnavailable(snapshot)) {
        return;
      }
      snapshots.add(snapshot);
    } on DioException catch (_) {
      return;
    } on TimeoutException catch (_) {
      return;
    }
  }

  Future<_CampusCardTransactionQueryAttempt> _queryTransactionsIfAvailable(
    CampusCardHttpSnapshot transactionIndexSnapshot, {
    DateTime? startDate,
    DateTime? endDate,
    required bool syncAllTransactions,
  }) async {
    try {
      final queryUri = _transactionQueryUriFor(transactionIndexSnapshot);
      final cachedQueryResult = syncAllTransactions
          ? await readLatestCachedCampusCard()
          : null;
      final cachedSnapshot = cachedQueryResult?.snapshot;
      final hasCachedPageWindow =
          (cachedSnapshot?.transactionPageCount ?? 0) > 0;
      final pageLimit = syncAllTransactions
          ? _transactionPagesToFetch(cachedSnapshot)
          : 1;
      final baseFields = _buildTransactionQueryFields(
        transactionIndexSnapshot.body,
        startDate: startDate,
        endDate: endDate,
      );
      final snapshots = <CampusCardHttpSnapshot>[];
      final seenPageKeys = <String>{};
      for (var pageNo = 1; pageNo <= pageLimit; pageNo++) {
        final fields = _fieldsForTransactionPage(baseFields, pageNo);
        final snapshot = await _gateway.queryTransactions(
          queryUri: queryUri,
          fields: fields,
          timeout: timeout,
          refererUri: transactionIndexSnapshot.finalUri,
        );
        if (_isAuthenticationRequired(snapshot) || _isUnavailable(snapshot)) {
          return _CampusCardTransactionQueryAttempt.failure(
            status: _isAuthenticationRequired(snapshot)
                ? CampusCardQueryStatus.oaLoginRequired
                : CampusCardQueryStatus.cardSystemUnavailable,
            message: _isAuthenticationRequired(snapshot)
                ? 'OA 登录状态不可用，无法查询校园卡交易记录'
                : '校园卡交易记录页面不可用',
            detail: _isAuthenticationRequired(snapshot)
                ? '交易记录查询接口返回登录页，请重新验证 OA 登录状态后再试。'
                : '交易记录查询接口返回不可用状态或错误页面。',
            finalUri: snapshot.finalUri,
          );
        }

        final pageRecords =
            CampusCardPageParser.parse([snapshot])?.records ?? const [];
        final count = pageRecords.length;
        if (syncAllTransactions) {
          final pageKey = _transactionPageKey(pageRecords);
          if (pageKey.isNotEmpty && !seenPageKeys.add(pageKey)) break;
          if (!hasCachedPageWindow && count == 0) break;
        }
        snapshots.add(snapshot);
        if (!syncAllTransactions) break;
        if (!hasCachedPageWindow && count < _transactionPageSize) break;
      }
      return _CampusCardTransactionQueryAttempt.success(snapshots);
    } on DioException catch (error) {
      return _CampusCardTransactionQueryAttempt.failure(
        status: CampusCardQueryStatus.networkError,
        message: '校园卡交易记录查询网络失败',
        detail: HttpService.describeError(error),
        finalUri: error.requestOptions.uri,
      );
    } on TimeoutException {
      return _CampusCardTransactionQueryAttempt.failure(
        status: CampusCardQueryStatus.networkError,
        message: '校园卡交易记录查询超时',
        detail: '访问校园卡交易记录查询接口超时。',
        finalUri: transactionQueryUri,
      );
    }
  }

  Uri _transactionQueryUriFor(CampusCardHttpSnapshot transactionIndexSnapshot) {
    final document = html_parser.parse(transactionIndexSnapshot.body);
    final form =
        document.querySelector('form#transparam') ??
        document.querySelector('form[action*="query"]') ??
        document.querySelector('form');
    final action = form?.attributes['action']?.trim();
    if (action != null && action.isNotEmpty) {
      return transactionIndexSnapshot.finalUri.resolve(action);
    }
    return transactionQueryUri;
  }

  Map<String, String> _buildTransactionQueryFields(
    String transactionIndexBody, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final document = html_parser.parse(transactionIndexBody);
    final form =
        document.querySelector('form#transparam') ??
        document.querySelector('form[action*="query"]') ??
        document.querySelector('form');
    final fields = form == null
        ? <String, String>{}
        : _extractFormDefaults(form);
    final csrf = _extractCsrf(document);
    fields.addAll({
      'aaxmlrequest': 'true',
      'pageNo': '1',
      'tabNo': '1',
      'pager.offset': '0',
      'tradename': fields['tradename'] ?? '',
      'timetype': fields['timetype'] ?? '1',
      '_tradedirect': fields['_tradedirect'] ?? 'on',
    });
    if (startDate != null) fields['starttime'] = _formatDate(startDate);
    fields.putIfAbsent('starttime', () => '');
    if (endDate != null) fields['endtime'] = _formatDate(endDate);
    fields.putIfAbsent('endtime', () => '');
    if (csrf != null) fields['_csrf'] = csrf;
    return fields;
  }

  Map<String, String> _fieldsForTransactionPage(
    Map<String, String> baseFields,
    int pageNo,
  ) {
    final fields = Map<String, String>.from(baseFields);
    fields['pageNo'] = pageNo.toString();
    fields['pager.offset'] = ((pageNo - 1) * _transactionPageSize).toString();
    return fields;
  }

  Map<String, String> _extractFormDefaults(html_dom.Element form) {
    final fields = <String, String>{};
    for (final input in form.querySelectorAll('input[name]')) {
      final name = input.attributes['name']?.trim();
      if (name == null || name.isEmpty) continue;
      final type = input.attributes['type']?.trim().toLowerCase() ?? '';
      final value = input.attributes['value'] ?? '';
      if ((type == 'checkbox' || type == 'radio') &&
          !input.attributes.containsKey('checked')) {
        if (type == 'checkbox' && name.startsWith('_')) {
          fields[name] = value;
        }
        continue;
      }
      fields[name] = value;
    }
    return fields;
  }

  String? _extractCsrf(html_dom.Document document) {
    final meta = document.querySelector('meta[name="_csrf"]');
    final token = meta?.attributes['content']?.trim();
    if (token != null && token.isNotEmpty) return token;
    final input = document.querySelector('input[name="_csrf"]');
    final inputToken = input?.attributes['value']?.trim();
    return inputToken == null || inputToken.isEmpty ? null : inputToken;
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Uri _findTransactionIndexUri(List<CampusCardHttpSnapshot> snapshots) {
    final candidates = <Uri>[];
    for (final snapshot in snapshots) {
      final document = html_parser.parse(snapshot.body);
      for (final element in document.querySelectorAll('a,button')) {
        final text = _normalizeText(element.text);
        final title = element.attributes['title'] ?? '';
        final combined = '$text $title';
        if (!_looksLikeAllTransactionsEntry(combined)) continue;
        candidates.addAll(_extractTransactionLinkUris(element, snapshot));
      }
    }
    for (final candidate in candidates) {
      if (_isCardUri(candidate)) return candidate;
    }
    return transactionIndexUri;
  }

  bool _looksLikeAllTransactionsEntry(String text) {
    final normalizedText = _normalizeText(text);
    return normalizedText.contains('查看所有交易记录') ||
        (normalizedText.contains('所有') && normalizedText.contains('交易记录')) ||
        normalizedText.contains('交易记录查询');
  }

  List<Uri> _extractTransactionLinkUris(
    html_dom.Element element,
    CampusCardHttpSnapshot entrySnapshot,
  ) {
    final values = <String>{};
    for (final attributeName in const [
      'href',
      'data-url',
      'data-href',
      'url',
      'action',
    ]) {
      final value = element.attributes[attributeName]?.trim();
      if (_isUsableTransactionHref(value)) values.add(value!);
    }
    final onclick = element.attributes['onclick']?.trim();
    if (onclick != null && onclick.isNotEmpty) {
      final patterns = [
        RegExp(r'''location(?:\.href)?\s*=\s*['"]([^'"]+)['"]'''),
        RegExp(r'''window\.open\(\s*['"]([^'"]+)['"]'''),
        RegExp(r'''['"]([^'"]*/epay/[^'"]*)['"]'''),
      ];
      for (final pattern in patterns) {
        for (final match in pattern.allMatches(onclick)) {
          final value = match.group(1)?.trim();
          if (_isUsableTransactionHref(value)) values.add(value!);
        }
      }
    }
    return values.map(entrySnapshot.finalUri.resolve).toList();
  }

  bool _isUsableTransactionHref(String? value) {
    if (value == null) return false;
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty ||
        trimmedValue == '#' ||
        trimmedValue.toLowerCase().startsWith('javascript:')) {
      return false;
    }
    return true;
  }

  bool _isCardUri(Uri uri) {
    return uri.host.toLowerCase() == 'card.sspu.edu.cn';
  }

  bool _isAuthenticationRequired(CampusCardHttpSnapshot snapshot) {
    final host = snapshot.finalUri.host.toLowerCase();
    final path = snapshot.finalUri.path.toLowerCase();
    final normalizedBody = _normalizeText(snapshot.body);
    return (host == 'id.sspu.edu.cn' && path.contains('/cas/login')) ||
        normalizedBody.contains('登录 - 上海第二工业大学') ||
        normalizedBody.contains('j_spring_cas_security_check') ||
        normalizedBody.contains('id="fm1"');
  }

  bool _isUnavailable(CampusCardHttpSnapshot snapshot) {
    final statusCode = snapshot.statusCode;
    if (statusCode != null && statusCode >= 400) return true;
    final normalizedBody = _normalizeText(snapshot.body);
    return normalizedBody.contains('forbidden') ||
        normalizedBody.contains('error') ||
        normalizedBody.contains('错误页面');
  }

  String _normalizeText(String text) {
    return text.replaceAll('\u00a0', ' ').replaceAll(RegExp(r'\s+'), ' ');
  }

  List<Uri> _findPossibleJumpUris(CampusCardHttpSnapshot snapshot) {
    final values = <String>{};
    final patterns = [
      RegExp(r'''https://card\.sspu\.edu\.cn[^"'<> ]*'''),
      RegExp(r'''location(?:\.href)?\s*=\s*['"]([^'"]+)['"]'''),
      RegExp(r'''window\.location\.href\s*=\s*['"]([^'"]+)['"]'''),
      RegExp(r'''parent\.location\.href\s*=\s*['"]([^'"]+)['"]'''),
    ];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(snapshot.body)) {
        final value = match.groupCount >= 1
            ? (match.group(1) ?? match.group(0) ?? '').trim()
            : '';
        if (value.isNotEmpty) values.add(value);
      }
    }

    return values
        .map(snapshot.finalUri.resolve)
        .where(_isCardUri)
        .toSet()
        .toList();
  }

  int _transactionPagesToFetch(CampusCardSnapshot? cachedSnapshot) {
    final cachedPageCount = cachedSnapshot?.transactionPageCount ?? 0;
    if (cachedPageCount > 0) return cachedPageCount.clamp(1, 200);
    final cachedRecordCount = cachedSnapshot?.records.length ?? 0;
    if (cachedRecordCount > 0) {
      return (cachedRecordCount / _transactionPageSize).ceil().clamp(1, 200);
    }
    return 200;
  }

  String _transactionPageKey(List<CampusCardTransactionRecord> records) {
    return records
        .map(
          (record) =>
              '${record.occurredAt}|${record.transactionId ?? ''}|${record.amount}',
        )
        .join('\n');
  }

  CampusCardQueryResult _buildResult(
    CampusCardQueryStatus status, {
    required String message,
    required String detail,
    DateTime? checkedAt,
    Uri? finalUri,
    CampusNetworkStatus? campusNetworkStatus,
    CampusCardSnapshot? snapshot,
  }) {
    return CampusCardQueryResult(
      status: status,
      message: message,
      detail: detail,
      checkedAt: checkedAt ?? DateTime.now(),
      entranceUri: entranceUri,
      finalUri: finalUri,
      campusNetworkStatus: campusNetworkStatus,
      snapshot: snapshot,
    );
  }

  int _normalizeAutoRefreshInterval(int minutes) {
    return minutes <= 0
        ? CampusCardService.defaultAutoRefreshIntervalMinutes
        : minutes;
  }

  static const int _transactionPageSize = 10;
}

class _CampusCardTransactionQueryAttempt {
  const _CampusCardTransactionQueryAttempt._({
    required this.snapshots,
    required this.status,
    required this.message,
    required this.detail,
    required this.finalUri,
  });

  factory _CampusCardTransactionQueryAttempt.success(
    List<CampusCardHttpSnapshot> snapshots,
  ) {
    return _CampusCardTransactionQueryAttempt._(
      snapshots: List.unmodifiable(snapshots),
      status: null,
      message: null,
      detail: null,
      finalUri: snapshots.isEmpty ? null : snapshots.last.finalUri,
    );
  }

  factory _CampusCardTransactionQueryAttempt.failure({
    required CampusCardQueryStatus status,
    required String message,
    required String detail,
    required Uri finalUri,
  }) {
    return _CampusCardTransactionQueryAttempt._(
      snapshots: const [],
      status: status,
      message: message,
      detail: detail,
      finalUri: finalUri,
    );
  }

  final List<CampusCardHttpSnapshot> snapshots;
  final CampusCardQueryStatus? status;
  final String? message;
  final String? detail;
  final Uri? finalUri;

  bool get isSuccess => status == null;
}
