/*
 * 鉴权业务数据缓存服务测试 — 校验快照持久化与最近三条保留策略
 * @Project : SSPU-AllinOne
 * @File : authenticated_data_cache_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-31
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/services/authenticated_data_cache_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
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

  test('每类数据全局只保留最近三条，仍支持按账号过滤读取', () async {
    const collection = 'test_collection_scoped_authenticated_cache';
    for (var index = 0; index < 5; index++) {
      await AuthenticatedDataCacheService.saveLatest(
        collection: collection,
        accountKey: '20260001',
        fetchedAt: DateTime(2026, 5, 1, 8, index),
        data: {'account': 'first', 'value': index},
      );
      await AuthenticatedDataCacheService.saveLatest(
        collection: collection,
        accountKey: '20260002',
        fetchedAt: DateTime(2026, 5, 1, 9, index),
        data: {'account': 'second', 'value': index},
      );
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

    expect(firstAccountEntries, isEmpty);
    expect(secondAccountEntries, hasLength(3));
    expect(secondAccountEntries.map((entry) => entry.data['account']).toSet(), {
      'second',
    });
    expect(secondAccountEntries.map((entry) => entry.data['value']), [4, 3, 2]);
    expect(await StorageService.getCollectionCount(collection), 3);
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

  test('校园卡缓存写入安全存储而不落入普通应用状态', () async {
    await AuthenticatedDataCacheService.saveLatest(
      collection: StorageKeys.campusCardCacheCollection,
      accountKey: '20260001',
      fetchedAt: DateTime(2026, 6, 9, 12),
      data: const {
        'balance': 23.45,
        'records': [
          {
            'occurredAt': '2026-06-09 12:47',
            'title': 'POS消费',
            'transactionId': 'T202606090001',
            'counterparty': '一食堂',
            'amount': -12.5,
          },
        ],
      },
    );

    final plainPayload = await StorageService.getAllData(
      StorageKeys.campusCardCacheCollection,
    );
    final secureEntry = await AuthenticatedDataCacheService.readLatest(
      StorageKeys.campusCardCacheCollection,
      accountKey: '20260001',
    );

    expect(plainPayload, isEmpty);
    expect(
      await StorageService.getCollectionCount(
        StorageKeys.campusCardCacheCollection,
      ),
      0,
    );
    expect(secureEntry?.data['balance'], 23.45);
    expect(secureEntry?.data.toString(), contains('POS消费'));
  });

  test('第二课堂缓存写入安全存储并清除旧普通缓存', () async {
    await StorageService.saveData(
      StorageKeys.studentReportCacheCollection,
      'legacy_plain_cache',
      const {
        'records': [
          {'itemName': '旧明文项目', 'credit': 1},
        ],
      },
    );

    await AuthenticatedDataCacheService.saveLatest(
      collection: StorageKeys.studentReportCacheCollection,
      accountKey: '20260001',
      fetchedAt: DateTime(2026, 5, 2, 12),
      data: const {
        'records': [
          {'itemName': '安全缓存项目', 'credit': 1},
        ],
        'rules': [
          {'category': '思想成长', 'item': '安全缓存项目'},
        ],
        'detailRecords': [
          {'name': '安全缓存项目', 'earnedCredit': 1},
        ],
      },
    );

    final plainPayload = await StorageService.getAllData(
      StorageKeys.studentReportCacheCollection,
    );
    final secureEntry = await AuthenticatedDataCacheService.readLatest(
      StorageKeys.studentReportCacheCollection,
      accountKey: '20260001',
    );

    expect(plainPayload, isEmpty);
    expect(
      await StorageService.getCollectionCount(
        StorageKeys.studentReportCacheCollection,
      ),
      0,
    );
    expect(secureEntry?.data.toString(), contains('安全缓存项目'));
    expect(secureEntry?.data.toString(), isNot(contains('20260001')));
    expect(secureEntry?.data.toString(), isNot(contains('旧明文项目')));
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

  test('缓存可在存储服务重新初始化后继续读取', () async {
    const collection = 'test_reinitialized_authenticated_cache';
    await AuthenticatedDataCacheService.saveLatest(
      collection: collection,
      accountKey: '20260001',
      fetchedAt: DateTime(2026, 5, 1, 8),
      data: const {'value': 'persisted'},
    );

    StorageService.debugUseSharedPreferencesStorageForTesting(true);

    final cachedEntry = await AuthenticatedDataCacheService.readLatest(
      collection,
      accountKey: '20260001',
    );

    expect(cachedEntry?.data['value'], 'persisted');
  });
}
