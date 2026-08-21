/* 清源页面框架。 */

import 'package:flutter/widgets.dart';

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
    return ColoredBox(
      color: backgroundColor ?? context.yhTheme.color.background,
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
