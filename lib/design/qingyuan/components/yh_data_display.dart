/* 清源数据展示组件。 */

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';
import 'yh_card.dart';

enum YhStatusKind { neutral, success, warning, danger, info }

class YhBadge extends StatelessWidget {
  const YhBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color ?? theme.color.danger,
          borderRadius: BorderRadius.circular(theme.radius.full),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.s,
            vertical: theme.spacing.xs,
          ),
          child: Text(
            label,
            style: theme.typography.caption.copyWith(
              color: theme.color.onBrand,
            ),
          ),
        ),
      ),
    );
  }
}

class YhStatusPill extends StatelessWidget {
  const YhStatusPill({
    super.key,
    required this.label,
    this.kind = YhStatusKind.neutral,
  });

  final String label;
  final YhStatusKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final (foreground, background, indicator) = switch (kind) {
      YhStatusKind.success => (
        theme.color.success,
        theme.color.successTint,
        theme.color.success,
      ),
      YhStatusKind.warning => (
        theme.color.warning,
        theme.color.warningTint,
        theme.color.warning,
      ),
      YhStatusKind.danger => (
        theme.color.danger,
        theme.color.dangerTint,
        theme.color.danger,
      ),
      YhStatusKind.info => (
        theme.color.brandStrong,
        theme.color.brandTint,
        theme.color.brandStrong,
      ),
      YhStatusKind.neutral => (
        theme.color.foreground,
        theme.color.foreground.withValues(alpha: 0),
        theme.color.foreground.withValues(alpha: 0),
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(theme.radius.full),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.s + theme.spacing.xs / 2,
          vertical: theme.spacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: indicator,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: theme.spacing.s - theme.spacing.xs / 2,
              ),
            ),
            SizedBox(width: theme.spacing.xs),
            Text(
              label,
              style: theme.typography.caption.copyWith(
                color: foreground,
                height: YhTypographyTokens.compactLineHeight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YhAvatar extends StatelessWidget {
  const YhAvatar({
    super.key,
    required this.semanticLabel,
    this.initials,
    this.image,
    this.size,
  });

  final String semanticLabel;
  final String? initials;
  final ImageProvider? image;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final dimension = size ?? theme.spacing.xl2;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: ClipOval(
          child: Container(
            width: dimension,
            height: dimension,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.color.brandTint,
              image: image == null
                  ? null
                  : DecorationImage(image: image!, fit: BoxFit.cover),
            ),
            child: image == null
                ? Text(
                    initials ?? semanticLabel.characters.first,
                    style: theme.typography.h3.copyWith(
                      color: theme.color.brandInk,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class YhMetricCard extends StatelessWidget {
  const YhMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.onTap,
    this.padding,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      semanticLabel: label,
      onTap: onTap,
      padding: padding ?? EdgeInsets.all(theme.spacing.m),
      radius: theme.radius.m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: theme.color.brandStrong),
                SizedBox(width: theme.spacing.s),
              ],
              Text(
                label,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            value,
            style: theme.typography.h2.copyWith(
              color: theme.color.foreground,
              fontFamily: YhTypographyTokens.fontFamilyMono,
            ),
          ),
          if (caption != null) ...[
            SizedBox(height: theme.spacing.xs),
            Text(
              caption!,
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class YhRing extends StatelessWidget {
  const YhRing({super.key, required this.value, this.label, this.size})
    : activity = false;

  const YhRing.activity({super.key, this.label, this.size})
    : value = 0,
      activity = true;

  final double value;
  final String? label;
  final double? size;
  final bool activity;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final normalized = value.clamp(0.0, 1.0);
    final dimension = size ?? theme.spacing.xl2 * 2;
    return Semantics(
      label: label ?? (activity ? '活动指示' : '环形进度'),
      value: activity ? '加载中' : '${(normalized * 100).round()}%',
      child: SizedBox.square(
        dimension: dimension,
        child: activity
            ? _YhActivityRing(
                sweep: theme.progress.activitySweep,
                track: theme.color.brandTint,
                active: theme.color.brandStrong,
                width: theme.spacing.xs,
              )
            : CustomPaint(
                painter: _YhRingPainter(
                  value: normalized,
                  track: theme.color.border,
                  active: theme.color.brandStrong,
                  width: theme.spacing.s,
                ),
                child: Center(
                  child: Text(
                    '${(normalized * 100).round()}%',
                    style: theme.typography.small.copyWith(
                      color: theme.color.foreground,
                      fontFamily: YhTypographyTokens.fontFamilyMono,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _YhActivityRing extends StatefulWidget {
  const _YhActivityRing({
    required this.sweep,
    required this.track,
    required this.active,
    required this.width,
  });

  final double sweep;
  final Color track;
  final Color active;
  final double width;

  @override
  State<_YhActivityRing> createState() => _YhActivityRingState();
}

class _YhActivityRingState extends State<_YhActivityRing>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visual = CustomPaint(
      painter: _YhRingPainter(
        value: widget.sweep,
        track: widget.track,
        active: widget.active,
        width: widget.width,
      ),
    );
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return visual;
    }
    final controller = _controller ??= AnimationController(
      vsync: this,
      duration: context.yhTheme.motion.slow,
    )..repeat();
    return RotationTransition(turns: controller, child: visual);
  }
}

class _YhRingPainter extends CustomPainter {
  const _YhRingPainter({
    required this.value,
    required this.track,
    required this.active,
    required this.width,
  });

  final double value;
  final Color track;
  final Color active;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - width) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..color = active
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_YhRingPainter oldDelegate) =>
      value != oldDelegate.value ||
      track != oldDelegate.track ||
      active != oldDelegate.active ||
      width != oldDelegate.width;
}

class YhFeedItem extends StatelessWidget {
  const YhFeedItem({
    super.key,
    required this.title,
    required this.summary,
    required this.source,
    this.timestamp,
    this.onTap,
  });

  final String title;
  final String summary;
  final String source;
  final String? timestamp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      semanticLabel: title,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.typography.h3.copyWith(color: theme.color.foreground),
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            summary,
            style: theme.typography.body.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          Row(
            children: [
              YhSourceBadge(label: source),
              if (timestamp != null) ...[
                const Spacer(),
                Text(
                  timestamp!,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class YhSourceBadge extends StatelessWidget {
  const YhSourceBadge({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: theme.spacing.m, color: theme.color.brandStrong),
          SizedBox(width: theme.spacing.xs),
        ],
        Text(
          label,
          style: theme.typography.caption.copyWith(color: theme.color.brandInk),
        ),
      ],
    );
  }
}
