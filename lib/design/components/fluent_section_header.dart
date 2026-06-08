/*
 * Fluent 2 分区标题 — 图标 / 标题 / 说明 / 右侧操作的横向排列
 * @Project : SSPU-AllinOne
 * @File : fluent_section_header.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

import '../fluent/fluent_context_ext.dart';
import 'fluent_surface.dart';

/// Fluent 2 页面分区标题。
class FluentSectionHeader extends StatelessWidget {
  const FluentSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.action,
  });

  /// 标题文本。
  final String title;

  /// 说明文本。
  final String? subtitle;

  /// 左侧图标。
  final IconData? icon;

  /// 图标强调色。
  final Color? accentColor;

  /// 右侧操作组件。
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final spacing = context.fluentSpacing;
    final type = context.fluentType;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          FluentSurfaceIcon(icon: icon!, color: accentColor),
          SizedBox(width: spacing.m),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: type.subtitle2.copyWith(
                    color: colors.neutralForeground1,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: spacing.xxs),
                Text(
                  subtitle!,
                  style: type.caption1.copyWith(
                    color: colors.neutralForeground3,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          SizedBox(width: spacing.m),
          action!,
        ],
      ],
    );
  }
}
