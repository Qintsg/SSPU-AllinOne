/*
 * 清源页面框架与安全区
 * @Project : SSPU-AllinOne
 * @File : yh_page_scaffold.dart
 * @Author : Qintsg, Codex
 * @Date : 2026-11-19
 */

import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;

import '../theme/yh_theme.dart';
import 'yh_app_bar.dart';

class YhPageScaffold extends StatelessWidget {
  const YhPageScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomBar,
    this.backgroundColor,
  });

  final Widget body;
  final YhAppBar? appBar;
  final Widget? bottomBar;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return miuix.MiuixSurface(
      color: backgroundColor ?? context.yhTheme.color.background,
      contentColor: context.yhTheme.color.foreground,
      child: SafeArea(
        child: Column(
          children: [
            ?appBar,
            Expanded(child: body),
            ?bottomBar,
          ],
        ),
      ),
    );
  }
}
