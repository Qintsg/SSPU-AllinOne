/*
 * 统一存储服务测试 — 校验 Web 兼容状态后端不会访问本地文件目录
 * @Project : SSPU-AllinOne
 * @File : storage_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-25
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  test('SharedPreferences 状态后端可初始化并跨重启读取', () async {
    await StorageService.init();
    await StorageService.setString('sample_string', 'value');
    await StorageService.setBool('sample_bool', true);

    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    await StorageService.init();

    expect(await StorageService.getString('sample_string'), 'value');
    expect(await StorageService.getBool('sample_bool'), isTrue);
    expect(
      await StorageService.getStateFilePath(),
      contains('SharedPreferences'),
    );
  });

  test('SharedPreferences 状态后端会迁移旧键值', () async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.eulaAccepted: true,
      'legacy_agreement_key': true,
      'legacy_string': 'legacy-value',
    });
    StorageService.debugUseSharedPreferencesStorageForTesting(true);

    await StorageService.init();

    expect(await StorageService.getBool('legacy_agreement_key'), isTrue);
    expect(await StorageService.getString('legacy_string'), 'legacy-value');
  });

  test('接受协议会同时写入当前协议键和旧版兼容键', () async {
    await StorageService.init();

    await StorageService.acceptCurrentAgreements();

    expect(await StorageService.getBool(StorageKeys.agreementAccepted), isTrue);
    expect(await StorageService.getBool(StorageKeys.eulaAccepted), isTrue);
    expect(await StorageService.areCurrentAgreementsAccepted(), isTrue);
    expect(await StorageService.isEulaAccepted(), isTrue);
  });

  test('仅有旧版 EULA 键时需要重新确认当前协议', () async {
    SharedPreferences.setMockInitialValues({StorageKeys.eulaAccepted: true});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);

    await StorageService.init();

    expect(await StorageService.getBool(StorageKeys.eulaAccepted), isTrue);
    expect(await StorageService.areCurrentAgreementsAccepted(), isFalse);
  });

  test('仅有旧版 MIT 协议键时需要重新确认当前协议', () async {
    SharedPreferences.setMockInitialValues({
      'agreement_20260515_accepted': true,
    });
    StorageService.debugUseSharedPreferencesStorageForTesting(true);

    await StorageService.init();

    expect(await StorageService.getBool('agreement_20260515_accepted'), isTrue);
    expect(await StorageService.areCurrentAgreementsAccepted(), isFalse);
  });
}
