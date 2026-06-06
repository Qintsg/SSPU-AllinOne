/*
 * 应用显示名服务 — 根据当前语言环境解析用户可见应用名称
 * @Project : SSPU-AllinOne
 * @File : app_display_name_service.dart
 * @Author : Qintsg
 * @Date : 2026-06-06
 */

import 'dart:ui';

import 'package:flutter/widgets.dart';

/// 应用显示名解析入口。
///
/// 当前仅负责 #191 的产品显示名本地化；后续完整 i18n 可在此处接入
/// 生成的 AppLocalizations，避免在业务页面散落语言判断。
class AppDisplayName {
  AppDisplayName._();

  /// 英文与技术语境下的公开名称。
  static const String english = 'SSPU-AllinOne';

  /// 中文语言环境下的用户可见名称。
  static const String chinese = '工大聚合';

  /// 根据给定语言环境返回用户可见显示名。
  static String forLocale(Locale? locale) {
    if (locale?.languageCode.toLowerCase() == 'zh') {
      return chinese;
    }

    return english;
  }

  /// 根据当前平台语言环境返回用户可见显示名。
  static String get currentPlatformName {
    return forLocale(PlatformDispatcher.instance.locale);
  }

  /// 根据最近的 Flutter 本地化上下文返回用户可见显示名。
  static String of(BuildContext context) {
    return forLocale(
      Localizations.maybeLocaleOf(context) ??
          PlatformDispatcher.instance.locale,
    );
  }
}
