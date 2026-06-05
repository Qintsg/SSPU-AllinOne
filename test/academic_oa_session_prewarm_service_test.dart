/*
 * OA 会话预热服务测试 — 校验应用启动和保存凭据后的静默会话准备
 * @Project : SSPU-AllinOne
 * @File : academic_oa_session_prewarm_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-04
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/models/academic_login_validation.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/academic_oa_session_prewarm_service.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('缺少 OA 账号或密码时不触发会话预热', () async {
    var ensureCalled = false;
    final service = AcademicOaSessionPrewarmService(
      ensureSession:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            ensureCalled = true;
            return _successResult();
          },
    );

    final missingAllResult = await service.prewarm();
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
    );
    final missingPasswordResult = await service.prewarm();

    expect(missingAllResult, isNull);
    expect(missingPasswordResult, isNull);
    expect(ensureCalled, isFalse);
  });

  test('已保存 OA 凭据时触发会话确保并透传策略', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final calls = <Map<String, bool>>[];
    final service = AcademicOaSessionPrewarmService(
      ensureSession:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            calls.add({
              'forceRefresh': forceRefresh,
              'requireCampusNetwork': requireCampusNetwork,
            });
            return _successResult();
          },
    );

    final result = await service.prewarm(
      forceRefresh: true,
      requireCampusNetwork: false,
    );

    expect(result?.isSuccess, isTrue);
    expect(calls, [
      {'forceRefresh': true, 'requireCampusNetwork': false},
    ]);
  });

  test('默认预热会强制刷新旧 OA 会话', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final calls = <Map<String, bool>>[];
    final service = AcademicOaSessionPrewarmService(
      ensureSession:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            calls.add({
              'forceRefresh': forceRefresh,
              'requireCampusNetwork': requireCampusNetwork,
            });
            return _successResult();
          },
    );

    await service.prewarm();

    expect(calls, [
      {'forceRefresh': true, 'requireCampusNetwork': false},
    ]);
  });

  test('会话预热异常不会影响调用方', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final service = AcademicOaSessionPrewarmService(
      ensureSession:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            throw StateError('network failed');
          },
    );

    final result = await service.prewarm();

    expect(result, isNull);
  });
}

AcademicLoginValidationResult _successResult() {
  return AcademicLoginValidationResult(
    status: AcademicLoginValidationStatus.success,
    message: 'OA 登录会话已就绪',
    detail: '测试会话',
    checkedAt: DateTime(2026, 6, 4),
    entranceUri: Uri.parse(
      'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
    ),
  );
}
