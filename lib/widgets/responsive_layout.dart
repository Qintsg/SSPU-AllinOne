/*
 * 响应式布局工具组件 — 根据 Fluent 2 窗口宽度等级切换布局策略
 * @Project : SSPU-AllinOne
 * @File : responsive_layout.dart
 * @Author : Qintsg
 * @Date : 2026-04-19
 */

import 'package:flutter/widgets.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_spacing.dart';
import '../theme/fluent_tokens.dart' show DeviceType;

/// 响应式布局构建器。
/// 根据可用宽度自动判断设备类型，回调 [builder] 传入设备类型与约束。
class ResponsiveBuilder extends StatelessWidget {
  /// 布局构建回调。
  final Widget Function(
    BuildContext context,
    DeviceType deviceType,
    BoxConstraints constraints,
  )
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = deviceTypeFromWidth(constraints.maxWidth);
        return builder(context, deviceType, constraints);
      },
    );
  }
}

/// 响应式页面内边距。
class ResponsivePadding extends StatelessWidget {
  /// 子组件。
  final Widget child;

  const ResponsivePadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, constraints) {
        final padding = responsivePagePadding(deviceType);
        return Padding(padding: padding, child: child);
      },
    );
  }
}

/// 根据宽度返回 Fluent 2 设备类型。
DeviceType deviceTypeFromWidth(double width) {
  return switch (AppBreakpoints.fromWidth(width)) {
    WindowSizeClass.compact => DeviceType.phone,
    WindowSizeClass.medium || WindowSizeClass.expanded => DeviceType.tablet,
    WindowSizeClass.large || WindowSizeClass.extraLarge => DeviceType.desktop,
  };
}

/// 根据设备类型返回页面内容边距。
EdgeInsets responsivePagePadding(DeviceType deviceType, {double vertical = 0}) {
  final horizontal = switch (deviceType) {
    DeviceType.phone => AppSpacing.md,
    DeviceType.tablet => AppSpacing.lg,
    DeviceType.desktop => AppSpacing.lg,
  };
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}

/// 窄屏时是否应将设置行的尾部控件堆叠到下一行。
bool shouldStackSettingsControls(BoxConstraints constraints) {
  return AppBreakpoints.fromWidth(constraints.maxWidth) ==
      WindowSizeClass.compact;
}

/// 响应式网格列数 — 根据设备类型返回合适的列数。
int responsiveGridColumns(
  DeviceType deviceType, {
  int phoneCols = 2,
  int tabletCols = 3,
  int desktopCols = 4,
}) {
  return switch (deviceType) {
    DeviceType.phone => phoneCols,
    DeviceType.tablet => tabletCols,
    DeviceType.desktop => desktopCols,
  };
}
