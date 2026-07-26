/*
 * 设置页常规分区组件 — 窗口行为与消息推送设置
 * @Project : SSPU-AllinOne
 * @File : settings_general_section.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import '../design/qingyuan/qingyuan_ui.dart';
import 'settings_update_section.dart';
import 'settings_appearance_section.dart';
import 'settings_widgets.dart';

/// 常规设置分区。
class SettingsGeneralSection extends StatelessWidget {
  final YhThemeMode themeMode;
  final VoidCallback? onOpenAppearance;

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
        _buildWindowBehaviorSection(context),
        SizedBox(height: spacing.l),
        SettingsAppearanceSection(
          themeMode: themeMode,
          onOpenDetails: onOpenAppearance,
        ),
        SizedBox(height: spacing.l),
        _buildHomeDisplaySection(context),
        SizedBox(height: spacing.l),
        SettingsUpdateSection(),
        SizedBox(height: spacing.l),
        _buildNotificationSection(context),
      ],
    );
  }

  Widget _buildHomeDisplaySection(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('首页显示', style: theme.typography.h3),
          ),
          SizedBox(height: theme.spacing.m),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.calendar,
            title: '显示今日学程时间轨',
            subtitle: '在主页时间轨展示当天课程',
            value: homeTodayCoursesTileVisible,
            onChanged: onHomeTodayCoursesTileVisibleChanged,
            key: const Key('settings-home-today-courses-switch'),
          ),
          SizedBox(height: theme.spacing.m),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.contact,
            title: _settingsTitle(context, '显示培养方案概览'),
            subtitle: _settingsSubtitle(context, '在主页概览展示已修学分和培养进度'),
            trailing: YhSwitch(
              key: const Key('settings-home-student-profile-card-switch'),
              semanticLabel: '显示培养方案概览',
              value: homeStudentProfileCardVisible,
              onChanged: onHomeStudentProfileCardVisibleChanged,
            ),
          ),
          SizedBox(height: theme.spacing.m),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.finance,
            title: _settingsTitle(context, '显示校园卡余额卡片'),
            subtitle: _settingsSubtitle(context, '在主页首屏展示校园卡余额和交易记录入口'),
            trailing: YhSwitch(
              key: const Key('settings-home-campus-card-switch'),
              semanticLabel: '显示校园卡余额卡片',
              value: homeCampusCardBalanceCardVisible,
              onChanged: onHomeCampusCardBalanceCardVisibleChanged,
            ),
          ),
          SizedBox(height: theme.spacing.m),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.sports,
            title: '显示体育考勤磁贴',
            subtitle: '在主页仪表盘展示体育考勤缓存摘要',
            value: homeSportsAttendanceTileVisible,
            onChanged: onHomeSportsAttendanceTileVisibleChanged,
            key: const Key('settings-home-sports-attendance-switch'),
          ),
          SizedBox(height: theme.spacing.m),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.academic,
            title: '显示第二课堂辅助坞',
            subtitle: '在时间轨下方展示第二课堂学分进度',
            value: homeStudentReportTileVisible,
            onChanged: onHomeStudentReportTileVisibleChanged,
            key: const Key('settings-home-student-report-switch'),
          ),
          SizedBox(height: theme.spacing.m),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.news,
            title: '显示时间轨待办',
            subtitle: '在主页时间轨展示最近校园待办',
            value: homeMessagesTileVisible,
            onChanged: onHomeMessagesTileVisibleChanged,
            key: const Key('settings-home-messages-switch'),
          ),
          SizedBox(height: theme.spacing.m),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.mail,
            title: '显示邮箱摘要磁贴',
            subtitle: '在主页仪表盘展示学校邮箱缓存摘要',
            value: homeEmailTileVisible,
            onChanged: onHomeEmailTileVisibleChanged,
            key: const Key('settings-home-email-switch'),
          ),
          SizedBox(height: theme.spacing.m),
          _buildHomeTileSwitch(
            context: context,
            icon: YhIcons.link,
            title: '显示常用入口辅助坞',
            subtitle: '在时间轨下方展示已收藏的校园服务',
            value: homeQuickLinksTileVisible,
            onChanged: onHomeQuickLinksTileVisibleChanged,
            key: const Key('settings-home-quick-links-switch'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTileSwitch({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Key key,
  }) {
    return buildResponsiveSettingsRow(
      context: context,
      icon: icon,
      title: _settingsTitle(context, title),
      subtitle: _settingsSubtitle(context, subtitle),
      trailing: YhSwitch(
        key: key,
        value: value,
        semanticLabel: title,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildWindowBehaviorSection(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('窗口行为', style: theme.typography.h3),
          ),
          SizedBox(height: theme.spacing.m),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.close,
            title: _settingsTitle(context, '关闭按钮行为'),
            subtitle: _settingsSubtitle(context, '选择点击窗口关闭按钮时的操作'),
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
        ],
      ),
    );
  }

  Widget _buildNotificationSection(BuildContext context) {
    final theme = context.yhTheme;
    final disabledColor = theme.color.border;

    return YhCard(
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
            trailing: YhSwitch(
              value: notificationEnabled,
              semanticLabel: '启用消息推送',
              onChanged: onNotificationChanged,
            ),
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
            trailing: YhSwitch(
              value: dndEnabled,
              semanticLabel: '勿扰时段',
              onChanged: notificationEnabled ? onDndChanged : null,
            ),
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

  Widget _settingsTitle(BuildContext context, String text) => Text(
    text,
    style: context.yhTheme.typography.body.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _settingsSubtitle(BuildContext context, String text) => Text(
    text,
    style: context.yhTheme.typography.small.copyWith(
      color: context.yhTheme.color.muted,
    ),
  );
}
