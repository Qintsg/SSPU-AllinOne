/*
 * 应用外观设置与动态配色
 * @Project : SSPU-AllinOne
 * @File : settings_appearance_page.dart
 * @Author : Qintsg, Codex
 * @Date : 2026-11-19
 */

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
  bool _savingMonet = false;

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
    final appearance = YhMonetPreference.maybeOf(context);
    final theme = context.yhTheme;
    return YhTaskPage(
      title: '外观',
      kicker: '设置',
      summary: '',
      source: '本机外观设置',
      sourceSymbol: '设',
      bodyFit: YhTaskPageBodyFit.content,
      primaryActionLabel: '完成',
      onPrimaryAction: widget.onApply,
      body: Builder(
        builder: (bodyContext) => Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: bodyContext.yhTheme.layout.formContentWidth,
            ),
            child: YhCard(
              padding: EdgeInsets.all(theme.spacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('明暗模式', style: theme.typography.h3),
                  SizedBox(height: theme.spacing.s),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: YhSegmented<YhThemeMode>(
                      key: const Key('appearance-theme-choice'),
                      value: _themeMode,
                      onChanged: widget.onChanged == null
                          ? null
                          : _changeThemeMode,
                      options: const [
                        YhSegmentedOption(
                          value: YhThemeMode.system,
                          label: '跟随系统',
                        ),
                        YhSegmentedOption(
                          value: YhThemeMode.light,
                          label: '亮色',
                        ),
                        YhSegmentedOption(value: YhThemeMode.dark, label: '暗色'),
                      ],
                    ),
                  ),
                  if (appearance?.onChanged case final onChanged?) ...[
                    SizedBox(height: theme.spacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Monet 动态配色', style: theme.typography.body),
                              SizedBox(height: theme.spacing.xs),
                              Text(
                                !kIsWeb &&
                                        defaultTargetPlatform ==
                                            TargetPlatform.android
                                    ? '从系统壁纸取色。'
                                    : '从应用品牌色生成配色。',
                                style: theme.typography.small.copyWith(
                                  color: theme.color.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        YhSwitch(
                          key: const Key('appearance-monet-switch'),
                          value: appearance!.enabled,
                          onChanged: (enabled) => _setMonet(onChanged, enabled),
                          disabled: _savingMonet,
                          semanticLabel: 'Monet 动态配色',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _changeThemeMode(YhThemeMode value) {
    setState(() => _themeMode = value);
    widget.onChanged?.call(value);
  }

  /// 写入动态色偏好，保存期间暂停重复操作。
  Future<void> _setMonet(Future<void> Function(bool) save, bool enabled) async {
    if (_savingMonet) return;
    setState(() => _savingMonet = true);
    try {
      await save(enabled);
    } on Exception {
      if (mounted) {
        showYhFeedback(
          context,
          message: '未能保存动态配色设置',
          severity: AppFeedbackSeverity.error,
        );
      }
    } finally {
      if (mounted) setState(() => _savingMonet = false);
    }
  }
}
