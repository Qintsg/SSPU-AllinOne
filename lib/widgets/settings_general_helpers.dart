/*
 * 设置页常规分区辅助渲染 — 标题、开关与语义标签
 * @Project : SSPU-AllinOne
 * @File : settings_general_helpers.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'settings_general_section.dart';

extension _SettingsGeneralHelpers on SettingsGeneralSection {
  /// 构建首页显示设置的轻量分组标题。
  ///
  /// :param context: 当前清源主题上下文。
  /// :param label: 分组标题文本。
  /// :returns: 具备标题语义的轻量分组标签。
  Widget _buildSettingsSubheading(BuildContext context, String label) {
    final theme = context.yhTheme;
    return Semantics(
      header: true,
      child: Text(
        label,
        style: theme.typography.caption.copyWith(
          color: theme.color.muted,
          fontWeight: theme.typography.semibold,
          letterSpacing: theme.layout.divider,
        ),
      ),
    );
  }

  /// 构建设置行标题。
  ///
  /// :param context: 当前清源主题上下文。
  /// :param text: 标题文本。
  /// :returns: 使用语义标题字重的文本。
  Widget _settingsTitle(BuildContext context, String text) => Text(
    text,
    style: context.yhTheme.typography.body.copyWith(
      fontWeight: context.yhTheme.typography.h1.fontWeight,
    ),
  );

  /// 构建设置行辅助说明。
  ///
  /// :param context: 当前清源主题上下文。
  /// :param text: 辅助说明文本。
  /// :returns: 使用弱化前景的辅助文本。
  Widget _settingsSubtitle(BuildContext context, String text) => Text(
    text,
    style: context.yhTheme.typography.small.copyWith(
      color: context.yhTheme.color.muted,
    ),
  );

  /// 为设置行提供 52dp 横向命中区，同时保持可见轨道尺寸不变。
  ///
  /// :param context: 当前清源主题上下文。
  /// :param value: 当前开关值。
  /// :param semanticLabel: 开关无障碍名称。
  /// :param onChanged: 即时写入回调；为空时禁用。
  /// :param key: 用于测试与状态定位的键。
  /// :returns: 居中承载清源开关的命中区域。
  Widget _buildSettingsSwitch({
    required BuildContext context,
    required bool value,
    required String semanticLabel,
    required ValueChanged<bool>? onChanged,
    Key? key,
  }) {
    final theme = context.yhTheme;
    return SizedBox(
      width: theme.control.minimumTarget + theme.spacing.xs,
      child: Center(
        child: YhSwitch(
          key: key,
          value: value,
          semanticLabel: semanticLabel,
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// 构建设置任务之间的轻量分隔线。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 使用布局 token 的分隔线。
  Widget _buildSectionDivider(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.s),
      child: SizedBox(
        height: theme.layout.divider,
        width: double.infinity,
        child: ColoredBox(color: theme.color.border),
      ),
    );
  }

  /// 返回当前窗口关闭行为的用户可读标签。
  ///
  /// :returns: 当前关闭策略文本。
  String _closeBehaviorLabel() => switch (closeBehavior) {
    'minimize' => '最小化到托盘',
    'exit' => '直接退出',
    _ => '每次询问',
  };

  /// 返回当前主题模式的用户可读标签。
  ///
  /// :returns: 当前主题模式文本。
  String _themeModeLabel() => switch (themeMode) {
    YhThemeMode.system => '跟随系统',
    YhThemeMode.light => '亮色',
    YhThemeMode.dark => '暗色',
  };
}
