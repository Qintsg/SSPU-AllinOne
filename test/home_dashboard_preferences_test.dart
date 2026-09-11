/*
 * 首页布局偏好测试 — 校验服务摘要顺序的修复与持久化
 * @Project : SSPU-AllinOne
 * @File : home_dashboard_preferences_test.dart
 * @Author : Qintsg
 * @Date : 2026-09-08
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/services/data_module_preferences.dart';
import 'package:sspu_allinone/services/home_dashboard_preferences.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  test('缺失配置使用稳定默认顺序', () async {
    expect(
      await HomeDashboardPreferences.instance.getOverviewOrder(),
      HomeDashboardPreferences.defaultOverviewOrder,
    );
  });

  test('未知、重复与缺失项会被修复为完整顺序', () {
    expect(
      HomeDashboardPreferences.normalizeOverviewOrder(const [
        'email',
        'unknown-item',
        'email',
        'campus-card',
      ]),
      const [
        HomeOverviewItem.email,
        HomeOverviewItem.campusCard,
        HomeOverviewItem.trainingPlan,
        HomeOverviewItem.sportsAttendance,
      ],
    );
  });

  test('自定义顺序写入后可原样恢复', () async {
    const expected = [
      HomeOverviewItem.sportsAttendance,
      HomeOverviewItem.email,
      HomeOverviewItem.campusCard,
      HomeOverviewItem.trainingPlan,
    ];

    await HomeDashboardPreferences.instance.setOverviewOrder(expected);

    expect(
      await HomeDashboardPreferences.instance.getOverviewOrder(),
      expected,
    );
    expect(
      await StorageService.getStringList(StorageKeys.homeOverviewOrder),
      expected.map((item) => item.storageId),
    );
  });

  test('首页显隐、摘要顺序和模块获取偏好连续十次存储重载后保持不变', () async {
    const expectedOrder = [
      HomeOverviewItem.email,
      HomeOverviewItem.sportsAttendance,
      HomeOverviewItem.trainingPlan,
      HomeOverviewItem.campusCard,
    ];
    await StorageService.setBool(
      StorageKeys.homeCampusCardBalanceCardVisible,
      false,
    );
    await HomeDashboardPreferences.instance.setOverviewOrder(expectedOrder);
    await DataModulePreferences.instance.setFetchEnabled(
      CampusDataModule.email,
      false,
    );

    for (var restart = 1; restart <= 10; restart++) {
      StorageService.debugUseSharedPreferencesStorageForTesting(true);

      expect(
        await StorageService.getBool(
          StorageKeys.homeCampusCardBalanceCardVisible,
          defaultValue: true,
        ),
        isFalse,
        reason: '第 $restart 次存储重载后的卡片显隐',
      );
      expect(
        await HomeDashboardPreferences.instance.getOverviewOrder(),
        expectedOrder,
        reason: '第 $restart 次存储重载后的摘要顺序',
      );
      expect(
        await DataModulePreferences.instance.isFetchEnabled(
          CampusDataModule.email,
        ),
        isFalse,
        reason: '第 $restart 次存储重载后的模块获取偏好',
      );
    }
  });
}
