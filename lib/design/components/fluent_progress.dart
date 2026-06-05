/*
 * Fluent 进度组件兼容层 — 包装外部 fluent_ui ProgressRing / ProgressBar
 * @Project : SSPU-AllinOne
 * @File : fluent_progress.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

/// Fluent 环形进度。
class FluentProgressRing extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final percent = value == null
        ? null
        : (value!.clamp(0, 1) * 100).toDouble();
    return SizedBox.square(
      dimension: size,
      child: ProgressRing(
        value: percent,
        strokeWidth: strokeWidth,
        activeColor: activeColor,
        semanticLabel: '加载进度',
      ),
    );
  }
}

/// Fluent 线性进度。
class FluentProgressBar extends StatelessWidget {
  const FluentProgressBar({super.key, this.value, this.height = 4});

  /// 进度值，范围 0..1；为空时显示不确定进度。
  final double? value;

  /// 进度条高度。
  final double height;

  @override
  Widget build(BuildContext context) {
    final percent = value == null
        ? null
        : (value!.clamp(0, 1) * 100).toDouble();
    return ProgressBar(
      value: percent,
      strokeWidth: height,
      semanticLabel: '加载进度',
    );
  }
}
