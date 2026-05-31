/*
 * Fluent 2 状态标签 — 统一轻量状态与能力标记视觉
 * @Project : SSPU-AllinOne
 * @File : fluent_status_chip.dart
 * @Author : Qintsg
 * @Date : 2026-05-31
 */

import 'package:flutter/material.dart';

import '../fluent/fluent_context_ext.dart';
import '../fluent/tokens/fluent_color_tokens.dart';

/// 状态标签色调。
enum FluentStatusChipTone {
  /// 中性信息。
  neutral,

  /// 品牌强调。
  brand,

  /// 成功状态。
  success,

  /// 警示状态。
  warning,

  /// 错误或风险状态。
  danger,
}

/// Fluent 2 轻量状态标签。
class FluentStatusChip extends StatelessWidget {
  const FluentStatusChip({
    super.key,
    required this.label,
    this.tone = FluentStatusChipTone.neutral,
    this.icon,
    this.semanticLabel,
  });

  /// 标签文字。
  final String label;

  /// 标签色调。
  final FluentStatusChipTone tone;

  /// 可选前置图标。
  final IconData? icon;

  /// 无障碍语义标签。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final stroke = context.fluentStroke;
    final type = context.fluentType;
    final visual = _resolveVisual(colors, tone);

    return Semantics(
      label: semanticLabel ?? label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.m,
          vertical: spacing.xs,
        ),
        decoration: BoxDecoration(
          color: visual.background,
          borderRadius: BorderRadius.circular(radii.circular),
          border: Border.all(color: visual.border, width: stroke.thin),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: visual.foreground),
              SizedBox(width: spacing.xs),
            ],
            Text(
              label,
              style: type.caption1Strong.copyWith(color: visual.foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChipVisual {
  const _StatusChipVisual({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}

/// 根据色调解析状态标签的前景、背景与描边。
_StatusChipVisual _resolveVisual(
  FluentColors colors,
  FluentStatusChipTone tone,
) {
  return switch (tone) {
    FluentStatusChipTone.neutral => _StatusChipVisual(
      foreground: colors.neutralForeground2,
      background: colors.neutralBackground2,
      border: colors.neutralStroke2,
    ),
    FluentStatusChipTone.brand => _StatusChipVisual(
      foreground: colors.brandForeground1,
      background: colors.brandStroke2.withValues(alpha: 0.22),
      border: colors.brandStroke2,
    ),
    FluentStatusChipTone.success => _StatusChipVisual(
      foreground: colors.statusSuccessForeground,
      background: colors.statusSuccessBackground,
      border: colors.statusSuccessForeground.withValues(alpha: 0.28),
    ),
    FluentStatusChipTone.warning => _StatusChipVisual(
      foreground: colors.statusWarningForeground,
      background: colors.statusWarningBackground,
      border: colors.statusWarningForeground.withValues(alpha: 0.28),
    ),
    FluentStatusChipTone.danger => _StatusChipVisual(
      foreground: colors.statusDangerForeground,
      background: colors.statusDangerBackground,
      border: colors.statusDangerForeground.withValues(alpha: 0.28),
    ),
  };
}
