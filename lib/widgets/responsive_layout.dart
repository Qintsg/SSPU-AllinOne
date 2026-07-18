/*
 * 响应式布局工具组件 — 根据清源窗口宽度等级切换布局策略
 * @Project : SSPU-AllinOne
 * @File : responsive_layout.dart
 * @Author : Qintsg
 * @Date : 2026-04-19
 */

import 'package:flutter/widgets.dart';

import '../design/qingyuan/theme/yh_theme.dart';

enum DeviceType { phone, tablet, desktop }

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

/// 根据宽度返回清源设备类型。
DeviceType deviceTypeFromWidth(double width) {
  final breakpoints = YhTheme.light.breakpoint;
  if (width < breakpoints.compact) return DeviceType.phone;
  if (width < breakpoints.expanded) return DeviceType.tablet;
  return DeviceType.desktop;
}

/// 根据设备类型返回页面内容边距。
EdgeInsets responsivePagePadding(DeviceType deviceType, {double vertical = 0}) {
  final horizontal = switch (deviceType) {
    DeviceType.phone => YhTheme.light.spacing.m,
    DeviceType.tablet || DeviceType.desktop => YhTheme.light.spacing.l,
  };
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}

/// 窄屏时是否应将设置行的尾部控件堆叠到下一行。
bool shouldStackSettingsControls(BoxConstraints constraints) {
  return constraints.maxWidth < YhTheme.light.breakpoint.compact;
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
