/*
 * 校园数据自动刷新偏好 — 统一管理教务、校园卡与邮箱的刷新时长
 * @Project : SSPU-AllinOne
 * @File : data_auto_refresh_preferences.dart
 * @Author : Qintsg
 * @Date : 2026-08-23
 */

import 'dart:async';

import 'storage_service.dart';

/// 校园数据来源共享的自动刷新偏好模块。
class DataAutoRefreshPreferences {
  /// 创建共享刷新偏好单例。
  ///
  /// :returns: 仅供 [instance] 持有的偏好实例。
  DataAutoRefreshPreferences._();

  /// 全局共享实例。
  static final DataAutoRefreshPreferences instance =
      DataAutoRefreshPreferences._();

  final StreamController<int> _changesController =
      StreamController<int>.broadcast(sync: true);

  /// 默认自动刷新间隔，单位分钟。
  static const int defaultIntervalMinutes = 30;

  static const List<String> _legacyIntervalKeys = [
    StorageKeys.academicEamsAutoRefreshIntervalMinutes,
    StorageKeys.sportsAttendanceAutoRefreshIntervalMinutes,
    StorageKeys.studentReportAutoRefreshIntervalMinutes,
    StorageKeys.campusCardAutoRefreshIntervalMinutes,
    StorageKeys.emailAutoRefreshIntervalMinutes,
  ];

  /// 共享刷新间隔写入后的页面级重载通知。
  ///
  /// :returns: 每次成功写入后的标准化分钟数流。
  Stream<int> get changes => _changesController.stream;

  /// 读取全部校园数据来源共用的自动刷新间隔。
  ///
  /// 首次读取时会迁移任一旧来源已经保存的间隔，避免升级后丢失用户选择。
  ///
  /// :returns: 大于零的刷新间隔分钟数。
  Future<int> getIntervalMinutes() async {
    final stored = await StorageService.getInt(
      StorageKeys.dataAutoRefreshIntervalMinutes,
    );
    if (stored != null) return _normalize(stored);

    var migrated = 0;
    for (final key in _legacyIntervalKeys) {
      final legacyValue = await StorageService.getInt(key);
      if (legacyValue == null) continue;
      final normalized = _normalize(legacyValue);
      if (normalized > migrated) migrated = normalized;
    }
    if (migrated > 0) {
      await StorageService.setInt(
        StorageKeys.dataAutoRefreshIntervalMinutes,
        migrated,
      );
      return migrated;
    }
    return defaultIntervalMinutes;
  }

  /// 保存全部校园数据来源共用的自动刷新间隔。
  ///
  /// :param minutes: 刷新间隔分钟数；非正数会恢复默认值。
  /// :returns: 无返回值。
  Future<void> setIntervalMinutes(int minutes) async {
    final normalized = _normalize(minutes);
    await StorageService.setInt(
      StorageKeys.dataAutoRefreshIntervalMinutes,
      normalized,
    );
    _changesController.add(normalized);
  }

  /// 将无效间隔归一化为安全默认值。
  ///
  /// :param minutes: 待检查的刷新间隔。
  /// :returns: 大于零的刷新间隔分钟数。
  int _normalize(int minutes) {
    return minutes <= 0 ? defaultIntervalMinutes : minutes;
  }
}
