/* 清源设置外观分区 — 主题模式与视觉预览。 */

import '../design/qingyuan/qingyuan_ui.dart';

/// 主题模式摘要；完整三态编辑由独立外观任务页承载。
class SettingsAppearanceSection extends StatelessWidget {
  const SettingsAppearanceSection({
    super.key,
    required this.themeMode,
    this.onOpenDetails,
  });

  final YhThemeMode themeMode;
  final VoidCallback? onOpenDetails;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('颜色主题', style: theme.typography.body),
                        SizedBox(height: theme.spacing.xs),
                        Text(
                          '当前：${_themeModeLabel(themeMode)}',
                          style: theme.typography.small.copyWith(
                            color: theme.color.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onOpenDetails != null) ...[
            SizedBox(height: theme.spacing.m),
            YhButton(
              label: '打开外观设置',
              onTap: onOpenDetails,
              variant: YhButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }

  String _themeModeLabel(YhThemeMode mode) => switch (mode) {
    YhThemeMode.system => '跟随系统',
    YhThemeMode.light => '亮色',
    YhThemeMode.dark => '暗色',
  };
}
