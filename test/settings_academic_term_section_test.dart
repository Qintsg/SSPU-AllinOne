/*
 * 设置页学期分区测试 — 校验全局学期设置入口
 * @Project : SSPU-AllinOne
 * @File : settings_academic_term_section_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/theme/app_theme.dart';
import 'package:sspu_allinone/widgets/settings_academic_term_section.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('设置页学期分区展示内置校历定位结果', (tester) async {
    await tester.pumpWidget(
      FluentApp(
        theme: AppTheme.build(Brightness.light),
        home: ScaffoldPage(
          content: SingleChildScrollView(
            child: SettingsAcademicTermSection(now: DateTime(2026, 3, 2)),
          ),
        ),
      ),
    );

    await _pumpUntilFound(
      tester,
      find.byKey(const Key('settings-academic-term-section')),
    );

    expect(
      find.byKey(const Key('settings-academic-term-section')),
      findsOneWidget,
    );
    expect(find.text('已定位当前教学周'), findsOneWidget);
    expect(find.text('2025-2026 学年春季学期 第 1 / 17 周'), findsOneWidget);
    expect(find.byKey(const Key('academic-term-year-select')), findsOneWidget);
    expect(
      find.byKey(const Key('academic-term-season-select')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('academic-term-week-box')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}
