/*
 * Fluent 2 页面容器 — 页面标题、内容安全区与滚动布局
 * @Project : SSPU-AllinOne
 * @File : fluent_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'package:flutter/material.dart';

import '../fluent/fluent_context_ext.dart';

/// Fluent 2 页面标题。
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
    final spacing = context.fluentSpacing;
    final type = context.fluentType;
    final colors = context.fluentColors;
    final children = <Widget>[
      if (leading != null) ...[leading!, SizedBox(width: spacing.s)],
      Expanded(
        child: DefaultTextStyle.merge(
          style: type.title3.copyWith(color: colors.neutralForeground1),
          child: title,
        ),
      ),
      if (commandBar != null) ...[SizedBox(width: spacing.s), commandBar!],
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.xxl, vertical: spacing.m),
      child: Row(children: children),
    );
  }
}

/// Fluent 2 页面容器。
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

    return Scaffold(
      appBar: header == null
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: SafeArea(bottom: false, child: header!),
            ),
      body: SafeArea(child: body),
    );
  }
}

/// Fluent 2 页面路由。
class FluentPageRoute<T> extends MaterialPageRoute<T> {
  FluentPageRoute({required super.builder});
}
