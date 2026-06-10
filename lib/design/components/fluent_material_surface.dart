/*
 * Fluent 材质表面 — 统一卡片背景、描边和轻量阴影
 * @Project : SSPU-AllinOne
 * @File : fluent_material_surface.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:fluent_ui/fluent_ui.dart';

import '../fluent/fluent_context_ext.dart';

/// Fluent 材质类型。
enum FluentMaterialTone {
  /// 页面主表面。
  base,

  /// 卡片表面。
  card,

  /// 弱强调表面。
  subtle,
}

/// 统一材质容器。
class FluentMaterialSurface extends StatelessWidget {
  const FluentMaterialSurface({
    super.key,
    required this.child,
    this.tone = FluentMaterialTone.card,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.shadows,
    this.clipBehavior = Clip.antiAlias,
  });

  /// 子内容。
  final Widget child;

  /// 材质语义。
  final FluentMaterialTone tone;

  /// 内边距。
  final EdgeInsetsGeometry? padding;

  /// 圆角。
  final BorderRadiusGeometry? borderRadius;

  /// 描边色。
  final Color? borderColor;

  /// 阴影令牌。
  final List<BoxShadow>? shadows;

  /// 裁剪行为。
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final stroke = context.fluentStroke;
    final background = switch (tone) {
      FluentMaterialTone.base => colors.neutralBackground1,
      FluentMaterialTone.card => colors.neutralBackground1,
      FluentMaterialTone.subtle => colors.neutralBackground2,
    };

    return Container(
      clipBehavior: clipBehavior,
      padding: padding ?? EdgeInsets.all(spacing.l),
      decoration: BoxDecoration(
        color: background,
        gradient: tone == FluentMaterialTone.card
            ? context.fluentGradients.cardSheen
            : null,
        borderRadius: borderRadius ?? radii.largeBorder,
        border: Border.all(
          color: borderColor ?? colors.neutralStroke2,
          width: stroke.thin,
        ),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
