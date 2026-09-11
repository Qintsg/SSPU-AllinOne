/* 快捷入口可用性筛选 — 集中处理平台白名单与 App 安装检测。 */

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'quick_links_config_service.dart';

typedef QuickLinkCanLaunch = Future<bool> Function(Uri uri);

/// 过滤当前设备上实际可用的快捷入口。
class QuickLinksAvailabilityService {
  QuickLinksAvailabilityService._();

  /// 从 Flutter 运行时映射快捷入口配置使用的平台名。
  static QuickLinkPlatform get currentPlatform {
    if (kIsWeb) return QuickLinkPlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => QuickLinkPlatform.android,
      TargetPlatform.iOS => QuickLinkPlatform.ios,
      TargetPlatform.windows => QuickLinkPlatform.windows,
      TargetPlatform.macOS => QuickLinkPlatform.macos,
      TargetPlatform.linux => QuickLinkPlatform.linux,
      TargetPlatform.fuchsia => QuickLinkPlatform.web,
    };
  }

  /// 按当前运行平台与系统链接能力筛选分组。
  static Future<List<QuickLinkGroupConfig>> filterCurrentGroups(
    List<QuickLinkGroupConfig> groups,
  ) => filterGroups(groups, platform: currentPlatform, canLaunch: canLaunchUrl);

  /// 按目标平台和 App 安装情况筛选分组，并移除空分组。
  static Future<List<QuickLinkGroupConfig>> filterGroups(
    List<QuickLinkGroupConfig> groups, {
    required QuickLinkPlatform platform,
    required QuickLinkCanLaunch canLaunch,
  }) async {
    final filteredGroups = <QuickLinkGroupConfig>[];
    for (final group in groups) {
      final visibleItems = <QuickLinkItemConfig>[];
      for (final item in group.items) {
        if (!item.supportsPlatform(platform)) continue;
        if (item.kind == QuickLinkKind.app) {
          final uri = Uri.tryParse(item.url);
          if (uri == null || uri.scheme.isEmpty) {
            continue;
          }
          try {
            if (!await canLaunch(uri)) continue;
          } catch (_) {
            continue;
          }
        }
        visibleItems.add(item);
      }
      if (visibleItems.isEmpty) continue;
      filteredGroups.add(
        QuickLinkGroupConfig(
          category: group.category,
          items: List.unmodifiable(visibleItems),
        ),
      );
    }
    return List.unmodifiable(filteredGroups);
  }
}
