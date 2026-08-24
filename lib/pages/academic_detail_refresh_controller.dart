/* 教务详情刷新展示协调 — 单飞、旧内容保留与页面销毁隔离。 */

// Public named parameters initialize private strategy fields for a small seam.
// ignore_for_file: prefer_initializing_formals

part of 'academic_page.dart';

typedef AcademicDetailRefreshTask<T> = RetainedRefreshTask<T>;
typedef AcademicDetailRefreshController<T> = RetainedRefreshController<T>;

class _AcademicDetailStateCard extends StatelessWidget {
  const _AcademicDetailStateCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final stateCard = YhCard(
      padding: EdgeInsets.all(compact ? theme.spacing.s : theme.spacing.m),
      child: child,
    );
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: compact ? double.infinity : theme.layout.formContentWidth,
        ),
        child: disableAnimations
            ? stateCard
            : AnimatedSize(
                duration: theme.motion.base,
                curve: theme.motion.curve,
                child: stateCard,
              ),
      ),
    );
  }
}

class _AcademicDetailLoadingState extends StatelessWidget {
  const _AcademicDetailLoadingState({
    required this.title,
    required this.source,
  });

  final String title;
  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: title,
          value: '加载中',
          child: SizedBox.square(
            dimension: theme.control.minimumTarget,
            child: CustomPaint(
              painter: _AcademicDetailSpinnerPainter(
                trackColor: theme.color.border,
                activeColor: theme.color.brandStrong,
              ),
            ),
          ),
        ),
        SizedBox(width: theme.spacing.m),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.typography.h2),
              SizedBox(height: theme.spacing.xs),
              Text(
                '正在从$source恢复数据；页面来源和返回路径保持可用。',
                style: theme.typography.body.copyWith(color: theme.color.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AcademicDetailMessageState extends StatelessWidget {
  const _AcademicDetailMessageState({
    required this.symbol,
    required this.title,
    required this.message,
    required this.accent,
    required this.actionLabel,
    required this.onAction,
  });

  final String symbol;
  final String title;
  final String message;
  final Color accent;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    final marker = Container(
      width: theme.control.minimumTarget,
      height: theme.control.minimumTarget,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Text(
        symbol,
        style: theme.typography.h2.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final copy = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.typography.h2),
        SizedBox(height: theme.spacing.xs),
        Text(
          message,
          style: theme.typography.body.copyWith(color: theme.color.muted),
        ),
      ],
    );
    final action = YhButton(
      label: actionLabel,
      variant: YhButtonVariant.secondary,
      onTap: onAction,
    );
    if (!compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          marker,
          SizedBox(width: theme.spacing.m),
          Expanded(child: copy),
          SizedBox(width: theme.spacing.m),
          action,
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            marker,
            SizedBox(width: theme.spacing.m),
            Expanded(child: copy),
          ],
        ),
        SizedBox(height: theme.spacing.s),
        action,
      ],
    );
  }
}

class _AcademicDetailSpinnerPainter extends CustomPainter {
  const _AcademicDetailSpinnerPainter({
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
  bool shouldRepaint(covariant _AcademicDetailSpinnerPainter oldDelegate) {
    return trackColor != oldDelegate.trackColor ||
        activeColor != oldDelegate.activeColor;
  }
}

Future<void> _showAcademicDetailFailure(
  BuildContext context, {
  required String title,
  required String message,
  required String detail,
}) {
  return YhDialog.show<void>(
    context,
    builder: (dialogContext) => YhDialog(
      eyebrow: '最近一次读取',
      title: title,
      content: Text('$message：$detail'),
      actions: [
        YhButton(
          label: '关闭',
          variant: YhButtonVariant.secondary,
          onTap: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}
