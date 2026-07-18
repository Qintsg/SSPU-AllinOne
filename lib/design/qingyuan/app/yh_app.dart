/* 清源应用宿主 — 只使用 Flutter Widgets 机械层。 */

import 'package:flutter/widgets.dart';

import '../navigation/yh_page_route.dart';
import '../theme/yh_theme.dart';

enum YhThemeMode { system, light, dark }

class YhApp extends StatelessWidget {
  const YhApp({
    super.key,
    required this.home,
    this.navigatorKey,
    this.theme = YhTheme.light,
    this.darkTheme = YhTheme.dark,
    this.themeMode = YhThemeMode.system,
    this.debugShowCheckedModeBanner = false,
    this.title = '工大聚合',
    this.locale,
    this.localizationsDelegates = const <LocalizationsDelegate<dynamic>>[],
    this.supportedLocales = const <Locale>[Locale('zh', 'CN')],
  });

  final Widget home;
  final GlobalKey<NavigatorState>? navigatorKey;
  final YhTheme theme;
  final YhTheme darkTheme;
  final YhThemeMode themeMode;
  final bool debugShowCheckedModeBanner;
  final String title;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates;
  final Iterable<Locale> supportedLocales;

  YhTheme _resolveTheme(BuildContext context) => switch (themeMode) {
    YhThemeMode.light => theme,
    YhThemeMode.dark => darkTheme,
    YhThemeMode.system =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark
          ? darkTheme
          : theme,
  };

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: theme.color.brandStrong,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      title: title,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          YhPageRoute<T>(settings: settings, builder: builder),
      home: home,
      builder: (context, child) {
        final resolved = _resolveTheme(context);
        return YhThemeScope(
          data: resolved,
          child: ColoredBox(
            color: resolved.color.background,
            child: DefaultTextStyle(
              style: resolved.typography.body.copyWith(
                color: resolved.color.foreground,
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
