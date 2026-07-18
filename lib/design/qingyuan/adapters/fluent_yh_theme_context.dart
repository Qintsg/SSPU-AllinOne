/* 清源迁移适配器 — 仅供尚未迁移的 Fluent 宿主注入清源主题。 */

import 'package:fluent_ui/fluent_ui.dart';

import '../theme/yh_theme.dart';

class FluentYhThemeExtension extends ThemeExtension<FluentYhThemeExtension> {
  const FluentYhThemeExtension(this.data);

  final YhTheme data;

  @override
  FluentYhThemeExtension copyWith({YhTheme? data}) =>
      FluentYhThemeExtension(data ?? this.data);

  @override
  FluentYhThemeExtension lerp(
    covariant FluentYhThemeExtension? other,
    double t,
  ) => other != null && t >= 0.5 ? other : this;
}
