/*
 * 全局学期服务测试 — 校验校历解析、手动设置与持久化
 * @Project : SSPU-AllinOne
 * @File : academic_term_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/services/academic_term_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    SharedPreferences.setMockInitialValues({});
  });

  test('内置校历按 issue 规则解析跨学年夏季和秋春学期', () async {
    final service = AcademicTermService();

    void expectResolved(
      DateTime date, {
      required int academicYear,
      required AcademicTermSeason season,
      required int week,
    }) {
      final context = service.resolveContext(
        AcademicTermSettings(
          autoSwitchEnabled: true,
          manualSelection: AcademicTermService.defaultManualSelection,
        ),
        now: date,
      );

      expect(context.source, AcademicTermContextSource.automatic);
      expect(context.selection.academicYear, academicYear);
      expect(context.selection.season, season);
      expect(context.selection.week, week);
    }

    expectResolved(
      DateTime(2025, 9),
      academicYear: 2024,
      season: AcademicTermSeason.summer,
      week: 3,
    );
    expectResolved(
      DateTime(2025, 9, 22),
      academicYear: 2025,
      season: AcademicTermSeason.fall,
      week: 1,
    );
    expectResolved(
      DateTime(2026, 1, 18),
      academicYear: 2025,
      season: AcademicTermSeason.fall,
      week: 17,
    );
    expectResolved(
      DateTime(2026, 3, 2),
      academicYear: 2025,
      season: AcademicTermSeason.spring,
      week: 1,
    );
    expectResolved(
      DateTime(2026, 6, 29),
      academicYear: 2025,
      season: AcademicTermSeason.summer,
      week: 1,
    );
    expectResolved(
      DateTime(2026, 8, 31),
      academicYear: 2025,
      season: AcademicTermSeason.summer,
      week: 3,
    );
  });

  test('自动模式未命中内置校历时回退手动设置', () {
    final service = AcademicTermService();
    final manualSelection = const AcademicTermSelection(
      academicYear: 2026,
      season: AcademicTermSeason.spring,
      week: 8,
    );

    final context = service.resolveContext(
      AcademicTermSettings(
        autoSwitchEnabled: true,
        manualSelection: manualSelection,
      ),
      now: DateTime(2030),
    );

    expect(context.source, AcademicTermContextSource.unresolved);
    expect(context.selection, manualSelection);
    expect(context.message, contains('未命中内置校历'));
  });

  test('关闭自动模式时始终使用手动设置', () {
    final service = AcademicTermService();
    final manualSelection = const AcademicTermSelection(
      academicYear: 2026,
      season: AcademicTermSeason.spring,
      week: 8,
    );

    final context = service.resolveContext(
      AcademicTermSettings(
        autoSwitchEnabled: false,
        manualSelection: manualSelection,
      ),
      now: DateTime(2025, 9, 22),
    );

    expect(context.source, AcademicTermContextSource.manual);
    expect(context.selection, manualSelection);
  });

  test('手动设置会按学期总周数规范化并持久化', () async {
    final service = AcademicTermService();
    await service.loadSettings();

    await service.setAutoSwitchEnabled(false);
    await service.setManualSelection(
      const AcademicTermSelection(
        academicYear: 2025,
        season: AcademicTermSeason.summer,
        week: 99,
      ),
    );

    final reloaded = AcademicTermService();
    final settings = await reloaded.loadSettings();

    expect(settings.autoSwitchEnabled, isFalse);
    expect(settings.manualSelection.academicYear, 2025);
    expect(settings.manualSelection.season, AcademicTermSeason.summer);
    expect(settings.manualSelection.week, 5);
  });
}
