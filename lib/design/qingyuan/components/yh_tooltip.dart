/* 清源工具提示 — 纯 Widgets Overlay 实现。 */

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';

class YhTooltip extends StatefulWidget {
  const YhTooltip({
    super.key,
    required this.message,
    required this.child,
    this.waitDuration = const Duration(milliseconds: 500),
  });

  final String message;
  final Widget child;
  final Duration waitDuration;

  @override
  State<YhTooltip> createState() => _YhTooltipState();
}

class _YhTooltipState extends State<YhTooltip> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;
  Timer? _timer;
  bool _hovered = false;
  bool _focused = false;

  void _schedule() {
    _timer?.cancel();
    if (_entry != null) return;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final delay = disableAnimations ? Duration.zero : widget.waitDuration;
    _timer = Timer(delay, _show);
  }

  void _show() {
    if (!mounted || (!_hovered && !_focused) || _entry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _entry = OverlayEntry(
      builder: (overlayContext) {
        final theme = overlayContext.yhTheme;
        return Positioned.fill(
          child: IgnorePointer(
            child: CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
              offset: Offset(0, theme.spacing.xs),
              child: Align(
                alignment: Alignment.topCenter,
                widthFactor: 1,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.color.foreground,
                    borderRadius: BorderRadius.circular(theme.radius.s),
                    boxShadow: theme.elevation.e2,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: theme.breakpoint.compact / 2,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: theme.spacing.s,
                        vertical: theme.spacing.xs,
                      ),
                      child: Text(
                        widget.message,
                        style: theme.typography.small.copyWith(
                          color: theme.color.surface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_entry!);
  }

  void _hideIfInactive() {
    if (_hovered || _focused) return;
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  @override
  void didUpdateWidget(YhTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message && _entry != null) {
      _entry!.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      hint: widget.message,
      child: Focus(
        canRequestFocus: false,
        onFocusChange: (focused) {
          _focused = focused;
          if (focused) {
            _schedule();
          } else {
            _hideIfInactive();
          }
        },
        child: MouseRegion(
          onEnter: (_) {
            _hovered = true;
            _schedule();
          },
          onExit: (_) {
            _hovered = false;
            _hideIfInactive();
          },
          child: CompositedTransformTarget(
            link: _layerLink,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
