/*
 * 设置页自动刷新分区组件 — 校园网检测频率与刷新设置快捷入口
 * @Project : SSPU-AllinOne
 * @File : settings_auto_refresh_section.dart
 * @Author : Qintsg
 * @Date : 2026-04-27
 */

import '../design/qingyuan/qingyuan_ui.dart';
import 'settings_widgets.dart';

part 'settings_auto_refresh_rows.dart';

/// 设置页自动刷新设置分区。
class SettingsAutoRefreshSection extends StatelessWidget {
  /// 校园网 / VPN 状态检测间隔，单位分钟。
  final int campusNetworkDetectionIntervalMinutes;

  /// 校园数据来源共用的自动刷新间隔，单位分钟。
  final int dataAutoRefreshIntervalMinutes;

  /// 体育部课外活动考勤自动刷新开关。
  final bool sportsAttendanceAutoRefreshEnabled;

  /// 校园卡余额自动刷新开关。
  final bool campusCardAutoRefreshEnabled;

  /// 学校邮箱自动刷新开关。
  final bool emailAutoRefreshEnabled;

  /// 第二课堂学分自动刷新开关。
  final bool studentReportAutoRefreshEnabled;

  /// 本专科教务自动刷新开关。
  final bool academicEamsAutoRefreshEnabled;

  /// 校园网 / VPN 状态检测间隔修改回调。
  final Future<void> Function(int minutes)
  onCampusNetworkDetectionIntervalChanged;

  /// 体育部课外活动考勤自动刷新开关修改回调。
  final Future<void> Function(bool enabled)
  onSportsAttendanceAutoRefreshChanged;

  /// 校园数据来源共用刷新间隔修改回调。
  final Future<void> Function(int minutes) onDataAutoRefreshIntervalChanged;

  /// 校园卡余额自动刷新开关修改回调。
  final Future<void> Function(bool enabled) onCampusCardAutoRefreshChanged;

  /// 学校邮箱自动刷新开关修改回调。
  final Future<void> Function(bool enabled) onEmailAutoRefreshChanged;

  /// 第二课堂学分自动刷新开关修改回调。
  final Future<void> Function(bool enabled) onStudentReportAutoRefreshChanged;

  /// 本专科教务自动刷新开关修改回调。
  final Future<void> Function(bool enabled) onAcademicEamsAutoRefreshChanged;

  /// 跳转职能部门自动刷新设置。
  final VoidCallback onOpenDepartmentRefreshSettings;

  /// 跳转教学单位自动刷新设置。
  final VoidCallback onOpenTeachingRefreshSettings;

  /// 跳转微信推文自动刷新设置。
  final VoidCallback onOpenWechatRefreshSettings;

  const SettingsAutoRefreshSection({
    super.key,
    required this.campusNetworkDetectionIntervalMinutes,
    required this.dataAutoRefreshIntervalMinutes,
    required this.sportsAttendanceAutoRefreshEnabled,
    required this.campusCardAutoRefreshEnabled,
    required this.emailAutoRefreshEnabled,
    required this.studentReportAutoRefreshEnabled,
    required this.academicEamsAutoRefreshEnabled,
    required this.onCampusNetworkDetectionIntervalChanged,
    required this.onDataAutoRefreshIntervalChanged,
    required this.onSportsAttendanceAutoRefreshChanged,
    required this.onCampusCardAutoRefreshChanged,
    required this.onEmailAutoRefreshChanged,
    required this.onStudentReportAutoRefreshChanged,
    required this.onAcademicEamsAutoRefreshChanged,
    required this.onOpenDepartmentRefreshSettings,
    required this.onOpenTeachingRefreshSettings,
    required this.onOpenWechatRefreshSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRefreshCard(context),
        SizedBox(height: theme.spacing.l),
        _buildConnectionDetectionCard(context),
        SizedBox(height: theme.spacing.l),
        _buildRefreshShortcutCard(context),
      ],
    );
  }

  /// 构建校园数据共享刷新设置卡片。
  ///
  /// :param context: 当前构建上下文。
  /// :returns: 含统一频率和五个来源开关的卡片。
  Widget _buildDataRefreshCard(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('校园数据自动刷新', style: theme.typography.h3),
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            '教务、体育、第二课堂、校园卡和邮箱共用一个刷新频率；每项仍可独立暂停。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.sync,
            title: _title(context, '统一刷新频率'),
            subtitle: Text(
              '修改后同时应用到以下五个校园数据来源',
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
            trailing: _buildDataRefreshIntervalComboBox(context),
          ),
          SizedBox(height: theme.spacing.m),
          _buildAcademicEamsAutoRefreshRow(context),
          SizedBox(height: theme.spacing.m),
          _buildSportsAttendanceAutoRefreshRow(context),
          SizedBox(height: theme.spacing.m),
          _buildStudentReportAutoRefreshRow(context),
          SizedBox(height: theme.spacing.m),
          _buildCampusCardAutoRefreshRow(context),
          SizedBox(height: theme.spacing.m),
          _buildEmailAutoRefreshRow(context),
        ],
      ),
    );
  }

  /// 构建校园网与 VPN 状态检测设置卡片。
  ///
  /// :param context: 当前构建上下文。
  /// :returns: 独立网络检测频率卡片。
  Widget _buildConnectionDetectionCard(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: buildResponsiveSettingsRow(
        context: context,
        icon: YhIcons.networkVpn,
        title: _title(context, '校园网 / VPN 状态检测'),
        subtitle: Text(
          '仅控制导航栏网络状态检测，不影响校园数据刷新频率',
          style: theme.typography.small.copyWith(color: theme.color.muted),
        ),
        trailing: _buildNetworkIntervalComboBox(context),
      ),
    );
  }

  /// 构建消息来源设置快捷入口卡片。
  ///
  /// :param context: 当前构建上下文。
  /// :returns: 三类消息来源的管理入口。
  Widget _buildRefreshShortcutCard(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('消息来源', style: theme.typography.h3),
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            '管理官网与公众号消息的显示、抓取条数和刷新策略。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          _buildShortcutRow(
            context: context,
            icon: YhIcons.education,
            title: '职能部门',
            description: '学校官网与职能部门消息',
            onPressed: onOpenDepartmentRefreshSettings,
          ),
          SizedBox(height: theme.spacing.m),
          _buildShortcutRow(
            context: context,
            icon: YhIcons.library,
            title: '教学单位',
            description: '学院、中心与教学单位消息',
            onPressed: onOpenTeachingRefreshSettings,
          ),
          SizedBox(height: theme.spacing.m),
          _buildShortcutRow(
            context: context,
            icon: YhIcons.chat,
            title: '微信推文',
            description: '微信公众号平台推文',
            onPressed: onOpenWechatRefreshSettings,
          ),
        ],
      ),
    );
  }

  /// 构建校园网状态检测间隔选择器。
  ///
  /// :param context: 当前构建上下文。
  /// :returns: 网络检测间隔选择控件。
  Widget _buildNetworkIntervalComboBox(BuildContext context) {
    final selectedValue =
        kIntervalOptions.containsKey(campusNetworkDetectionIntervalMinutes)
        ? campusNetworkDetectionIntervalMinutes
        : 15;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: context.yhTheme.layout.inlineControlWidth,
      ),
      child: YhSelect<int>(
        label: '校园网检测间隔',
        showLabel: false,
        value: selectedValue,
        options: [
          for (final entry in kIntervalOptions.entries)
            YhSelectOption<int>(value: entry.key, label: entry.value),
        ],
        onChanged: (value) {
          if (value != null) {
            onCampusNetworkDetectionIntervalChanged(value);
          }
        },
      ),
    );
  }

  /// 构建五个校园数据来源共用的刷新间隔选择器。
  ///
  /// :param context: 当前构建上下文。
  /// :returns: 共享刷新间隔选择控件。
  Widget _buildDataRefreshIntervalComboBox(BuildContext context) {
    final enabledOptions = kIntervalOptions.entries.where(
      (entry) => entry.key > 0,
    );
    final selectedValue =
        kIntervalOptions.containsKey(dataAutoRefreshIntervalMinutes)
        ? dataAutoRefreshIntervalMinutes
        : 30;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: context.yhTheme.layout.inlineControlWidth,
      ),
      child: YhSelect<int>(
        key: const Key('settings-data-refresh-interval'),
        label: '校园数据统一刷新间隔',
        showLabel: false,
        value: selectedValue,
        options: [
          for (final entry in enabledOptions)
            YhSelectOption<int>(value: entry.key, label: entry.value),
        ],
        onChanged: (value) {
          if (value != null) onDataAutoRefreshIntervalChanged(value);
        },
      ),
    );
  }

  /// 构建单个消息来源管理入口。
  ///
  /// :param context: 当前构建上下文。
  /// :param icon: 来源图标。
  /// :param title: 来源名称。
  /// :param description: 来源内容说明。
  /// :param onPressed: 打开来源设置的回调。
  /// :returns: 响应式消息来源入口行。
  Widget _buildShortcutRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onPressed,
  }) {
    return buildResponsiveSettingsRow(
      context: context,
      icon: icon,
      title: _title(context, title),
      subtitle: Text(
        description,
        style: context.yhTheme.typography.small.copyWith(
          color: context.yhTheme.color.muted,
        ),
      ),
      trailing: YhButton(
        label: '管理',
        onTap: onPressed,
        variant: YhButtonVariant.secondary,
      ),
    );
  }

  /// 构建设置行标题文本。
  ///
  /// :param context: 当前构建上下文。
  /// :param text: 标题内容。
  /// :returns: 使用设置标题字重的文本组件。
  Widget _title(BuildContext context, String text) => Text(
    text,
    style: context.yhTheme.typography.body.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
}
