/*
 * 快捷跳转配置服务 — 从 YAML 资产读取校园站点分组与链接
 * @Project : SSPU-AllinOne
 * @File : quick_links_config_service.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import 'package:flutter/services.dart';

/// 快捷链接的打开方式。
enum QuickLinkKind { web, app, oa }

/// 快捷链接可见的运行平台。
enum QuickLinkPlatform { android, ios, windows, macos, linux, web }

/// 快捷链接条目配置。
class QuickLinkItemConfig {
  /// 页面显示名称。
  final String name;

  /// 外部跳转地址。
  final String url;

  /// 可选图标键名，用于后续通过 YAML 自定义图标。
  final String? icon;

  /// 条目的打开方式；旧配置默认为网页。
  final QuickLinkKind kind;

  /// 可见平台白名单；空集表示全平台。
  final Set<QuickLinkPlatform> platforms;

  /// App 安装标识（Android 包名或 iOS scheme）。
  final String? appId;

  const QuickLinkItemConfig({
    required this.name,
    required this.url,
    this.icon,
    this.kind = QuickLinkKind.web,
    this.platforms = const {},
    this.appId,
  });

  /// 当前条目是否声明支持目标平台。
  bool supportsPlatform(QuickLinkPlatform platform) =>
      platforms.isEmpty || platforms.contains(platform);
}

/// 快捷链接分组配置。
class QuickLinkGroupConfig {
  /// 分组标题。
  final String category;

  /// 分组内链接条目。
  final List<QuickLinkItemConfig> items;

  const QuickLinkGroupConfig({required this.category, required this.items});
}

/// 快捷跳转 YAML 配置服务。
class QuickLinksConfigService {
  QuickLinksConfigService._();

  static final QuickLinksConfigService instance = QuickLinksConfigService._();

  static const String assetPath = 'assets/config/quick_links.yaml';

  /// 从资产文件读取快捷跳转配置。
  Future<List<QuickLinkGroupConfig>> loadGroups() async {
    final yamlText = await rootBundle.loadString(assetPath);
    return parseGroups(yamlText);
  }

  /// 解析当前仓库约定的简单 YAML 结构。
  /// 支持 item 级 `icon` / `kind` / `platforms` / `appId` 字段，
  /// 未知字段会被忽略。
  static List<QuickLinkGroupConfig> parseGroups(String yamlText) {
    final groups = <QuickLinkGroupConfig>[];
    String? currentCategory;
    final currentItems = <QuickLinkItemConfig>[];
    final currentItemFields = <String, String>{};

    void flushItem() {
      final name = currentItemFields['name']?.trim() ?? '';
      final url = currentItemFields['url']?.trim() ?? '';
      final icon = currentItemFields['icon']?.trim();
      final appId = currentItemFields['appId']?.trim();
      if (name.isNotEmpty && url.isNotEmpty) {
        currentItems.add(
          QuickLinkItemConfig(
            name: name,
            url: url,
            icon: icon == null || icon.isEmpty ? null : icon,
            kind: _parseKind(currentItemFields['kind']),
            platforms: _parsePlatforms(currentItemFields['platforms']),
            appId: appId == null || appId.isEmpty ? null : appId,
          ),
        );
      }
      currentItemFields.clear();
    }

    void flushGroup() {
      flushItem();
      if (currentCategory != null && currentItems.isNotEmpty) {
        groups.add(
          QuickLinkGroupConfig(
            category: currentCategory,
            items: List.unmodifiable(currentItems),
          ),
        );
      }
      currentItems.clear();
    }

    for (final rawLine in yamlText.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || line == 'site_groups:') {
        continue;
      }

      if (line.startsWith('- category:')) {
        flushGroup();
        currentCategory = _readValue(line);
        continue;
      }

      if (line == 'items:') continue;

      if (line.startsWith('- name:')) {
        flushItem();
        currentItemFields['name'] = _readValue(line);
        continue;
      }

      if (line.startsWith('url:')) {
        currentItemFields['url'] = _readValue(line);
        continue;
      }

      if (line.startsWith('icon:')) {
        currentItemFields['icon'] = _readValue(line);
        continue;
      }

      if (line.startsWith('kind:')) {
        currentItemFields['kind'] = _readValue(line);
        continue;
      }

      if (line.startsWith('platforms:')) {
        currentItemFields['platforms'] = _readValue(line);
        continue;
      }

      if (line.startsWith('appId:')) {
        currentItemFields['appId'] = _readValue(line);
      }
    }

    flushGroup();
    return List.unmodifiable(groups);
  }

  static String _readValue(String line) {
    final separatorIndex = line.indexOf(':');
    if (separatorIndex < 0 || separatorIndex == line.length - 1) return '';
    final rawValue = line.substring(separatorIndex + 1).trim();
    if (rawValue.length >= 2 &&
        ((rawValue.startsWith('"') && rawValue.endsWith('"')) ||
            (rawValue.startsWith("'") && rawValue.endsWith("'")))) {
      return rawValue.substring(1, rawValue.length - 1);
    }
    return rawValue;
  }

  static QuickLinkKind _parseKind(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'app' => QuickLinkKind.app,
      'oa' => QuickLinkKind.oa,
      _ => QuickLinkKind.web,
    };
  }

  static Set<QuickLinkPlatform> _parsePlatforms(String? value) {
    if (value == null || value.trim().isEmpty) return const {};
    final normalized = value
        .trim()
        .replaceFirst(RegExp(r'^\['), '')
        .replaceFirst(RegExp(r'\]$'), '');
    final platforms = <QuickLinkPlatform>{};
    for (final rawPlatform in normalized.split(',')) {
      final platform = switch (rawPlatform.trim().toLowerCase()) {
        'android' => QuickLinkPlatform.android,
        'ios' => QuickLinkPlatform.ios,
        'windows' => QuickLinkPlatform.windows,
        'macos' => QuickLinkPlatform.macos,
        'linux' => QuickLinkPlatform.linux,
        'web' => QuickLinkPlatform.web,
        _ => null,
      };
      if (platform != null) platforms.add(platform);
    }
    return Set.unmodifiable(platforms);
  }
}
