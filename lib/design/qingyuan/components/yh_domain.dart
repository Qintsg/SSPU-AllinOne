/* 清源校园域组件。 */

import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';
import 'yh_card.dart';
import 'yh_data_display.dart';
import 'yh_progress.dart';

class YhTodayCard extends StatelessWidget {
  const YhTodayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.typography.h2.copyWith(color: theme.color.foreground),
          ),
          Text(
            subtitle,
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          child,
        ],
      ),
    );
  }
}

class YhCourseBlock extends StatelessWidget {
  const YhCourseBlock({
    super.key,
    required this.name,
    required this.time,
    this.location,
    this.color,
    this.ongoing = false,
    this.conflict = false,
    this.onTap,
  });

  final String name;
  final String time;
  final String? location;
  final Color? color;
  final bool ongoing;
  final bool conflict;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = color ?? theme.color.serviceSchedule;
    final base = conflict ? theme.color.danger : accent;
    final background = conflict
        ? theme.color.dangerTint
        : Color.alphaBlend(base.withValues(alpha: 0.13), theme.color.surface);
    final foreground = conflict ? theme.color.danger : base;
    final semanticLabel = [
      name,
      time,
      if (location?.trim().isNotEmpty == true) location!.trim(),
      if (ongoing) '进行中',
      if (conflict) '时间冲突',
    ].join('，');

    Widget surface({bool hovered = false}) => AnimatedContainer(
      duration: theme.motion.fast,
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m - theme.spacing.xs,
        vertical: theme.spacing.s + theme.spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: hovered
            ? Color.alphaBlend(base.withValues(alpha: 0.06), background)
            : background,
        border: ongoing || conflict
            ? Border.all(color: foreground, width: theme.layout.controlBorder)
            : null,
        borderRadius: BorderRadius.circular(theme.radius.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.small.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.caption.copyWith(
              color: foreground.withValues(alpha: 0.85),
            ),
          ),
          if (location?.trim().isNotEmpty == true)
            Text(
              location!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.caption.copyWith(
                color: foreground.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(container: true, label: semanticLabel, child: surface());
    }
    return YhPressable(
      semanticLabel: semanticLabel,
      onPressed: onTap,
      builder: (context, state, child) => surface(hovered: state.hovered),
      child: const SizedBox.shrink(),
    );
  }
}

enum YhMessageRole { user, assistant }

class YhAiMessage extends StatelessWidget {
  const YhAiMessage({
    super.key,
    required this.message,
    required this.role,
    this.pending = false,
  });

  final String message;
  final YhMessageRole role;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final user = role == YhMessageRole.user;
    return Semantics(
      label: '${user ? '我' : '清源助手'}：$message',
      child: Align(
        alignment: user
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: user ? theme.color.brandStrong : theme.color.surface,
            border: user ? null : Border.all(color: theme.color.border),
            borderRadius: BorderRadius.circular(theme.radius.m),
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.m),
            child: pending
                ? YhProgress(showPercent: false, semanticLabel: '正在生成回复')
                : Text(
                    message,
                    style: theme.typography.body.copyWith(
                      color: user
                          ? theme.color.onBrand
                          : theme.color.foreground,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class YhBalanceModule extends StatelessWidget {
  const YhBalanceModule({
    super.key,
    required this.label,
    required this.balance,
    this.caption,
    this.onTap,
  });

  final String label;
  final String balance;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => YhMetricCard(
    label: label,
    value: balance,
    caption: caption,
    onTap: onTap,
  );
}

class YhAttendanceItem extends StatelessWidget {
  const YhAttendanceItem({
    super.key,
    required this.title,
    required this.detail,
    required this.status,
    this.kind = YhStatusKind.neutral,
  });

  final String title;
  final String detail;
  final String status;
  final YhStatusKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  detail,
                  style: theme.typography.small.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: theme.spacing.m),
          YhStatusPill(label: status, kind: kind),
        ],
      ),
    );
  }
}
