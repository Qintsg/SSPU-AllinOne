/* 清源页面路由 — 集中处理跨端入场与减少动态。 */

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';

class YhPageRoute<T> extends PageRouteBuilder<T> {
  YhPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionDuration: YhTheme.light.motion.slow,
         reverseTransitionDuration: YhTheme.light.motion.base,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final disableAnimations =
               MediaQuery.maybeOf(context)?.disableAnimations ?? false;
           if (disableAnimations) return child;
           final curved = CurvedAnimation(
             parent: animation,
             curve: context.yhTheme.motion.curve,
           );
           return FadeTransition(
             opacity: curved,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: const Offset(0.02, 0),
                 end: Offset.zero,
               ).animate(curved),
               child: child,
             ),
           );
         },
       );
}
