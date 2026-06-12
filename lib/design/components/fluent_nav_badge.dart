/*
 * Fluent 导航徽标 — 导航项与按钮上的轻量数量提示
 * @Project : SSPU-AllinOne
 * @File : fluent_nav_badge.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:fluent_ui/fluent_ui.dart';

import '../fluent/fluent_context_ext.dart';

/// 导航徽标。
class FluentNavBadge extends StatelessWidget {
  const FluentNavBadge({
    super.key,
    this.count,
    this.label,
    this.showDot = false,
  }) : assert(count != null || label != null || showDot);

  /// 数量。
  final int? count;

  /// 自定义文案。
  final String? label;

  /// 是否只展示圆点。
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final type = context.fluentType;
    final text =
        label ??
        (count == null
            ? ''
            : count! > 99
            ? '99+'
            : '$count');

    if (showDot && text.isEmpty) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: colors.statusDangerForeground,
          borderRadius: BorderRadius.circular(radii.circular),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.statusDangerForeground,
        borderRadius: BorderRadius.circular(radii.circular),
      ),
      child: Text(
        text,
        style: type.caption2Strong.copyWith(
          color: colors.neutralForegroundOnBrand,
        ),
      ),
    );
  }
}
