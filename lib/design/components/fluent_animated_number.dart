/*
 * Fluent 数字动画 — 首次直显，数值变化时按系统动效偏好滚动
 * @Project : SSPU-AllinOne
 * @File : fluent_animated_number.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:fluent_ui/fluent_ui.dart';

import '../fluent/fluent_context_ext.dart';

/// 数字变化动画。
class FluentAnimatedNumber extends StatefulWidget {
  const FluentAnimatedNumber({
    super.key,
    required this.value,
    this.formatter,
    this.style,
    this.textAlign,
  });

  /// 要展示的数值。
  final double value;

  /// 数值格式化。
  final String Function(double value)? formatter;

  /// 文本样式。
  final TextStyle? style;

  /// 文本对齐。
  final TextAlign? textAlign;

  @override
  State<FluentAnimatedNumber> createState() => _FluentAnimatedNumberState();
}

class _FluentAnimatedNumberState extends State<FluentAnimatedNumber> {
  late double _displayValue = widget.value;

  @override
  void didUpdateWidget(covariant FluentAnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        MediaQuery.disableAnimationsOf(context)) {
      _displayValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.fluentMotion;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final text = _format(disableAnimations ? widget.value : _displayValue);

    if (disableAnimations) {
      return Text(text, style: widget.style, textAlign: widget.textAlign);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _displayValue, end: widget.value),
      duration: motion.durationSlow,
      curve: motion.curveDecelerateMid,
      onEnd: () => _displayValue = widget.value,
      builder: (context, value, _) {
        return Text(
          _format(value),
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    );
  }

  String _format(double value) {
    return widget.formatter?.call(value) ?? value.toStringAsFixed(0);
  }
}
