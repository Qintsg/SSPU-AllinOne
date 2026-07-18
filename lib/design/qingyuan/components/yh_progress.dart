/* 清源线性进度 — 确定与不确定模式。 */

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';

class YhProgress extends StatelessWidget {
  const YhProgress({
    super.key,
    this.value,
    this.showPercent = true,
    this.semanticLabel,
  });

  final double? value;
  final bool showPercent;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final normalized = value?.clamp(0.0, 1.0);
    final label = normalized == null ? '加载中' : '${(normalized * 100).round()}%';
    final bar = Semantics(
      label: semanticLabel ?? '加载进度',
      value: label,
      child: SizedBox(
        height: theme.spacing.s,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(theme.radius.full),
          child: ColoredBox(
            color: theme.color.border,
            child: normalized == null
                ? const _IndeterminateProgress()
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AnimatedFractionallySizedBox(
                      duration: theme.motion.slow,
                      curve: theme.motion.curve,
                      widthFactor: normalized,
                      child: ColoredBox(
                        color: normalized == 1
                            ? theme.color.success
                            : theme.color.brandStrong,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
    if (!showPercent) return bar;
    return Row(
      children: [
        Expanded(child: bar),
        SizedBox(width: theme.spacing.s),
        Text(
          label,
          style: theme.typography.small.copyWith(
            color: theme.color.muted,
            fontFamily: YhTypographyTokens.fontFamilyMono,
          ),
        ),
      ],
    );
  }
}

class YhProgressBar extends StatelessWidget {
  const YhProgressBar({super.key, required this.value, this.semanticLabel});

  final double value;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => YhProgress(
    value: value,
    showPercent: false,
    semanticLabel: semanticLabel,
  );
}

class _IndeterminateProgress extends StatefulWidget {
  const _IndeterminateProgress();

  @override
  State<_IndeterminateProgress> createState() => _IndeterminateProgressState();
}

class _IndeterminateProgressState extends State<_IndeterminateProgress>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Duration _animationDuration;

  AnimationController get _animationController {
    return _controller ??= AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationDuration = context.yhTheme.motion.slow * 3;
    _controller?.duration = _animationDuration;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      return FractionallySizedBox(
        widthFactor: 0.4,
        alignment: Alignment.center,
        child: ColoredBox(color: theme.color.brandStrong),
      );
    }
    final controller = _animationController;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Align(
        alignment: Alignment(-1 + controller.value * 2, 0),
        child: FractionallySizedBox(widthFactor: 0.4, child: child),
      ),
      child: ColoredBox(color: theme.color.brandStrong),
    );
  }
}
