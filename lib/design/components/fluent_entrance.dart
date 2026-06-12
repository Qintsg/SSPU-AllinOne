/*
 * Fluent 入场动画 — 统一尊重系统禁用动画的轻量转场
 * @Project : SSPU-AllinOne
 * @File : fluent_entrance.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:fluent_ui/fluent_ui.dart';

import '../fluent/fluent_context_ext.dart';

/// 构建 Fluent 入场动画。
Widget fluentEntrance({
  required BuildContext context,
  required Widget child,
  Duration? delay,
}) {
  if (MediaQuery.disableAnimationsOf(context)) return child;
  final motion = context.fluentMotion;
  return _FluentEntrance(
    delay: delay ?? Duration.zero,
    duration: motion.durationSlow,
    curve: motion.curveDecelerateMid,
    child: child,
  );
}

class _FluentEntrance extends StatefulWidget {
  const _FluentEntrance({
    required this.delay,
    required this.duration,
    required this.curve,
    required this.child,
  });

  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<_FluentEntrance> createState() => _FluentEntranceState();
}

class _FluentEntranceState extends State<_FluentEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(curve);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
