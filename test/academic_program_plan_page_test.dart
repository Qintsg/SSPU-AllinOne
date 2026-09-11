/*
 * 培养方案详情页测试 — 校验模块进度、课程浏览与响应式布局
 * @Project : SSPU-AllinOne
 * @File : academic_program_plan_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-09-08
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/pages/academic_page.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';

void main() {
  testWidgets('培养方案页展示总进度、模块进度和课程', (tester) async {
    final result = _programResult();
    await tester.pumpWidget(
      YhApp(
        home: AcademicProgramPlanPage(
          client: _FakeProgramPlanClient(result),
          initialResult: result,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('培养方案'), findsWidgets);
    expect(find.text('3.0/5.0'), findsOneWidget);
    expect(find.text('公共基础'), findsWidgets);
    expect(find.text('高等数学'), findsOneWidget);
    expect(find.text('大学英语'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('培养方案空数据展示可恢复的空状态', (tester) async {
    final result = _programResult(courses: const []);
    await tester.pumpWidget(
      YhApp(
        home: AcademicProgramPlanPage(
          client: _FakeProgramPlanClient(result),
          initialResult: result,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('academic-program-plan-empty')),
      findsOneWidget,
    );
    expect(find.text('当前没有培养方案课程'), findsOneWidget);
    expect(find.text('重新读取'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('培养方案登录失效和网络失败展示明确恢复入口', (tester) async {
    for (final status in [
      AcademicEamsQueryStatus.oaLoginRequired,
      AcademicEamsQueryStatus.networkError,
    ]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final result = AcademicEamsQueryResult(
        status: status,
        message: status == AcademicEamsQueryStatus.oaLoginRequired
            ? '需要重新登录'
            : '培养方案网络失败',
        detail: '请检查网络或登录状态后重试。',
        checkedAt: DateTime(2026, 9, 8, 9),
        entranceUri: Uri.parse('https://oa.sspu.edu.cn/'),
      );
      await tester.pumpWidget(
        YhApp(
          home: AcademicProgramPlanPage(
            client: _FakeProgramPlanClient(result),
            initialResult: result,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(result.message), findsOneWidget);
      expect(find.text('检查后重试'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('培养方案模块进度在 360px 宽度下无布局异常', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final result = _programResult(moduleName: '公共基础课程与通识教育模块');
    await tester.pumpWidget(
      YhApp(
        home: AcademicProgramPlanPage(
          client: _FakeProgramPlanClient(result),
          initialResult: result,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('公共基础课程与通识教育模块'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _FakeProgramPlanClient implements AcademicProgramPlanClient {
  _FakeProgramPlanClient(this.result);

  final AcademicEamsQueryResult result;

  @override
  Future<AcademicEamsQueryResult> fetchProgramPlan({
    bool requireCampusNetwork = true,
  }) async => result;
}

AcademicEamsQueryResult _programResult({
  List<AcademicProgramPlanCourse>? courses,
  String moduleName = '公共基础',
}) {
  final fetchedAt = DateTime(2026, 9, 8, 9);
  final source = Uri.parse(
    'https://jx.sspu.edu.cn/eams/teach/program/student/myPlan.action',
  );
  return AcademicEamsQueryResult(
    status: AcademicEamsQueryStatus.success,
    message: '培养方案读取成功',
    detail: '只读快照',
    checkedAt: fetchedAt,
    entranceUri: Uri.parse('https://oa.sspu.edu.cn/'),
    finalUri: source,
    snapshot: AcademicEamsSnapshot(
      fetchedAt: fetchedAt,
      sourceUri: source,
      warnings: const [],
      hasCourseOfferingEntry: false,
      hasFreeClassroomEntry: false,
      programPlan: AcademicProgramPlanSnapshot(
        planName: '2024 级软件工程培养方案',
        fetchedAt: fetchedAt,
        sourceUri: source,
        courses:
            courses ??
            [
              AcademicProgramPlanCourse(
                courseName: '高等数学',
                courseCode: 'MATH101',
                credit: 3,
                moduleName: moduleName,
                suggestedTerm: '1',
                rawCells: [moduleName, '高等数学', '3'],
              ),
              AcademicProgramPlanCourse(
                courseName: '大学英语',
                courseCode: 'ENG101',
                credit: 2,
                moduleName: moduleName,
                suggestedTerm: '2',
                rawCells: [moduleName, '大学英语', '2'],
              ),
            ],
      ),
      programCompletion: const AcademicProgramCompletionSnapshot(
        completedCourseCount: 1,
        pendingCourseCount: 1,
        completedCredits: 3,
        pendingCredits: 2,
        moduleProgress: [
          AcademicProgramModuleProgress(
            moduleName: '公共基础',
            totalCourseCount: 2,
            completedCourseCount: 1,
            pendingCourseCount: 1,
            totalCredits: 5,
            completedCredits: 3,
            pendingCredits: 2,
          ),
        ],
      ),
    ),
  );
}
