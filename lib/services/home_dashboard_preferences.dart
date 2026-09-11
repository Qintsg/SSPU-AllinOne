/*
 * 首页布局偏好 — 管理服务摘要的稳定标识、顺序与持久化
 * @Project : SSPU-AllinOne
 * @File : home_dashboard_preferences.dart
 * @Author : Qintsg
 * @Date : 2026-09-08
 */

import 'storage_service.dart';

/// 首页右侧或紧凑端网格中的可排序服务摘要。
enum HomeOverviewItem {
  trainingPlan('training-plan'),
  campusCard('campus-card'),
  email('email'),
  sportsAttendance('sports-attendance');

  const HomeOverviewItem(this.storageId);

  /// 跨版本持久化使用的稳定标识。
  final String storageId;

  /// 从持久化标识恢复摘要类型；未知值安全忽略。
  static HomeOverviewItem? fromStorageId(String value) {
    for (final item in values) {
      if (item.storageId == value) return item;
    }
    return null;
  }
}

/// 首页服务摘要排序偏好。
class HomeDashboardPreferences {
  HomeDashboardPreferences._();

  /// 全局共享实例。
  static final HomeDashboardPreferences instance = HomeDashboardPreferences._();

  /// 新安装与旧版本升级后的默认摘要顺序。
  static const List<HomeOverviewItem> defaultOverviewOrder = [
    HomeOverviewItem.trainingPlan,
    HomeOverviewItem.campusCard,
    HomeOverviewItem.email,
    HomeOverviewItem.sportsAttendance,
  ];

  /// 读取并修复首页服务摘要顺序。
  ///
  /// 未知项、重复项会被移除；升级后新增的摘要会追加到末尾。
  Future<List<HomeOverviewItem>> getOverviewOrder() async {
    final stored = await StorageService.getStringList(
      StorageKeys.homeOverviewOrder,
    );
    return normalizeOverviewOrder(stored);
  }

  /// 保存完整的首页服务摘要顺序。
  Future<void> setOverviewOrder(List<HomeOverviewItem> order) async {
    final normalized = normalizeOverviewItems(order);
    await StorageService.setStringList(
      StorageKeys.homeOverviewOrder,
      normalized.map((item) => item.storageId).toList(),
    );
  }

  /// 将持久化字符串归一化为完整、唯一的摘要顺序。
  static List<HomeOverviewItem> normalizeOverviewOrder(
    Iterable<String> stored,
  ) {
    return normalizeOverviewItems(
      stored.map(HomeOverviewItem.fromStorageId).whereType<HomeOverviewItem>(),
    );
  }

  /// 将摘要列表归一化为完整、唯一的顺序。
  static List<HomeOverviewItem> normalizeOverviewItems(
    Iterable<HomeOverviewItem> items,
  ) {
    final normalized = <HomeOverviewItem>[];
    for (final item in items) {
      if (!normalized.contains(item)) normalized.add(item);
    }
    for (final item in defaultOverviewOrder) {
      if (!normalized.contains(item)) normalized.add(item);
    }
    return List<HomeOverviewItem>.unmodifiable(normalized);
  }
}
