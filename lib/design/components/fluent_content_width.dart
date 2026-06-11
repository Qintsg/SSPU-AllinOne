/*
 * Fluent 内容宽度容器 — 统一一级页最大宽度与横向居中
 * @Project : SSPU-AllinOne
 * @File : fluent_content_width.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:fluent_ui/fluent_ui.dart';

import '../fluent/fluent_context_ext.dart';

/// 将页面内容约束在统一最大宽度内。
class FluentContentWidth extends StatelessWidget {
  const FluentContentWidth({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  /// 子内容。
  final Widget child;

  /// 最大宽度；为空时使用 [AppMetrics.contentMaxWidth]。
  final double? maxWidth;

  /// 内容对齐方式。
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? context.appMetrics.contentMaxWidth,
        ),
        child: child,
      ),
    );
  }
}
