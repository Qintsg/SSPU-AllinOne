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
import 'package:sspu_allinone/models/sports_attendance.dart';
import 'package:sspu_allinone/models/student_report.dart';
import 'package:sspu_allinone/pages/academic_page.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
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
    await tester.tap(find.byKey(const Key('academic-sports-refresh')));
    await pumpUntilFound(tester, find.text('8'));

    expect(find.text('课外活动考勤'), findsOneWidget);
    expect(find.textContaining('体育部查询系统只读汇总'), findsNothing);
    expect(find.textContaining('展示晨跑'), findsNothing);
    expect(find.text('总次数'), findsOneWidget);
    expect(find.text('早操 2 次'), findsOneWidget);
    expect(find.text('课外活动 3 次'), findsOneWidget);
    expect(find.text('次数调整 -1 次'), findsOneWidget);
    expect(find.text('体育长廊 4 次'), findsOneWidget);
    expect(find.text('上次刷新：2026-04-30 00:00'), findsOneWidget);
    final sportsTitleCenter = tester.getCenter(find.text('课外活动考勤'));
    final sportsLastRefreshCenter = tester.getCenter(
      find.text('上次刷新：2026-04-30 00:00'),
    );
    final sportsSummaryBottom = tester.getBottomLeft(find.text('总次数')).dy;
    final sportsButtonCenter = tester.getCenter(find.text('查看考勤记录'));
    expect(sportsLastRefreshCenter.dy, greaterThan(sportsTitleCenter.dy));
    expect(sportsLastRefreshCenter.dy, greaterThan(sportsSummaryBottom));
    expect((sportsButtonCenter.dy - sportsTitleCenter.dy).abs(), lessThan(20));
    expect(sportsService.requireCampusNetworkValues, [false]);

    await tester.ensureVisible(find.text('查看考勤记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看考勤记录'));
    await tester.pumpAndSettle();

    expect(find.text('课外活动考勤记录'), findsOneWidget);
    expect(find.text('2 条'), findsOneWidget);
    expect(find.text('总次数'), findsWidgets);
    expect(find.text('晨跑次数'), findsOneWidget);
    expect(find.text('类别'), findsOneWidget);
    expect(find.text('日期/时间'), findsOneWidget);
    expect(find.text('项目'), findsOneWidget);
    expect(find.text('地点'), findsOneWidget);
    expect(find.text('次数'), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('academic-sports-refresh')));
    await pumpUntilFound(tester, find.text('请先保存体育部查询密码'));

    expect(find.text('请先保存体育部查询密码'), findsOneWidget);
    expect(find.textContaining('OA 密码不同'), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('academic-sports-refresh')));
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
    final titleLeft = tester.getTopLeft(find.text('第二课堂学分')).dx;
    final lastRefreshLeft = tester
        .getTopLeft(find.text('上次刷新：2026-05-01 00:00'))
        .dx;
    final refreshLeft = tester.getTopLeft(studentReportRefresh).dx;
    expect(lastRefreshCenter.dy, greaterThan(titleCenter.dy));
    expect((lastRefreshLeft - titleLeft).abs(), lessThan(1));
    expect((refreshCenter.dy - lastRefreshCenter.dy).abs(), lessThan(1));
    expect(refreshLeft - lastRefreshRight, greaterThanOrEqualTo(0));
    expect(refreshLeft - lastRefreshRight, lessThan(16));
    expect(
      lastRefreshCenter.dy,
      lessThan(tester.getTopLeft(find.text('总已获分数')).dy),
    );

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

  testWidgets('体育考勤详情页在移动端以横向表格展示且不溢出', (tester) async {
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

    await tester.tap(find.byKey(const Key('academic-sports-refresh')));
    await pumpUntilFound(tester, find.text('8'));

    await tester.ensureVisible(find.text('查看考勤记录'));
    await tester.tap(find.text('查看考勤记录'));
    await tester.pumpAndSettle();

    expect(find.text('汇总表'), findsOneWidget);
    expect(find.text('明细表'), findsOneWidget);
    expect(find.text('晨跑次数'), findsOneWidget);
    expect(find.byType(Table), findsWidgets);
    expect(find.text('2026-04-01 06:50'), findsOneWidget);
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
}
