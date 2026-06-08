/*
 * 全局学期服务测试 — 校验内置校历定位、假期状态与持久化兼容
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

  test('未设置全局学期时按内置校历自动定位秋春教学周', () {
    final service = AcademicTermService();

    expectTeachingWeek(
      service.resolveContext(
        const AcademicTermSettings(),
        now: DateTime(2025, 9, 22),
      ),
      academicYear: 2025,
      season: AcademicTermSeason.fall,
      week: 1,
      source: AcademicTermContextSource.automatic,
    );
    expectTeachingWeek(
      service.resolveContext(
        const AcademicTermSettings(),
        now: DateTime(2026, 3, 2),
      ),
      academicYear: 2025,
      season: AcademicTermSeason.spring,
      week: 1,
      source: AcademicTermContextSource.automatic,
    );
    expectTeachingWeek(
      service.resolveContext(
        const AcademicTermSettings(),
        now: DateTime(2026, 9, 21),
      ),
      academicYear: 2026,
      season: AcademicTermSeason.fall,
      week: 1,
      source: AcademicTermContextSource.automatic,
    );
    expectTeachingWeek(
      service.resolveContext(
        const AcademicTermSettings(),
        now: DateTime(2027, 2, 22),
      ),
      academicYear: 2026,
      season: AcademicTermSeason.spring,
      week: 1,
      source: AcademicTermContextSource.automatic,
    );
    expectTeachingWeek(
      service.resolveContext(
        const AcademicTermSettings(),
        now: DateTime(2027, 3, 1),
      ),
      academicYear: 2026,
      season: AcademicTermSeason.spring,
      week: 2,
      source: AcademicTermContextSource.automatic,
    );
  });

  test('夏季学期按逐年内置教学段定位且中间区间显示暑假', () {
    final service = AcademicTermService();

    expectTeachingWeek(
      service.resolveContext(
        const AcademicTermSettings(),
        now: DateTime(2024, 6, 24),
      ),
      academicYear: 2023,
      season: AcademicTermSeason.summer,
      week: 1,
      source: AcademicTermContextSource.automatic,
    );
    expectTeachingWeek(
      service.resolveContext(
        const AcademicTermSettings(),
        now: DateTime(2024, 7, 14),
      ),
      academicYear: 2023,
      season: AcademicTermSeason.summer,
      week: 3,
      source: AcademicTermContextSource.automatic,
    );

    final gapContext = service.resolveContext(
      const AcademicTermSettings(),
      now: DateTime(2024, 8),
    );
    expect(gapContext.term.academicYear, 2023);
    expect(gapContext.term.season, AcademicTermSeason.summer);
    expect(gapContext.dateStatus, AcademicTermDateStatus.summerVacation);
    expect(gapContext.isTeachingWeek, isFalse);
    expect(gapContext.summaryLabel, '2023-2024 学年夏季学期 暑假');

    expectTeachingWeek(
      service.resolveContext(
        const AcademicTermSettings(),
        now: DateTime(2024, 9, 2),
      ),
      academicYear: 2023,
      season: AcademicTermSeason.summer,
      week: 4,
      source: AcademicTermContextSource.automatic,
    );

    final futureGapContext = service.resolveContext(
      const AcademicTermSettings(),
      now: DateTime(2026, 8),
    );
    expect(futureGapContext.term.academicYear, 2025);
    expect(futureGapContext.term.season, AcademicTermSeason.summer);
    expect(futureGapContext.dateStatus, AcademicTermDateStatus.summerVacation);
  });

  test('所选全局学期在教学段外保留相对周数且不返回第零周', () {
    final service = AcademicTermService();
    final context = service.resolveContext(
      const AcademicTermSettings(
        selectedTerm: AcademicTermChoice(
          academicYear: 2026,
          season: AcademicTermSeason.fall,
        ),
      ),
      now: DateTime(2026, 9, 14),
    );

    expect(context.source, AcademicTermContextSource.selected);
    expect(context.dateStatus, AcademicTermDateStatus.winterVacation);
    expect(context.selection?.week, -1);
    expect(context.selection?.week, isNot(0));
    expect(context.summaryLabel, '2026-2027 学年秋季学期 寒假');
  });

  test('夏季学期长范围外按寒假处理而不是硬套暑假', () {
    final service = AcademicTermService();
    final context = service.resolveContext(
      const AcademicTermSettings(
        selectedTerm: AcademicTermChoice(
          academicYear: 2025,
          season: AcademicTermSeason.summer,
        ),
      ),
      now: DateTime(2026, 5, 25),
    );

    expect(context.source, AcademicTermContextSource.selected);
    expect(context.dateStatus, AcademicTermDateStatus.winterVacation);
    expect(context.summaryLabel, '2025-2026 学年夏季学期 寒假');
  });

  test('2023 年以前学期保留选择但不提供日期定位', () {
    final service = AcademicTermService();
    final context = service.resolveContext(
      const AcademicTermSettings(
        selectedTerm: AcademicTermChoice(
          academicYear: 2022,
          season: AcademicTermSeason.fall,
        ),
      ),
      now: DateTime(2022, 9, 12),
    );

    expect(context.source, AcademicTermContextSource.unsupported);
    expect(context.dateStatus, AcademicTermDateStatus.unsupported);
    expect(context.selection, isNull);
    expect(context.message, contains('保留为可选择项'));
  });

  test('自动定位不把内置校历边界外日期强行归到最近学期', () {
    final service = AcademicTermService();
    final beforeKnownContext = service.resolveContext(
      const AcademicTermSettings(),
      now: DateTime(2022, 9, 12),
    );
    final afterKnownContext = service.resolveContext(
      const AcademicTermSettings(),
      now: DateTime(2028),
    );

    expect(beforeKnownContext.source, AcademicTermContextSource.unsupported);
    expect(beforeKnownContext.term, AcademicTermService.defaultTerm);
    expect(beforeKnownContext.dateStatus, AcademicTermDateStatus.unsupported);
    expect(afterKnownContext.source, AcademicTermContextSource.unsupported);
    expect(afterKnownContext.term, AcademicTermService.defaultTerm);
    expect(afterKnownContext.dateStatus, AcademicTermDateStatus.unsupported);
  });

  test('全局学期选择仅持久化学年和学期并清理旧周数开关', () async {
    final service = AcademicTermService();
    await StorageService.setInt(StorageKeys.academicTermManualWeek, 8);
    await StorageService.setBool(
      StorageKeys.academicTermAutoSwitchEnabled,
      true,
    );

    await service.setSelectedTerm(
      const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.summer,
      ),
    );

    final reloaded = AcademicTermService();
    final settings = await reloaded.loadSettings();

    expect(settings.selectedTerm?.academicYear, 2025);
    expect(settings.selectedTerm?.season, AcademicTermSeason.summer);
    expect(
      await StorageService.getInt(StorageKeys.academicTermManualWeek),
      isNull,
    );
    expect(
      await StorageService.getBool(StorageKeys.academicTermAutoSwitchEnabled),
      isFalse,
    );
  });
}

void expectTeachingWeek(
  AcademicTermContext context, {
  required int academicYear,
  required AcademicTermSeason season,
  required int week,
  required AcademicTermContextSource source,
}) {
  expect(context.source, source);
  expect(context.term.academicYear, academicYear);
  expect(context.term.season, season);
  expect(context.selection?.academicYear, academicYear);
  expect(context.selection?.season, season);
  expect(context.selection?.week, week);
  expect(context.dateStatus, AcademicTermDateStatus.teaching);
  expect(context.isTeachingWeek, isTrue);
}
