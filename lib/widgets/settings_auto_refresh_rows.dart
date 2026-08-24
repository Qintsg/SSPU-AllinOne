/*
 * 设置页自动刷新行 — 构建共享频率下的来源开关
 * @Project : SSPU-AllinOne
 * @File : settings_auto_refresh_rows.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

part of 'settings_auto_refresh_section.dart';

extension _SettingsAutoRefreshRows on SettingsAutoRefreshSection {
  /// 构建体育考勤来源开关行。
  ///
  /// :param context: 当前构建上下文。
  /// :returns: 体育考勤自动刷新设置行。
  Widget _buildSportsAttendanceAutoRefreshRow(BuildContext context) {
    return _buildSourceToggleRow(
      context: context,
      icon: YhIcons.sports,
      title: '体育考勤',
      description: '需要校园网或学校 VPN，并使用体育查询密码',
      semanticLabel: '体育考勤自动刷新',
      enabled: sportsAttendanceAutoRefreshEnabled,
      onChanged: onSportsAttendanceAutoRefreshChanged,
    );
  }

  /// 构建校园卡来源开关行。
  ///
  /// :param context: 当前构建上下文。
  /// :returns: 校园卡自动刷新设置行。
  Widget _buildCampusCardAutoRefreshRow(BuildContext context) {
    return _buildSourceToggleRow(
      context: context,
      icon: YhIcons.finance,
      title: '校园卡余额',
      description: '需要校园网或学校 VPN，并使用 OA 登录状态',
      semanticLabel: '校园卡余额自动刷新',
      enabled: campusCardAutoRefreshEnabled,
      onChanged: onCampusCardAutoRefreshChanged,
    );
  }

  /// 构建学校邮箱来源开关行。
  ///
  /// :param context: 当前构建上下文。
  /// :returns: 学校邮箱自动刷新设置行。
  Widget _buildEmailAutoRefreshRow(BuildContext context) {
    return _buildSourceToggleRow(
      context: context,
      icon: YhIcons.mail,
      title: '学校邮箱',
      description: '无需校园网或 VPN，使用学校邮箱账户收信',
      semanticLabel: '学校邮箱自动刷新',
      enabled: emailAutoRefreshEnabled,
      onChanged: onEmailAutoRefreshChanged,
    );
  }

  /// 构建第二课堂来源开关行。
  ///
  /// :param context: 当前构建上下文。
  /// :returns: 第二课堂自动刷新设置行。
  Widget _buildStudentReportAutoRefreshRow(BuildContext context) {
    return _buildSourceToggleRow(
      context: context,
      icon: YhIcons.certificate,
      title: '第二课堂',
      description: '需要校园网或学校 VPN，并使用 OA 登录状态',
      semanticLabel: '第二课堂自动刷新',
      enabled: studentReportAutoRefreshEnabled,
      onChanged: onStudentReportAutoRefreshChanged,
    );
  }

  /// 构建本专科教务来源开关行。
  ///
  /// :param context: 当前构建上下文。
  /// :returns: 本专科教务自动刷新设置行。
  Widget _buildAcademicEamsAutoRefreshRow(BuildContext context) {
    return _buildSourceToggleRow(
      context: context,
      icon: YhIcons.task,
      title: '本专科教务',
      description: '课程、成绩、考试与培养方案共用一次自动读取',
      semanticLabel: '本专科教务自动刷新',
      enabled: academicEamsAutoRefreshEnabled,
      onChanged: onAcademicEamsAutoRefreshChanged,
    );
  }

  /// 构建共享频率下的单个来源开关行。
  ///
  /// :param context: 当前构建上下文。
  /// :param icon: 来源图标。
  /// :param title: 来源标题。
  /// :param description: 来源约束说明。
  /// :param semanticLabel: 开关的无障碍名称。
  /// :param enabled: 当前是否启用自动刷新。
  /// :param onChanged: 开关状态变化回调。
  /// :returns: 响应式来源开关行。
  Widget _buildSourceToggleRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String semanticLabel,
    required bool enabled,
    required Future<void> Function(bool enabled) onChanged,
  }) {
    final theme = context.yhTheme;
    return buildResponsiveSettingsRow(
      context: context,
      icon: icon,
      title: _title(context, title),
      subtitle: Text(
        description,
        style: theme.typography.small.copyWith(color: theme.color.muted),
      ),
      trailing: YhSwitch(
        value: enabled,
        semanticLabel: semanticLabel,
        onChanged: (value) => onChanged(value),
      ),
    );
  }
}
