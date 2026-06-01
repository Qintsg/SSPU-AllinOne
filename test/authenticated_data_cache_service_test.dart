/*
 * 鉴权业务数据缓存服务测试 — 校验快照持久化与最近三条保留策略
 * @Project : SSPU-AllinOne
 * @File : authenticated_data_cache_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-31
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/services/authenticated_data_cache_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    SharedPreferences.setMockInitialValues({});
  });

  test('缓存按获取时间倒序读取并只保留最近三条', () async {
    const collection = 'test_authenticated_cache';
    for (var index = 0; index < 5; index++) {
      await AuthenticatedDataCacheService.saveLatest(
        collection: collection,
        accountKey: '20260001',
        fetchedAt: DateTime(2026, 5, 1, 8, index),
        data: {'value': index},
      );
    }

    final entries = await AuthenticatedDataCacheService.readLatestRecords(
      collection,
    );

    expect(entries, hasLength(3));
    expect(entries.map((entry) => entry.data['value']), [4, 3, 2]);
    expect(await StorageService.getCollectionCount(collection), 3);
  });

  test('按账号读取缓存，避免切换账号后展示他人数据', () async {
    const collection = 'test_account_scoped_authenticated_cache';
    await AuthenticatedDataCacheService.saveLatest(
      collection: collection,
      accountKey: '20260001',
      fetchedAt: DateTime(2026, 5, 1, 8),
      data: const {'value': 'first-account'},
    );
    await AuthenticatedDataCacheService.saveLatest(
      collection: collection,
      accountKey: '20260002',
      fetchedAt: DateTime(2026, 5, 1, 9),
      data: const {'value': 'second-account'},
    );

    final firstAccountEntry = await AuthenticatedDataCacheService.readLatest(
      collection,
      accountKey: '20260001',
    );

    expect(firstAccountEntry?.data['value'], 'first-account');
    expect(
      await AuthenticatedDataCacheService.readLatest(
        collection,
        accountKey: '20269999',
      ),
      isNull,
    );
  });

  test('每个账号独立保留最近三条，同获取时间不会互相覆盖', () async {
    const collection = 'test_owner_scoped_authenticated_cache';
    for (var index = 0; index < 5; index++) {
      for (final account in ['20260001', '20260002']) {
        await AuthenticatedDataCacheService.saveLatest(
          collection: collection,
          accountKey: account,
          fetchedAt: DateTime(2026, 5, 1, 8, index),
          data: {'value': index},
        );
      }
    }

    final firstAccountEntries =
        await AuthenticatedDataCacheService.readLatestRecords(
          collection,
          accountKey: '20260001',
        );
    final secondAccountEntries =
        await AuthenticatedDataCacheService.readLatestRecords(
          collection,
          accountKey: '20260002',
        );

    expect(firstAccountEntries, hasLength(3));
    expect(secondAccountEntries, hasLength(3));
    expect(firstAccountEntries.map((entry) => entry.data['value']), [4, 3, 2]);
    expect(secondAccountEntries.map((entry) => entry.data['value']), [4, 3, 2]);
    expect(await StorageService.getCollectionCount(collection), 6);
  });

  test('缓存持久化 owner 使用不可逆标识，不写入明文学工号', () async {
    const collection = 'test_private_owner_authenticated_cache';
    await AuthenticatedDataCacheService.saveLatest(
      collection: collection,
      accountKey: '20260001',
      fetchedAt: DateTime(2026, 5, 1, 8),
      data: const {'value': 'cached'},
    );

    final storedPayload = (await StorageService.getAllData(
      collection,
    )).values.single;

    expect(storedPayload.toString(), isNot(contains('20260001')));
    expect(storedPayload['ownerAccount'], isNotEmpty);
    expect(storedPayload['ownerAccount'], isNot('20260001'));
    expect(
      await AuthenticatedDataCacheService.readLatest(
        collection,
        accountKey: '20260001',
      ),
      isNotNull,
    );
  });

  test('缓存持久化前移除 URI 中的敏感查询参数', () async {
    const collection = 'test_sanitized_uri_authenticated_cache';
    await AuthenticatedDataCacheService.saveLatest(
      collection: collection,
      accountKey: '20260001',
      fetchedAt: DateTime(2026, 5, 1, 8),
      data: const {
        'sourceUri': 'https://id.sspu.edu.cn/cas/login?ticket=ST-secret#token',
        'snapshot': {
          'finalUri': 'https://jx.sspu.edu.cn/eams/std.action?ids=20260001',
        },
        'records': [
          {'sourceUri': 'https://card.sspu.edu.cn/epay/?token=secret'},
        ],
      },
    );

    final storedPayload = (await StorageService.getAllData(
      collection,
    )).values.single;

    expect(storedPayload.toString(), isNot(contains('ticket')));
    expect(storedPayload.toString(), isNot(contains('ST-secret')));
    expect(storedPayload.toString(), isNot(contains('ids')));
    expect(storedPayload.toString(), isNot(contains('20260001')));
    expect(storedPayload.toString(), isNot(contains('token')));
    expect(storedPayload['sourceUri'], 'https://id.sspu.edu.cn/cas/login');
    expect(
      (storedPayload['snapshot'] as Map<String, dynamic>)['finalUri'],
      'https://jx.sspu.edu.cn/eams/std.action',
    );
  });

  test('缓存条目可按自动刷新间隔判断是否过期', () async {
    final entry = AuthenticatedDataCacheEntry(
      key: 'sample',
      fetchedAt: DateTime.now().subtract(const Duration(minutes: 31)),
      data: const {'value': 'cached'},
    );

    expect(entry.isStaleFor(30), isTrue);
    expect(entry.isStaleFor(0), isFalse);
  });
}
