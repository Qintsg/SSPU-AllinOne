/*
 * 数据模块访问偏好 — 将首页显隐与联网获取权限分离
 * @Project : SSPU-AllinOne
 * @File : data_module_preferences.dart
 * @Author : Qintsg
 * @Date : 2026-09-08
 */

import 'dart:async';

import 'storage_service.dart';

/// 可以独立停止联网读取的校园数据模块。
enum CampusDataModule {
  academicEams('academic-eams'),
  campusCard('campus-card'),
  email('email'),
  sportsAttendance('sports-attendance'),
  studentReport('student-report');

  const CampusDataModule(this.storageId);

  /// 跨版本稳定的模块标识。
  final String storageId;

  /// 模块对应的持久化键。
  String get storageKey => switch (this) {
    CampusDataModule.academicEams => StorageKeys.academicEamsModuleFetchEnabled,
    CampusDataModule.campusCard => StorageKeys.campusCardModuleFetchEnabled,
    CampusDataModule.email => StorageKeys.emailModuleFetchEnabled,
    CampusDataModule.sportsAttendance =>
      StorageKeys.sportsAttendanceModuleFetchEnabled,
    CampusDataModule.studentReport =>
      StorageKeys.studentReportModuleFetchEnabled,
  };
}

/// 管理模块级联网获取偏好。
class DataModulePreferences {
  DataModulePreferences._();

  /// 全局共享实例。
  static final DataModulePreferences instance = DataModulePreferences._();

  final StreamController<CampusDataModule> _changesController =
      StreamController<CampusDataModule>.broadcast();

  /// 模块获取偏好变化，用于已挂载页面立即停止或恢复定时刷新。
  Stream<CampusDataModule> get changes => _changesController.stream;

  /// 未保存偏好时默认允许获取，保持升级用户的既有行为。
  Future<bool> isFetchEnabled(CampusDataModule module) {
    return StorageService.getBool(module.storageKey, defaultValue: true);
  }

  /// 保存模块是否允许联网获取。
  Future<void> setFetchEnabled(CampusDataModule module, bool enabled) async {
    await StorageService.setBool(module.storageKey, enabled);
    _changesController.add(module);
  }

  /// 一次读取全部模块状态，供设置页构建稳定快照。
  Future<Map<CampusDataModule, bool>> readAll() async {
    final result = <CampusDataModule, bool>{};
    for (final module in CampusDataModule.values) {
      result[module] = await isFetchEnabled(module);
    }
    return Map<CampusDataModule, bool>.unmodifiable(result);
  }
}
