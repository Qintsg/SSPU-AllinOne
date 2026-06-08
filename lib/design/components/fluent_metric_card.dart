/*
 * Fluent 2 指标卡片 — 用于校园业务数据摘要
 * @Project : SSPU-AllinOne
 * @File : fluent_metric_card.dart
 * @Author : Qintsg
 * @Date : 2026-05-31
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

import '../fluent/fluent_context_ext.dart';
import '../fluent/tokens/fluent_color_tokens.dart';
import 'fluent_card.dart';
import 'fluent_status_chip.dart';

/// Fluent 2 指标卡片。
class FluentMetricCard extends StatelessWidget {
  const FluentMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    this.description,
    this.icon,
    this.tone = FluentStatusChipTone.brand,
    this.onPressed,
    this.semanticLabel,
  });

  /// 指标标签。
  final String label;

  /// 指标数值。
  final String value;

  /// 数值后缀，例如“次”“项”。
  final String? suffix;

  /// 辅助说明。
  final String? description;

  /// 视觉锚点图标。
  final IconData? icon;

  /// 指标色调。
  final FluentStatusChipTone tone;

  /// 点击回调；非空时指标卡片可聚焦并可键盘激活。
  final VoidCallback? onPressed;

  /// 无障碍语义标签。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final type = context.fluentType;
    final visual = _resolveMetricVisual(colors, tone);
    final labelStyle = type.caption1Strong.copyWith(
      color: colors.neutralForeground2,
    );

    return FluentCard(
      elevated: false,
      bordered: true,
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? '$label $value${suffix ?? ''}',
      padding: EdgeInsets.all(spacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: visual.background,
                    borderRadius: radii.mediumBorder,
                  ),
                  child: Icon(icon, size: 18, color: visual.foreground),
                ),
                SizedBox(width: spacing.s),
              ],
              Expanded(child: Text(label, style: labelStyle)),
            ],
          ),
          SizedBox(height: spacing.s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.title1.copyWith(
                    color: visual.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (suffix != null && suffix!.isNotEmpty) ...[
                SizedBox(width: spacing.xs),
                Padding(
                  padding: EdgeInsets.only(bottom: spacing.xxs),
                  child: Text(
                    suffix!,
                    style: type.body1Strong.copyWith(
                      color: colors.neutralForeground1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (description != null && description!.isNotEmpty) ...[
            SizedBox(height: spacing.xs),
            Text(
              description!,
              style: type.caption1.copyWith(color: colors.neutralForeground3),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricVisual {
  const _MetricVisual({required this.foreground, required this.background});

  final Color foreground;
  final Color background;
}

/// 根据指标色调解析指标卡片的强调色。
_MetricVisual _resolveMetricVisual(
  FluentColors colors,
  FluentStatusChipTone tone,
) {
  return switch (tone) {
    FluentStatusChipTone.neutral => _MetricVisual(
      foreground: colors.neutralForeground2,
      background: colors.neutralBackground2,
    ),
    FluentStatusChipTone.brand => _MetricVisual(
      foreground: colors.brandForeground1,
      background: colors.brandStroke2.withValues(alpha: 0.22),
    ),
    FluentStatusChipTone.success => _MetricVisual(
      foreground: colors.statusSuccessForeground,
      background: colors.statusSuccessBackground,
    ),
    FluentStatusChipTone.warning => _MetricVisual(
      foreground: colors.statusWarningForeground,
      background: colors.statusWarningBackground,
    ),
    FluentStatusChipTone.danger => _MetricVisual(
      foreground: colors.statusDangerForeground,
      background: colors.statusDangerBackground,
    ),
  };
}
