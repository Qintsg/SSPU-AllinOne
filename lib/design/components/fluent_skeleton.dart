/*
 * Fluent 骨架屏 — 尊重系统禁用动画设置的加载占位
 * @Project : SSPU-AllinOne
 * @File : fluent_skeleton.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:fluent_ui/fluent_ui.dart';

import '../fluent/fluent_context_ext.dart';
import '../fluent/tokens/fluent_motion.dart';

/// Fluent 骨架占位。
class FluentSkeleton extends StatefulWidget {
  const FluentSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  /// 宽度。
  final double? width;

  /// 高度。
  final double height;

  /// 圆角。
  final BorderRadiusGeometry? borderRadius;

  @override
  State<FluentSkeleton> createState() => _FluentSkeletonState();
}

class _FluentSkeletonState extends State<FluentSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    const motion = FluentMotion();
    _controller = AnimationController(
      vsync: this,
      duration: motion.durationSkeleton,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      _controller.repeat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
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
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final baseColor = colors.neutralBackground3;
    final highlightColor = colors.neutralBackground2;

    Widget child = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: widget.borderRadius ?? radii.mediumBorder,
      ),
    );

    if (!disableAnimations) {
      child = AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? radii.mediumBorder,
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.1, 0.45, 0.9],
                colors: [baseColor, highlightColor, baseColor],
                transform: _SkeletonGradientTransform(_controller.value),
              ),
            ),
          );
        },
      );
    }

    return Semantics(container: true, label: '加载占位', child: child);
  }
}

class _SkeletonGradientTransform extends GradientTransform {
  const _SkeletonGradientTransform(this.value);

  final double value;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (value * 2 - 1), 0, 0);
  }
}
