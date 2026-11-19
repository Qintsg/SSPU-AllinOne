/*
 * 清源应用宿主与全局 Miuix 主题
 * @Project : SSPU-AllinOne
 * @File : yh_app.dart
 * @Author : Qintsg, Codex
 * @Date : 2026-11-19
 */

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;

import '../components/yh_miuix.dart';
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
    this.monetEnabled = false,
    this.onMonetChanged,
    this.debugShowCheckedModeBanner = false,
    this.title = '工大聚合',
    this.onGenerateTitle,
    this.builder,
    this.locale,
    this.localizationsDelegates = const <LocalizationsDelegate<dynamic>>[],
    this.supportedLocales = const <Locale>[Locale('zh', 'CN')],
  });

  final Widget home;
  final GlobalKey<NavigatorState>? navigatorKey;
  final YhTheme theme;
  final YhTheme darkTheme;
  final YhThemeMode themeMode;
  final bool monetEnabled;
  final Future<void> Function(bool)? onMonetChanged;
  final bool debugShowCheckedModeBanner;
  final String title;
  final GenerateAppTitle? onGenerateTitle;
  final TransitionBuilder? builder;
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
      onGenerateTitle: onGenerateTitle,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          YhPageRoute<T>(settings: settings, builder: builder),
      home: home,
      builder: (context, child) {
        final base = _resolveTheme(context);
        final usesWallpaper =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
        return miuix.MiuixThemeController(
          colorSchemeMode: monetEnabled
              ? miuix.MiuixColorSchemeMode.monetSystem
              : miuix.MiuixColorSchemeMode.system,
          isDark: base.color.background.computeLuminance() < 0.5,
          lightColors: yhMiuixColors(theme.color),
          darkColors: yhMiuixColors(darkTheme.color),
          keyColor: usesWallpaper ? null : theme.color.brandStrong,
          child: Builder(
            builder: (context) {
              final palette = miuix.MiuixTheme.of(context).colors;
              final resolved = monetEnabled
                  ? yhThemeWithMonet(base, palette)
                  : base;
              return YhMonetPreference(
                enabled: monetEnabled,
                onChanged: onMonetChanged,
                child: YhThemeScope(
                  data: resolved,
                  child: Builder(
                    builder: (themedContext) {
                      final content = ColoredBox(
                        color: resolved.color.background,
                        child: DefaultTextStyle(
                          style: resolved.typography.body.copyWith(
                            color: resolved.color.foreground,
                          ),
                          child: child ?? const SizedBox.shrink(),
                        ),
                      );
                      return builder?.call(themedContext, content) ?? content;
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// 将动态色偏好提供给设置路线。
class YhMonetPreference extends InheritedWidget {
  const YhMonetPreference({
    super.key,
    required this.enabled,
    required this.onChanged,
    required super.child,
  });

  final bool enabled;
  final Future<void> Function(bool)? onChanged;

  /// 读取当前应用的动态色偏好。
  static YhMonetPreference? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<YhMonetPreference>();

  @override
  bool updateShouldNotify(YhMonetPreference oldWidget) =>
      enabled != oldWidget.enabled || onChanged != oldWidget.onChanged;
}
