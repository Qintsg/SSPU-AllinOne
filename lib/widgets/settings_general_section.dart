/*
 * 设置页常规分区组件 — 窗口行为与消息推送设置
 * @Project : SSPU-AllinOne
 * @File : settings_general_section.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import '../design/fluent_ui.dart';

import '../theme/app_spacing.dart';
import 'settings_update_section.dart';
import 'settings_widgets.dart';

/// 常规设置分区。
class SettingsGeneralSection extends StatelessWidget {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWindowBehaviorSection(context),
        const SizedBox(height: AppSpacing.lg),
        _buildHomeDisplaySection(context),
        const SizedBox(height: AppSpacing.lg),
        SettingsUpdateSection(),
        const SizedBox(height: AppSpacing.lg),
        _buildNotificationSection(context),
      ],
    );
  }

  Widget _buildHomeDisplaySection(BuildContext context) {
    final type = context.fluentType;
    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('首页显示', style: type.subtitle1)),
            const SizedBox(height: AppSpacing.md),
            _buildHomeTileSwitch(
              context: context,
              icon: FluentIcons.calendar,
              title: '显示今日课程磁贴',
              subtitle: '在主页仪表盘展示当天课表摘要',
              value: homeTodayCoursesTileVisible,
              onChanged: onHomeTodayCoursesTileVisibleChanged,
              key: const Key('settings-home-today-courses-switch'),
            ),
            const SizedBox(height: AppSpacing.md),
            buildResponsiveSettingsRow(
              context: context,
              icon: FluentIcons.contact,
              title: Text('显示学籍信息卡片', style: type.body1Strong),
              subtitle: Text('在主页首屏展示姓名、学号、院系、专业和行政班级', style: type.caption1),
              trailing: FluentSwitch(
                key: const Key('settings-home-student-profile-card-switch'),
                value: homeStudentProfileCardVisible,
                onChanged: onHomeStudentProfileCardVisibleChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            buildResponsiveSettingsRow(
              context: context,
              icon: FluentIcons.paymentCard,
              title: Text('显示校园卡余额卡片', style: type.body1Strong),
              subtitle: Text('在主页首屏展示校园卡余额和交易记录入口', style: type.caption1),
              trailing: FluentSwitch(
                key: const Key('settings-home-campus-card-switch'),
                value: homeCampusCardBalanceCardVisible,
                onChanged: onHomeCampusCardBalanceCardVisibleChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildHomeTileSwitch(
              context: context,
              icon: FluentIcons.running,
              title: '显示体育考勤磁贴',
              subtitle: '在主页仪表盘展示体育考勤缓存摘要',
              value: homeSportsAttendanceTileVisible,
              onChanged: onHomeSportsAttendanceTileVisibleChanged,
              key: const Key('settings-home-sports-attendance-switch'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildHomeTileSwitch(
              context: context,
              icon: FluentIcons.education,
              title: '显示第二课堂磁贴',
              subtitle: '在主页仪表盘展示第二课堂学分摘要',
              value: homeStudentReportTileVisible,
              onChanged: onHomeStudentReportTileVisibleChanged,
              key: const Key('settings-home-student-report-switch'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildHomeTileSwitch(
              context: context,
              icon: FluentIcons.news,
              title: '显示最新消息磁贴',
              subtitle: '在主页仪表盘展示最近校园消息',
              value: homeMessagesTileVisible,
              onChanged: onHomeMessagesTileVisibleChanged,
              key: const Key('settings-home-messages-switch'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildHomeTileSwitch(
              context: context,
              icon: FluentIcons.mail,
              title: '显示邮箱摘要磁贴',
              subtitle: '在主页仪表盘展示学校邮箱缓存摘要',
              value: homeEmailTileVisible,
              onChanged: onHomeEmailTileVisibleChanged,
              key: const Key('settings-home-email-switch'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildHomeTileSwitch(
              context: context,
              icon: FluentIcons.link,
              title: '显示快速跳转磁贴',
              subtitle: '在主页仪表盘展示常用校园入口',
              value: homeQuickLinksTileVisible,
              onChanged: onHomeQuickLinksTileVisibleChanged,
              key: const Key('settings-home-quick-links-switch'),
            ),
          ],
        ),
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
    final type = context.fluentType;
    return buildResponsiveSettingsRow(
      context: context,
      icon: icon,
      title: Text(title, style: type.body1Strong),
      subtitle: Text(subtitle, style: type.caption1),
      trailing: FluentSwitch(key: key, value: value, onChanged: onChanged),
    );
  }

  Widget _buildWindowBehaviorSection(BuildContext context) {
    final type = context.fluentType;
    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('窗口行为', style: type.subtitle1)),
            const SizedBox(height: AppSpacing.md),
            buildResponsiveSettingsRow(
              context: context,
              icon: FluentIcons.clear,
              title: Text('关闭按钮行为', style: type.body1Strong),
              subtitle: Text('选择点击窗口关闭按钮时的操作', style: type.caption1),
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: FluentSelect<String>(
                  isExpanded: true,
                  value: closeBehavior,
                  items: const [
                    FluentSelectItem(value: 'ask', child: Text('每次询问')),
                    FluentSelectItem(value: 'minimize', child: Text('最小化到托盘')),
                    FluentSelectItem(value: 'exit', child: Text('直接退出')),
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
      ),
    );
  }

  Widget _buildNotificationSection(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final disabledColor = colors.neutralForegroundDisabled;

    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('消息推送', style: type.subtitle1)),
            const SizedBox(height: AppSpacing.md),
            buildResponsiveSettingsRow(
              context: context,
              icon: FluentIcons.ringer,
              title: Text('启用消息推送', style: type.body1Strong),
              subtitle: Text('当自动刷新发现新消息时推送系统通知', style: type.caption1),
              trailing: FluentSwitch(
                value: notificationEnabled,
                onChanged: onNotificationChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            buildResponsiveSettingsRow(
              context: context,
              icon: FluentIcons.ringerOff,
              iconColor: notificationEnabled ? null : disabledColor,
              title: Text(
                '勿扰时段',
                style: type.body1Strong.copyWith(
                  color: notificationEnabled ? null : disabledColor,
                ),
              ),
              subtitle: Text(
                '在指定时间段内不推送通知',
                style: type.caption1.copyWith(
                  color: notificationEnabled ? null : disabledColor,
                ),
              ),
              trailing: FluentSwitch(
                value: dndEnabled,
                onChanged: notificationEnabled ? onDndChanged : null,
              ),
            ),
            if (dndEnabled && notificationEnabled)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xxl,
                  top: AppSpacing.md,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    buildTimePicker(
                      context: context,
                      label: '开始',
                      hour: dndStartHour,
                      minute: dndStartMinute,
                      onChanged: onDndStartChanged,
                    ),
                    Text('—', style: type.body1Strong),
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
      ),
    );
  }
}
