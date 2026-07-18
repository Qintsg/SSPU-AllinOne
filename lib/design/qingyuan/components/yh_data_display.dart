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
    final (foreground, background) = switch (kind) {
      YhStatusKind.success => (theme.color.success, theme.color.successTint),
      YhStatusKind.warning => (theme.color.warning, theme.color.warningTint),
      YhStatusKind.danger => (theme.color.danger, theme.color.dangerTint),
      YhStatusKind.info => (theme.color.brandStrong, theme.color.brandTint),
      YhStatusKind.neutral => (theme.color.muted, theme.color.sunken),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(theme.radius.full),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.s,
          vertical: theme.spacing.xs,
        ),
        child: Text(
          label,
          style: theme.typography.small.copyWith(color: foreground),
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
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      semanticLabel: label,
      onTap: onTap,
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
  const YhRing({super.key, required this.value, this.label, this.size});

  final double value;
  final String? label;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final normalized = value.clamp(0.0, 1.0);
    final dimension = size ?? theme.spacing.xl2 * 2;
    return Semantics(
      label: label ?? '环形进度',
      value: '${(normalized * 100).round()}%',
      child: SizedBox.square(
        dimension: dimension,
        child: CustomPaint(
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
