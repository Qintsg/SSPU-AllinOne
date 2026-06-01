/*
 * 鉴权业务数据缓存服务 — 保存只读业务快照并保留最近记录
 * @Project : SSPU-AllinOne
 * @File : authenticated_data_cache_service.dart
 * @Author : Qintsg
 * @Date : 2026-05-31
 */

import 'storage_service.dart';

/// 鉴权业务数据缓存条目。
/// 仅包含业务解析结果和读取时间，不保存凭据、Cookie 或其它身份材料。
class AuthenticatedDataCacheEntry {
  const AuthenticatedDataCacheEntry({
    required this.key,
    required this.fetchedAt,
    required this.data,
  });

  /// 存储集合内的记录键。
  final String key;

  /// 业务数据获取时间。
  final DateTime fetchedAt;

  /// 业务快照 JSON。
  final Map<String, dynamic> data;

  /// 是否已经超过指定自动刷新间隔。
  bool isStaleFor(int intervalMinutes) {
    if (intervalMinutes <= 0) return false;
    return DateTime.now().difference(fetchedAt) >=
        Duration(minutes: intervalMinutes);
  }
}

/// 鉴权业务数据缓存服务。
class AuthenticatedDataCacheService {
  AuthenticatedDataCacheService._();

  static const String _ownerAccountKey = 'ownerAccount';

  /// 每类业务数据最多保留的历史记录数。
  static const int maxRecordsPerType = 3;

  /// 保存一条业务快照，并清理同集合中更旧的记录。
  static Future<void> saveLatest({
    required String collection,
    required String accountKey,
    required DateTime fetchedAt,
    required Map<String, dynamic> data,
  }) async {
    final ownerAccount = _ownerKeyForAccount(accountKey);
    if (ownerAccount.isEmpty) return;
    final normalizedFetchedAt = fetchedAt.toUtc();
    final key = [
      ownerAccount,
      normalizedFetchedAt.microsecondsSinceEpoch,
      DateTime.now().toUtc().microsecondsSinceEpoch,
    ].join('_');
    final payload = _sanitizeCachePayload(data);
    payload[_ownerAccountKey] = ownerAccount;
    payload['fetchedAt'] = normalizedFetchedAt.toIso8601String();

    await StorageService.saveData(collection, key, payload);
    await _trimCollection(collection, ownerAccount);
  }

  /// 读取指定集合中最新一条业务快照。
  static Future<AuthenticatedDataCacheEntry?> readLatest(
    String collection, {
    String? accountKey,
  }) async {
    final entries = await readLatestRecords(collection, accountKey: accountKey);
    return entries.isEmpty ? null : entries.first;
  }

  /// 读取指定集合中按时间倒序排列的业务快照。
  static Future<List<AuthenticatedDataCacheEntry>> readLatestRecords(
    String collection, {
    String? accountKey,
  }) async {
    final expectedOwner = accountKey == null
        ? null
        : _ownerKeyForAccount(accountKey);
    final records = await StorageService.getAllData(collection);
    final entries = <AuthenticatedDataCacheEntry>[];
    for (final item in records.entries) {
      final fetchedAt = _parseFetchedAt(item.value);
      if (fetchedAt == null) continue;
      if (expectedOwner != null &&
          item.value[_ownerAccountKey] != expectedOwner) {
        continue;
      }
      entries.add(
        AuthenticatedDataCacheEntry(
          key: item.key,
          fetchedAt: fetchedAt,
          data: item.value,
        ),
      );
    }
    entries.sort((a, b) => b.fetchedAt.compareTo(a.fetchedAt));
    return entries;
  }

  /// 清理全部鉴权业务数据缓存。
  static Future<void> clearAll() async {
    for (final collection in _authenticatedCollections) {
      await StorageService.clearCollection(collection);
    }
  }

  static Future<void> _trimCollection(
    String collection,
    String ownerAccount,
  ) async {
    final entries = (await readLatestRecords(
      collection,
    )).where((entry) => entry.data[_ownerAccountKey] == ownerAccount).toList();
    if (entries.length <= maxRecordsPerType) return;
    for (final entry in entries.skip(maxRecordsPerType)) {
      await StorageService.removeData(collection, entry.key);
    }
  }

  static DateTime? _parseFetchedAt(Map<String, dynamic> data) {
    final value = data['fetchedAt'];
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  static Map<String, dynamic> _sanitizeCachePayload(Map<String, dynamic> data) {
    return Map<String, dynamic>.fromEntries(
      data.entries.map(
        (entry) =>
            MapEntry(entry.key, _sanitizeCacheValue(entry.key, entry.value)),
      ),
    );
  }

  static Object? _sanitizeCacheValue(String key, Object? value) {
    if (value is Map<String, dynamic>) return _sanitizeCachePayload(value);
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(
            entry.key.toString(),
            _sanitizeCacheValue(entry.key.toString(), entry.value),
          ),
        ),
      );
    }
    if (value is List) {
      return value.map((item) => _sanitizeCacheValue(key, item)).toList();
    }
    if (value is String && _isUriField(key)) return _sanitizeUriString(value);
    return value;
  }

  static bool _isUriField(String key) {
    return key.toLowerCase().endsWith('uri');
  }

  static String _sanitizeUriString(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return value;
    final sanitizedUri = StringBuffer('${uri.scheme}:');
    if (uri.hasAuthority) {
      sanitizedUri.write('//');
      if (uri.userInfo.isNotEmpty) sanitizedUri.write('${uri.userInfo}@');
      sanitizedUri.write(uri.host);
      if (uri.hasPort) sanitizedUri.write(':${uri.port}');
    }
    sanitizedUri.write(uri.path);
    return sanitizedUri.toString();
  }

  static String _normalizeAccountKey(Object? value) {
    if (value is! String) return '';
    return value.trim().toLowerCase();
  }

  static String _ownerKeyForAccount(Object? value) {
    final normalizedAccount = _normalizeAccountKey(value);
    if (normalizedAccount.isEmpty) return '';
    return StorageService.hashPassword(
      'authenticated-cache:$normalizedAccount',
    );
  }

  static List<String> get _authenticatedCollections => [
    StorageKeys.campusCardCacheCollection,
    StorageKeys.sportsAttendanceCacheCollection,
    StorageKeys.studentReportCacheCollection,
    StorageKeys.academicEamsOverviewCacheCollection,
    StorageKeys.academicEamsCourseTableCacheCollection,
    StorageKeys.emailMailboxCacheCollection,
    '${StorageKeys.emailMailboxCacheCollection}_imap',
    '${StorageKeys.emailMailboxCacheCollection}_pop',
    '${StorageKeys.emailMailboxCacheCollection}_smtp',
  ];
}
