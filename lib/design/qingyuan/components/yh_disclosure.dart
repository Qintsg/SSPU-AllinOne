/* 清源披露面板 — 可展开的说明与次级设置容器。 */

import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../icons/yh_icons.dart';
import '../theme/yh_theme.dart';

class YhDisclosure extends StatefulWidget {
  const YhDisclosure({
    super.key,
    required this.title,
    required this.content,
    this.leadingIcon,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget content;
  final IconData? leadingIcon;
  final bool initiallyExpanded;

  @override
  State<YhDisclosure> createState() => _YhDisclosureState();
}

class _YhDisclosureState extends State<YhDisclosure> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = theme.motion.effective(
      theme.motion.base,
      disableAnimations: disableAnimations,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: Border.all(color: theme.color.border, width: 1.5),
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YhPressable(
            semanticLabel: '${_expanded ? '收起' : '展开'}${widget.title}',
            toggled: _expanded,
            onPressed: _toggle,
            builder: (context, state, child) => ColoredBox(
              color: state.hovered ? theme.color.sunken : theme.color.surface,
              child: child,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
              child: Row(
                children: [
                  if (widget.leadingIcon != null) ...[
                    Icon(widget.leadingIcon, color: theme.color.brandStrong),
                    SizedBox(width: theme.spacing.s),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.typography.body.copyWith(
                        color: theme.color.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: duration,
                    curve: theme.motion.curve,
                    child: Icon(YhIcons.chevronRight, color: theme.color.muted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: theme.motion.curve,
            alignment: Alignment.topCenter,
            child: _expanded
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: theme.color.border),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(theme.spacing.l),
                      child: widget.content,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
