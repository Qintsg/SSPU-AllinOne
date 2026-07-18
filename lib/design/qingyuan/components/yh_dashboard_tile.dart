/* 清源仪表盘磁贴 — 首页业务状态与内容的统一承载。 */

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';
import 'yh_card.dart';

enum YhDataState {
  ready('已就绪'),
  loading('加载中'),
  degraded('待更新'),
  notConfigured('待配置'),
  failed('异常');

  const YhDataState(this.label);
  final String label;
}

class YhDashboardTile extends StatelessWidget {
  const YhDashboardTile({
    super.key,
    required this.title,
    required this.icon,
    required this.state,
    required this.child,
    this.subtitle,
    this.accentColor,
    this.actions = const <Widget>[],
    this.footer,
    this.onTap,
    this.minHeight,
    this.semanticLabel,
  });

  final String title;
  final IconData icon;
  final YhDataState state;
  final Widget child;
  final String? subtitle;
  final Color? accentColor;
  final List<Widget> actions;
  final Widget? footer;
  final VoidCallback? onTap;
  final double? minHeight;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = accentColor ?? theme.color.brandStrong;
    return YhCard(
      onTap: onTap,
      semanticLabel: semanticLabel ?? title,
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              minHeight ?? theme.breakpoint.compact / 3 + theme.spacing.m,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(theme.radius.m),
          child: Stack(
            children: [
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: theme.spacing.xs,
                  child: ColoredBox(color: accent),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(theme.spacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(theme.radius.s),
                          ),
                          child: SizedBox.square(
                            dimension: theme.control.compact,
                            child: Icon(icon, color: accent),
                          ),
                        ),
                        SizedBox(width: theme.spacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: theme.typography.h3,
                                    ),
                                  ),
                                  _YhStateBadge(state: state),
                                ],
                              ),
                              if (subtitle?.trim().isNotEmpty == true) ...[
                                SizedBox(height: theme.spacing.xs),
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.typography.caption.copyWith(
                                    color: theme.color.muted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (actions.isNotEmpty) ...[
                          SizedBox(width: theme.spacing.s),
                          Wrap(
                            spacing: theme.spacing.xs,
                            runSpacing: theme.spacing.xs,
                            alignment: WrapAlignment.end,
                            children: actions,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: theme.spacing.l),
                    Align(
                      alignment: AlignmentDirectional.topStart,
                      child: child,
                    ),
                    if (footer != null) ...[
                      SizedBox(height: theme.spacing.m),
                      footer!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YhStateBadge extends StatelessWidget {
  const _YhStateBadge({required this.state});
  final YhDataState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final colors = switch (state) {
      YhDataState.ready => (theme.color.successTint, theme.color.success),
      YhDataState.loading => (theme.color.brandTint, theme.color.brandInk),
      YhDataState.degraded || YhDataState.notConfigured => (
        theme.color.warningTint,
        theme.color.warning,
      ),
      YhDataState.failed => (theme.color.dangerTint, theme.color.danger),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(theme.radius.full),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.s,
          vertical: theme.spacing.xs,
        ),
        child: Text(
          state.label,
          style: theme.typography.caption.copyWith(
            color: colors.$2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
