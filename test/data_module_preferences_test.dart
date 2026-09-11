/*
 * 数据模块访问偏好测试 — 校验停止获取开关的默认值与持久化
 * @Project : SSPU-AllinOne
 * @File : data_module_preferences_test.dart
 * @Author : Qintsg
 * @Date : 2026-09-08
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/services/data_module_preferences.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  test('升级与新安装默认允许所有校园数据模块联网获取', () async {
    for (final module in CampusDataModule.values) {
      expect(
        await DataModulePreferences.instance.isFetchEnabled(module),
        isTrue,
        reason: module.storageId,
      );
    }
  });

  test('各模块停止获取开关独立持久化', () async {
    await DataModulePreferences.instance.setFetchEnabled(
      CampusDataModule.email,
      false,
    );

    expect(
      await DataModulePreferences.instance.isFetchEnabled(
        CampusDataModule.email,
      ),
      isFalse,
    );
    expect(
      await DataModulePreferences.instance.isFetchEnabled(
        CampusDataModule.academicEams,
      ),
      isTrue,
    );
    expect(
      await StorageService.getBool(StorageKeys.emailModuleFetchEnabled),
      isFalse,
    );
  });

  test('修改模块获取偏好会广播对应模块', () async {
    final changes = <CampusDataModule>[];
    final subscription = DataModulePreferences.instance.changes.listen(
      changes.add,
    );

    await DataModulePreferences.instance.setFetchEnabled(
      CampusDataModule.campusCard,
      false,
    );
    await Future<void>.delayed(Duration.zero);

    expect(changes, [CampusDataModule.campusCard]);
    await subscription.cancel();
  });
}
