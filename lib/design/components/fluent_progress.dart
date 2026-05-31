/*
 * Fluent 2 进度组件 — 环形与线性进度均使用令牌绘制
 * @Project : SSPU-AllinOne
 * @File : fluent_progress.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../fluent/fluent_context_ext.dart';

/// Fluent 2 环形进度。
class FluentProgressRing extends StatefulWidget {
  const FluentProgressRing({
    super.key,
    this.value,
    this.size = 24,
    this.strokeWidth = 3,
    this.activeColor,
  });

  /// 进度值，范围 0..1；为空时显示不确定进度。
  final double? value;

  /// 外接正方形尺寸。
  final double size;

  /// 描边宽度。
  final double strokeWidth;

  /// 自定义前景色。
  final Color? activeColor;

  @override
  State<FluentProgressRing> createState() => _FluentProgressRingState();
}

class _FluentProgressRingState extends State<FluentProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.value == null) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant FluentProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.value != null && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    return Semantics(
      label: '加载进度',
      value: widget.value == null
          ? null
          : '${(widget.value!.clamp(0, 1) * 100).round()}%',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _FluentRingPainter(
                animationValue: _controller.value,
                value: widget.value,
                activeColor: widget.activeColor ?? colors.brandBackground,
                trackColor: colors.neutralBackground3,
                strokeWidth: widget.strokeWidth,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Fluent 2 线性进度。
class FluentProgressBar extends StatefulWidget {
  const FluentProgressBar({super.key, this.value, this.height = 4});

  /// 进度值，范围 0..1；为空时显示不确定进度。
  final double? value;

  /// 进度条高度。
  final double height;

  @override
  State<FluentProgressBar> createState() => _FluentProgressBarState();
}

class _FluentProgressBarState extends State<FluentProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    if (widget.value == null) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant FluentProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.value != null && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radii.circular),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.neutralBackground3),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _FluentBarPainter(
                  animationValue: _controller.value,
                  value: widget.value,
                  activeColor: colors.brandBackground,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FluentRingPainter extends CustomPainter {
  const _FluentRingPainter({
    required this.animationValue,
    required this.value,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double animationValue;
  final double? value;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = activeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    if (value == null) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + animationValue * math.pi * 2,
        math.pi * 1.35,
        false,
        active,
      );
      return;
    }
    canvas.drawArc(
      rect,
      -math.pi / 2,
      value!.clamp(0, 1) * math.pi * 2,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _FluentRingPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        value != oldDelegate.value ||
        activeColor != oldDelegate.activeColor ||
        trackColor != oldDelegate.trackColor ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}

class _FluentBarPainter extends CustomPainter {
  const _FluentBarPainter({
    required this.animationValue,
    required this.value,
    required this.activeColor,
  });

  final double animationValue;
  final double? value;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = activeColor;
    if (value == null) {
      final segmentWidth = size.width * 0.36;
      final left = (size.width + segmentWidth) * animationValue - segmentWidth;
      canvas.drawRect(Rect.fromLTWH(left, 0, segmentWidth, size.height), paint);
      return;
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * value!.clamp(0, 1), size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FluentBarPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        value != oldDelegate.value ||
        activeColor != oldDelegate.activeColor;
  }
}
