/*
 * 设置页自动刷新行 — 构建受限服务刷新开关与间隔选择
 * @Project : SSPU-AllinOne
 * @File : settings_auto_refresh_rows.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

part of 'settings_auto_refresh_section.dart';

extension _SettingsAutoRefreshRows on SettingsAutoRefreshSection {
  Widget _buildSportsAttendanceAutoRefreshRow(BuildContext context) {
    final theme = context.yhTheme;
    return buildResponsiveSettingsRow(
      context: context,
      icon: YhIcons.sports,
      title: _title(context, '体育查询自动刷新'),
      subtitle: Text(
        '控制教务中心课外活动考勤卡片的自动读取；体育查询需要校园网或学校 VPN，关闭后仍可在卡片右上角手动刷新',
        style: theme.typography.small.copyWith(color: theme.color.muted),
      ),
      trailing: _buildAutoRefreshControls(
        context: context,
        semanticLabel: '体育查询自动刷新',
        enabled: sportsAttendanceAutoRefreshEnabled,
        interval: sportsAttendanceAutoRefreshIntervalMinutes,
        onEnabledChanged: onSportsAttendanceAutoRefreshChanged,
        onIntervalChanged: onSportsAttendanceAutoRefreshIntervalChanged,
      ),
    );
  }

  Widget _buildCampusCardAutoRefreshRow(BuildContext context) {
    final theme = context.yhTheme;
    return buildResponsiveSettingsRow(
      context: context,
      icon: YhIcons.finance,
      title: _title(context, '校园卡余额自动刷新'),
      subtitle: Text(
        '控制主页校园卡余额卡片的自动读取；需要校园网或学校 VPN 与 OA 登录，关闭后仍可在卡片右下角手动刷新',
        style: theme.typography.small.copyWith(color: theme.color.muted),
      ),
      trailing: _buildAutoRefreshControls(
        context: context,
        semanticLabel: '校园卡余额自动刷新',
        enabled: campusCardAutoRefreshEnabled,
        interval: campusCardAutoRefreshIntervalMinutes,
        onEnabledChanged: onCampusCardAutoRefreshChanged,
        onIntervalChanged: onCampusCardAutoRefreshIntervalChanged,
      ),
    );
  }

  Widget _buildEmailAutoRefreshRow(BuildContext context) {
    final theme = context.yhTheme;
    return buildResponsiveSettingsRow(
      context: context,
      icon: YhIcons.mail,
      title: _title(context, '学校邮箱自动刷新'),
      subtitle: Text(
        '控制学校邮箱页面的自动收信；邮箱系统不要求校园网或 VPN，关闭后仍可在邮箱页手动读取',
        style: theme.typography.small.copyWith(color: theme.color.muted),
      ),
      trailing: _buildAutoRefreshControls(
        context: context,
        semanticLabel: '学校邮箱自动刷新',
        enabled: emailAutoRefreshEnabled,
        interval: emailAutoRefreshIntervalMinutes,
        onEnabledChanged: onEmailAutoRefreshChanged,
        onIntervalChanged: onEmailAutoRefreshIntervalChanged,
      ),
    );
  }

  Widget _buildStudentReportAutoRefreshRow(BuildContext context) {
    final theme = context.yhTheme;
    return buildResponsiveSettingsRow(
      context: context,
      icon: YhIcons.certificate,
      title: _title(context, '第二课堂学分自动刷新'),
      subtitle: Text(
        '控制教务中心第二课堂学分卡片的自动读取；需要校园网或学校 VPN 与 OA 登录，关闭后仍可在卡片右上角手动刷新',
        style: theme.typography.small.copyWith(color: theme.color.muted),
      ),
      trailing: _buildAutoRefreshControls(
        context: context,
        semanticLabel: '第二课堂学分自动刷新',
        enabled: studentReportAutoRefreshEnabled,
        interval: studentReportAutoRefreshIntervalMinutes,
        onEnabledChanged: onStudentReportAutoRefreshChanged,
        onIntervalChanged: onStudentReportAutoRefreshIntervalChanged,
      ),
    );
  }

  Widget _buildAcademicEamsAutoRefreshRow(BuildContext context) {
    final theme = context.yhTheme;
    return buildResponsiveSettingsRow(
      context: context,
      icon: YhIcons.task,
      title: _title(context, '本专科教务自动刷新'),
      subtitle: Text(
        '控制教务中心本专科教务摘要和独立课程表页面的自动读取；需要校园网或学校 VPN 与 OA 登录，关闭后仍可在页面中手动刷新',
        style: theme.typography.small.copyWith(color: theme.color.muted),
      ),
      trailing: _buildAutoRefreshControls(
        context: context,
        semanticLabel: '本专科教务自动刷新',
        enabled: academicEamsAutoRefreshEnabled,
        interval: academicEamsAutoRefreshIntervalMinutes,
        onEnabledChanged: onAcademicEamsAutoRefreshChanged,
        onIntervalChanged: onAcademicEamsAutoRefreshIntervalChanged,
      ),
    );
  }

  Widget _buildAutoRefreshControls({
    required BuildContext context,
    required String semanticLabel,
    required bool enabled,
    required int interval,
    required Future<void> Function(bool enabled) onEnabledChanged,
    required Future<void> Function(int minutes) onIntervalChanged,
  }) {
    return Wrap(
      spacing: context.yhTheme.spacing.s,
      runSpacing: context.yhTheme.spacing.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        YhSwitch(
          value: enabled,
          semanticLabel: semanticLabel,
          onChanged: (value) => onEnabledChanged(value),
        ),
        _buildEnabledIntervalDropdown(
          label: '$semanticLabel间隔',
          selectedIntervalMinutes: interval,
          enabled: enabled,
          onChanged: onIntervalChanged,
        ),
      ],
    );
  }

  Widget _buildEnabledIntervalDropdown({
    required String label,
    required int selectedIntervalMinutes,
    required bool enabled,
    required Future<void> Function(int minutes) onChanged,
  }) {
    final enabledIntervalOptions = Map<int, String>.fromEntries(
      kIntervalOptions.entries.where((entry) => entry.key > 0),
    );
    final selectedValue =
        enabledIntervalOptions.containsKey(selectedIntervalMinutes)
        ? selectedIntervalMinutes
        : 30;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: YhSelect<int>(
        label: label,
        showLabel: false,
        value: selectedValue,
        enabled: enabled,
        options: [
          for (final entry in enabledIntervalOptions.entries)
            YhSelectOption<int>(value: entry.key, label: entry.value),
        ],
        onChanged: enabled
            ? (value) {
                if (value != null) {
                  onChanged(value);
                }
              }
            : null,
      ),
    );
  }
}
