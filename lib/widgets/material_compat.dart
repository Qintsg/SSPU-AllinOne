/*
 * Material 3 迁移兼容组件 — 将历史 Fluent 风格调用映射到 Material 控件
 * @Project : SSPU-AllinOne
 * @File : material_compat.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */
// ignore_for_file: constant_identifier_names, use_null_aware_elements

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'package:flutter/foundation.dart';
export 'package:flutter/material.dart' hide Card, Flex;

import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';

/// 历史图标语义到 Material Icons 的映射。
class FluentIcons {
  FluentIcons._();

  static const IconData home = Icons.home_outlined;
  static const IconData education = Icons.school_outlined;
  static const IconData calendar = Icons.calendar_month_outlined;
  static const IconData info = Icons.info_outline;
  static const IconData info_solid = Icons.info;
  static const IconData mail = Icons.mail_outline;
  static const IconData link = Icons.link;
  static const IconData settings = Icons.settings_outlined;
  static const IconData check_mark = Icons.check;
  static const IconData blocked = Icons.block;
  static const IconData clear = Icons.close;
  static const IconData q_r_code = Icons.qr_code;
  static const IconData shield = Icons.shield_outlined;
  static const IconData edit = Icons.edit_outlined;
  static const IconData warning = Icons.warning_amber_outlined;
  static const IconData filter = Icons.filter_alt_outlined;
  static const IconData inbox = Icons.inbox_outlined;
  static const IconData refresh = Icons.refresh;
  static const IconData search = Icons.search;
  static const IconData read = Icons.mark_email_read_outlined;
  static const IconData chevron_left = Icons.chevron_left;
  static const IconData chevron_right = Icons.chevron_right;
  static const IconData back = Icons.arrow_back;
  static const IconData forward = Icons.arrow_forward;
  static const IconData chrome_back = Icons.arrow_back;
  static const IconData open_in_new_window = Icons.open_in_new;
  static const IconData open_source = Icons.code;
  static const IconData document_set = Icons.description_outlined;
  static const IconData code = Icons.integration_instructions_outlined;
  static const IconData lock = Icons.lock_outline;
  static const IconData fingerprint = Icons.fingerprint;
  static const IconData broom = Icons.cleaning_services_outlined;
  static const IconData delete = Icons.delete_outline;
  static const IconData save = Icons.save_outlined;
  static const IconData plug_connected = Icons.power;
  static const IconData plug_disconnected = Icons.power_off;
  static const IconData sync_status = Icons.sync;
  static const IconData running = Icons.directions_run_outlined;
  static const IconData payment_card = Icons.credit_card_outlined;
  static const IconData ringer = Icons.notifications_outlined;
  static const IconData ringer_off = Icons.notifications_off_outlined;
  static const IconData chat = Icons.chat_outlined;
  static const IconData library = Icons.local_library_outlined;
  static const IconData globe = Icons.public_outlined;
  static const IconData people = Icons.groups_outlined;
  static const IconData contact = Icons.contacts_outlined;
  static const IconData database = Icons.storage_outlined;
  static const IconData video = Icons.videocam_outlined;
  static const IconData event = Icons.event_outlined;
  static const IconData megaphone = Icons.campaign_outlined;
  static const IconData news = Icons.article_outlined;
  static const IconData certificate = Icons.verified_outlined;
  static const IconData list = Icons.list_alt_outlined;
  static const IconData clock = Icons.schedule;
  static const IconData location = Icons.location_on_outlined;
  static const IconData calendar_week = Icons.view_week_outlined;
  static const IconData money = Icons.account_balance_wallet_outlined;
  static const IconData search_issue = Icons.manage_search;
  static const IconData sync = Icons.sync;
  static const IconData global_nav_button = Icons.menu;
}

/// Material 3 的历史主题访问兼容包装。
class FluentTheme {
  FluentTheme._();

  /// 返回当前 Material 主题的兼容视图。
  static FluentThemeData of(BuildContext context) {
    return FluentThemeData(Theme.of(context));
  }
}

/// Material 主题兼容视图。
class FluentThemeData {
  final ThemeData _theme;

  const FluentThemeData(this._theme);

  /// 当前亮度。
  Brightness get brightness => _theme.brightness;

  /// 主强调色。
  Color get accentColor => _theme.colorScheme.primary;

  /// 次要文本/图标色。
  Color get inactiveColor => _theme.colorScheme.onSurfaceVariant;

  /// 兼容排版访问。
  FluentTypography get typography => FluentTypography(_theme.textTheme);

  /// 兼容资源色访问。
  FluentResources get resources => FluentResources(_theme.colorScheme);
}

/// 历史排版 token 到 Material TextTheme 的映射。
class FluentTypography {
  final TextTheme _textTheme;

  const FluentTypography(this._textTheme);

  TextStyle? get title => _textTheme.headlineSmall;
  TextStyle? get display => _textTheme.displaySmall;
  TextStyle? get subtitle => _textTheme.titleLarge;
  TextStyle? get bodyLarge => _textTheme.bodyLarge;
  TextStyle? get body => _textTheme.bodyMedium;
  TextStyle? get bodyStrong => _textTheme.titleSmall;
  TextStyle? get caption => _textTheme.bodySmall;
}

/// 历史资源色到 Material ColorScheme 的映射。
class FluentResources {
  final ColorScheme _colorScheme;

  const FluentResources(this._colorScheme);

  Color get textFillColorSecondary => _colorScheme.onSurfaceVariant;
  Color get textFillColorDisabled =>
      _colorScheme.onSurfaceVariant.withValues(alpha: 0.45);
  Color get controlAltFillColorSecondary => _colorScheme.surfaceContainerHighest;
  Color get controlFillColorDisabled => _colorScheme.surfaceContainerHighest;
  Color get systemFillColorSuccessBackground => _colorScheme.primaryContainer;
  Color get systemFillColorSuccess => _colorScheme.onPrimaryContainer;
  Color get systemFillColorNeutralBackground => _colorScheme.surfaceContainerHigh;
  Color get controlStrokeColorDefault => _colorScheme.outlineVariant;
  Color get subtleFillColorSecondary => _colorScheme.surfaceContainerHighest;
  Color get systemFillColorCaution => _colorScheme.tertiary;
  Color get systemFillColorSolidNeutral => _colorScheme.onSurfaceVariant;
  Color get systemFillColorCritical => _colorScheme.error;
}

/// Material 3 卡片兼容组件，支持历史 `padding` 参数。
class Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final ShapeBorder? shape;

  const Card({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerLow,
      shape: shape ?? AppShapes.cardShape,
      child: Padding(
        padding: padding ?? AppSpacing.cardPadding,
        child: child,
      ),
    );
  }
}

/// Material 3 Flex 兼容组件，支持历史 `direction` 参数。
class Flex extends StatelessWidget {
  final Axis direction;
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const Flex({
    super.key,
    required this.direction,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return direction == Axis.horizontal
        ? Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: children,
          )
        : Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: children,
          );
  }
}

/// Material 3 页面标题兼容组件。
class PageHeader extends StatelessWidget {
  final Widget title;
  final Widget? leading;
  final Widget? commandBar;

  const PageHeader({super.key, required this.title, this.leading, this.commandBar});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (leading != null) children.add(leading!);
    children.add(Expanded(child: DefaultTextStyle.merge(style: Theme.of(context).textTheme.titleLarge, child: title)));
    if (commandBar != null) children.add(commandBar!);

    return Padding(
      padding: AppSpacing.regularPagePadding,
      child: Row(children: children),
    );
  }
}

/// Material 3 页面脚手架兼容组件。
class ScaffoldPage extends StatelessWidget {
  final Widget? header;
  final Widget? content;
  final List<Widget>? children;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  const ScaffoldPage({super.key, this.header, this.content})
    : children = null,
      padding = null,
      scrollable = false;

  const ScaffoldPage.scrollable({
    super.key,
    this.header,
    required this.children,
    this.padding,
  }) : content = null,
       scrollable = true;

  @override
  Widget build(BuildContext context) {
    final body = scrollable
        ? SingleChildScrollView(
            padding: padding ?? AppSpacing.regularPagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children ?? const [],
            ),
          )
        : content ?? const SizedBox();

    return Scaffold(
      appBar: header == null ? null : PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: SafeArea(bottom: false, child: header!),
      ),
      body: SafeArea(child: body),
    );
  }
}

/// Material 3 次级按钮兼容组件。
class Button extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;

  const Button({super.key, required this.child, this.onPressed, this.style});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}

/// Material 3 开关兼容组件。
class ToggleSwitch extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final Widget? content;

  const ToggleSwitch({super.key, required this.checked, this.onChanged, this.content});

  @override
  Widget build(BuildContext context) {
    if (content == null) return Switch(value: checked, onChanged: onChanged);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        content!,
        const SizedBox(width: AppSpacing.sm),
        Switch(value: checked, onChanged: onChanged),
      ],
    );
  }
}

/// Material 3 下拉框选项兼容组件。
class ComboBoxItem<T> {
  final T value;
  final Widget child;

  const ComboBoxItem({required this.value, required this.child});
}

/// Material 3 下拉框兼容组件。
class ComboBox<T> extends StatelessWidget {
  final T? value;
  final List<ComboBoxItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? placeholder;
  final bool isExpanded;

  const ComboBox({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.placeholder,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      isExpanded: isExpanded,
      hint: placeholder,
      items: items
          .map((item) => DropdownMenuItem<T>(value: item.value, child: item.child))
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// Material 3 文本框兼容组件。
class TextBox extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool autofocus;
  final int? maxLines;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final TextStyle? style;

  const TextBox({
    super.key,
    this.controller,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.autofocus = false,
    this.maxLines = 1,
    this.expands = false,
    this.textAlignVertical,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(hintText: placeholder, prefixIcon: prefix, suffixIcon: suffix),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      autofocus: autofocus,
      maxLines: expands ? null : maxLines,
      expands: expands,
      textAlignVertical: textAlignVertical,
      style: style,
    );
  }
}

/// 密码框显隐模式兼容枚举。
enum PasswordRevealMode { peekAlways }

/// Material 3 密码框兼容组件。
class PasswordBox extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final FocusNode? focusNode;
  final PasswordRevealMode? revealMode;
  final ValueChanged<String>? onSubmitted;

  const PasswordBox({
    super.key,
    this.controller,
    this.placeholder,
    this.focusNode,
    this.revealMode,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: true,
      decoration: InputDecoration(hintText: placeholder, prefixIcon: const Icon(Icons.lock_outline)),
      onSubmitted: onSubmitted,
    );
  }
}

/// Material 3 进度环兼容组件。
class ProgressRing extends StatelessWidget {
  final double? strokeWidth;
  final Color? activeColor;

  const ProgressRing({super.key, this.strokeWidth, this.activeColor});

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(strokeWidth: strokeWidth ?? 4, color: activeColor);
  }
}

/// Material 3 线性进度兼容组件。
class ProgressBar extends StatelessWidget {
  final double? value;

  const ProgressBar({super.key, this.value});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(value: value == null ? null : value! / 100);
  }
}

/// Material 3 对话框兼容组件。
class ContentDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final BoxConstraints? constraints;

  const ContentDialog({super.key, this.title, this.content, this.actions, this.constraints});

  @override
  Widget build(BuildContext context) {
    final dialog = AlertDialog(title: title, content: content, actions: actions);
    if (constraints == null) return dialog;
    return ConstrainedBox(constraints: constraints!, child: dialog);
  }
}

/// 反馈严重级别兼容枚举。
enum InfoBarSeverity { info, success, warning, error }

/// Material 3 反馈条兼容组件。
class InfoBar extends StatelessWidget {
  final Widget title;
  final Widget? content;
  final InfoBarSeverity severity;
  final Widget? action;
  final bool isLong;

  const InfoBar({
    super.key,
    required this.title,
    this.content,
    this.severity = InfoBarSeverity.info,
    this.action,
    this.isLong = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = switch (severity) {
      InfoBarSeverity.info => (colorScheme.surfaceContainerHighest, colorScheme.onSurface),
      InfoBarSeverity.success => (colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
      InfoBarSeverity.warning => (colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
      InfoBarSeverity.error => (colorScheme.errorContainer, colorScheme.onErrorContainer),
    };

    return Material(
      color: colors.$1,
      borderRadius: AppShapes.md,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: colors.$2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [title, if (content != null) ...[const SizedBox(height: AppSpacing.xs), content!]],
                ),
              ),
            ),
            if (action case final action?) action,
          ],
        ),
      ),
    );
  }
}

/// 显示 Material 3 SnackBar 兼容反馈。
void displayInfoBar(BuildContext context, {required Widget Function(BuildContext ctx, VoidCallback close) builder}) {
  final messenger = ScaffoldMessenger.of(context);
  late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
  controller = messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Builder(builder: (ctx) => builder(ctx, () => controller.close())),
    ),
  );
}

/// Material 页面路由兼容别名。
class FluentPageRoute<T> extends MaterialPageRoute<T> {
  FluentPageRoute({required super.builder});
}

/// Hover 状态兼容数据。
class HoverButtonStates {
  final bool isHovered;
  final bool isPressed;

  const HoverButtonStates({required this.isHovered, required this.isPressed});
}

/// Material 3 Hover 按钮兼容组件。
class HoverButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, HoverButtonStates states) builder;

  const HoverButton({super.key, required this.onPressed, required this.builder});

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onPressed == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: widget.onPressed == null ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.onPressed == null ? null : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onPressed == null ? null : () => setState(() => _pressed = false),
        child: widget.builder(context, HoverButtonStates(isHovered: _hovered, isPressed: _pressed)),
      ),
    );
  }
}

/// Material 3 展开面板兼容组件。
class Expander extends StatelessWidget {
  final Widget header;
  final Widget? icon;
  final Widget content;

  const Expander({super.key, required this.header, this.icon, required this.content});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(leading: icon, title: header, children: [Padding(padding: AppSpacing.cardPadding, child: content)]);
  }
}

/// Material 3 标签控件兼容组件。
class InfoLabel extends StatelessWidget {
  final String label;
  final Widget child;

  const InfoLabel({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

/// 数值框按钮布局兼容枚举。
enum SpinButtonPlacementMode { inline }

/// Material 3 数值输入兼容组件。
class NumberBox extends StatelessWidget {
  final num value;
  final num? min;
  final num? max;
  final SpinButtonPlacementMode? mode;
  final num? smallChange;
  final ValueChanged<num?>? onChanged;

  const NumberBox({
    super.key,
    required this.value,
    this.min,
    this.max,
    this.mode,
    this.smallChange,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(value),
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (text) => onChanged?.call(num.tryParse(text)),
    );
  }
}
