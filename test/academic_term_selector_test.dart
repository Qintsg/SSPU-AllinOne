/*
 * 学期选择组件测试 — 校验设置页与紧凑详情模式渲染
 * @Project : SSPU-AllinOne
 * @File : academic_term_selector_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/theme/app_theme.dart';
import 'package:sspu_allinone/widgets/academic_term_selector.dart';

void main() {
  testWidgets('学期选择组件在紧凑宽度下可渲染周数选择', (tester) async {
    var selection = const AcademicTermSelection(
      academicYear: 2025,
      season: AcademicTermSeason.summer,
      week: 2,
    );

    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      FluentApp(
        theme: AppTheme.build(Brightness.light),
        home: ScaffoldPage(
          content: SizedBox(
            width: 320,
            child: StatefulBuilder(
              builder: (context, setState) {
                return AcademicTermSelector(
                  selection: selection,
                  variant: AcademicTermSelectorVariant.compact,
                  onChanged: (value) => setState(() => selection = value),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('academic-term-selector')), findsOneWidget);
    expect(find.text('2025 学年夏季学期 第 2 / 5 周'), findsOneWidget);
    expect(find.byKey(const Key('academic-term-week-box')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
