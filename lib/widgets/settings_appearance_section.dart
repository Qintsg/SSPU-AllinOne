/* 清源设置外观分区 — 主题模式与视觉预览。 */

import '../design/qingyuan/qingyuan_ui.dart';

/// 主题模式设置，保持系统/亮色/暗色三态与清源宿主一致。
class SettingsAppearanceSection extends StatelessWidget {
  const SettingsAppearanceSection({
    super.key,
    required this.themeMode,
    required this.onChanged,
  });

  final YhThemeMode themeMode;
  final ValueChanged<YhThemeMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('外观', style: theme.typography.h3),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            '选择应用界面的明暗模式；系统模式会跟随设备设置。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: YhSegmented<YhThemeMode>(
              value: themeMode,
              onChanged: onChanged,
              options: const [
                YhSegmentedOption(
                  value: YhThemeMode.system,
                  label: '跟随系统',
                  icon: YhIcons.settings,
                ),
                YhSegmentedOption(
                  value: YhThemeMode.light,
                  label: '亮色',
                  icon: YhIcons.sun,
                ),
                YhSegmentedOption(
                  value: YhThemeMode.dark,
                  label: '暗色',
                  icon: YhIcons.moon,
                ),
              ],
            ),
          ),
          SizedBox(height: theme.spacing.m),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.color.sunken,
              border: Border.all(color: theme.color.border),
              borderRadius: BorderRadius.circular(theme.radius.input),
            ),
            child: Padding(
              padding: EdgeInsets.all(theme.spacing.m),
              child: Row(
                children: [
                  Icon(YhIcons.palette, color: theme.color.brandStrong),
                  SizedBox(width: theme.spacing.m),
                  Expanded(
                    child: Text(
                      '清源界面会同时保持 MiSans 排版、低饱和校园色与可见焦点。',
                      style: theme.typography.small.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
