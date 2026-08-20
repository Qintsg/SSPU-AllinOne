/*
 * 设置页常规分区组件 — 窗口行为与消息推送设置
 * @Project : SSPU-AllinOne
 * @File : settings_general_section.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import '../design/qingyuan/qingyuan_ui.dart';
import 'settings_widgets.dart';

part 'settings_general_helpers.dart';

/// 常规设置分区。
class SettingsGeneralSection extends StatelessWidget {
  final YhThemeMode themeMode;
  final VoidCallback? onOpenAppearance;
  final VoidCallback? onOpenUpdate;

  /// 当前关闭行为。
  final String closeBehavior;

  /// 是否启用消息推送。
  final bool notificationEnabled;

  /// 是否启用勿扰。
  final bool dndEnabled;

  /// 首页是否显示学籍信息卡片。
  final bool homeStudentProfileCardVisible;

  /// 首页是否显示校园卡余额卡片。
  final bool homeCampusCardBalanceCardVisible;

  /// 首页是否显示今日课程磁贴。
  final bool homeTodayCoursesTileVisible;

  /// 首页是否显示体育考勤磁贴。
  final bool homeSportsAttendanceTileVisible;

  /// 首页是否显示第二课堂磁贴。
  final bool homeStudentReportTileVisible;

  /// 首页是否显示最新消息磁贴。
  final bool homeMessagesTileVisible;

  /// 首页是否显示邮箱摘要磁贴。
  final bool homeEmailTileVisible;

  /// 首页是否显示快速跳转磁贴。
  final bool homeQuickLinksTileVisible;

  /// 勿扰开始时间。
  final int dndStartHour;
  final int dndStartMinute;

  /// 勿扰结束时间。
  final int dndEndHour;
  final int dndEndMinute;

  /// 关闭行为修改回调。
  final ValueChanged<String> onCloseBehaviorChanged;

  /// 消息推送开关回调。
  final ValueChanged<bool> onNotificationChanged;

  /// 勿扰开关回调。
  final ValueChanged<bool> onDndChanged;

  /// 首页学籍信息卡片显示开关回调。
  final ValueChanged<bool> onHomeStudentProfileCardVisibleChanged;

  /// 首页校园卡余额卡片显示开关回调。
  final ValueChanged<bool> onHomeCampusCardBalanceCardVisibleChanged;

  /// 首页今日课程磁贴显示开关回调。
  final ValueChanged<bool> onHomeTodayCoursesTileVisibleChanged;

  /// 首页体育考勤磁贴显示开关回调。
  final ValueChanged<bool> onHomeSportsAttendanceTileVisibleChanged;

  /// 首页第二课堂磁贴显示开关回调。
  final ValueChanged<bool> onHomeStudentReportTileVisibleChanged;

  /// 首页最新消息磁贴显示开关回调。
  final ValueChanged<bool> onHomeMessagesTileVisibleChanged;

  /// 首页邮箱摘要磁贴显示开关回调。
  final ValueChanged<bool> onHomeEmailTileVisibleChanged;

  /// 首页快速跳转磁贴显示开关回调。
  final ValueChanged<bool> onHomeQuickLinksTileVisibleChanged;

  /// 勿扰开始时间修改回调。
  final Future<void> Function(int hour, int minute) onDndStartChanged;

  /// 勿扰结束时间修改回调。
  final Future<void> Function(int hour, int minute) onDndEndChanged;

  const SettingsGeneralSection({
    super.key,
    this.themeMode = YhThemeMode.system,
    this.onOpenAppearance,
    this.onOpenUpdate,
    required this.closeBehavior,
    required this.notificationEnabled,
    required this.dndEnabled,
    required this.homeStudentProfileCardVisible,
    required this.homeCampusCardBalanceCardVisible,
    required this.homeTodayCoursesTileVisible,
    required this.homeSportsAttendanceTileVisible,
    required this.homeStudentReportTileVisible,
    required this.homeMessagesTileVisible,
    required this.homeEmailTileVisible,
    required this.homeQuickLinksTileVisible,
    required this.dndStartHour,
    required this.dndStartMinute,
    required this.dndEndHour,
    required this.dndEndMinute,
    required this.onCloseBehaviorChanged,
    required this.onNotificationChanged,
    required this.onDndChanged,
    required this.onHomeStudentProfileCardVisibleChanged,
    required this.onHomeCampusCardBalanceCardVisibleChanged,
    required this.onHomeTodayCoursesTileVisibleChanged,
    required this.onHomeSportsAttendanceTileVisibleChanged,
    required this.onHomeStudentReportTileVisibleChanged,
    required this.onHomeMessagesTileVisibleChanged,
    required this.onHomeEmailTileVisibleChanged,
    required this.onHomeQuickLinksTileVisibleChanged,
    required this.onDndStartChanged,
    required this.onDndEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.yhTheme.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHomeDisplaySection(context),
        SizedBox(height: spacing.l),
        _buildNotificationSection(context),
        SizedBox(height: spacing.l),
        _buildApplicationExperienceSection(context),
      ],
    );
  }

  /// 构建八项首页显示开关的响应式任务账本。
  ///
  /// :param context: 当前清源主题与媒体查询上下文。
  /// :returns: 首页显示设置卡片。
  Widget _buildHomeDisplaySection(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    return YhCard(
      key: const Key('settings-home-display-card'),
      padding: EdgeInsets.fromLTRB(
        theme.spacing.l,
        theme.spacing.l,
        theme.spacing.l,
        compact ? theme.spacing.m : theme.spacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              '首页显示',
              style: theme.typography.h3.copyWith(
                fontWeight: theme.typography.h1.fontWeight,
              ),
            ),
          ),
          SizedBox(height: theme.spacing.s),
          _buildSettingsSubheading(context, '时间与学习'),
          SizedBox(height: theme.spacing.s),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.schedule,
            title: '今日学程时间轨',
            subtitle: '当天课程与时间方向',
            value: homeTodayCoursesTileVisible,
            onChanged: onHomeTodayCoursesTileVisibleChanged,
            key: const Key('settings-home-today-courses-switch'),
          ),
          if (!compact) SizedBox(height: theme.spacing.s),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.info,
            title: '最近校园待办',
            subtitle: '把最近一项校园消息加入时间轨',
            value: homeMessagesTileVisible,
            onChanged: onHomeMessagesTileVisibleChanged,
            key: const Key('settings-home-messages-switch'),
          ),
          if (!compact) SizedBox(height: theme.spacing.s),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.academic,
            title: '培养方案',
            subtitle: '已修学分与培养进度',
            semanticLabel: '显示培养方案概览',
            value: homeStudentProfileCardVisible,
            onChanged: onHomeStudentProfileCardVisibleChanged,
            key: const Key('settings-home-student-profile-card-switch'),
          ),
          if (!compact) SizedBox(height: theme.spacing.s),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.academic,
            title: '第二课堂',
            subtitle: '底部行动坞中的学分进度',
            value: homeStudentReportTileVisible,
            onChanged: onHomeStudentReportTileVisibleChanged,
            key: const Key('settings-home-student-report-switch'),
          ),
          SizedBox(height: theme.spacing.l),
          _buildSettingsSubheading(context, '校园服务'),
          SizedBox(height: theme.spacing.s),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.finance,
            title: '校园卡余额',
            subtitle: '余额、今日消费与交易入口',
            semanticLabel: '显示校园卡余额卡片',
            value: homeCampusCardBalanceCardVisible,
            onChanged: onHomeCampusCardBalanceCardVisibleChanged,
            key: const Key('settings-home-campus-card-switch'),
          ),
          if (!compact) SizedBox(height: theme.spacing.s),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.attendance,
            title: '体育考勤',
            subtitle: '本学期出勤摘要',
            value: homeSportsAttendanceTileVisible,
            onChanged: onHomeSportsAttendanceTileVisibleChanged,
            key: const Key('settings-home-sports-attendance-switch'),
          ),
          if (!compact) SizedBox(height: theme.spacing.s),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.mail,
            title: '学校邮箱',
            subtitle: '未读邮件摘要',
            value: homeEmailTileVisible,
            onChanged: onHomeEmailTileVisibleChanged,
            key: const Key('settings-home-email-switch'),
          ),
          if (!compact) SizedBox(height: theme.spacing.s),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.link,
            title: '常用入口',
            subtitle: '已收藏校园服务行动坞',
            value: homeQuickLinksTileVisible,
            onChanged: onHomeQuickLinksTileVisibleChanged,
            key: const Key('settings-home-quick-links-switch'),
          ),
        ],
      ),
    );
  }

  /// 构建保持标题同行的首页模块开关。
  ///
  /// :param context: 当前清源主题与媒体查询上下文。
  /// :param icon: 模块的语义图标。
  /// :param title: 模块标题。
  /// :param subtitle: 模块说明。
  /// :param semanticLabel: 可选的开关无障碍名称。
  /// :param value: 当前开关值。
  /// :param onChanged: 即时写入回调。
  /// :param key: 用于测试与状态定位的键。
  /// :returns: 当前断点对应的设置行。
  Widget _buildHomeTileSwitch({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    String? semanticLabel,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Key key,
  }) {
    final theme = context.yhTheme;
    final row = buildResponsiveSettingsRow(
      context: context,
      icon: icon,
      title: _settingsTitle(context, title),
      subtitle: _settingsSubtitle(context, subtitle),
      trailing: _buildSettingsSwitch(
        context: context,
        key: key,
        value: value,
        semanticLabel: semanticLabel ?? title,
        onChanged: onChanged,
      ),
      stackTrailing: false,
    );
    if (MediaQuery.sizeOf(context).width >= theme.breakpoint.compact) {
      return row;
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: theme.control.minimumTarget + theme.spacing.s,
      ),
      child: row,
    );
  }

  /// 构建窗口、外观和更新的紧凑应用体验入口。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 应用体验设置卡片。
  Widget _buildApplicationExperienceSection(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('应用体验', style: theme.typography.h3),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            '窗口、外观和更新集中在这里，完整操作会进入对应任务页。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.s),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.close,
            title: _settingsTitle(context, '关闭按钮行为'),
            subtitle: _settingsSubtitle(context, '当前：${_closeBehaviorLabel()}'),
            trailing: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: theme.layout.compactContentWidth,
              ),
              child: YhSelect<String>(
                label: '关闭按钮行为',
                showLabel: false,
                value: closeBehavior,
                options: const [
                  YhSelectOption(value: 'ask', label: '每次询问'),
                  YhSelectOption(value: 'minimize', label: '最小化到托盘'),
                  YhSelectOption(value: 'exit', label: '直接退出'),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onCloseBehaviorChanged(value);
                  }
                },
              ),
            ),
          ),
          _buildSectionDivider(context),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.palette,
            title: _settingsTitle(context, '颜色主题'),
            subtitle: _settingsSubtitle(context, '当前：${_themeModeLabel()}'),
            trailing: YhButton(
              label: '打开外观',
              variant: YhButtonVariant.text,
              onTap: onOpenAppearance,
              disabled: onOpenAppearance == null,
            ),
          ),
          _buildSectionDivider(context),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.download,
            title: _settingsTitle(context, '更新与版本'),
            subtitle: _settingsSubtitle(context, '手动检查，不在启动时自动联网'),
            trailing: YhButton(
              label: '打开更新',
              variant: YhButtonVariant.text,
              onTap: onOpenUpdate,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建消息总开关、勿扰和时间范围设置。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 消息推送设置卡片。
  Widget _buildNotificationSection(BuildContext context) {
    final theme = context.yhTheme;
    final disabledColor = theme.color.border;

    return YhCard(
      key: const Key('settings-notification-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('消息推送', style: theme.typography.h3),
          ),
          SizedBox(height: theme.spacing.m),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.notification,
            title: _settingsTitle(context, '启用消息推送'),
            subtitle: _settingsSubtitle(context, '当自动刷新发现新消息时推送系统通知'),
            trailing: _buildSettingsSwitch(
              context: context,
              value: notificationEnabled,
              semanticLabel: '启用消息推送',
              onChanged: onNotificationChanged,
            ),
            stackTrailing: false,
          ),
          SizedBox(height: theme.spacing.m),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.notificationOff,
            iconColor: notificationEnabled ? null : disabledColor,
            title: Text(
              '勿扰时段',
              style: theme.typography.body.copyWith(
                color: notificationEnabled
                    ? theme.color.foreground
                    : disabledColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '在指定时间段内不推送通知',
              style: theme.typography.small.copyWith(
                color: notificationEnabled ? theme.color.muted : disabledColor,
              ),
            ),
            trailing: _buildSettingsSwitch(
              context: context,
              value: dndEnabled,
              semanticLabel: '勿扰时段',
              onChanged: notificationEnabled ? onDndChanged : null,
            ),
            stackTrailing: false,
          ),
          if (dndEnabled && notificationEnabled)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: theme.spacing.xl2,
                top: theme.spacing.m,
              ),
              child: Wrap(
                spacing: theme.spacing.s,
                runSpacing: theme.spacing.s,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  buildTimePicker(
                    context: context,
                    label: '开始',
                    hour: dndStartHour,
                    minute: dndStartMinute,
                    onChanged: onDndStartChanged,
                  ),
                  Text(
                    '—',
                    style: theme.typography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  buildTimePicker(
                    context: context,
                    label: '结束',
                    hour: dndEndHour,
                    minute: dndEndMinute,
                    onChanged: onDndEndChanged,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
