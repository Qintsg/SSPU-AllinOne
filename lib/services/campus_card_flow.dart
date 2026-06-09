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
  }) async {
    try {
      final fields = _buildTransactionQueryFields(
        transactionIndexSnapshot.body,
        startDate: startDate,
        endDate: endDate,
      );
      final snapshot = await _gateway.queryTransactions(
        queryUri: transactionQueryUri,
        fields: fields,
        timeout: timeout,
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
      return _CampusCardTransactionQueryAttempt.success(snapshot);
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

  Map<String, String> _buildTransactionQueryFields(
    String transactionIndexBody, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final csrf = _extractCsrf(transactionIndexBody);
    final fields = {
      'aaxmlrequest': 'true',
      'pageNo': '1',
      'tabNo': '0',
      'pager.offset': '0',
      'tradename': '',
      'starttime': startDate == null ? '' : _formatDate(startDate),
      'endtime': endDate == null ? '' : _formatDate(endDate),
      'timetype': '1',
      '_tradedirect': '',
    };
    if (csrf != null) fields['_csrf'] = csrf;
    return fields;
  }

  String? _extractCsrf(String body) {
    final document = html_parser.parse(body);
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
        .map(
          (uri) => uri.host.toLowerCase() == 'card.sspu.edu.cn'
              ? uri.replace(scheme: 'http')
              : uri,
        )
        .where((uri) => uri.host.toLowerCase() == 'card.sspu.edu.cn')
        .toSet()
        .toList();
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
}

class _CampusCardTransactionQueryAttempt {
  const _CampusCardTransactionQueryAttempt._({
    required this.snapshot,
    required this.status,
    required this.message,
    required this.detail,
    required this.finalUri,
  });

  factory _CampusCardTransactionQueryAttempt.success(
    CampusCardHttpSnapshot snapshot,
  ) {
    return _CampusCardTransactionQueryAttempt._(
      snapshot: snapshot,
      status: null,
      message: null,
      detail: null,
      finalUri: snapshot.finalUri,
    );
  }

  factory _CampusCardTransactionQueryAttempt.failure({
    required CampusCardQueryStatus status,
    required String message,
    required String detail,
    required Uri finalUri,
  }) {
    return _CampusCardTransactionQueryAttempt._(
      snapshot: null,
      status: status,
      message: message,
      detail: detail,
      finalUri: finalUri,
    );
  }

  final CampusCardHttpSnapshot? snapshot;
  final CampusCardQueryStatus? status;
  final String? message;
  final String? detail;
  final Uri? finalUri;

  bool get isSuccess => snapshot != null;
}
