/*
 * 课程表任务状态面板 — 承载读取、空与失败恢复的视觉实现
 * @Project : SSPU-AllinOne
 * @File : course_schedule_state_panel.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'course_schedule_page.dart';

class _ScheduleStatePanel extends StatelessWidget {
  const _ScheduleStatePanel({
    this.loading = false,
    this.symbol,
    required this.statusLabel,
    required this.title,
    required this.message,
    required this.contextLabel,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.onCalendar,
  });

  final bool loading;
  final String? symbol;
  final String statusLabel;
  final String title;
  final String message;
  final String contextLabel;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onCalendar;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final effectiveAccent = theme.color.serviceSchedule;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final compact = viewportWidth < theme.breakpoint.medium;
    final compactActionMinWidth =
        (viewportWidth -
            theme.spacing.m * 2 -
            theme.spacing.l * 2 -
            theme.spacing.s -
            theme.spacing.xs) /
        2;
    return YhCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: compact
              ? theme.control.regular * 6 + theme.spacing.xl
              : theme.control.regular * 8,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                Semantics(
                  label: title,
                  value: '加载中',
                  child: SizedBox.square(
                    dimension: theme.control.minimumTarget,
                    child: CustomPaint(
                      painter: _ScheduleSpinnerPainter(
                        trackColor: theme.color.border,
                        activeColor: effectiveAccent,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: theme.layout.bottomNavigationHeight,
                  height: theme.layout.bottomNavigationHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: effectiveAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(theme.radius.l),
                  ),
                  child: Text(
                    symbol ?? '→',
                    style: theme.typography.display.copyWith(
                      color: effectiveAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              SizedBox(height: theme.spacing.l),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.color.brandTint,
                  borderRadius: BorderRadius.circular(theme.radius.full),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.s,
                    vertical: theme.spacing.xs,
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.typography.caption.copyWith(
                      color: effectiveAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: theme.spacing.s),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.typography.h2,
                ),
              ),
              SizedBox(height: theme.spacing.s),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: theme.control.regular * 11,
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.typography.body.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ),
              SizedBox(height: theme.spacing.m),
              Text(
                contextLabel,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
              if (!loading &&
                  primaryActionLabel != null &&
                  onPrimaryAction != null &&
                  onCalendar != null) ...[
                SizedBox(height: theme.spacing.l),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: theme.spacing.s,
                  runSpacing: theme.spacing.s,
                  children: [
                    YhButton(
                      key: const Key('schedule-state-calendar'),
                      label: '查看校历',
                      minWidth: compact ? compactActionMinWidth : null,
                      variant: YhButtonVariant.secondary,
                      onTap: onCalendar,
                    ),
                    YhButton(
                      key: const Key('schedule-state-primary'),
                      label: primaryActionLabel!,
                      minWidth: compact ? compactActionMinWidth : null,
                      onTap: onPrimaryAction,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleSpinnerPainter extends CustomPainter {
  const _ScheduleSpinnerPainter({
    required this.trackColor,
    required this.activeColor,
  });

  final Color trackColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide / 12;
    final bounds = Offset.zero & size;
    final arcBounds = bounds.deflate(strokeWidth / 2);
    canvas.drawCircle(
      bounds.center,
      (size.shortestSide - strokeWidth) / 2,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawArc(
      arcBounds,
      -math.pi / 2,
      math.pi * 0.72,
      false,
      Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _ScheduleSpinnerPainter oldDelegate) {
    return trackColor != oldDelegate.trackColor ||
        activeColor != oldDelegate.activeColor;
  }
}
