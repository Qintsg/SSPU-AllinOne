/*
 * 第二课堂积分规则页测试 — 核验响应式账本与异常字段保护。
 * @Project : SSPU-AllinOne
 * @File : student_report_rules_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/models/student_report.dart';
import 'package:sspu_allinone/pages/academic_page.dart';

import 'support/qingyuan_visual_fixtures.dart';

/// 注册第二课堂积分规则页的行为测试。
///
/// :returns: 无返回值。
void main() {
  testWidgets('窄屏先显示完成差额并以单一连续账本呈现全部类别', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      YhApp(
        home: StudentReportRulesPage(
          summary: qingyuanAcademicStudentReportContentSummary,
        ),
      ),
    );

    expect(find.text('第二课堂积分规则'), findsOneWidget);
    expect(find.text('8.5 / 10'), findsOneWidget);
    expect(find.text('还差 1.5 分'), findsOneWidget);
    expect(find.text('报告讲座'), findsOneWidget);
    expect(find.text('社会实践'), findsOneWidget);
    expect(find.text('创新创业'), findsOneWidget);
    expect(find.text('通识讲座'), findsOneWidget);
    expect(find.text('志愿服务'), findsOneWidget);
    expect(find.text('创新训练项目'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏默认定位未完成类别并可原位切换规则明细', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      YhApp(
        home: StudentReportRulesPage(
          summary: qingyuanAcademicStudentReportContentSummary,
        ),
      ),
    );

    expect(find.text('通识讲座'), findsOneWidget);
    expect(find.text('志愿服务'), findsNothing);

    await tester.tap(find.text('社会实践'));
    await tester.pumpAndSettle();

    expect(find.text('志愿服务'), findsOneWidget);
    expect(find.text('通识讲座'), findsNothing);
    expect(find.text('8.5 / 10'), findsOneWidget);
  });

  testWidgets('空态保留来源和统一返回成绩单路径', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => Center(
            child: YhButton(
              label: '打开规则',
              onTap: () => Navigator.of(context).push(
                YhPageRoute(
                  builder: (_) => StudentReportRulesPage(
                    summary: qingyuanAcademicStudentReportEmptyResult.summary!,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开规则'));
    await tester.pumpAndSettle();

    expect(find.text('第二课堂积分规则'), findsOneWidget);
    expect(find.textContaining('第二课堂 · 本地快照'), findsOneWidget);
    expect(find.text('暂时没有可核验的积分规则'), findsOneWidget);
    expect(find.text('等待规则数据'), findsOneWidget);
    expect(find.text('返回成绩单'), findsOneWidget);

    await tester.tap(find.text('返回成绩单'));
    await tester.pumpAndSettle();

    expect(find.text('打开规则'), findsOneWidget);
    expect(find.text('第二课堂积分规则'), findsNothing);
  });

  testWidgets('规则字段缺失时说明来源不足而不推测为零分', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final summary = SecondClassroomCreditSummary(
      records: const [],
      rules: const [
        SecondClassroomCreditRuleRow(
          category: '自定义类别',
          item: '待补项目',
          level: '',
          participation: '',
          credit: null,
          earnedCredit: null,
          requiredCredit: null,
          passStatus: '',
        ),
      ],
      fetchedAt: DateTime(2026, 7, 18, 8, 42),
      sourceUri: Uri.parse('https://student.example.invalid/report'),
    );

    await tester.pumpWidget(
      YhApp(home: StudentReportRulesPage(summary: summary)),
    );

    expect(find.text('总积分要求待来源补全'), findsOneWidget);
    expect(find.text('必修要求未提供'), findsOneWidget);
    expect(find.text('状态未提供'), findsOneWidget);
    expect(find.text('条件待来源补全'), findsOneWidget);
    expect(find.text('积分待来源补全'), findsOneWidget);
    expect(find.text('尚无已获记录'), findsOneWidget);
    expect(find.textContaining('0 / 0'), findsNothing);
  });

  testWidgets('宽屏类别支持方向键且减少动态时立即完成切换', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      YhApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1200, 900),
            disableAnimations: true,
          ),
          child: StudentReportRulesPage(
            summary: qingyuanAcademicStudentReportContentSummary,
          ),
        ),
      ),
    );

    final currentCategory = find.byWidgetPredicate(
      (widget) => widget is YhPressable && widget.semanticLabel == '报告讲座规则',
    );
    final pressable = tester.widget<YhPressable>(currentCategory);
    pressable.focusNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(find.text('志愿服务'), findsOneWidget);
    expect(find.text('通识讲座'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('767dp 仍保持连续账本而不提前切换双栏', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(767, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      YhApp(
        home: StudentReportRulesPage(
          summary: qingyuanAcademicStudentReportContentSummary,
        ),
      ),
    );

    expect(find.text('通识讲座'), findsOneWidget);
    expect(find.text('志愿服务'), findsOneWidget);
    expect(find.text('创新训练项目'), findsOneWidget);
    expect(find.bySemanticsLabel('报告讲座规则'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
