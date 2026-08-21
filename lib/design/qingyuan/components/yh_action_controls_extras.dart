/*
 * 清源滑杆与步骤器 — 从操作控件中独立出的交互控件
 * @Project : SSPU-AllinOne
 * @File : yh_action_controls_extras.dart
 * @Author : Qintsg
 * @Date : 2026-08-21
 */

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';

class YhSlider extends StatefulWidget {
  const YhSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '滑杆',
    this.divisions,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final String label;
  final int? divisions;

  @override
  State<YhSlider> createState() => _YhSliderState();
}

class _YhSliderState extends State<YhSlider> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'YhSlider');

  double get _value => widget.value.clamp(0, 1);

  void _setValue(double value) {
    if (widget.onChanged == null) return;
    final normalized = value.clamp(0.0, 1.0);
    final divisions = widget.divisions;
    widget.onChanged!(
      divisions == null
          ? normalized
          : (normalized * divisions).round() / divisions,
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Semantics(
      slider: true,
      enabled: widget.onChanged != null,
      label: widget.label,
      value: '${(_value * 100).round()}%',
      increasedValue: '${((_value + 0.1).clamp(0, 1) * 100).round()}%',
      decreasedValue: '${((_value - 0.1).clamp(0, 1) * 100).round()}%',
      onIncrease: widget.onChanged == null
          ? null
          : () => _setValue(_value + 0.1),
      onDecrease: widget.onChanged == null
          ? null
          : () => _setValue(_value - 0.1),
      child: FocusableActionDetector(
        enabled: widget.onChanged != null,
        focusNode: _focusNode,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowRight):
              DirectionalFocusIntent(TraversalDirection.right),
          SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(
            TraversalDirection.left,
          ),
        },
        actions: {
          DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
            onInvoke: (intent) {
              _setValue(
                _value +
                    (intent.direction == TraversalDirection.right ? 0.1 : -0.1),
              );
              return null;
            },
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.onChanged == null
                ? null
                : (details) => _setValue(
                    details.localPosition.dx / constraints.maxWidth,
                  ),
            onHorizontalDragUpdate: widget.onChanged == null
                ? null
                : (details) => _setValue(
                    details.localPosition.dx / constraints.maxWidth,
                  ),
            child: SizedBox(
              height: theme.control.minimumTarget,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: theme.spacing.s,
                    decoration: BoxDecoration(
                      color: theme.color.border,
                      borderRadius: BorderRadius.circular(theme.radius.full),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _value,
                    child: Container(
                      height: theme.spacing.s,
                      decoration: BoxDecoration(
                        color: theme.color.brandStrong,
                        borderRadius: BorderRadius.circular(theme.radius.full),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(_value * 2 - 1, 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.color.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.color.brandStrong,
                          width: theme.focus.ringWidth,
                        ),
                        boxShadow: theme.elevation.e1,
                      ),
                      child: SizedBox.square(dimension: theme.spacing.l),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class YhStepper extends StatelessWidget {
  const YhStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    this.onStepSelected,
  });

  final List<String> steps;
  final int currentStep;
  final ValueChanged<int>? onStepSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0)
            Expanded(
              child: Container(
                height: theme.focus.ringWidth,
                color: index <= currentStep
                    ? theme.color.brandStrong
                    : theme.color.border,
              ),
            ),
          YhPressable(
            semanticLabel: '第 ${index + 1} 步，${steps[index]}',
            selected: index == currentStep,
            onPressed: onStepSelected == null
                ? null
                : () => onStepSelected!(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: index <= currentStep
                        ? theme.color.brandStrong
                        : theme.color.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.color.border),
                  ),
                  child: SizedBox.square(
                    dimension: theme.spacing.xl,
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.typography.small.copyWith(
                          color: index <= currentStep
                              ? theme.color.onBrand
                              : theme.color.muted,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(steps[index], style: theme.typography.caption),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
