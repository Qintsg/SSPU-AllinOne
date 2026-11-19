/*
 * 清源移动端 Miuix 液态玻璃悬浮导航
 * @Project : SSPU-AllinOne
 * @File : yh_miuix_floating_navigation.dart
 * @Author : Codex
 * @Date : 2026-11-19
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;

import '../components/yh_miuix.dart';
import '../theme/yh_theme.dart';
import 'yh_navigation.dart';

/// 在移动设备上为主导航提供玻璃材质与独立的背景采样。
class YhMiuixFloatingNavigation extends StatefulWidget {
  const YhMiuixFloatingNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
    this.actionIndex,
  });

  /// 仅原生 Android 与 iOS 使用悬浮玻璃导航。
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  final List<YhNavigationItem> items;
  final int selectedIndex;
  final int? actionIndex;
  final ValueChanged<int> onSelected;
  final Widget child;

  @override
  State<YhMiuixFloatingNavigation> createState() =>
      _YhMiuixFloatingNavigationState();
}

class _YhMiuixFloatingNavigationState extends State<YhMiuixFloatingNavigation> {
  final _backdrop = miuix.MiuixLayerBackdrop();

  @override
  void dispose() {
    _backdrop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final media = MediaQuery.of(context);
    final margin = theme.spacing.m;
    final bottom = media.viewPadding.bottom + theme.spacing.s;
    const labelSize = miuix.MiuixGlassNavigationBarDefaults.labelSize;
    final extraHeight = (media.textScaler.scale(labelSize) - labelSize).clamp(
      0.0,
      theme.control.minimumTarget,
    );
    final barHeight = theme.layout.bottomNavigationHeight + extraHeight;
    final keyboardVisible = media.viewInsets.bottom > 0;
    final clearance = keyboardVisible
        ? 0.0
        : bottom + barHeight + theme.spacing.s;

    return Stack(
      fit: StackFit.expand,
      children: [
        miuix.MiuixLayerBackdropCapture(
          backdrop: _backdrop,
          child: ColoredBox(
            color: theme.color.background,
            child: Padding(
              padding: EdgeInsets.only(bottom: clearance),
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: !keyboardVisible,
                child: widget.child,
              ),
            ),
          ),
        ),
        if (!keyboardVisible)
          Positioned(
            bottom: bottom,
            left: margin + media.padding.left,
            right: margin + media.padding.right,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: theme.breakpoint.compact),
                child: YhMiuixTheme(
                  child: miuix.MiuixGlassNavigationBar(
                    key: const Key('mobile-bottom-navigation'),
                    height: barHeight,
                    backdrop: _backdrop,
                    selectedIndex: widget.selectedIndex,
                    onSelect: widget.onSelected,
                    selectedColor: theme.color.brandInk,
                    unselectedColor: theme.color.muted,
                    indicatorColor: theme.color.brandTint,
                    items: [
                      for (final (index, item) in widget.items.indexed)
                        miuix.MiuixGlassNavigationItem(
                          label: item.label,
                          icon: miuix.MiuixIcon(
                            icon: item.icon,
                            tint:
                                index == widget.actionIndex &&
                                    index == widget.selectedIndex
                                ? theme.color.brandInk
                                : null,
                          ),
                          isAction: index == widget.actionIndex,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
