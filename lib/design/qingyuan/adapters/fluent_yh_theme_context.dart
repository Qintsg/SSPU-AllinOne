/* 清源迁移适配器 — 从现有 Fluent 宿主读取 YhTheme。 */

import 'package:fluent_ui/fluent_ui.dart';

import '../theme/yh_theme.dart';

extension YhThemeContext on BuildContext {
  YhTheme get yhTheme {
    final host = FluentTheme.of(this);
    return host.extension<YhTheme>() ??
        (host.brightness == Brightness.dark ? YhTheme.dark : YhTheme.light);
  }
}
