/*
 * 清源首页专属视图部件 — 概览行、快捷操作与时间轨绘制
 * @Project : SSPU-AllinOne
 * @File : home_dashboard_widgets.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

part of 'home_page.dart';

class _HomeOverviewCard extends StatelessWidget {
  const _HomeOverviewCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.value,
    this.onTap,
    this.embedded = true,
    this.compact = false,
    this.valueColor,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String value;
  final VoidCallback? onTap;
  final bool embedded;
  final bool compact;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final dense =
        compact || MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    final iconSize = dense
        ? theme.spacing.xl
        : theme.control.regular - theme.spacing.xs;
    final row = Padding(
      padding: embedded
          ? EdgeInsets.symmetric(
              horizontal: dense ? theme.spacing.s : theme.spacing.m,
              vertical: theme.spacing.xs,
            )
          : EdgeInsets.zero,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                color.withValues(alpha: theme.opacity.domainTint),
                theme.color.surface,
              ),
              borderRadius: BorderRadius.circular(theme.radius.input),
            ),
            child: SizedBox.square(
              dimension: iconSize,
              child: Icon(
                icon,
                size: dense ? theme.spacing.m : theme.spacing.l,
                color: color,
              ),
            ),
          ),
          SizedBox(width: dense ? theme.spacing.s : theme.spacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: compact && !embedded ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (dense ? theme.typography.small : theme.typography.body)
                          .copyWith(fontWeight: theme.typography.semibold),
                ),
                if (!dense) ...[
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: dense ? theme.layout.divider * 2 : theme.spacing.m),
          Text(
            value,
            style: (dense ? theme.typography.small : theme.typography.body)
                .copyWith(
                  fontFamily: YhTypographyTokens.fontFamilyMono,
                  fontWeight: theme.typography.semibold,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
    if (!embedded) {
      return YhCard(
        semanticLabel: '$title，$detail，$value',
        onTap: onTap,
        padding: EdgeInsets.all(dense ? theme.spacing.s : theme.spacing.l),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: theme.control.regular),
          child: row,
        ),
      );
    }
    if (onTap == null) {
      return Semantics(
        label: '$title，$detail，$value',
        container: true,
        child: row,
      );
    }
    return YhPressable(
      semanticLabel: '$title，$detail，$value',
      onPressed: onTap,
      builder: (context, state, child) => ColoredBox(
        color: state.hovered ? theme.color.brandTint : theme.color.surface,
        child: child,
      ),
      child: row,
    );
  }
}

class _HomeQuickAction extends StatelessWidget {
  const _HomeQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.compact,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = theme.motion.effective(
      theme.motion.fast,
      disableAnimations: disableAnimations,
    );
    final child = compact
        ? Icon(icon, size: theme.spacing.l, color: theme.color.foreground)
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.spacing.s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: theme.spacing.l - theme.spacing.xs,
                  color: theme.color.foreground,
                ),
                SizedBox(width: theme.spacing.s),
                Text(
                  label,
                  style: theme.typography.small.copyWith(
                    color: theme.color.foreground,
                  ),
                ),
                SizedBox(width: theme.spacing.xs),
                ExcludeSemantics(
                  child: Text(
                    '↗',
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                      fontFamily: YhTypographyTokens.fontFamilyMono,
                    ),
                  ),
                ),
              ],
            ),
          );
    return YhPressable(
      semanticLabel: '$label，外部链接，将打开外部应用',
      hint: '打开前会显示目标网站确认',
      onPressed: onPressed,
      builder: (context, state, child) => AnimatedContainer(
        duration: duration,
        curve: theme.motion.curve,
        constraints: BoxConstraints(minHeight: theme.control.minimumTarget),
        decoration: BoxDecoration(
          color: state.hovered || state.focused || state.pressed
              ? theme.color.brandTint
              : theme.color.surface.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(theme.radius.input),
        ),
        child: child,
      ),
      child: child,
    );
  }
}

class _HomeTimelineEntry {
  const _HomeTimelineEntry({
    required this.time,
    required this.title,
    required this.detail,
    required this.minuteOfDay,
    required this.minutesUntil,
  });

  factory _HomeTimelineEntry.course(
    AcademicCourseTableEntry course,
    DateTime now, {
    String? timeOverride,
  }) {
    final period = CoursePeriodTable.standard.periodOf(course.startUnit);
    final time = timeOverride ?? period?.startTime ?? course.timeText;
    final minuteOfDay = _parseMinuteOfDay(time);
    return _HomeTimelineEntry(
      time: time,
      title: course.courseName,
      detail: course.location?.trim().isNotEmpty == true
          ? course.location!.trim()
          : course.teacher?.trim().isNotEmpty == true
          ? course.teacher!.trim()
          : course.timeText,
      minuteOfDay: minuteOfDay,
      minutesUntil: minuteOfDay - now.hour * 60 - now.minute,
    );
  }

  factory _HomeTimelineEntry.message(MessageItem message, DateTime now) {
    final fallback = DateTime(now.year, now.month, now.day, 16);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      message.timestamp ?? fallback.millisecondsSinceEpoch,
    );
    final minuteOfDay = dateTime.hour * 60 + dateTime.minute;
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
    return _HomeTimelineEntry(
      time: time,
      title: message.title,
      detail: message.title.contains('作业') ? '在教务系统提交' : '在信息中心查看',
      minuteOfDay: minuteOfDay,
      minutesUntil: minuteOfDay - now.hour * 60 - now.minute,
    );
  }

  final String time;
  final String title;
  final String detail;
  final int minuteOfDay;
  final int minutesUntil;

  bool get isUpcoming => minutesUntil >= 0;

  static int _parseMinuteOfDay(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return 0;
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }
}

class _HomeTimelineBackdropPainter extends CustomPainter {
  const _HomeTimelineBackdropPainter(this.theme);

  final YhTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width - theme.spacing.xl2,
      size.height - theme.spacing.xl2,
    );
    final radius = theme.layout.statusProgressWidth / 2;
    final midSpread = theme.spacing.xl + theme.spacing.xs;
    final outerSpread = theme.spacing.xl2 + theme.spacing.l;
    canvas.drawCircle(
      center,
      radius + outerSpread,
      Paint()
        ..color = theme.color.onStructural.withValues(
          alpha: theme.opacity.timelineOrbitOuter,
        ),
    );
    canvas.drawCircle(
      center,
      radius + midSpread,
      Paint()
        ..color = theme.color.onStructural.withValues(
          alpha: theme.opacity.timelineOrbitMid,
        ),
    );
    canvas.drawCircle(center, radius, Paint()..color = theme.color.structural);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = theme.layout.divider
        ..color = theme.color.onStructural.withValues(
          alpha: theme.opacity.timelineOrbit,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _HomeTimelineBackdropPainter oldDelegate) {
    return theme != oldDelegate.theme;
  }
}

class _HomeTimelineRow extends StatelessWidget {
  const _HomeTimelineRow({
    required this.entry,
    required this.current,
    required this.last,
    required this.dense,
  });

  final _HomeTimelineEntry entry;
  final bool current;
  final bool last;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    final trackWidth = compact
        ? theme.spacing.m - theme.layout.divider * 2
        : theme.spacing.m + theme.layout.divider * 2;
    final timeWidth = dense
        ? theme.control.regular + theme.layout.divider * 2
        : theme.control.regular + theme.spacing.s + theme.spacing.xs;
    final rowHeight = compact
        ? theme.control.regular + theme.spacing.xs
        : dense
        ? theme.control.regular
        : theme.control.regular + theme.spacing.s + theme.layout.divider * 2;
    return SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: timeWidth,
            child: Text(
              entry.time,
              style: theme.typography.small.copyWith(
                color: theme.color.onStructural,
                fontFamily: YhTypographyTokens.fontFamilyMono,
                fontWeight: theme.typography.semibold,
              ),
            ),
          ),
          SizedBox(width: compact ? theme.spacing.xs : theme.spacing.s),
          SizedBox(
            width: trackWidth,
            height: rowHeight,
            child: CustomPaint(
              painter: _HomeTimelineTrackPainter(
                current: current,
                last: last,
                theme: theme,
              ),
            ),
          ),
          SizedBox(width: compact ? theme.spacing.xs : theme.spacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.body.copyWith(
                    color: theme.color.onStructural,
                    fontWeight: theme.typography.semibold,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  current ? '${entry.detail} · 当前' : entry.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.onStructural.withValues(
                      alpha: theme.opacity.timelineDetail,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTimelineTrackPainter extends CustomPainter {
  const _HomeTimelineTrackPainter({
    required this.current,
    required this.last,
    required this.theme,
  });

  final bool current;
  final bool last;
  final YhTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, theme.spacing.s);
    if (!last) {
      canvas.drawLine(
        Offset(center.dx, center.dy + theme.spacing.xs),
        Offset(center.dx, size.height),
        Paint()
          ..color = theme.color.onStructural.withValues(
            alpha: theme.opacity.timelineTrack,
          )
          ..strokeWidth = theme.layout.divider,
      );
    }
    if (current) {
      canvas.drawCircle(
        center,
        theme.spacing.s,
        Paint()
          ..color = theme.color.brandTint.withValues(
            alpha: theme.opacity.timelineCurrentRing,
          ),
      );
    }
    final dotRadius = theme.spacing.s - theme.spacing.xs / 2;
    canvas.drawCircle(
      center,
      dotRadius,
      Paint()
        ..color = current
            ? theme.color.brandTint
            : theme.color.onStructural.withValues(
                alpha: theme.opacity.timelineDot,
              ),
    );
    canvas.drawCircle(
      center,
      dotRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = theme.focus.ringWidth
        ..color = theme.color.structural,
    );
  }

  @override
  bool shouldRepaint(covariant _HomeTimelineTrackPainter oldDelegate) {
    return current != oldDelegate.current ||
        last != oldDelegate.last ||
        theme != oldDelegate.theme;
  }
}
