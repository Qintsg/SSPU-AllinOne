/*
 * Fluent 拉伸卡片体 — 在等高行和滚动单列中复用的三段式卡片布局
 * @Project : SSPU-AllinOne
 * @File : fluent_stretch_card_body.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

import '../fluent/fluent_context_ext.dart';

/// 让卡片主体在等高行中把底部信息推到底，在滚动单列中自然流式排布。
class FluentStretchCardBody extends StatelessWidget {
  const FluentStretchCardBody({
    super.key,
    required this.header,
    required this.body,
    this.footer,
    this.spacing,
  });

  /// 顶部区域，通常为标题、状态和主要摘要。
  final Widget header;

  /// 主体区域。
  final Widget body;

  /// 底部区域，通常为上次刷新与操作。
  final Widget? footer;

  /// 分段间距；默认使用 Fluent 主题间距。
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final gap = spacing ?? context.fluentSpacing.l;
    if (footer == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(height: gap),
          body,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            SizedBox(height: gap),
            body,
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: gap),
          child: footer!,
        ),
      ],
    );
  }
}
