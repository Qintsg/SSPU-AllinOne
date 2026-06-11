/*
 * 全局学期服务 — 维护当前全局学期与内置校历周数定位
 * @Project : SSPU-AllinOne
 * @File : academic_term_service.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'package:flutter/foundation.dart';

import '../models/academic_term.dart';
import 'academic_calendar_service.dart';
import 'storage_service.dart';

/// 内置校历解析器。
class AcademicCalendarResolver {
  AcademicCalendarResolver({List<AcademicTermDefinition>? definitions})
    : _definitions = definitions ?? defaultDefinitions;

  /// 官网校历栏目当前可选择的已知学年。
  static const List<int> knownAcademicYears = [
    2015,
    2016,
    2017,
    2018,
    2019,
    2020,
    2021,
    2022,
    2023,
    2024,
    2025,
    2026,
  ];

  /// 具备可定位日期的内置校历定义。
  static final List<AcademicTermDefinition> defaultDefinitions = [
    _fall(2023, DateTime(2023, 9, 25)),
    _spring(2023, DateTime(2024, 2, 26)),
    _summer(
      2023,
      startDate: DateTime(2024, 6, 24),
      endDate: DateTime(2024, 9, 15),
      segments: [
        _segment(DateTime(2024, 6, 24), DateTime(2024, 7, 14), 1, 3),
        _segment(DateTime(2024, 9, 2), DateTime(2024, 9, 15), 4, 5),
      ],
    ),
    _fall(2024, DateTime(2024, 9, 16)),
    _spring(2024, DateTime(2025, 2, 17)),
    _summer(
      2024,
      startDate: DateTime(2025, 6, 16),
      endDate: DateTime(2025, 9, 21),
      segments: [
        _segment(DateTime(2025, 6, 16), DateTime(2025, 6, 29), 1, 2),
        _segment(DateTime(2025, 9, 1), DateTime(2025, 9, 21), 3, 5),
      ],
    ),
    _fall(2025, DateTime(2025, 9, 22)),
    _spring(2025, DateTime(2026, 3, 2)),
    _summer(
      2025,
      startDate: DateTime(2026, 6, 29),
      endDate: DateTime(2026, 9, 20),
      segments: [
        _segment(DateTime(2026, 6, 29), DateTime(2026, 7, 12), 1, 2),
        _segment(DateTime(2026, 8, 31), DateTime(2026, 9, 20), 3, 5),
      ],
    ),
    _fall(2026, DateTime(2026, 9, 21)),
    _spring(2026, DateTime(2027, 2, 22)),
    _summer(
      2026,
      startDate: DateTime(2027, 6, 21),
      endDate: DateTime(2027, 9, 19),
      segments: [
        _segment(DateTime(2027, 6, 21), DateTime(2027, 7, 4), 1, 2),
        _segment(DateTime(2027, 8, 30), DateTime(2027, 9, 19), 3, 5),
      ],
    ),
  ];

  final List<AcademicTermDefinition> _definitions;

  /// 所有可选学期。
  List<AcademicTermChoice> get availableTerms {
    return [
      for (final year in knownAcademicYears)
        for (final season in AcademicTermSeason.values)
          AcademicTermChoice(academicYear: year, season: season),
    ];
  }

  /// 按学期查找内置定义。
  AcademicTermDefinition? definitionFor(AcademicTermChoice choice) {
    for (final definition in _definitions) {
      if (definition.choice == choice) return definition;
    }
    return null;
  }

  /// 按日期自动匹配内置学期。
  AcademicTermDefinition? definitionForDate(DateTime date) {
    for (final definition in _definitions) {
      if (definition.contains(date)) return definition;
    }
    return null;
  }

  /// 按日期匹配当前上下文；寒假等空档优先指向下一个已知学期。
  AcademicTermDefinition? definitionForContext(DateTime date) {
    final direct = definitionForDate(date);
    if (direct != null) return direct;

    final target = AcademicTermDefinition.dateOnly(date);
    final sortedDefinitions = [..._definitions]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    for (var index = 0; index < sortedDefinitions.length - 1; index++) {
      final current = sortedDefinitions[index];
      final next = sortedDefinitions[index + 1];
      if (target.isAfter(current.endDate) && target.isBefore(next.startDate)) {
        return next;
      }
    }

    return null;
  }

  /// 判断某学期是否为官网已知学期。
  bool isKnownTerm(AcademicTermChoice choice) {
    return knownAcademicYears.contains(choice.academicYear);
  }

  /// 合并动态校历与内置定义；同一学年学期以动态解析结果为准。
  static List<AcademicTermDefinition> mergeDefinitions({
    required List<AcademicTermDefinition> dynamicDefinitions,
    List<AcademicTermDefinition>? fallbackDefinitions,
  }) {
    final fallback = fallbackDefinitions ?? defaultDefinitions;
    final dynamicChoices = dynamicDefinitions
        .map((definition) => definition.choice)
        .toSet();
    return [
      ...dynamicDefinitions,
      for (final definition in fallback)
        if (!dynamicChoices.contains(definition.choice)) definition,
    ];
  }

  static AcademicTermDefinition _fall(int year, DateTime startDate) {
    return _continuous(year, AcademicTermSeason.fall, startDate, 17);
  }

  static AcademicTermDefinition _spring(int year, DateTime startDate) {
    return _continuous(year, AcademicTermSeason.spring, startDate, 17);
  }

  static AcademicTermDefinition _continuous(
    int year,
    AcademicTermSeason season,
    DateTime startDate,
    int weeks,
  ) {
    final endDate = startDate.add(Duration(days: weeks * 7 - 1));
    return AcademicTermDefinition(
      choice: AcademicTermChoice(academicYear: year, season: season),
      startDate: startDate,
      endDate: endDate,
      teachingSegments: [_segment(startDate, endDate, 1, weeks)],
    );
  }

  static AcademicTermDefinition _summer(
    int year, {
    required DateTime startDate,
    required DateTime endDate,
    required List<AcademicTermTeachingSegment> segments,
  }) {
    return AcademicTermDefinition(
      choice: AcademicTermChoice(
        academicYear: year,
        season: AcademicTermSeason.summer,
      ),
      startDate: startDate,
      endDate: endDate,
      teachingSegments: segments,
    );
  }

  static AcademicTermTeachingSegment _segment(
    DateTime startDate,
    DateTime endDate,
    int startWeek,
    int endWeek,
  ) {
    return AcademicTermTeachingSegment(
      startDate: startDate,
      endDate: endDate,
      startWeek: startWeek,
      endWeek: endWeek,
    );
  }
}

/// 全局学期设置服务。
class AcademicTermService extends ChangeNotifier {
  AcademicTermService({
    AcademicCalendarResolver? calendarResolver,
    AcademicCalendarClient? calendarService,
  }) : _calendarResolver = calendarResolver ?? AcademicCalendarResolver(),
       _calendarService = calendarService ?? AcademicCalendarService.instance;

  /// 全局单例。
  static final AcademicTermService instance = AcademicTermService();

  /// 默认学期。
  static const AcademicTermChoice defaultTerm = AcademicTermChoice(
    academicYear: 2025,
    season: AcademicTermSeason.fall,
  );

  final AcademicCalendarResolver _calendarResolver;
  final AcademicCalendarClient _calendarService;

  AcademicTermSettings? _settings;

  /// 可选学期列表。
  List<AcademicTermChoice> get availableTerms =>
      _calendarResolver.availableTerms;

  /// 当前缓存设置。
  AcademicTermSettings get settings =>
      _settings ?? const AcademicTermSettings();

  /// 加载设置。
  Future<AcademicTermSettings> loadSettings() async {
    final storedAcademicYear = await StorageService.getInt(
      StorageKeys.academicTermManualYear,
    );
    final storedSeason = await StorageService.getString(
      StorageKeys.academicTermManualSeason,
    );

    _settings = AcademicTermSettings(
      selectedTerm: storedAcademicYear == null || storedSeason == null
          ? null
          : AcademicTermChoice(
              academicYear: storedAcademicYear,
              season: AcademicTermSeason.fromCode(storedSeason),
            ),
    );
    notifyListeners();
    return settings;
  }

  /// 读取当前生效学期上下文。
  Future<AcademicTermContext> getEffectiveContext({DateTime? now}) async {
    if (_settings == null) await loadSettings();
    final resolvedAt = now ?? DateTime.now();
    try {
      await _calendarService.ensureCalendarsForDate(now: resolvedAt);
      final definitions = await _calendarService.readCachedTermDefinitions();
      if (definitions.isNotEmpty) {
        return resolveContext(
          settings,
          now: resolvedAt,
          calendarResolver: AcademicCalendarResolver(
            definitions: AcademicCalendarResolver.mergeDefinitions(
              dynamicDefinitions: definitions,
            ),
          ),
        );
      }
    } catch (_) {
      // 校历抓取或解析失败时必须回退内置校历，不阻断设置页和课程表等核心功能。
    }
    return resolveContext(settings, now: resolvedAt);
  }

  /// 按设置解析当前生效学期上下文。
  AcademicTermContext resolveContext(
    AcademicTermSettings settings, {
    DateTime? now,
    AcademicCalendarResolver? calendarResolver,
  }) {
    final resolvedAt = now ?? DateTime.now();
    final resolver = calendarResolver ?? _calendarResolver;
    final selectedTerm = settings.selectedTerm;
    final automaticDefinition = resolver.definitionForContext(resolvedAt);
    if (selectedTerm == null && automaticDefinition == null) {
      return AcademicTermContext(
        term: defaultTerm,
        source: AcademicTermContextSource.unsupported,
        dateStatus: AcademicTermDateStatus.unsupported,
        resolvedAt: resolvedAt,
        isTeachingWeek: false,
        message: '当前日期不在已内置的校历定位范围内。',
      );
    }

    final term = automaticDefinition?.choice ?? selectedTerm ?? defaultTerm;
    final queryTerm = selectedTerm;
    final source = selectedTerm == null
        ? AcademicTermContextSource.automatic
        : AcademicTermContextSource.selected;
    final definition = resolver.definitionFor(term);

    if (definition == null) {
      return AcademicTermContext(
        term: term,
        source: AcademicTermContextSource.unsupported,
        dateStatus: AcademicTermDateStatus.unsupported,
        resolvedAt: resolvedAt,
        isTeachingWeek: false,
        queryTerm: queryTerm,
        message: resolver.isKnownTerm(term)
            ? '该学期保留为可选择项，但暂无可定位的内置校历。'
            : '该学期不在官网已知校历范围内。',
      );
    }

    final teachingSegment = definition.teachingSegmentFor(resolvedAt);
    if (teachingSegment != null) {
      final week = teachingSegment.resolveWeek(resolvedAt);
      return AcademicTermContext(
        term: term,
        selection: definition.selectionFor(resolvedAt, week: week),
        definition: definition,
        source: source,
        dateStatus: AcademicTermDateStatus.teaching,
        resolvedAt: resolvedAt,
        isTeachingWeek: true,
        queryTerm: queryTerm,
        message: queryTerm != null && queryTerm != term
            ? '已根据当前日期定位教学周；查询相关内容时使用所选学期。'
            : '已根据内置校历计算当前教学周。',
      );
    }

    final dateStatus =
        definition.choice.season == AcademicTermSeason.summer &&
            definition.contains(resolvedAt)
        ? AcademicTermDateStatus.summerVacation
        : AcademicTermDateStatus.winterVacation;
    final selection = definition.selectionFor(resolvedAt);
    return AcademicTermContext(
      term: term,
      selection: selection,
      definition: definition,
      source: source,
      dateStatus: dateStatus,
      resolvedAt: resolvedAt,
      isTeachingWeek: false,
      queryTerm: queryTerm,
      message: dateStatus == AcademicTermDateStatus.summerVacation
          ? '当前日期处于该夏季学期的暑假区间。'
          : queryTerm != null && queryTerm != term
          ? '当前日期处于学期间隔；查询相关内容时使用所选学期。'
          : '当前日期未落在该学期教学周内，按寒假处理。',
    );
  }

  /// 保存全局学期选择。
  Future<void> setSelectedTerm(AcademicTermChoice term) async {
    await StorageService.setInt(
      StorageKeys.academicTermManualYear,
      term.academicYear,
    );
    await StorageService.setString(
      StorageKeys.academicTermManualSeason,
      term.season.code,
    );
    await StorageService.remove(StorageKeys.academicTermManualWeek);
    await StorageService.remove(StorageKeys.academicTermAutoSwitchEnabled);
    _settings = AcademicTermSettings(selectedTerm: term);
    notifyListeners();
  }
}
