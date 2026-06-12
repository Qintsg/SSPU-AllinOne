/*
 * 教务中心页面测试 — 校验体育部课外活动考勤汇总与明细展示
 * @Project : SSPU-AllinOne
 * @File : academic_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-30
 */

import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/models/sports_attendance.dart';
import 'package:sspu_allinone/models/student_report.dart';
import 'package:sspu_allinone/pages/academic_page.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
import 'package:sspu_allinone/services/academic_term_service.dart';
import 'package:sspu_allinone/services/sports_attendance_service.dart';
import 'package:sspu_allinone/services/student_report_service.dart';

part 'academic_page_test_support.dart';

/// 等待异步卡片加载完成。
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

/// 推进页面动画和 Fluent 点击态短计时器，避免组件卸载后残留 timer。
Future<void> disposeAcademicPage(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 420));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> pumpAcademicPage(
  WidgetTester tester, {
  required AcademicEamsClient academicEamsService,
  required SportsAttendanceClient sportsAttendanceService,
  required StudentReportClient studentReportService,
  bool academicEamsAutoRefreshEnabledOverride = false,
  bool sportsAttendanceAutoRefreshEnabledOverride = false,
  int sportsAttendanceAutoRefreshIntervalOverride = 30,
  bool studentReportAutoRefreshEnabledOverride = false,
  int studentReportAutoRefreshIntervalOverride = 30,
}) async {
  await tester.pumpWidget(
    FluentApp(
      home: AcademicPage(
        academicEamsService: academicEamsService,
        sportsAttendanceService: sportsAttendanceService,
        studentReportService: studentReportService,
        academicEamsAutoRefreshEnabledOverride:
            academicEamsAutoRefreshEnabledOverride,
        sportsAttendanceAutoRefreshEnabledOverride:
            sportsAttendanceAutoRefreshEnabledOverride,
        sportsAttendanceAutoRefreshIntervalOverride:
            sportsAttendanceAutoRefreshIntervalOverride,
        studentReportAutoRefreshEnabledOverride:
            studentReportAutoRefreshEnabledOverride,
        studentReportAutoRefreshIntervalOverride:
            studentReportAutoRefreshIntervalOverride,
      ),
    ),
  );
}

void main() {
  testWidgets('教务中心展示体育部考勤总次数并可进入明细页', (tester) async {
    final sportsService = _FakeSportsAttendanceClient(result: _successResult);
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: sportsService,
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    expect(find.textContaining('自动刷新未开启'), findsWidgets);
    final sportsRefresh = find.byKey(const Key('academic-sports-refresh'));
    await tester.ensureVisible(sportsRefresh);
    await tester.tap(sportsRefresh);
    await pumpUntilFound(tester, find.text('8'));

    expect(find.text('课外活动考勤'), findsOneWidget);
    expect(find.text('总次数'), findsOneWidget);
    expect(find.text('早操 2 次'), findsOneWidget);
    expect(find.text('课外活动 3 次'), findsOneWidget);
    expect(find.text('次数调整 -1 次'), findsOneWidget);
    expect(find.text('体育长廊 4 次'), findsOneWidget);
    expect(find.text('上次刷新：2026-04-30 00:00'), findsOneWidget);
    expect(sportsService.requireCampusNetworkValues, [false]);

    await tester.ensureVisible(find.text('查看考勤记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看考勤记录'));
    await tester.pumpAndSettle();

    expect(find.text('课外活动考勤记录'), findsOneWidget);
    expect(find.textContaining('明细 2 条'), findsOneWidget);
    expect(find.textContaining('2026-04-01'), findsWidgets);
    expect(find.textContaining('体育长廊'), findsWidgets);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心展示体育部登录失败状态', (tester) async {
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: SportsAttendanceQueryResult(
          status: SportsAttendanceQueryStatus.missingSportsPassword,
          message: '请先保存体育部查询密码',
          detail: '体育部查询系统密码与 OA 密码不同，需单独配置。',
          checkedAt: DateTime(2026, 4, 30),
          entranceUri: Uri.parse('https://tygl.sspu.edu.cn/sportscore/'),
        ),
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final sportsRefresh = find.byKey(const Key('academic-sports-refresh'));
    await tester.ensureVisible(sportsRefresh);
    await tester.tap(sportsRefresh);
    await pumpUntilFound(tester, find.text('请先保存体育部查询密码'));

    expect(find.text('请先保存体育部查询密码'), findsOneWidget);
    expect(find.textContaining('OA 密码不同'), findsOneWidget);
    expect(find.text('刷新失败:未设置体育密码×'), findsOneWidget);
    expect(find.text('上次刷新：2026-04-30 00:00'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心自动刷新开启时会主动读取体育考勤', (tester) async {
    final sportsService = _FakeSportsAttendanceClient(result: _successResult);
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: sportsService,
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      sportsAttendanceAutoRefreshEnabledOverride: true,
      sportsAttendanceAutoRefreshIntervalOverride: 1,
    );

    await pumpUntilFound(tester, find.text('8'));

    expect(find.text('总次数'), findsOneWidget);
    expect(sportsService.fetchCount, 1);
    expect(sportsService.requireCampusNetworkValues, [true]);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    expect(sportsService.fetchCount, 2);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心展示校园网或 VPN 不可用状态', (tester) async {
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: SportsAttendanceQueryResult(
          status: SportsAttendanceQueryStatus.campusNetworkUnavailable,
          message: '校园网 / VPN 不可用，无法访问体育部查询系统',
          detail: '无法访问 tygl.sspu.edu.cn',
          checkedAt: DateTime(2026, 4, 30),
          entranceUri: Uri.parse('https://tygl.sspu.edu.cn/sportscore/'),
        ),
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final sportsRefresh = find.byKey(const Key('academic-sports-refresh'));
    await tester.ensureVisible(sportsRefresh);
    await tester.tap(sportsRefresh);
    await pumpUntilFound(tester, find.textContaining('校园网 / VPN 不可用'));

    expect(find.textContaining('无法访问体育部查询系统'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心展示第二课堂学分并可进入明细页', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final studentReportRefresh = find.byKey(
      const Key('academic-student-report-refresh'),
    );
    await tester.ensureVisible(studentReportRefresh);
    await tester.tap(studentReportRefresh);
    await pumpUntilFound(tester, find.text('总已获分数'));

    expect(find.text('刷新成功√'), findsOneWidget);
    expect(find.text('第二课堂学分'), findsOneWidget);
    expect(find.text('总已获分数'), findsOneWidget);
    expect(find.text('总必修积分'), findsOneWidget);
    expect(find.text('总体通过情况'), findsOneWidget);
    expect(find.text('详情记录'), findsOneWidget);
    expect(find.text('10.55'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('未通过'), findsOneWidget);
    expect(find.text('5 项'), findsOneWidget);
    expect(find.text('社会实践'), findsWidgets);
    expect(find.text('报告与讲座'), findsWidgets);
    expect(find.text('校园文化活动'), findsWidgets);
    expect(find.text('创新创业活动'), findsWidgets);
    expect(find.text('4.65/2.00'), findsWidgets);
    expect(find.text('1.50/2.00'), findsWidgets);
    expect(find.text('1.00/2.00'), findsWidgets);
    expect(find.text('2.00/0.00'), findsWidgets);
    expect(find.text('上次刷新：2026-05-01 00:00'), findsOneWidget);
    expect(find.textContaining('数据来自学工报表系统'), findsNothing);
    final titleCenter = tester.getCenter(find.text('第二课堂学分'));
    final lastRefreshCenter = tester.getCenter(
      find.text('上次刷新：2026-05-01 00:00'),
    );
    final refreshCenter = tester.getCenter(studentReportRefresh);
    final lastRefreshRight = tester
        .getTopRight(find.text('上次刷新：2026-05-01 00:00'))
        .dx;
    final refreshLeft = tester.getTopLeft(studentReportRefresh).dx;
    expect(lastRefreshCenter.dy, greaterThan(titleCenter.dy));
    expect((refreshCenter.dy - lastRefreshCenter.dy).abs(), lessThan(1));
    expect(refreshLeft - lastRefreshRight, greaterThanOrEqualTo(0));
    expect(refreshLeft - lastRefreshRight, lessThan(16));

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('刷新成功√'), findsNothing);

    final detailButton = find.byKey(
      const Key('academic-student-report-detail'),
    );
    await tester.ensureVisible(detailButton);
    await tester.pumpAndSettle();
    await tester.tap(detailButton);
    await tester.pumpAndSettle();

    expect(find.text('第二课堂详情'), findsOneWidget);
    expect(find.text('总计'), findsOneWidget);
    expect(find.text('总积分'), findsNothing);
    expect(find.text('总已获分数'), findsOneWidget);
    expect(find.text('已获积分详情'), findsOneWidget);
    expect(find.text('规则矩阵'), findsOneWidget);
    expect(find.byIcon(FluentIcons.chevronDown), findsOneWidget);
    expect(find.text('名称'), findsOneWidget);
    expect(find.text('获得积分'), findsOneWidget);
    expect(find.textContaining('志愿服务'), findsWidgets);
    expect(find.textContaining('创新训练项目'), findsWidgets);

    await tester.tap(
      find.byKey(const Key('academic-student-report-detail-collapse')),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(FluentIcons.chevronRight), findsOneWidget);
    expect(find.textContaining('创新训练项目'), findsNothing);

    await tester.tap(
      find.byKey(const Key('academic-student-report-detail-collapse')),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(FluentIcons.chevronDown), findsOneWidget);
    expect(find.textContaining('创新训练项目'), findsWidgets);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心自动刷新开启时会主动读取第二课堂学分', (tester) async {
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      studentReportAutoRefreshEnabledOverride: true,
    );

    await pumpUntilFound(tester, find.text('总已获分数'));

    expect(find.text('详情记录'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('第二课堂手动刷新失败时显示预置短原因', (tester) async {
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(
        result: StudentReportQueryResult(
          status: StudentReportQueryStatus.campusNetworkUnavailable,
          message: '校园网 / VPN 不可用，无法访问学工报表系统',
          detail: '无法访问 xgbb.sspu.edu.cn',
          checkedAt: DateTime(2026, 5, 1),
          entranceUri: Uri.parse(
            'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=xgreport',
          ),
        ),
      ),
    );

    final studentReportRefresh = find.byKey(
      const Key('academic-student-report-refresh'),
    );
    await tester.ensureVisible(studentReportRefresh);
    await tester.tap(studentReportRefresh);
    await pumpUntilFound(tester, find.text('刷新失败:校园网/VPN不可用×'));

    expect(find.textContaining('无法访问学工报表系统'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('刷新失败:校园网/VPN不可用×'), findsNothing);
    await disposeAcademicPage(tester);
  });

  testWidgets('第二课堂卡片和详情页在移动端宽度下不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final studentReportRefresh = find.byKey(
      const Key('academic-student-report-refresh'),
    );
    await tester.ensureVisible(studentReportRefresh);
    await tester.tap(studentReportRefresh);
    await pumpUntilFound(tester, find.text('社会实践'));

    expect(find.text('4.65/2.00'), findsOneWidget);
    expect(find.text('1.50/2.00'), findsOneWidget);
    expect(find.text('1.00/2.00'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final detailButton = find.byKey(
      const Key('academic-student-report-detail'),
    );
    await tester.ensureVisible(detailButton);
    await tester.tap(detailButton);
    await tester.pumpAndSettle();

    expect(find.text('已获积分详情'), findsOneWidget);
    expect(find.text('规则矩阵'), findsOneWidget);
    expect(find.byType(Table), findsNothing);
    expect(find.text('必修'), findsWidgets);
    expect(find.text('通过'), findsWidgets);
    expect(find.text('参与情况'), findsWidgets);
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('第二课堂摘要中等宽度下固定为二乘二布局', (tester) async {
    await tester.binding.setSurfaceSize(const Size(760, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final studentReportRefresh = find.byKey(
      const Key('academic-student-report-refresh'),
    );
    await tester.ensureVisible(studentReportRefresh);
    await tester.tap(studentReportRefresh);
    await pumpUntilFound(tester, find.text('创新创业活动'));

    final socialTop = tester.getTopLeft(find.text('社会实践')).dy;
    final reportTop = tester.getTopLeft(find.text('报告与讲座')).dy;
    final cultureTop = tester.getTopLeft(find.text('校园文化活动')).dy;
    final innovationTop = tester.getTopLeft(find.text('创新创业活动')).dy;

    expect((socialTop - reportTop).abs(), lessThan(1));
    expect((cultureTop - innovationTop).abs(), lessThan(1));
    expect(cultureTop, greaterThan(socialTop));
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心宽屏下体育与第二课堂卡片行内等高', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      sportsAttendanceAutoRefreshEnabledOverride: true,
      studentReportAutoRefreshEnabledOverride: true,
    );

    await pumpUntilFound(tester, find.text('总已获分数'));

    final sportsCard = find.byKey(const Key('academic-sports-card'));
    final studentReportCard = find.byKey(
      const Key('academic-student-report-card'),
    );
    final sportsSize = tester.getSize(sportsCard);
    final studentReportSize = tester.getSize(studentReportCard);
    expect((sportsSize.height - studentReportSize.height).abs(), lessThan(1));
    expect(
      tester.getBottomLeft(sportsCard).dy,
      tester.getBottomLeft(studentReportCard).dy,
    );
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心中屏下体育与第二课堂卡片行内等高', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      sportsAttendanceAutoRefreshEnabledOverride: true,
      studentReportAutoRefreshEnabledOverride: true,
    );

    await pumpUntilFound(tester, find.text('总已获分数'));

    final sportsCard = find.byKey(const Key('academic-sports-card'));
    final studentReportCard = find.byKey(
      const Key('academic-student-report-card'),
    );
    final sportsSize = tester.getSize(sportsCard);
    final studentReportSize = tester.getSize(studentReportCard);
    expect((sportsSize.height - studentReportSize.height).abs(), lessThan(1));
    expect(
      tester.getBottomLeft(sportsCard).dy,
      tester.getBottomLeft(studentReportCard).dy,
    );
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心窄屏下单列卡片不强制等高且无溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      sportsAttendanceAutoRefreshEnabledOverride: true,
      studentReportAutoRefreshEnabledOverride: true,
    );

    await pumpUntilFound(tester, find.text('总已获分数'));

    final sportsCard = find.byKey(const Key('academic-sports-card'));
    final studentReportCard = find.byKey(
      const Key('academic-student-report-card'),
    );
    expect(
      tester.getTopLeft(studentReportCard).dy,
      greaterThan(tester.getBottomLeft(sportsCard).dy),
    );
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心展示本专科教务摘要并可进入课程表页', (tester) async {
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    await tester.tap(find.byKey(const Key('academic-eams-refresh')));
    await pumpUntilFound(tester, find.textContaining('姓名：张三'));

    expect(find.text('本专科教务'), findsOneWidget);
    expect(find.textContaining('课表 1门'), findsOneWidget);
    expect(find.textContaining('开课检索：入口已识别'), findsOneWidget);

    final openCourseSchedule = find.byKey(const Key('open-course-schedule'));
    await tester.ensureVisible(openCourseSchedule);
    await tester.tap(openCourseSchedule);
    await tester.pumpAndSettle();

    expect(find.text('课程表'), findsOneWidget);
    expect(find.text('高等数学'), findsOneWidget);
    expect(find.textContaining('周一 第1-2节'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('本专科教务考试卡片预览并在详情页切换学期', (tester) async {
    final academicService = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      examResultResolver: (term, _) => _academicExamResultForSeason(
        term?.season ?? AcademicTermSeason.spring,
      ),
    );
    await pumpAcademicPage(
      tester,
      academicEamsService: academicService,
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final refresh = find.byKey(const Key('academic-eams-refresh'));
    await tester.ensureVisible(refresh);
    await tester.tap(refresh);
    await pumpUntilFound(tester, find.text('大学生心理健康教育'));

    expect(find.byKey(const Key('academic-eams-exam-card')), findsOneWidget);
    final primaryCard = find.byType(AcademicEamsSummaryCard);
    final examCard = find.byKey(const Key('academic-eams-exam-card'));
    expect(
      find.descendant(of: primaryCard, matching: examCard),
      findsOneWidget,
    );
    expect(find.text('大学生心理健康教育'), findsOneWidget);
    expect(find.text('高等数学D2'), findsNothing);
    expect(find.text('通用学术英语B'), findsNothing);
    expect(find.textContaining('考试情况尚未发布'), findsNothing);
    expect(find.textContaining('暂无信息'), findsNothing);
    expect(find.textContaining('2026-06-17'), findsOneWidget);
    expect(find.textContaining('4201'), findsOneWidget);
    expect(find.textContaining('考试 3场'), findsOneWidget);
    expect(find.textContaining('还有 2 门考试信息'), findsOneWidget);
    expect(
      find.byKey(const Key('academic-eams-exam-year-select')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('academic-eams-exam-season-select')),
      findsNothing,
    );
    expect(find.textContaining('教务学期'), findsNothing);
    expect(find.textContaining('semester.id'), findsNothing);
    expect(academicService.overviewFetchCount, 1);
    expect(academicService.examFetchCount, 1);

    final detailButton = find.byKey(const Key('academic-eams-exam-detail'));
    await tester.ensureVisible(detailButton);
    await tester.tap(detailButton);
    await tester.pumpAndSettle();

    expect(find.text('考试安排详情'), findsOneWidget);
    expect(
      find.byKey(const Key('academic-eams-exam-year-select')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('academic-eams-exam-season-select')),
      findsOneWidget,
    );
    expect(find.text('2025-2026 学年'), findsOneWidget);
    expect(find.text('春季学期'), findsOneWidget);
    await tester.tap(find.byKey(const Key('academic-eams-exam-season-select')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('academic-eams-exam-season-option-fall')),
      findsWidgets,
    );
    expect(
      find.byKey(const Key('academic-eams-exam-season-option-spring')),
      findsWidgets,
    );
    expect(
      find.byKey(const Key('academic-eams-exam-season-option-summer')),
      findsWidgets,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    for (final header in [
      '考试类型',
      '课程序号',
      '课程名称',
      '考试日期',
      '考试安排',
      '考试地点',
      '考试情况',
      '其它说明',
    ]) {
      expect(
        find.text(header),
        // “考试类型”同时出现在筛选下拉与表头，“考试安排”出现在表头与字段。
        (header == '考试安排' || header == '考试类型')
            ? findsWidgets
            : findsOneWidget,
      );
    }
    expect(find.text('高等数学D2'), findsOneWidget);
    expect(find.text('大学生心理健康教育'), findsOneWidget);
    expect(find.text('通用学术英语B'), findsOneWidget);
    expect(find.textContaining('考试情况尚未发布'), findsNothing);
    expect(find.textContaining('暂无信息'), findsNothing);
    expect(find.text('第17周期末考试'), findsWidgets);
    expect(
      find.descendant(of: find.byType(Table), matching: find.text('-')),
      findsWidgets,
    );

    await tester.tap(find.byKey(const Key('academic-eams-exam-season-select')));
    await tester.pumpAndSettle();
    final fallOption = find
        .byKey(const Key('academic-eams-exam-season-option-fall'))
        .last;
    await tester.tapAt(tester.getCenter(fallOption));
    await tester.pumpAndSettle();

    expect(academicService.examFetchCount, 1);
    expect(find.text('大学生心理健康教育'), findsOneWidget);
    expect(find.text('程序设计基础'), findsNothing);

    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await pumpUntilFound(tester, find.text('程序设计基础'));

    expect(
      academicService.examTermValues.last?.season,
      AcademicTermSeason.fall,
    );
    // 下拉解析出的真实 semester.id 会随查询传入，便于学期接口失败时复用。
    expect(academicService.examSemesterValues.last?.id, '1041');
    expect(find.textContaining('有考试信息的课程 2 门'), findsOneWidget);

    await tester.tap(find.byKey(const Key('academic-eams-exam-season-select')));
    await tester.pumpAndSettle();
    final summerOption = find
        .byKey(const Key('academic-eams-exam-season-option-summer'))
        .last;
    await tester.tapAt(tester.getCenter(summerOption));
    await tester.pumpAndSettle();
    expect(academicService.examFetchCount, 2);
    expect(find.text('程序设计基础'), findsOneWidget);

    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await pumpUntilFound(tester, find.text('当前学期暂无可展示的考试信息。'));
    expect(
      academicService.examTermValues.last?.season,
      AcademicTermSeason.summer,
    );
    expect(academicService.examSemesterValues.last, isNull);

    await tester.tap(find.byKey(const Key('academic-eams-exam-season-select')));
    await tester.pumpAndSettle();
    final springOption = find
        .byKey(const Key('academic-eams-exam-season-option-spring'))
        .last;
    await tester.tapAt(tester.getCenter(springOption));
    await tester.pumpAndSettle();
    expect(academicService.examFetchCount, 3);
    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await pumpUntilFound(tester, find.text('大学生心理健康教育'));
    expect(
      academicService.examTermValues.last?.season,
      AcademicTermSeason.spring,
    );
    expect(academicService.examSemesterValues.last, isNull);

    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();
    expect(find.text('大学生心理健康教育'), findsOneWidget);
    expect(find.textContaining('考试 3场'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  test('考试缓存学期与目标学期一致时才作为可展示缓存', () {
    const springTerm = AcademicTermChoice(
      academicYear: 2025,
      season: AcademicTermSeason.spring,
    );
    const fallTerm = AcademicTermChoice(
      academicYear: 2025,
      season: AcademicTermSeason.fall,
    );

    // _academicExamResult 的缓存学期是 2025-2026 春季。
    expect(
      displayableExamCacheForTerm(_academicExamResult, springTerm),
      same(_academicExamResult),
    );
    // 学期不一致（春季缓存 vs 秋季默认）时不展示该缓存，避免标题与记录错位。
    expect(displayableExamCacheForTerm(_academicExamResult, fallTerm), isNull);
    // 明显过期的缓存（2020 秋）对任何近期学期都不展示。
    expect(displayableExamCacheForTerm(_staleExamCacheResult, springTerm), isNull);
    // 缺省入参时安全返回 null。
    expect(displayableExamCacheForTerm(null, springTerm), isNull);
    expect(displayableExamCacheForTerm(_academicExamResult, null), isNull);
  });

  testWidgets('考试详情页缺少初始学期时填入全局默认学期', (tester) async {
    final academicService = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      examResultResolver: (term, _) =>
          _academicExamResultForSeason(term?.season ?? AcademicTermSeason.fall),
    );
    await tester.pumpWidget(
      FluentApp(
        home: AcademicEamsExamDetailPage(
          academicEamsService: academicService,
          initialResult: null,
          initialSelectedTerm: null,
          initialSelectedSemester: null,
          onResultChanged: (_, _, _) {},
        ),
      ),
    );
    await pumpUntilFound(tester, find.textContaining('2025-2026 学年'));

    expect(
      find.byKey(const Key('academic-eams-exam-detail-refresh')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await pumpUntilFound(tester, find.text('程序设计基础'));

    expect(academicService.examTermValues.last, isNotNull);
    expect(
      academicService.examTermValues.last,
      AcademicTermService.defaultTerm,
    );
    await disposeAcademicPage(tester);
  });
}
