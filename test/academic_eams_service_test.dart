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
import 'package:sspu_allinone/models/academic_term.dart';
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
    expect(result.snapshot?.profile?.studentId, '20260001');
    expect(result.snapshot?.profile?.department, '计算机与信息工程学院');
    expect(result.snapshot?.profile?.major, '软件工程');
    expect(result.snapshot?.profile?.className, '软件 241');
    expect(result.snapshot?.profile?.gender, '男');
    expect(result.snapshot?.profile?.studyLength, '4 年');
    expect(result.snapshot?.profile?.educationLevel, '本科');
    expect(result.snapshot?.courseTable?.entries.length, 1);
    expect(result.snapshot?.grades?.historyRecords.length, 1);
    expect(result.snapshot?.programCompletion?.completedCredits, 7);
    final overviewExamRecords = result.snapshot?.exams?.records ?? const [];
    final overviewMathExam = overviewExamRecords.firstWhere(
      (record) => record.courseName == '高等数学',
    );
    expect(overviewMathExam.examLocation, '综合楼 A201');
    expect(result.snapshot?.hasCourseOfferingEntry, isTrue);
    expect(result.snapshot?.hasFreeClassroomEntry, isTrue);
  });

  test('考试安排按全局学期映射 EAMS semester.id 并保留无日期但有说明的记录', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway(includeUndatedExamRows: true);
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final result = await service.fetchExamSchedule(
      term: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.spring,
      ),
    );

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(result.snapshot?.exams?.selectedSemester?.id, '1042');
    // 默认查询期末考试（examType.id=1），并保留可切换的考试类型选项。
    expect(result.snapshot?.exams?.selectedExamType, '1');
    expect(result.snapshot?.exams?.examTypeOptions, isNotEmpty);
    final records = result.snapshot?.exams?.records ?? const [];
    expect(records.map((record) => record.courseName), [
      '高等数学D2',
      '大学生心理健康教育',
      '通用学术英语B',
    ]);
    // 未发布考试日期但带说明的行应保留。
    final undatedRecord = records.firstWhere(
      (record) => record.courseName == '高等数学D2',
    );
    expect(undatedRecord.examType, '期末考试');
    expect(undatedRecord.courseSequence, '2291');
    expect(undatedRecord.hasScheduledExamDate, isFalse);
    expect(undatedRecord.displayExamDate, isEmpty);
    expect(undatedRecord.otherExplanation, '第17周期末考试');
    final psychologyRecord = records.firstWhere(
      (record) => record.courseName == '大学生心理健康教育',
    );
    expect(psychologyRecord.examType, '期末考试');
    expect(psychologyRecord.examDate, '2026-06-17');
    expect(psychologyRecord.examLocation, '4201');
    expect(psychologyRecord.hasScheduledExamDate, isTrue);
    expect(
      gateway.requestedPageUris.any(
        (uri) =>
            uri.path.contains('stdExamTable!examTable.action') &&
            uri.queryParameters['semester.id'] == '1042' &&
            uri.queryParameters['examType.id'] == '1',
      ),
      isTrue,
    );
    expect(gateway.lastSubmittedFields?['dataType'], 'semesterCalendar');
  });

  test('考试安排支持使用下拉选中的其它学期重新查询', () async {
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

    final result = await service.fetchExamSchedule(
      semester: AcademicEamsSemesterOption.fromEamsFields(
        id: '1041',
        schoolYear: '2025-2026',
        termCode: '1',
      ),
    );

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(result.snapshot?.exams?.selectedSemester?.id, '1041');
    expect(result.snapshot?.exams?.records.single.courseName, '程序设计基础');
    expect(
      gateway.requestedPageUris.any(
        (uri) =>
            uri.path.contains('stdExamTable!examTable.action') &&
            uri.queryParameters['semester.id'] == '1041',
      ),
      isTrue,
    );
  });

  test('考试安排在网站仅返回部分学期时按目标学期推断查询 id', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway(springOnlySemesterCalendar: true);
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final result = await service.fetchExamSchedule(
      term: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.fall,
      ),
    );

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(result.snapshot?.exams?.selectedSemester?.id, '1041');
    expect(result.snapshot?.exams?.records.single.courseName, '程序设计基础');
    expect(
      gateway.requestedPageUris.any(
        (uri) =>
            uri.path.contains('stdExamTable!examTable.action') &&
            uri.queryParameters['semester.id'] == '1041',
      ),
      isTrue,
    );
  });

  test('考试安排识别网站返回的中文学期名称并使用真实 semester.id', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway(chineseNamedSemesterCalendar: true);
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final result = await service.fetchExamSchedule(
      term: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.spring,
      ),
    );

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(result.snapshot?.exams?.selectedSemester?.id, '1042');
    expect(
      result.snapshot?.exams?.selectedSemester?.termChoice?.season,
      AcademicTermSeason.spring,
    );
    expect(
      result.snapshot?.exams?.records.map((record) => record.courseName),
      contains('高等数学'),
    );
    expect(
      gateway.requestedPageUris.any(
        (uri) =>
            uri.path.contains('stdExamTable!examTable.action') &&
            uri.queryParameters['semester.id'] == '1042',
      ),
      isTrue,
    );
    expect(
      gateway.requestedPageUris.any(
        (uri) =>
            uri.path.contains('stdExamTable!examTable.action') &&
            uri.queryParameters['semester.id'] == '66',
      ),
      isFalse,
    );
  });

  test('考试安排优先使用网站学期列表而不是旧缓存推断出的错误 semester.id', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway(chineseNamedSemesterCalendar: true);
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final result = await service.fetchExamSchedule(
      term: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.spring,
      ),
      semester: AcademicEamsSemesterOption.fromEamsFields(
        id: '66',
        schoolYear: '2025-2026',
        termCode: '2',
      ),
    );

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(result.snapshot?.exams?.selectedSemester?.id, '1042');
    expect(
      result.snapshot?.exams?.records.map((record) => record.courseName),
      contains('高等数学'),
    );
    expect(
      gateway.requestedPageUris.any(
        (uri) =>
            uri.path.contains('stdExamTable!examTable.action') &&
            uri.queryParameters['semester.id'] == '1042',
      ),
      isTrue,
    );
    expect(
      gateway.requestedPageUris.any(
        (uri) =>
            uri.path.contains('stdExamTable!examTable.action') &&
            uri.queryParameters['semester.id'] == '66',
      ),
      isFalse,
    );
  });

  test('考试安排忽略与目标学期不一致的旧 semester.id', () async {
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

    final result = await service.fetchExamSchedule(
      term: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.fall,
      ),
      semester: AcademicEamsSemesterOption.fromEamsFields(
        id: '1042',
        schoolYear: '2025-2026',
        termCode: '2',
      ),
    );

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(result.snapshot?.exams?.selectedSemester?.id, '1041');
    expect(result.snapshot?.exams?.records.single.courseName, '程序设计基础');
    expect(
      gateway.requestedPageUris.any(
        (uri) =>
            uri.path.contains('stdExamTable!examTable.action') &&
            uri.queryParameters['semester.id'] == '1041',
      ),
      isTrue,
    );
  });

  test('考试安排过滤仅有占位详情的课程行', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway(placeholderOnlyExamRow: true);
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final result = await service.fetchExamSchedule(
      term: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.spring,
      ),
      examTypeId: '5',
    );

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(result.snapshot?.exams?.selectedExamType, '5');
    final records = result.snapshot?.exams?.records ?? const [];
    // 仅含 "-"/占位信息（含备注）的考试不展示。
    expect(records.any((record) => record.courseName == '只含占位信息课程'), isFalse);
    expect(records, isEmpty);
  });

  test('考试安排解析保留跨列未发布行并对齐其它说明列', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway(includeUndatedExamRows: true);
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final result = await service.fetchExamSchedule(
      term: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.spring,
      ),
    );

    expect(result.status, AcademicEamsQueryStatus.success);
    final records = result.snapshot?.exams?.records ?? const [];
    expect(
      records.map((record) => record.courseName),
      containsAll(['高等数学D2', '大学生心理健康教育', '通用学术英语B']),
    );
    final mathRecord = records.firstWhere(
      (record) => record.courseName == '高等数学D2',
    );
    expect(mathRecord.displayExamDate, isEmpty);
    expect(mathRecord.displayExamArrange, isEmpty);
    expect(mathRecord.displayExamLocation, isEmpty);
    expect(mathRecord.displayExamSituation, isEmpty);
    expect(mathRecord.otherExplanation, '第17周期末考试');
    expect(mathRecord.displayOtherExplanation, '第17周期末考试');
    final psychologyRecord = records.firstWhere(
      (record) => record.courseName == '大学生心理健康教育',
    );
    expect(psychologyRecord.displayExamDate, '2026-06-17');
    expect(psychologyRecord.displayExamArrange, '第16周 星期三 13:00-14:30');
    final englishRecord = records.firstWhere(
      (record) => record.courseName == '通用学术英语B',
    );
    expect(englishRecord.displayExamDate, isEmpty);
    expect(englishRecord.displayExamArrange, isEmpty);
    expect(englishRecord.displayOtherExplanation, '第17周期末考试');
  });

  test('考试安排在学期列表接口失败时使用壳页默认学期兜底', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway(failSemesterCalendar: true);
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final result = await service.fetchExamSchedule(
      term: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.spring,
      ),
    );

    expect(result.status, AcademicEamsQueryStatus.partialSuccess);
    expect(result.snapshot?.exams?.selectedSemester?.id, '1042');
    expect(
      result.snapshot?.exams?.records.map((record) => record.courseName),
      contains('高等数学'),
    );
    expect(result.snapshot?.warnings.join('；'), contains('考试学期列表读取超时'));
    expect(
      gateway.requestedPageUris.any(
        (uri) =>
            uri.path.contains('stdExamTable!examTable.action') &&
            uri.queryParameters['semester.id'] == '1042',
      ),
      isTrue,
    );
  });

  test('考试安排短课程表头不会误把课程序号当课程名称', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway(useShortExamCourseHeader: true);
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final result = await service.fetchExamSchedule(
      term: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.spring,
      ),
    );

    expect(result.status, AcademicEamsQueryStatus.success);
    final records = result.snapshot?.exams?.records ?? const [];
    final mathRecord = records.firstWhere(
      (record) => record.courseName == '高等数学',
    );
    expect(mathRecord.courseSequence, 'MATH101');
  });

  test('从空根菜单发现真实学籍个人信息入口', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final gateway = FakeAcademicEamsGateway(
      disableNumberedStudentProfileMenu: true,
    );
    final service = buildAcademicEamsServiceForTest(
      gateway: gateway,
      campusReachable: true,
    );

    final result = await service.fetchOverview();

    expect(result.status, AcademicEamsQueryStatus.success);
    expect(result.snapshot?.profile?.studentId, '20260001');
    expect(result.snapshot?.profile?.name, '张三');
    expect(
      gateway.requestedPageUris,
      contains(
        predicate<Uri>(
          (uri) =>
              uri.path.contains('home!submenus.action') &&
              (uri.queryParameters['menu.id'] ?? '').isEmpty,
        ),
      ),
    );
    expect(
      gateway.requestedPageUris.any(
        (uri) => uri.path.contains('studentDetail.action'),
      ),
      isTrue,
    );
  });

  test('本专科教务缓存不持久化明文学籍字段并从安全存储恢复学籍', () async {
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
    final storedProfile = storedPayload['profile'];
    final cachedResult = await service.readLatestCachedOverview();
    final secureProfile = await AcademicCredentialsService.instance
        .readStudentProfile();

    expect(storedPayload.toString(), isNot(contains('20260001')));
    expect(storedPayload.toString(), isNot(contains('张三')));
    expect(storedPayload.toString(), isNot(contains('软件 241')));
    expect(storedPayload.toString(), isNot(contains('学号')));
    expect(storedProfile.toString(), isNot(contains('计算机与信息工程学院')));
    expect(storedProfile.toString(), isNot(contains('软件工程')));
    expect(secureProfile?.studentId, '20260001');
    expect(secureProfile?.gender, '男');
    expect(secureProfile?.studyLength, '4 年');
    expect(secureProfile?.educationLevel, '本科');
    expect(cachedResult?.snapshot?.profile?.name, '张三');
    expect(cachedResult?.snapshot?.profile?.studentId, '20260001');
    expect(cachedResult?.snapshot?.profile?.rawFields, isEmpty);
  });

  test('学籍页学号与 OA 账号不一致时不保存学籍缓存', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    final service = buildAcademicEamsServiceForTest(
      gateway: FakeAcademicEamsGateway(
        studentProfileSnapshot: AcademicEamsHttpSnapshot(
          finalUri: Uri.parse('https://jx.sspu.edu.cn/eams/std.action'),
          statusCode: 200,
          body: '''
<html><body><table>
<tr><th>学号</th><th>姓名</th><th>专业</th></tr>
<tr><td>20269999</td><td>李四</td><td>软件工程</td></tr>
</table></body></html>
''',
        ),
      ),
      campusReachable: true,
    );

    final result = await service.fetchOverview();

    expect(result.status, AcademicEamsQueryStatus.unexpectedError);
    expect(result.message, '学籍信息账号不一致');
    expect(
      await AcademicCredentialsService.instance.readStudentProfile(),
      isNull,
    );
  });

  test('学籍页解析失败时保留旧加密学籍缓存', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      academicEamsSessionSnapshot,
    );
    await AcademicCredentialsService.instance.saveStudentProfile(
      const AcademicEamsProfile(
        name: '旧缓存',
        studentId: '20260001',
        department: '旧学院',
        major: '旧专业',
        className: '旧班级',
        gender: '男',
        studyLength: '4 年',
        educationLevel: '本科',
        rawFields: {},
      ),
    );
    final service = buildAcademicEamsServiceForTest(
      gateway: FakeAcademicEamsGateway(
        studentProfileSnapshot: AcademicEamsHttpSnapshot(
          finalUri: Uri.parse('https://jx.sspu.edu.cn/eams/std.action'),
          statusCode: 200,
          body: '<html><body><p>暂无可解析学籍字段</p></body></html>',
        ),
      ),
      campusReachable: true,
    );

    await service.fetchOverview();
    final cachedProfile = await AcademicCredentialsService.instance
        .readStudentProfile();

    expect(cachedProfile?.name, '旧缓存');
    expect(cachedProfile?.major, '旧专业');
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
