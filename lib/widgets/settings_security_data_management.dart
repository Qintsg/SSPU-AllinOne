/*
 * 设置页安全分区数据管理 — 整合本地缓存与全量数据清理入口
 * @Project : SSPU-AllinOne
 * @File : settings_security_data_management.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

part of 'settings_security_section.dart';

class _DataManagementRow extends StatelessWidget {
  const _DataManagementRow({
    required this.onClearMessageCache,
    required this.onClearAllData,
  });

  final VoidCallback onClearMessageCache;
  final VoidCallback onClearAllData;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final colors = context.fluentColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack = shouldStackSettingsControls(constraints);
        final summary = _buildSummary(theme, colors);
        final actions = _buildActions();

        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summary,
              const SizedBox(height: FluentSpacing.m),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: summary),
            const SizedBox(width: FluentSpacing.l),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildSummary(FluentThemeData theme, FluentColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(FluentIcons.database, color: colors.statusDangerForeground),
        const SizedBox(width: FluentSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('数据管理', style: theme.typography.subtitle),
              const SizedBox(height: FluentSpacing.xs),
              Text(
                '清理信息中心缓存，或清除所有本地数据并退出应用。',
                style: theme.typography.caption?.copyWith(
                  color: colors.neutralForeground2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Wrap(
      spacing: FluentSpacing.s,
      runSpacing: FluentSpacing.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DangerActionButton(
          key: const Key('settings-clear-message-cache'),
          icon: FluentIcons.broom,
          label: '清理信息中心缓存',
          onPressed: onClearMessageCache,
        ),
        _DangerActionButton(
          key: const Key('settings-clear-all-data'),
          icon: FluentIcons.delete,
          label: '清除所有数据',
          onPressed: onClearAllData,
        ),
      ],
    );
  }
}

class _DangerActionButton extends StatelessWidget {
  const _DangerActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final type = context.fluentType;
    final style = ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsetsDirectional.symmetric(
          horizontal: FluentSpacing.m,
          vertical: FluentSpacing.xs,
        ),
      ),
      textStyle: WidgetStatePropertyAll(type.body1Strong),
      iconSize: const WidgetStatePropertyAll(16),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: radii.mediumBorder),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.isPressed) {
          return colors.statusDangerForeground.withValues(alpha: 0.18);
        }
        if (states.isHovered || states.isFocused) {
          return colors.statusDangerForeground.withValues(alpha: 0.12);
        }
        return colors.statusDangerBackground;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.isDisabled) return colors.neutralForegroundDisabled;
        return colors.statusDangerForeground;
      }),
    );

    return ButtonTheme.merge(
      data: ButtonThemeData(defaultButtonStyle: style),
      child: Button(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(width: FluentSpacing.xs + FluentSpacing.xxs),
            Text(label),
          ],
        ),
      ),
    );
  }
}
