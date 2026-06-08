/*
 * 本专科教务服务测试 — 校验 OA 会话、只读摘要、开课检索与空闲教室查询
 * @Project : SSPU-AllinOne
 * @File : academic_eams_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_login_validation.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

import 'academic_eams_service_test_support.dart';

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

  test('本专科教务自动刷新设置默认关闭并可持久化间隔', () async {
    final service = buildAcademicEamsServiceForTest(
      gateway: FakeAcademicEamsGateway(),
      campusReachable: true,
    );

    expect(await service.isAutoRefreshEnabled(), isFalse);
    expect(
      await service.getAutoRefreshIntervalMinutes(),
      AcademicEamsService.defaultAutoRefreshIntervalMinutes,
    );

    await service.setAutoRefreshEnabled(true);
    await service.setAutoRefreshIntervalMinutes(60);

    expect(await service.isAutoRefreshEnabled(), isTrue);
    expect(await service.getAutoRefreshIntervalMinutes(), 60);
  });

  test('未保存学工号时不访问本专科教务入口', () async {
    final gateway = FakeAcademicEamsGateway();
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final result = await service.fetchOverview();

    expect(result.status, AcademicEamsQueryStatus.missingOaAccount);
    expect(gateway.openCount, 0);
  });

  test('校园网或 VPN 不可达时先刷新 OA 会话再停止本专科教务查询', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final gateway = FakeAcademicEamsGateway();
    final calls = <Map<String, bool>>[];
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: false,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            calls.add({
              'forceRefresh': forceRefresh,
              'requireCampusNetwork': requireCampusNetwork,
            });
            await AcademicCredentialsService.instance.saveOaLoginSession(
              academicEamsSessionSnapshot,
            );
            return AcademicLoginValidationResult(
              status: AcademicLoginValidationStatus.success,
              message: 'OA 登录校验通过',
              detail: '已刷新 OA 会话',
              checkedAt: DateTime(2026, 5, 2),
              entranceUri: academicEamsOaEntranceUri,
              finalUri: academicEamsOaEntranceUri,
              sessionSnapshot: academicEamsSessionSnapshot,
            );
          },
    );

    final result = await service.fetchOverview();

    expect(result.status, AcademicEamsQueryStatus.campusNetworkUnavailable);
    expect(result.detail, contains('OA 登录会话已刷新'));
    expect(gateway.openCount, 0);
    expect(calls, [
      {'forceRefresh': true, 'requireCampusNetwork': false},
    ]);
  });

  test('校园网或 VPN 不可达且 OA 刷新失败时提示网络环境', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final gateway = FakeAcademicEamsGateway();
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: false,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            return AcademicLoginValidationResult(
              status: AcademicLoginValidationStatus.networkError,
              message: 'OA 登录网络失败',
              detail: '无法连接 OA 登录页',
              checkedAt: DateTime(2026, 5, 2),
              entranceUri: academicEamsOaEntranceUri,
            );
          },
    );

    final result = await service.fetchOverview();

    expect(result.status, AcademicEamsQueryStatus.oaLoginRequired);
    expect(result.detail, contains('当前网络环境不是校园网或 VPN'));
    expect(result.detail, contains('OA 登录可在当前网络下刷新'));
    expect(gateway.openCount, 0);
  });

  test('OA 会话失效时刷新登录态后解析教务摘要与课表', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    var refreshCount = 0;
    final gateway = FakeAcademicEamsGateway(requireAuthFirst: true);
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            refreshCount++;
            await AcademicCredentialsService.instance.saveOaLoginSession(
              academicEamsSessionSnapshot,
            );
            return AcademicLoginValidationResult(
              status: AcademicLoginValidationStatus.success,
              message: 'OA 登录校验通过',
              detail: '已刷新 OA 会话',
              checkedAt: DateTime(2026, 5, 2),
              entranceUri: academicEamsOaEntranceUri,
              finalUri: academicEamsOaEntranceUri,
              sessionSnapshot: academicEamsSessionSnapshot,
            );
          },
    );

    final result = await service.fetchOverview();

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(refreshCount, 1);
    expect(gateway.openCount, 2);
    expect(gateway.resetCookieHeaders.last['oa.sspu.edu.cn'], contains('OA='));
    expect(result.snapshot?.profile?.name, '张三');
    expect(result.snapshot?.courseTable?.entries.length, 1);
    expect(result.snapshot?.grades?.historyRecords.length, 1);
    expect(result.snapshot?.programCompletion?.completedCredits, 7);
    expect(result.snapshot?.exams?.records.single.location, '综合楼 A201');
    expect(result.snapshot?.hasCourseOfferingEntry, isTrue);
    expect(result.snapshot?.hasFreeClassroomEntry, isTrue);
  });

  test('本专科教务缓存不持久化明文学号或原始个人字段', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final service = buildAcademicEamsServiceForTest(
      gateway: FakeAcademicEamsGateway(),
      campusReachable: true,
    );

    await service.fetchOverview();
    final storedPayload = (await StorageService.getAllData(
      StorageKeys.academicEamsOverviewCacheCollection,
    )).values.single;
    final cachedResult = await service.readLatestCachedOverview();

    expect(storedPayload.toString(), isNot(contains('20260001')));
    expect(storedPayload.toString(), isNot(contains('学号')));
    expect(cachedResult?.snapshot?.profile?.name, '张三');
    expect(cachedResult?.snapshot?.profile?.studentId, isNull);
    expect(cachedResult?.snapshot?.profile?.rawFields, isEmpty);
  });

  test('独立课表读取只解析当前学期课表', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final service = buildAcademicEamsServiceForTest(
      gateway: FakeAcademicEamsGateway(),
      campusReachable: true,
    );

    final result = await service.fetchCourseTable();

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(result.snapshot?.courseTable?.entries.single.courseName, '高等数学');
    expect(result.snapshot?.grades, isNull);
    expect(result.snapshot?.programPlan, isNull);
  });

  test('开课检索会提交只读查询表单并解析列表', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway();
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final result = await service.searchCourseOfferings(
      const AcademicCourseOfferingSearchCriteria(
        termName: '2025-2026-2',
        courseName: '高等数学',
        teacher: '张老师',
      ),
    );

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(gateway.lastSubmittedMethod, 'GET');
    expect(gateway.lastSubmittedFields?['semester'], '2025-2026-2');
    expect(gateway.lastSubmittedFields?['courseName'], '高等数学');
    expect(gateway.lastSubmittedFields?['teacherName'], '张老师');
    expect(result.courseOfferings?.records.single.locationText, '综合楼 A101');
  });

  test('开课检索遇到旧 OA 会话失效时强制刷新登录凭证', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final forceRefreshValues = <bool>[];
    final gateway = FakeAcademicEamsGateway(requireAuthFirst: true);
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            forceRefreshValues.add(forceRefresh);
            await AcademicCredentialsService.instance.saveOaLoginSession(
              academicEamsSessionSnapshot,
            );
            return AcademicLoginValidationResult(
              status: AcademicLoginValidationStatus.success,
              message: 'OA 登录校验通过',
              detail: '已刷新 OA 会话',
              checkedAt: DateTime(2026, 5, 2),
              entranceUri: academicEamsOaEntranceUri,
              finalUri: academicEamsOaEntranceUri,
              sessionSnapshot: academicEamsSessionSnapshot,
            );
          },
    );

    final result = await service.searchCourseOfferings(
      const AcademicCourseOfferingSearchCriteria(courseName: '高等数学'),
    );

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(forceRefreshValues, [true]);
    expect(gateway.openCount, 2);
  });

  test('未指定学期时不会把开课检索默认收窄到首个下拉选项', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway();
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    await service.searchCourseOfferings(
      const AcademicCourseOfferingSearchCriteria(courseName: '高等数学'),
    );

    expect(gateway.lastSubmittedFields?['semester'], isEmpty);
  });

  test('空闲教室查询会提交只读表单并解析结果', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway();
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final result = await service.searchFreeClassrooms(
      const AcademicFreeClassroomSearchCriteria(
        campus: '金海',
        building: '综合楼',
        dateText: '2026-05-02',
        lessonFrom: 1,
        lessonTo: 2,
      ),
    );

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(gateway.lastSubmittedFields?['campus'], '金海');
    expect(gateway.lastSubmittedFields?['building'], '综合楼');
    expect(gateway.lastSubmittedFields?['date'], '2026-05-02');
    expect(gateway.lastSubmittedFields?['startUnit'], '1');
    expect(gateway.lastSubmittedFields?['endUnit'], '2');
    expect(result.freeClassrooms?.records.single.roomName, '综合楼 A301');
  });

  test('子菜单探测的瞬时失败不会被缓存到后续查询', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway(failFreeClassroomMenuOnce: true);
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final firstResult = await service.fetchOverview();
    final secondResult = await service.fetchOverview();

    expect(firstResult.snapshot?.hasFreeClassroomEntry, isFalse);
    expect(secondResult.snapshot?.hasFreeClassroomEntry, isTrue);
  });

  test('查询过程中切换账号时不会把旧账号教务摘要写入新账号缓存', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final service = buildAcademicEamsServiceForTest(
      gateway: FakeAcademicEamsGateway(),
      campusReachable: true,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            await AcademicCredentialsService.instance.saveCredentials(
              oaAccount: '20260002',
              oaPassword: 'oa-pass',
            );
            await AcademicCredentialsService.instance.saveOaLoginSession(
              academicEamsSessionSnapshot,
            );
            return AcademicLoginValidationResult(
              status: AcademicLoginValidationStatus.success,
              message: 'OA 登录校验通过',
              detail: '已刷新 OA 会话',
              checkedAt: DateTime(2026, 5, 2),
              entranceUri: academicEamsOaEntranceUri,
              finalUri: academicEamsOaEntranceUri,
              sessionSnapshot: academicEamsSessionSnapshot,
            );
          },
    );

    final result = await service.fetchOverview();
    final cachedResult = await service.readLatestCachedOverview();

    expect(result.status, AcademicEamsQueryStatus.unexpectedError);
    expect(result.snapshot, isNull);
    expect(
      (await AcademicCredentialsService.instance.getStatus()).oaAccount,
      '20260002',
    );
    expect(cachedResult, isNull);
  });
}
