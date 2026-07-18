/*
 * 清源统一交互基座 — 汇聚鼠标、键盘、触控、语义与减少动态
 * @Project : SSPU-AllinOne
 * @File : yh_pressable.dart
 * @Author : Qintsg
 * @Date : 2026-07-18
 */

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';

@immutable
class YhPressableState {
  const YhPressableState({
    required this.hovered,
    required this.focused,
    required this.pressed,
    required this.disabled,
  });

  final bool hovered;
  final bool focused;
  final bool pressed;
  final bool disabled;
}

typedef YhPressableBuilder =
    Widget Function(BuildContext context, YhPressableState state, Widget child);

class YhPressable extends StatefulWidget {
  const YhPressable({
    super.key,
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
    this.builder,
    this.autofocus = false,
  });

  final String semanticLabel;
  final VoidCallback? onPressed;
  final Widget child;
  final YhPressableBuilder? builder;
  final bool autofocus;

  @override
  State<YhPressable> createState() => _YhPressableState();
}

class _YhPressableState extends State<YhPressable> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _activate() {
    if (_enabled) widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final state = YhPressableState(
      hovered: _hovered,
      focused: _focused,
      pressed: _pressed,
      disabled: !_enabled,
    );
    final content =
        widget.builder?.call(context, state, widget.child) ?? widget.child;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = context.yhTheme.motion.effective(
      context.yhTheme.motion.fast,
      disableAnimations: disableAnimations,
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _enabled,
        autofocus: widget.autofocus,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? _activate : null,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          child: AnimatedContainer(
            duration: duration,
            curve: context.yhTheme.motion.curve,
            constraints: BoxConstraints(
              minWidth: context.yhTheme.control.minimumTarget,
              minHeight: context.yhTheme.control.minimumTarget,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: _focused
                    ? context.yhTheme.color.brandStrong
                    : context.yhTheme.color.brandStrong.withValues(alpha: 0),
                width: context.yhTheme.focus.ringWidth,
              ),
              borderRadius: BorderRadius.circular(
                context.yhTheme.radius.s + context.yhTheme.focus.ringGap,
              ),
            ),
            child: AnimatedScale(
              scale: _pressed ? context.yhTheme.motion.pressedScale : 1,
              duration: duration,
              curve: context.yhTheme.motion.curve,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
