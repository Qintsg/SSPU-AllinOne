/*
 * 课程表视觉布局回归测试 — 校验桌面周视图密度与操作呈现
 * @Project : SSPU-AllinOne
 * @File : course_schedule_visual_layout_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-23
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/course_schedule_page.dart';

import 'support/qingyuan_visual_fixtures.dart';

/// 注册课表视觉布局回归测试。
///
/// :returns: 无返回值。
void main() {
  testWidgets('1200x900 桌面课表按单节时间轴定位跨节课程', (tester) async {
    const viewport = Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = viewport;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      YhApp(
        home: MediaQuery(
          data: const MediaQueryData(size: viewport, devicePixelRatio: 1),
          child: CourseSchedulePage(
            academicEamsService: QingyuanVisualAcademicEamsClient(
              result: qingyuanScheduleContentResult,
            ),
            initialResult: qingyuanScheduleContentResult,
            autoRefreshEnabledOverride: false,
            autoRefreshIntervalOverride: 30,
            nowOverride: qingyuanVisualNow,
            termLabelOverride: '2025-2026 第2学期',
          ),
        ),
      ),
    );
    await tester.pump();

    final firstRow = find.byKey(const Key('course-period-1'));
    final secondRow = find.byKey(const Key('course-period-2'));
    final courseBlock = find.byKey(const Key('course-week-block-1-1-数据结构'));
    final theme = tester.element(firstRow).yhTheme;
    final expectedRowHeight = theme.control.minimumTarget + theme.spacing.m;
    final actualRowHeight =
        tester.getTopLeft(secondRow).dy - tester.getTopLeft(firstRow).dy;

    expect(actualRowHeight, closeTo(expectedRowHeight, 0.5));
    expect(
      tester.getSize(courseBlock).height,
      closeTo(expectedRowHeight * 2 - theme.spacing.xs * 2, 0.5),
    );
    expect(
      tester.getTopLeft(courseBlock).dx,
      greaterThan(tester.getTopLeft(firstRow).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('1200x900 桌面刷新操作使用紧凑图标按钮', (tester) async {
    const viewport = Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = viewport;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      YhApp(
        home: MediaQuery(
          data: const MediaQueryData(size: viewport, devicePixelRatio: 1),
          child: CourseSchedulePage(
            academicEamsService: QingyuanVisualAcademicEamsClient(
              result: qingyuanScheduleContentResult,
            ),
            initialResult: qingyuanScheduleContentResult,
            autoRefreshEnabledOverride: false,
            autoRefreshIntervalOverride: 30,
            nowOverride: qingyuanVisualNow,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget(find.byKey(const Key('course-schedule-refresh'))),
      isA<YhIconButton>(),
    );
    expect(find.bySemanticsLabel('刷新课程表'), findsOneWidget);
  });
}
