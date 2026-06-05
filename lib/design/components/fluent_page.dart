/*
 * Fluent 页面兼容层 — 包装外部 fluent_ui ScaffoldPage / PageHeader
 * @Project : SSPU-AllinOne
 * @File : fluent_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'package:fluent_ui/fluent_ui.dart' as fluent hide FluentIcons;
import 'package:flutter/widgets.dart';

import '../fluent/fluent_context_ext.dart';

/// Fluent 页面标题。
class FluentPageHeader extends StatelessWidget {
  const FluentPageHeader({
    super.key,
    required this.title,
    this.leading,
    this.commandBar,
  });

  /// 标题内容。
  final Widget title;

  /// 左侧内容。
  final Widget? leading;

  /// 右侧命令区。
  final Widget? commandBar;

  @override
  Widget build(BuildContext context) {
    return fluent.PageHeader(
      leading: leading,
      title: title,
      commandBar: commandBar,
    );
  }
}

/// Fluent 页面容器。
class FluentPage extends StatelessWidget {
  const FluentPage({super.key, this.header, this.content})
    : children = null,
      padding = null,
      scrollable = false;

  const FluentPage.scrollable({
    super.key,
    this.header,
    required this.children,
    this.padding,
  }) : content = null,
       scrollable = true;

  /// 顶部标题栏。
  final Widget? header;

  /// 非滚动内容。
  final Widget? content;

  /// 滚动内容列表。
  final List<Widget>? children;

  /// 滚动内容内边距。
  final EdgeInsetsGeometry? padding;

  /// 是否为滚动页面。
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final spacing = context.fluentSpacing;
    final body = scrollable
        ? SingleChildScrollView(
            padding: padding ?? EdgeInsets.all(spacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children ?? const [],
            ),
          )
        : content ?? const SizedBox.shrink();

    return fluent.ScaffoldPage(
      header: header,
      content: SafeArea(child: body),
    );
  }
}

/// Fluent 页面路由。
class FluentPageRoute<T> extends fluent.FluentPageRoute<T> {
  FluentPageRoute({required super.builder});
}
