/*
 * 教务凭据安全存储服务测试 — 校验本地可解密凭据的保存与清除语义
 * @Project : SSPU-AllinOne
 * @File : academic_credentials_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-24
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/academic_credentials.dart';
import 'package:sspu_allinone/models/academic_login_validation.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/authenticated_data_cache_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  final service = AcademicCredentialsService.instance;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    SharedPreferences.setMockInitialValues({});
  });

  test('保存教务凭据后返回账号与密码填写状态', () async {
    await service.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
      sportsQueryPassword: 'sports-pass',
      emailPassword: 'mail-pass',
    );

    final status = await service.getStatus();

    expect(status.oaAccount, '20260001');
    expect(status.emailAccount, '20260001@sspu.edu.cn');
    expect(status.hasOaPassword, isTrue);
    expect(status.hasSportsQueryPassword, isTrue);
    expect(status.hasEmailPassword, isTrue);
    expect(
      await service.readSecret(AcademicCredentialSecret.oaPassword),
      'oa-pass',
    );
  });

  test('空密码输入不会覆盖已有密码', () async {
    await service.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
      sportsQueryPassword: 'sports-pass',
      emailPassword: 'mail-pass',
    );

    await service.saveCredentials(
      oaAccount: '20260002',
      oaPassword: null,
      sportsQueryPassword: null,
      emailPassword: null,
    );

    final status = await service.getStatus();

    expect(status.oaAccount, '20260002');
    expect(status.emailAccount, '20260002@sspu.edu.cn');
    expect(status.hasOaPassword, isTrue);
    expect(
      await service.readSecret(AcademicCredentialSecret.oaPassword),
      'oa-pass',
    );
    expect(
      await service.readSecret(AcademicCredentialSecret.sportsQueryPassword),
      'sports-pass',
    );
    expect(
      await service.readSecret(AcademicCredentialSecret.emailPassword),
      'mail-pass',
    );
  });

  test('可以单独清除指定密码字段', () async {
    await service.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
      sportsQueryPassword: 'sports-pass',
      emailPassword: 'mail-pass',
    );

    await service.clearSecret(AcademicCredentialSecret.sportsQueryPassword);

    final status = await service.getStatus();

    expect(status.hasOaPassword, isTrue);
    expect(status.hasSportsQueryPassword, isFalse);
    expect(status.hasEmailPassword, isTrue);
    expect(
      await service.readSecret(AcademicCredentialSecret.sportsQueryPassword),
      isNull,
    );
  });

  test('OA 账号或密码变化时清除旧登录会话', () async {
    await service.saveCredentials(oaAccount: '20260001', oaPassword: 'oa-pass');
    await service.saveOaLoginSession(
      AcademicLoginSessionSnapshot(
        cookieHeadersByHost: const {
          'oa.sspu.edu.cn': 'ecology_JSessionid=fake-session',
        },
        authenticatedAt: DateTime(2026, 4, 27),
        entranceUri: Uri.parse(
          'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
        ),
        finalUri: Uri.parse(
          'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
        ),
      ),
    );

    await service.saveCredentials(oaAccount: '20260002');

    expect(await service.readOaLoginSession(), isNull);
  });

  test('同账号更新 OA 密码后旧登录会话不可复用', () async {
    await service.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'old-pass',
    );
    await service.saveOaLoginSession(
      AcademicLoginSessionSnapshot(
        cookieHeadersByHost: const {
          'oa.sspu.edu.cn': 'ecology_JSessionid=fake-session',
        },
        authenticatedAt: DateTime(2026, 4, 27),
        entranceUri: Uri.parse(
          'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
        ),
        finalUri: Uri.parse(
          'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
        ),
      ),
    );

    await service.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'new-pass',
    );

    expect(await service.readOaLoginSession(), isNull);
  });

  test('清除所有教务凭据时逐项删除安全存储键', () async {
    await service.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
      sportsQueryPassword: 'sports-pass',
      emailPassword: 'mail-pass',
    );

    await service.clearAll();

    final status = await service.getStatus();

    expect(status.oaAccount, isEmpty);
    expect(status.emailAccount, isEmpty);
    expect(status.hasOaPassword, isFalse);
    expect(status.hasSportsQueryPassword, isFalse);
    expect(status.hasEmailPassword, isFalse);
  });

  test('切换账号时保留鉴权业务缓存并依赖账号隔离读取', () async {
    await service.saveCredentials(oaAccount: '20260001');
    await AuthenticatedDataCacheService.saveLatest(
      collection: StorageKeys.campusCardCacheCollection,
      accountKey: '20260001',
      fetchedAt: DateTime(2026, 5, 1, 8),
      data: const {'balance': 23.45},
    );

    await service.saveCredentials(oaAccount: '20260002');

    expect(
      await AuthenticatedDataCacheService.readLatest(
        StorageKeys.campusCardCacheCollection,
        accountKey: '20260001',
      ),
      isNotNull,
    );
    expect(
      await AuthenticatedDataCacheService.readLatest(
        StorageKeys.campusCardCacheCollection,
        accountKey: '20260002',
      ),
      isNull,
    );
  });

  test('同账号更新任一密码时保留已解析业务缓存', () async {
    await service.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
      sportsQueryPassword: 'sports-pass',
      emailPassword: 'mail-pass',
    );
    await AuthenticatedDataCacheService.saveLatest(
      collection: StorageKeys.emailMailboxCacheCollection,
      accountKey: '20260001@sspu.edu.cn',
      fetchedAt: DateTime(2026, 5, 1, 8),
      data: const {'subject': '旧邮件'},
    );

    await service.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'new-mail-pass',
    );

    expect(
      await AuthenticatedDataCacheService.readLatest(
        StorageKeys.emailMailboxCacheCollection,
        accountKey: '20260001@sspu.edu.cn',
      ),
      isNotNull,
    );
  });
}
