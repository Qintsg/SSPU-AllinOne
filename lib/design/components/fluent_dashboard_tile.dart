/*
 * Fluent 仪表盘磁贴 — 首页业务卡片统一结构
 * @Project : SSPU-AllinOne
 * @File : fluent_dashboard_tile.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

import '../fluent/fluent_context_ext.dart';
import 'fluent_card.dart';
import 'fluent_data_state.dart';
import 'fluent_status_chip.dart';

/// 首页仪表盘业务磁贴。
class FluentDashboardTile extends StatelessWidget {
  const FluentDashboardTile({
    super.key,
    required this.title,
    required this.icon,
    required this.state,
    required this.child,
    this.subtitle,
    this.accentColor,
    this.actions,
    this.footer,
    this.onPressed,
    this.minHeight,
    this.semanticLabel,
  });

  /// 标题。
  final String title;

  /// 标题图标。
  final IconData icon;

  /// 数据状态。
  final FluentDataState state;

  /// 主体。
  final Widget child;

  /// 副标题。
  final String? subtitle;

  /// 业务强调色。
  final Color? accentColor;

  /// 标题右侧动作。
  final List<Widget>? actions;

  /// 底部内容。
  final Widget? footer;

  /// 点击磁贴回调。
  final VoidCallback? onPressed;

  /// 最小高度。
  final double? minHeight;

  /// 无障碍语义。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final type = context.fluentType;
    final accent = accentColor ?? colors.brandForeground1;

    return FluentCard(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? title,
      padding: EdgeInsets.zero,
      minHeight: minHeight ?? context.appMetrics.dashboardTileMinHeight,
      bordered: true,
      child: ClipRRect(
        borderRadius: radii.largeBorder,
        child: Stack(
          children: [
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: accent),
            ),
            Padding(
              padding: EdgeInsets.all(spacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: radii.mediumBorder,
                        ),
                        child: Icon(icon, color: accent, size: 20),
                      ),
                      SizedBox(width: spacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: type.subtitle2.copyWith(
                                      color: colors.neutralForeground1,
                                    ),
                                  ),
                                ),
                                _StateChip(state: state),
                              ],
                            ),
                            if (subtitle != null &&
                                subtitle!.trim().isNotEmpty) ...[
                              SizedBox(height: spacing.xs),
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: type.caption1.copyWith(
                                  color: colors.neutralForeground3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (actions != null && actions!.isNotEmpty) ...[
                        SizedBox(width: spacing.s),
                        Wrap(
                          spacing: spacing.xs,
                          runSpacing: spacing.xs,
                          alignment: WrapAlignment.end,
                          children: actions!,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: spacing.l),
                  Align(alignment: AlignmentDirectional.topStart, child: child),
                  if (footer != null) ...[SizedBox(height: spacing.m), footer!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final FluentDataState state;

  @override
  Widget build(BuildContext context) {
    final tone = switch (state) {
      FluentDataState.ready => FluentStatusChipTone.success,
      FluentDataState.loading => FluentStatusChipTone.brand,
      FluentDataState.degraded ||
      FluentDataState.notConfigured => FluentStatusChipTone.warning,
      FluentDataState.failed => FluentStatusChipTone.danger,
    };
    return FluentStatusChip(label: state.label, tone: tone);
  }
}
