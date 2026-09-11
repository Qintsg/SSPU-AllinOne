/*
 * 设置页常规分区组件 — 窗口行为与消息推送设置
 * @Project : SSPU-AllinOne
 * @File : settings_general_section.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import '../design/qingyuan/qingyuan_ui.dart';
import '../services/data_module_preferences.dart';
import '../services/home_dashboard_preferences.dart';
import '../services/notification_service.dart';
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

  /// 是否启用普通校园消息通知。
  final bool messageNotificationEnabled;

  /// 当前系统通知权限状态。
  final NotificationPermissionStatus notificationPermissionStatus;

  /// 是否启用勿扰。
  final bool dndEnabled;

  /// 是否启用课程开始提醒。
  final bool courseReminderEnabled;

  /// 是否启用考试提醒。
  final bool examReminderEnabled;

  /// 课程提醒提前量，单位分钟。
  final int courseReminderLeadMinutes;

  /// 考试提醒提前量，单位分钟。
  final int examReminderLeadMinutes;

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

  /// 首页服务摘要的展示顺序。
  final List<HomeOverviewItem> homeOverviewOrder;

  /// 各校园数据模块是否允许联网获取。
  final Map<CampusDataModule, bool> dataModuleFetchEnabled;

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

  /// 普通校园消息通知开关回调。
  final ValueChanged<bool> onMessageNotificationChanged;

  /// 重新查询系统通知权限。
  final VoidCallback onNotificationPermissionRefresh;

  /// 勿扰开关回调。
  final ValueChanged<bool> onDndChanged;

  /// 课程提醒开关回调。
  final ValueChanged<bool> onCourseReminderChanged;

  /// 考试提醒开关回调。
  final ValueChanged<bool> onExamReminderChanged;

  /// 课程提醒提前量修改回调。
  final ValueChanged<int> onCourseReminderLeadMinutesChanged;

  /// 考试提醒提前量修改回调。
  final ValueChanged<int> onExamReminderLeadMinutesChanged;

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

  /// 首页服务摘要顺序修改回调。
  final ValueChanged<List<HomeOverviewItem>> onHomeOverviewOrderChanged;

  /// 模块联网获取权限修改回调。
  final void Function(CampusDataModule module, bool enabled)
  onDataModuleFetchChanged;

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
    required this.messageNotificationEnabled,
    this.notificationPermissionStatus = NotificationPermissionStatus.unknown,
    required this.dndEnabled,
    required this.courseReminderEnabled,
    required this.examReminderEnabled,
    required this.courseReminderLeadMinutes,
    required this.examReminderLeadMinutes,
    required this.homeStudentProfileCardVisible,
    required this.homeCampusCardBalanceCardVisible,
    required this.homeTodayCoursesTileVisible,
    required this.homeSportsAttendanceTileVisible,
    required this.homeStudentReportTileVisible,
    required this.homeMessagesTileVisible,
    required this.homeEmailTileVisible,
    required this.homeQuickLinksTileVisible,
    required this.homeOverviewOrder,
    required this.dataModuleFetchEnabled,
    required this.dndStartHour,
    required this.dndStartMinute,
    required this.dndEndHour,
    required this.dndEndMinute,
    required this.onCloseBehaviorChanged,
    required this.onNotificationChanged,
    required this.onMessageNotificationChanged,
    required this.onNotificationPermissionRefresh,
    required this.onDndChanged,
    required this.onCourseReminderChanged,
    required this.onExamReminderChanged,
    required this.onCourseReminderLeadMinutesChanged,
    required this.onExamReminderLeadMinutesChanged,
    required this.onHomeStudentProfileCardVisibleChanged,
    required this.onHomeCampusCardBalanceCardVisibleChanged,
    required this.onHomeTodayCoursesTileVisibleChanged,
    required this.onHomeSportsAttendanceTileVisibleChanged,
    required this.onHomeStudentReportTileVisibleChanged,
    required this.onHomeMessagesTileVisibleChanged,
    required this.onHomeEmailTileVisibleChanged,
    required this.onHomeQuickLinksTileVisibleChanged,
    required this.onHomeOverviewOrderChanged,
    required this.onDataModuleFetchChanged,
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
        _buildDataAccessSection(context),
        SizedBox(height: spacing.l),
        _buildNotificationSection(context),
        SizedBox(height: spacing.l),
        _buildApplicationExperienceSection(context),
      ],
    );
  }

  /// 构建独立于首页显隐和自动刷新频率的联网获取权限卡片。
  Widget _buildDataAccessSection(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      key: const Key('settings-data-module-access-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              '联网获取',
              style: theme.typography.h3.copyWith(
                fontWeight: theme.typography.h1.fontWeight,
              ),
            ),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            '关闭后继续保留本地缓存，但首页、详情页、手动刷新与后台刷新都不会访问对应校园服务。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.s),
          for (
            var index = 0;
            index < CampusDataModule.values.length;
            index++
          ) ...[
            if (index > 0) SizedBox(height: theme.spacing.xs),
            _buildDataModuleFetchRow(context, CampusDataModule.values[index]),
          ],
        ],
      ),
    );
  }

  /// 构建单个校园数据模块的获取权限开关。
  Widget _buildDataModuleFetchRow(
    BuildContext context,
    CampusDataModule module,
  ) {
    final (title, subtitle, icon) = switch (module) {
      CampusDataModule.academicEams => (
        '本专科教务数据',
        '课表、成绩、考试与培养方案',
        YhIcons.academic,
      ),
      CampusDataModule.campusCard => ('校园卡数据', '余额、卡状态与消费明细', YhIcons.finance),
      CampusDataModule.email => ('学校邮箱数据', '收件箱、邮件正文与附件', YhIcons.mail),
      CampusDataModule.sportsAttendance => (
        '体育考勤数据',
        '体育部课外活动打卡记录',
        YhIcons.attendance,
      ),
      CampusDataModule.studentReport => (
        '第二课堂数据',
        '学工报表与第二课堂学分',
        YhIcons.education,
      ),
    };
    return _buildHomeTileSwitch(
      context: context,
      icon: icon,
      title: title,
      subtitle: subtitle,
      semanticLabel: '允许获取$title',
      value: dataModuleFetchEnabled[module] ?? true,
      onChanged: (enabled) => onDataModuleFetchChanged(module, enabled),
      key: Key('settings-module-${module.storageId}-fetch-switch'),
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
          _buildSettingsSubheading(context, '时间与行动'),
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
            title: '第二课堂',
            subtitle: '底部行动坞中的学分进度',
            value: homeStudentReportTileVisible,
            onChanged: onHomeStudentReportTileVisibleChanged,
            key: const Key('settings-home-student-report-switch'),
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
          SizedBox(height: theme.spacing.l),
          _buildSettingsSubheading(context, '服务摘要'),
          SizedBox(height: theme.spacing.xs),
          Text(
            '排序只改变首页摘要位置；隐藏不等于停止获取，联网权限请在“联网获取”分区控制。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.s),
          for (var index = 0; index < homeOverviewOrder.length; index++) ...[
            if (index > 0) SizedBox(height: theme.spacing.xs),
            _buildHomeOverviewOrderRow(
              context: context,
              item: homeOverviewOrder[index],
              index: index,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建一个同时支持显隐与排序的服务摘要行。
  Widget _buildHomeOverviewOrderRow({
    required BuildContext context,
    required HomeOverviewItem item,
    required int index,
  }) {
    final theme = context.yhTheme;
    final (
      title,
      icon,
      visible,
      onVisibleChanged,
      switchKey,
      semanticLabel,
    ) = switch (item) {
      HomeOverviewItem.trainingPlan => (
        '培养方案',
        YhIcons.academic,
        homeStudentProfileCardVisible,
        onHomeStudentProfileCardVisibleChanged,
        const Key('settings-home-student-profile-card-switch'),
        '显示培养方案概览',
      ),
      HomeOverviewItem.campusCard => (
        '校园卡余额',
        YhIcons.finance,
        homeCampusCardBalanceCardVisible,
        onHomeCampusCardBalanceCardVisibleChanged,
        const Key('settings-home-campus-card-switch'),
        '显示校园卡余额卡片',
      ),
      HomeOverviewItem.email => (
        '学校邮箱',
        YhIcons.mail,
        homeEmailTileVisible,
        onHomeEmailTileVisibleChanged,
        const Key('settings-home-email-switch'),
        '显示学校邮箱摘要',
      ),
      HomeOverviewItem.sportsAttendance => (
        '体育考勤',
        YhIcons.attendance,
        homeSportsAttendanceTileVisible,
        onHomeSportsAttendanceTileVisibleChanged,
        const Key('settings-home-sports-attendance-switch'),
        '显示体育考勤摘要',
      ),
    };
    final position = index + 1;
    return KeyedSubtree(
      key: Key('settings-home-overview-${item.storageId}-row'),
      child: buildResponsiveSettingsRow(
        context: context,
        icon: icon,
        title: _settingsTitle(context, title),
        subtitle: _settingsSubtitle(
          context,
          '第 $position 位 · ${visible ? '显示中' : '已隐藏'}',
        ),
        stackTrailing: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            YhIconButton(
              key: Key('settings-home-overview-${item.storageId}-up'),
              icon: YhIcons.chevronUp,
              semanticLabel: '上移$title',
              variant: YhIconButtonVariant.ghost,
              disabled: index == 0,
              onTap: () => _moveHomeOverviewItem(index, index - 1),
            ),
            YhIconButton(
              key: Key('settings-home-overview-${item.storageId}-down'),
              icon: YhIcons.chevronDown,
              semanticLabel: '下移$title',
              variant: YhIconButtonVariant.ghost,
              disabled: index == homeOverviewOrder.length - 1,
              onTap: () => _moveHomeOverviewItem(index, index + 1),
            ),
            SizedBox(width: theme.spacing.xs),
            _buildSettingsSwitch(
              context: context,
              key: switchKey,
              value: visible,
              semanticLabel: semanticLabel,
              onChanged: onVisibleChanged,
            ),
          ],
        ),
      ),
    );
  }

  /// 将服务摘要从一个位置移动到另一个位置。
  void _moveHomeOverviewItem(int from, int to) {
    if (from == to || to < 0 || to >= homeOverviewOrder.length) return;
    final next = List<HomeOverviewItem>.of(homeOverviewOrder);
    final item = next.removeAt(from);
    next.insert(to, item);
    onHomeOverviewOrderChanged(next);
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
    final academicFetchEnabled =
        dataModuleFetchEnabled[CampusDataModule.academicEams] ?? true;
    final remindersAvailable = notificationEnabled && academicFetchEnabled;

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
          _buildNotificationPermissionStatus(context),
          SizedBox(height: theme.spacing.m),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.notification,
            title: _settingsTitle(context, '启用消息推送'),
            subtitle: _settingsSubtitle(context, '系统通知总开关；关闭后课程、考试和普通消息通知都会停止'),
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
            icon: YhIcons.info,
            iconColor: notificationEnabled ? null : disabledColor,
            title: Text(
              '普通消息通知',
              style: theme.typography.body.copyWith(
                color: notificationEnabled
                    ? theme.color.foreground
                    : disabledColor,
                fontWeight: theme.typography.h1.fontWeight,
              ),
            ),
            subtitle: Text(
              notificationEnabled ? '自动刷新发现新校园消息时推送' : '需先启用消息推送总开关',
              style: theme.typography.small.copyWith(
                color: notificationEnabled ? theme.color.muted : disabledColor,
              ),
            ),
            trailing: _buildSettingsSwitch(
              context: context,
              key: const Key('settings-message-notification-switch'),
              value: messageNotificationEnabled,
              semanticLabel: '普通消息通知',
              onChanged: notificationEnabled
                  ? onMessageNotificationChanged
                  : null,
            ),
            stackTrailing: false,
          ),
          SizedBox(height: theme.spacing.m),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.schedule,
            iconColor: remindersAvailable ? null : disabledColor,
            title: Text(
              '课程提醒',
              style: theme.typography.body.copyWith(
                color: remindersAvailable
                    ? theme.color.foreground
                    : disabledColor,
                fontWeight: theme.typography.h1.fontWeight,
              ),
            ),
            subtitle: Text(
              academicFetchEnabled
                  ? '在课程开始前 $courseReminderLeadMinutes 分钟提醒'
                  : '需先允许获取本专科教务数据',
              style: theme.typography.small.copyWith(
                color: remindersAvailable ? theme.color.muted : disabledColor,
              ),
            ),
            trailing: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    theme.layout.compactContentWidth +
                    theme.spacing.s +
                    theme.control.minimumTarget +
                    theme.spacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: YhSelect<int>(
                      key: const Key('settings-course-reminder-lead-select'),
                      label: '课程提醒提前时间',
                      showLabel: false,
                      compact: true,
                      enabled: remindersAvailable,
                      value: courseReminderLeadMinutes,
                      options: const [
                        YhSelectOption(value: 5, label: '提前 5 分钟'),
                        YhSelectOption(value: 15, label: '提前 15 分钟'),
                        YhSelectOption(value: 30, label: '提前 30 分钟'),
                        YhSelectOption(value: 60, label: '提前 1 小时'),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          onCourseReminderLeadMinutesChanged(value);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: theme.spacing.s),
                  _buildSettingsSwitch(
                    context: context,
                    key: const Key('settings-course-reminder-switch'),
                    value: courseReminderEnabled,
                    semanticLabel: '课程提醒',
                    onChanged: remindersAvailable
                        ? onCourseReminderChanged
                        : null,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: theme.spacing.m),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.calendar,
            iconColor: remindersAvailable ? null : disabledColor,
            title: Text(
              '考试提醒',
              style: theme.typography.body.copyWith(
                color: remindersAvailable
                    ? theme.color.foreground
                    : disabledColor,
                fontWeight: theme.typography.h1.fontWeight,
              ),
            ),
            subtitle: Text(
              academicFetchEnabled
                  ? '在考试开始前 ${examReminderLeadMinutes ~/ 60} 小时提醒'
                  : '需先允许获取本专科教务数据',
              style: theme.typography.small.copyWith(
                color: remindersAvailable ? theme.color.muted : disabledColor,
              ),
            ),
            trailing: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    theme.layout.compactContentWidth +
                    theme.spacing.s +
                    theme.control.minimumTarget +
                    theme.spacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: YhSelect<int>(
                      key: const Key('settings-exam-reminder-lead-select'),
                      label: '考试提醒提前时间',
                      showLabel: false,
                      compact: true,
                      enabled: remindersAvailable,
                      value: examReminderLeadMinutes,
                      options: const [
                        YhSelectOption(value: 60, label: '提前 1 小时'),
                        YhSelectOption(value: 6 * 60, label: '提前 6 小时'),
                        YhSelectOption(value: 12 * 60, label: '提前 12 小时'),
                        YhSelectOption(value: 24 * 60, label: '提前 24 小时'),
                        YhSelectOption(value: 48 * 60, label: '提前 48 小时'),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          onExamReminderLeadMinutesChanged(value);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: theme.spacing.s),
                  _buildSettingsSwitch(
                    context: context,
                    key: const Key('settings-exam-reminder-switch'),
                    value: examReminderEnabled,
                    semanticLabel: '考试提醒',
                    onChanged: remindersAvailable
                        ? onExamReminderChanged
                        : null,
                  ),
                ],
              ),
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
                fontWeight: theme.typography.h1.fontWeight,
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
                      fontWeight: theme.typography.h1.fontWeight,
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

  Widget _buildNotificationPermissionStatus(BuildContext context) {
    final theme = context.yhTheme;
    final (text, color) = switch (notificationPermissionStatus) {
      NotificationPermissionStatus.granted => (
        '系统通知权限：已允许',
        theme.color.success,
      ),
      NotificationPermissionStatus.denied => (
        '系统通知权限：已拒绝，请前往系统设置开启后再试',
        theme.color.danger,
      ),
      NotificationPermissionStatus.notRequired => (
        '系统通知权限：由当前平台通知服务管理',
        theme.color.muted,
      ),
      NotificationPermissionStatus.unsupported => (
        '系统通知权限：当前平台不支持',
        theme.color.warning,
      ),
      NotificationPermissionStatus.unknown => (
        '系统通知权限：暂时无法查询，启用时会再次检查',
        theme.color.muted,
      ),
    };
    return Padding(
      padding: EdgeInsetsDirectional.only(start: theme.spacing.xl2),
      child: Wrap(
        spacing: theme.spacing.s,
        runSpacing: theme.spacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(text, style: theme.typography.small.copyWith(color: color)),
          YhButton(
            key: const Key('settings-notification-permission-refresh'),
            label: '刷新状态',
            variant: YhButtonVariant.text,
            onTap: onNotificationPermissionRefresh,
          ),
        ],
      ),
    );
  }
}
