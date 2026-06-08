/*
 * 全局学期服务 — 统一维护当前学年、学期与周数设置
 * @Project : SSPU-AllinOne
 * @File : academic_term_service.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'package:flutter/foundation.dart';

import '../models/academic_term.dart';
import 'storage_service.dart';

/// 校历解析器。
class AcademicCalendarResolver {
  AcademicCalendarResolver({List<AcademicTermCalendarSegment>? segments})
    : _segments = segments ?? defaultSegments;

  /// #172 已明确的内置校历段。
  static final List<AcademicTermCalendarSegment> defaultSegments = [
    AcademicTermCalendarSegment(
      academicYear: 2024,
      season: AcademicTermSeason.summer,
      startDate: DateTime(2025, 9, 1),
      endDate: DateTime(2025, 9, 21),
      startWeek: 3,
    ),
    AcademicTermCalendarSegment(
      academicYear: 2025,
      season: AcademicTermSeason.fall,
      startDate: DateTime(2025, 9, 22),
      endDate: DateTime(2026, 1, 18),
      startWeek: 1,
    ),
    AcademicTermCalendarSegment(
      academicYear: 2025,
      season: AcademicTermSeason.spring,
      startDate: DateTime(2026, 3, 2),
      endDate: DateTime(2026, 6, 28),
      startWeek: 1,
    ),
    AcademicTermCalendarSegment(
      academicYear: 2025,
      season: AcademicTermSeason.summer,
      startDate: DateTime(2026, 6, 29),
      endDate: DateTime(2026, 7, 12),
      startWeek: 1,
    ),
    AcademicTermCalendarSegment(
      academicYear: 2025,
      season: AcademicTermSeason.summer,
      startDate: DateTime(2026, 8, 31),
      endDate: DateTime(2026, 9, 20),
      startWeek: 3,
    ),
  ];

  final List<AcademicTermCalendarSegment> _segments;

  /// 尝试按内置校历解析日期。
  AcademicTermSelection? resolve(DateTime date) {
    for (final segment in _segments) {
      if (segment.contains(date)) return segment.resolve(date);
    }
    return null;
  }
}

/// 全局学期设置服务。
class AcademicTermService extends ChangeNotifier {
  AcademicTermService({AcademicCalendarResolver? calendarResolver})
    : _calendarResolver = calendarResolver ?? AcademicCalendarResolver();

  /// 全局单例。
  static final AcademicTermService instance = AcademicTermService();

  /// 默认手动设置。
  static final AcademicTermSelection defaultManualSelection =
      AcademicTermSelection(
        academicYear: 2025,
        season: AcademicTermSeason.fall,
        week: 1,
      );

  final AcademicCalendarResolver _calendarResolver;

  AcademicTermSettings? _settings;

  /// 当前缓存设置。
  AcademicTermSettings get settings =>
      _settings ??
      AcademicTermSettings(
        autoSwitchEnabled: true,
        manualSelection: defaultManualSelection,
      );

  /// 加载设置。
  Future<AcademicTermSettings> loadSettings() async {
    final autoSwitchEnabled = await StorageService.getBool(
      StorageKeys.academicTermAutoSwitchEnabled,
      defaultValue: true,
    );
    final academicYear =
        await StorageService.getInt(StorageKeys.academicTermManualYear) ??
        defaultManualSelection.academicYear;
    final season = AcademicTermSeason.fromCode(
      await StorageService.getString(StorageKeys.academicTermManualSeason),
    );
    final week =
        await StorageService.getInt(StorageKeys.academicTermManualWeek) ??
        defaultManualSelection.week;

    _settings = AcademicTermSettings(
      autoSwitchEnabled: autoSwitchEnabled,
      manualSelection: AcademicTermSelection(
        academicYear: academicYear,
        season: season,
        week: week,
      ).normalized(),
    );
    notifyListeners();
    return settings;
  }

  /// 读取当前生效学期上下文。
  Future<AcademicTermContext> getEffectiveContext({DateTime? now}) async {
    if (_settings == null) await loadSettings();
    return resolveContext(settings, now: now);
  }

  /// 按设置解析当前生效学期上下文。
  AcademicTermContext resolveContext(
    AcademicTermSettings settings, {
    DateTime? now,
  }) {
    final resolvedAt = now ?? DateTime.now();
    final manualSelection = settings.manualSelection.normalized();

    if (!settings.autoSwitchEnabled) {
      return AcademicTermContext(
        selection: manualSelection,
        manualSelection: manualSelection,
        autoSwitchEnabled: false,
        source: AcademicTermContextSource.manual,
        resolvedAt: resolvedAt,
        message: '当前使用手动学期设置。',
      );
    }

    final automaticSelection = _calendarResolver.resolve(resolvedAt);
    if (automaticSelection != null) {
      return AcademicTermContext(
        selection: automaticSelection,
        manualSelection: manualSelection,
        autoSwitchEnabled: true,
        source: AcademicTermContextSource.automatic,
        resolvedAt: resolvedAt,
        message: '已根据内置校历自动计算当前学期与周数。',
      );
    }

    return AcademicTermContext(
      selection: manualSelection,
      manualSelection: manualSelection,
      autoSwitchEnabled: true,
      source: AcademicTermContextSource.unresolved,
      resolvedAt: resolvedAt,
      message: '当前日期未命中内置校历，已暂时使用手动学期设置。',
    );
  }

  /// 保存自动切换开关。
  Future<void> setAutoSwitchEnabled(bool enabled) async {
    final current = settings;
    await StorageService.setBool(
      StorageKeys.academicTermAutoSwitchEnabled,
      enabled,
    );
    _settings = current.copyWith(autoSwitchEnabled: enabled);
    notifyListeners();
  }

  /// 保存手动学期设置。
  Future<void> setManualSelection(AcademicTermSelection selection) async {
    final normalized = selection.normalized();
    await StorageService.setInt(
      StorageKeys.academicTermManualYear,
      normalized.academicYear,
    );
    await StorageService.setString(
      StorageKeys.academicTermManualSeason,
      normalized.season.code,
    );
    await StorageService.setInt(
      StorageKeys.academicTermManualWeek,
      normalized.week,
    );
    _settings = settings.copyWith(manualSelection: normalized);
    notifyListeners();
  }
}
