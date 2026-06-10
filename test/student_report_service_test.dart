/*
 * 学工报表服务测试 — 校验 OA 会话、校园网前置检测与第二课堂学分解析
 * @Project : SSPU-AllinOne
 * @File : student_report_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/academic_credentials.dart';
import 'package:sspu_allinone/models/academic_login_validation.dart';
import 'package:sspu_allinone/models/student_report.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/authenticated_data_cache_service.dart';
import 'package:sspu_allinone/services/campus_network_status_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/services/student_report_service.dart';

part 'student_report_service_test_support.dart';

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

  test('第二课堂学分自动刷新设置默认关闭并可持久化间隔', () async {
    final service = _buildService(
      gateway: _FakeStudentReportGateway(),
      campusReachable: true,
    );

    expect(await service.isAutoRefreshEnabled(), isFalse);
    expect(
      await service.getAutoRefreshIntervalMinutes(),
      StudentReportService.defaultAutoRefreshIntervalMinutes,
    );

    await service.setAutoRefreshEnabled(true);
    await service.setAutoRefreshIntervalMinutes(60);

    expect(await service.isAutoRefreshEnabled(), isTrue);
    expect(await service.getAutoRefreshIntervalMinutes(), 60);
  });

  test('未保存学工号时不访问学工报表入口', () async {
    final gateway = _FakeStudentReportGateway();
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchSecondClassroomCredits();

    expect(result.status, StudentReportQueryStatus.missingOaAccount);
    expect(gateway.openCount, 0);
  });

  test('校园网或 VPN 不可达时先刷新 OA 会话再停止学工报表查询', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final gateway = _FakeStudentReportGateway();
    final calls = <Map<String, bool>>[];
    final service = _buildService(
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
              _sessionSnapshot,
            );
            return _loginSuccessResult();
          },
    );

    final result = await service.fetchSecondClassroomCredits();

    expect(result.status, StudentReportQueryStatus.campusNetworkUnavailable);
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
    final gateway = _FakeStudentReportGateway();
    final service = _buildService(
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
              checkedAt: DateTime(2026, 5, 1),
              entranceUri: _oaEntranceUri,
            );
          },
    );

    final result = await service.fetchSecondClassroomCredits();

    expect(result.status, StudentReportQueryStatus.oaLoginRequired);
    expect(result.detail, contains('当前网络环境不是校园网或 VPN'));
    expect(result.detail, contains('OA 登录可在当前网络下刷新'));
    expect(gateway.openCount, 0);
  });

  test('OA 会话失效时刷新登录态后解析第二课堂学分', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    var refreshCount = 0;
    final gateway = _FakeStudentReportGateway(requireAuthFirst: true);
    final service = _buildService(
      gateway: gateway,
      campusReachable: true,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            refreshCount++;
            await AcademicCredentialsService.instance.saveOaLoginSession(
              _sessionSnapshot,
            );
            return AcademicLoginValidationResult(
              status: AcademicLoginValidationStatus.success,
              message: 'OA 登录校验通过',
              detail: '已刷新 OA 会话',
              checkedAt: DateTime(2026, 5, 1),
              entranceUri: _oaEntranceUri,
              finalUri: _oaEntranceUri,
              sessionSnapshot: _sessionSnapshot,
            );
          },
    );

    final result = await service.fetchSecondClassroomCredits();

    expect(result.status, StudentReportQueryStatus.success);
    expect(refreshCount, 1);
    expect(gateway.openCount, 2);
    expect(gateway.resetCookieHeaders.last['oa.sspu.edu.cn'], contains('OA='));
    expect(result.summary?.records.first.credit, 1.5);
    expect(result.summary?.records.first.category, '思想成长');
    expect(result.summary?.records.last.itemName, '创新训练项目');
  });

  test('登录状态校验不读取第二课堂学分明细页', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final gateway = _FakeStudentReportGateway();
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.validateLoginStatus();

    expect(result.status, StudentReportQueryStatus.success);
    expect(result.summary, isNull);
    expect(gateway.fetchCount, 0);
  });

  test('OA 门户页包含学工报表 SSO 链接时先换取业务会话', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final gateway = _FakeStudentReportGateway(entryPage: _oaPortalSnapshot);
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.validateLoginStatus();

    expect(result.status, StudentReportQueryStatus.success);
    expect(gateway.fetchedUris, hasLength(1));
    expect(gateway.fetchedUris.single.path, '/sharedc/sso/fore-login.do');
  });

  test('学工报表 SSO 返回登录页时自动刷新 OA 会话并重试', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    var refreshCount = 0;
    final gateway = _FakeStudentReportGateway(
      entryPage: _oaPortalSnapshot,
      requireAuthReportEntryFirst: true,
    );
    final service = _buildService(
      gateway: gateway,
      campusReachable: true,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            refreshCount++;
            await AcademicCredentialsService.instance.saveOaLoginSession(
              _sessionSnapshot,
            );
            return _loginSuccessResult();
          },
    );

    final result = await service.fetchSecondClassroomCredits();

    expect(result.status, StudentReportQueryStatus.success);
    expect(refreshCount, 1);
    expect(
      gateway.fetchedUris
          .where((uri) => uri.path.contains('/sharedc/sso/'))
          .length,
      2,
    );
  });

  test('学工报表 SSO 链路超时时返回网络错误状态', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final gateway = _FakeStudentReportGateway(
      entryPage: _oaPortalSnapshot,
      timeoutReportEntry: true,
    );
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.validateLoginStatus();

    expect(result.status, StudentReportQueryStatus.networkError);
    expect(result.message, '学工报表查询超时');
  });

  test('有效首页包含前端错误脚本时不误判为系统不可用', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final gateway = _FakeStudentReportGateway(entryPage: _clientErrorHome);
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.validateLoginStatus();

    expect(result.status, StudentReportQueryStatus.success);
  });

  test('从第二学堂学分查询菜单 onclick 定位明细页', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final gateway = _FakeStudentReportGateway(entryPage: _onclickHome);
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchSecondClassroomCredits();

    expect(result.status, StudentReportQueryStatus.success);
    expect(
      gateway.fetchedUris.single.path,
      '/sharedc/dc/studentxfform/index.do',
    );
    expect(result.summary?.records, hasLength(2));
  });

  test('第二课堂明细页过期时自动刷新 OA 会话后重新读取', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    var refreshCount = 0;
    final gateway = _FakeStudentReportGateway(
      entryPage: _onclickHome,
      requireAuthCreditFirst: true,
    );
    final service = _buildService(
      gateway: gateway,
      campusReachable: true,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            refreshCount++;
            await AcademicCredentialsService.instance.saveOaLoginSession(
              _sessionSnapshot,
            );
            return _loginSuccessResult();
          },
    );

    final result = await service.fetchSecondClassroomCredits();

    expect(result.status, StudentReportQueryStatus.success);
    expect(refreshCount, 1);
    expect(
      gateway.fetchedUris
          .where((uri) => uri.path.contains('/studentxfform/'))
          .length,
      2,
    );
  });

  test('解析得分列和空白类别延续的第二课堂明细', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final gateway = _FakeStudentReportGateway(
      entryPage: _onclickHome,
      creditPage: _snapshot(_scoreColumnCreditHtml),
    );
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchSecondClassroomCredits();

    expect(result.status, StudentReportQueryStatus.success);
    final records = result.summary?.records;
    expect(records, hasLength(2));
    expect(records?[0].credit, 0.5);
    expect(records?[0].semester, '2025-2026-2');
    expect(records?[0].occurredAt, '2026-03-01');
    expect(records?[1].category, '社会实践');
    expect(records?[1].itemName, '专题讲座');
    expect(records?[1].credit, 1);
  });

  test('解析无显式学期行的第二课堂成绩明细学期且不把活动类型当状态', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final gateway = _FakeStudentReportGateway(
      entryPage: _onclickHome,
      creditPage: _snapshot(_semesterDetailCreditHtml),
    );
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchSecondClassroomCredits();

    expect(result.status, StudentReportQueryStatus.success);
    final records = result.summary?.records;
    expect(records, hasLength(1));
    expect(records?.single.semester, '2024-2025-1');
    expect(records?.single.category, '活动');
    expect(records?.single.itemName, '迎新志愿服务');
    expect(records?.single.status, isNull);
    expect(records?.single.credit, 1);
  });

  test('解析规则矩阵总计和已获分数详情且忽略签到时间', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final gateway = _FakeStudentReportGateway(
      entryPage: _onclickHome,
      creditPage: _snapshot(_ruleMatrixCreditHtml),
      detailPagesByPath: {
        '/sharedc/dc/studentxfform/detail.do?rule=1': _snapshot(
          _detailCreditHtml,
        ),
        '/sharedc/dc/studentxfform/detail.do?rule=2': _snapshot(
          _detailCreditHtml,
        ),
        '/sharedc/dc/studentxfform/detail.do?rule=3': _snapshot(
          _detailCreditHtml,
        ),
      },
    );
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchSecondClassroomCredits();

    expect(result.status, StudentReportQueryStatus.success);
    expect(
      gateway.fetchedUris
          .map((uri) => uri.path)
          .where((path) => path.endsWith('/detail.do')),
      hasLength(3),
    );
    final summary = result.summary;
    expect(summary?.warning, isNull);
    expect(summary?.rules, hasLength(4));
    expect(summary?.rules[1].category, '思想成长');
    expect(summary?.rules[1].item, '理论学习');
    expect(summary?.rules.last.item, '通识讲座');
    expect(summary?.totals?.totalCredit, 5);
    expect(summary?.totals?.totalEarnedCredit, 4);
    expect(summary?.totals?.totalRequiredCredit, 4);
    expect(summary?.totals?.passStatus, '未通过');
    expect(summary?.detailRecords, hasLength(2));
    expect(summary?.detailRecords.first.name, '主题团日');
    expect(summary?.detailRecords.first.item, '主题教育');
    expect(summary?.detailRecords.first.participation, '2');
    expect(summary?.detailRecords.first.earnedCredit, 1.5);
    expect(
      summary?.detailRecords.first.toJson().toString(),
      isNot(contains('签到时间')),
    );
    expect(
      summary?.detailRecords.first.toJson().toString(),
      isNot(contains('示例签到时间A')),
    );
  });

  test('详情解析失败时返回警告并保留旧加密缓存', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    await AuthenticatedDataCacheService.saveLatest(
      collection: StorageKeys.studentReportCacheCollection,
      accountKey: '20260001',
      fetchedAt: DateTime(2026, 5, 1),
      data: _cachedSummary('旧缓存项目').toJson(),
    );
    final gateway = _FakeStudentReportGateway(
      entryPage: _onclickHome,
      creditPage: _snapshot(_ruleMatrixCreditHtml),
      detailPagesByPath: {
        '/sharedc/dc/studentxfform/detail.do?rule=1': _snapshot(
          '<html><body>不是详情表</body></html>',
        ),
        '/sharedc/dc/studentxfform/detail.do?rule=2': _snapshot(
          '<html><body>不是详情表</body></html>',
        ),
        '/sharedc/dc/studentxfform/detail.do?rule=3': _snapshot(
          '<html><body>不是详情表</body></html>',
        ),
      },
    );
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchSecondClassroomCredits();
    final cached = await service.readLatestCachedSecondClassroomCredits();

    expect(result.status, StudentReportQueryStatus.success);
    expect(result.summary?.rules, hasLength(4));
    expect(result.summary?.warning, contains('部分已获分数详情无法解析'));
    expect(cached?.summary?.records.single.itemName, '旧缓存项目');
    expect(cached?.summary?.warning, isNull);
  });

  test('第二课堂缓存写入安全存储并清理旧普通缓存集合', () async {
    await StorageService.saveData(
      StorageKeys.studentReportCacheCollection,
      'legacy_plain_cache',
      _cachedSummary('旧明文项目').toJson(),
    );

    await AuthenticatedDataCacheService.saveLatest(
      collection: StorageKeys.studentReportCacheCollection,
      accountKey: '20260001',
      fetchedAt: DateTime(2026, 5, 2),
      data: _cachedSummary('安全缓存项目').toJson(),
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
  });

  test('第二课堂查询过程中清除 OA 密码时不会重新写入学工缓存', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final gateway = _FakeStudentReportGateway(
      beforeCreditReturn: () => AcademicCredentialsService.instance.clearSecret(
        AcademicCredentialSecret.oaPassword,
      ),
    );
    final service = _buildService(
      gateway: gateway,
      campusReachable: true,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            await AcademicCredentialsService.instance.saveOaLoginSession(
              _sessionSnapshot,
            );
            return _loginSuccessResult();
          },
    );

    final result = await service.fetchSecondClassroomCredits();
    final cachedResult = await service.readLatestCachedSecondClassroomCredits();

    expect(result.status, StudentReportQueryStatus.unexpectedError);
    expect(result.summary, isNull);
    expect(cachedResult, isNull);
  });
}
