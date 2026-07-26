/* 清源外观设置任务页。 */

import '../design/qingyuan/qingyuan_ui.dart';

class SettingsAppearancePage extends StatefulWidget {
  const SettingsAppearancePage({
    super.key,
    required this.themeMode,
    required this.onChanged,
    required this.onApply,
  });

  final YhThemeMode themeMode;
  final ValueChanged<YhThemeMode>? onChanged;
  final VoidCallback onApply;

  @override
  State<SettingsAppearancePage> createState() => _SettingsAppearancePageState();
}

class _SettingsAppearancePageState extends State<SettingsAppearancePage> {
  late YhThemeMode _themeMode = widget.themeMode;

  @override
  void didUpdateWidget(covariant SettingsAppearancePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode &&
        widget.themeMode != _themeMode) {
      _themeMode = widget.themeMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return YhTaskPage(
      title: '外观',
      kicker: '设置',
      summary: '跟随系统、亮色和暗色即时生效，并保持相同信息层级。',
      source: '本机外观设置',
      sourceSymbol: '设',
      primaryActionLabel: '应用主题',
      onPrimaryAction: widget.onApply,
      body: _AppearanceTaskCard(
        themeMode: _themeMode,
        onChanged: widget.onChanged == null ? null : _changeThemeMode,
      ),
    );
  }

  void _changeThemeMode(YhThemeMode value) {
    setState(() => _themeMode = value);
    widget.onChanged?.call(value);
  }
}

class _AppearanceTaskCard extends StatelessWidget {
  const _AppearanceTaskCard({required this.themeMode, required this.onChanged});

  final YhThemeMode themeMode;
  final ValueChanged<YhThemeMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: Border.all(
          color: theme.color.border,
          width: theme.layout.controlBorder,
        ),
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.l),
        child: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: YhSegmented<YhThemeMode>(
              value: themeMode,
              onChanged: onChanged,
              options: const [
                YhSegmentedOption(value: YhThemeMode.system, label: '跟随系统'),
                YhSegmentedOption(value: YhThemeMode.light, label: '亮色'),
                YhSegmentedOption(value: YhThemeMode.dark, label: '暗色'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
