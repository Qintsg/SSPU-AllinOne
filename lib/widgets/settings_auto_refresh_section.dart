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

  /// 体育部课外活动考勤自动刷新开关。
  final bool sportsAttendanceAutoRefreshEnabled;

  /// 体育部课外活动考勤自动刷新间隔，单位分钟。
  final int sportsAttendanceAutoRefreshIntervalMinutes;

  /// 校园卡余额自动刷新开关。
  final bool campusCardAutoRefreshEnabled;

  /// 校园卡余额自动刷新间隔，单位分钟。
  final int campusCardAutoRefreshIntervalMinutes;

  /// 学校邮箱自动刷新开关。
  final bool emailAutoRefreshEnabled;

  /// 学校邮箱自动刷新间隔，单位分钟。
  final int emailAutoRefreshIntervalMinutes;

  /// 第二课堂学分自动刷新开关。
  final bool studentReportAutoRefreshEnabled;

  /// 第二课堂学分自动刷新间隔，单位分钟。
  final int studentReportAutoRefreshIntervalMinutes;

  /// 本专科教务自动刷新开关。
  final bool academicEamsAutoRefreshEnabled;

  /// 本专科教务自动刷新间隔，单位分钟。
  final int academicEamsAutoRefreshIntervalMinutes;

  /// 校园网 / VPN 状态检测间隔修改回调。
  final Future<void> Function(int minutes)
  onCampusNetworkDetectionIntervalChanged;

  /// 体育部课外活动考勤自动刷新开关修改回调。
  final Future<void> Function(bool enabled)
  onSportsAttendanceAutoRefreshChanged;

  /// 体育部课外活动考勤自动刷新间隔修改回调。
  final Future<void> Function(int minutes)
  onSportsAttendanceAutoRefreshIntervalChanged;

  /// 校园卡余额自动刷新开关修改回调。
  final Future<void> Function(bool enabled) onCampusCardAutoRefreshChanged;

  /// 校园卡余额自动刷新间隔修改回调。
  final Future<void> Function(int minutes)
  onCampusCardAutoRefreshIntervalChanged;

  /// 学校邮箱自动刷新开关修改回调。
  final Future<void> Function(bool enabled) onEmailAutoRefreshChanged;

  /// 学校邮箱自动刷新间隔修改回调。
  final Future<void> Function(int minutes) onEmailAutoRefreshIntervalChanged;

  /// 第二课堂学分自动刷新开关修改回调。
  final Future<void> Function(bool enabled) onStudentReportAutoRefreshChanged;

  /// 第二课堂学分自动刷新间隔修改回调。
  final Future<void> Function(int minutes)
  onStudentReportAutoRefreshIntervalChanged;

  /// 本专科教务自动刷新开关修改回调。
  final Future<void> Function(bool enabled) onAcademicEamsAutoRefreshChanged;

  /// 本专科教务自动刷新间隔修改回调。
  final Future<void> Function(int minutes)
  onAcademicEamsAutoRefreshIntervalChanged;

  /// 跳转职能部门自动刷新设置。
  final VoidCallback onOpenDepartmentRefreshSettings;

  /// 跳转教学单位自动刷新设置。
  final VoidCallback onOpenTeachingRefreshSettings;

  /// 跳转微信推文自动刷新设置。
  final VoidCallback onOpenWechatRefreshSettings;

  const SettingsAutoRefreshSection({
    super.key,
    required this.campusNetworkDetectionIntervalMinutes,
    required this.sportsAttendanceAutoRefreshEnabled,
    required this.sportsAttendanceAutoRefreshIntervalMinutes,
    required this.campusCardAutoRefreshEnabled,
    required this.campusCardAutoRefreshIntervalMinutes,
    required this.emailAutoRefreshEnabled,
    required this.emailAutoRefreshIntervalMinutes,
    required this.studentReportAutoRefreshEnabled,
    required this.studentReportAutoRefreshIntervalMinutes,
    required this.academicEamsAutoRefreshEnabled,
    required this.academicEamsAutoRefreshIntervalMinutes,
    required this.onCampusNetworkDetectionIntervalChanged,
    required this.onSportsAttendanceAutoRefreshChanged,
    required this.onSportsAttendanceAutoRefreshIntervalChanged,
    required this.onCampusCardAutoRefreshChanged,
    required this.onCampusCardAutoRefreshIntervalChanged,
    required this.onEmailAutoRefreshChanged,
    required this.onEmailAutoRefreshIntervalChanged,
    required this.onStudentReportAutoRefreshChanged,
    required this.onStudentReportAutoRefreshIntervalChanged,
    required this.onAcademicEamsAutoRefreshChanged,
    required this.onAcademicEamsAutoRefreshIntervalChanged,
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
        _buildCampusNetworkIntervalCard(context),
        SizedBox(height: theme.spacing.l),
        _buildRefreshShortcutCard(context),
      ],
    );
  }

  Widget _buildCampusNetworkIntervalCard(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('自动刷新设置', style: theme.typography.h3),
          ),
          SizedBox(height: theme.spacing.m),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.networkVpn,
            title: _title(context, '校园网 / VPN 状态检测'),
            subtitle: Text(
              '控制导航栏状态徽标的自动检测频率；关闭后仍可点击徽标手动检测',
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
            trailing: _buildIntervalComboBox(context),
          ),
          SizedBox(height: theme.spacing.m),
          _buildSportsAttendanceAutoRefreshRow(context),
          SizedBox(height: theme.spacing.m),
          _buildCampusCardAutoRefreshRow(context),
          SizedBox(height: theme.spacing.m),
          _buildEmailAutoRefreshRow(context),
          SizedBox(height: theme.spacing.m),
          _buildStudentReportAutoRefreshRow(context),
          SizedBox(height: theme.spacing.m),
          _buildAcademicEamsAutoRefreshRow(context),
        ],
      ),
    );
  }

  Widget _buildRefreshShortcutCard(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('消息自动刷新快捷入口', style: theme.typography.h3),
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            '以下入口会跳转到对应分区顶部的自动刷新设置面板。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          _buildShortcutRow(
            context: context,
            icon: YhIcons.education,
            title: '职能部门',
            description: '配置职能部门官网消息的自动刷新频率和抓取条数',
            onPressed: onOpenDepartmentRefreshSettings,
          ),
          SizedBox(height: theme.spacing.m),
          _buildShortcutRow(
            context: context,
            icon: YhIcons.library,
            title: '教学单位',
            description: '配置学院、中心等教学单位消息的自动刷新频率和抓取条数',
            onPressed: onOpenTeachingRefreshSettings,
          ),
          SizedBox(height: theme.spacing.m),
          _buildShortcutRow(
            context: context,
            icon: YhIcons.chat,
            title: '微信推文',
            description: '配置公众号平台推文的自动刷新频率和抓取条数',
            onPressed: onOpenWechatRefreshSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalComboBox(BuildContext context) {
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
        label: '前往设置',
        onTap: onPressed,
        variant: YhButtonVariant.secondary,
      ),
    );
  }

  Widget _title(BuildContext context, String text) => Text(
    text,
    style: context.yhTheme.typography.body.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
}
