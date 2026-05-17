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
    final textTheme = Theme.of(context).textTheme;
    return buildResponsiveSettingsRow(
      context: context,
      icon: Icons.directions_run_outlined,
      title: Text('体育查询自动刷新', style: textTheme.titleSmall),
      subtitle: Text(
        '控制教务中心课外活动考勤卡片的自动读取；体育查询需要校园网或学校 VPN，关闭后仍可在卡片右上角手动刷新',
        style: textTheme.bodySmall,
      ),
      trailing: _buildAutoRefreshControls(
        enabled: sportsAttendanceAutoRefreshEnabled,
        interval: sportsAttendanceAutoRefreshIntervalMinutes,
        onEnabledChanged: onSportsAttendanceAutoRefreshChanged,
        onIntervalChanged: onSportsAttendanceAutoRefreshIntervalChanged,
      ),
    );
  }

  Widget _buildCampusCardAutoRefreshRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return buildResponsiveSettingsRow(
      context: context,
      icon: Icons.credit_card_outlined,
      title: Text('校园卡余额自动刷新', style: textTheme.titleSmall),
      subtitle: Text(
        '控制主页校园卡余额卡片的自动读取；需要校园网或学校 VPN 与 OA 登录，关闭后仍可在卡片右下角手动刷新',
        style: textTheme.bodySmall,
      ),
      trailing: _buildAutoRefreshControls(
        enabled: campusCardAutoRefreshEnabled,
        interval: campusCardAutoRefreshIntervalMinutes,
        onEnabledChanged: onCampusCardAutoRefreshChanged,
        onIntervalChanged: onCampusCardAutoRefreshIntervalChanged,
      ),
    );
  }

  Widget _buildEmailAutoRefreshRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return buildResponsiveSettingsRow(
      context: context,
      icon: Icons.mail_outline,
      title: Text('学校邮箱自动刷新', style: textTheme.titleSmall),
      subtitle: Text(
        '控制学校邮箱页面的自动收信；邮箱系统不要求校园网或 VPN，关闭后仍可在邮箱页手动读取',
        style: textTheme.bodySmall,
      ),
      trailing: _buildAutoRefreshControls(
        enabled: emailAutoRefreshEnabled,
        interval: emailAutoRefreshIntervalMinutes,
        onEnabledChanged: onEmailAutoRefreshChanged,
        onIntervalChanged: onEmailAutoRefreshIntervalChanged,
      ),
    );
  }

  Widget _buildStudentReportAutoRefreshRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return buildResponsiveSettingsRow(
      context: context,
      icon: Icons.school_outlined,
      title: Text('第二课堂学分自动刷新', style: textTheme.titleSmall),
      subtitle: Text(
        '控制教务中心第二课堂学分卡片的自动读取；需要校园网或学校 VPN 与 OA 登录，关闭后仍可在卡片右上角手动刷新',
        style: textTheme.bodySmall,
      ),
      trailing: _buildAutoRefreshControls(
        enabled: studentReportAutoRefreshEnabled,
        interval: studentReportAutoRefreshIntervalMinutes,
        onEnabledChanged: onStudentReportAutoRefreshChanged,
        onIntervalChanged: onStudentReportAutoRefreshIntervalChanged,
      ),
    );
  }

  Widget _buildAcademicEamsAutoRefreshRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return buildResponsiveSettingsRow(
      context: context,
      icon: Icons.assignment_outlined,
      title: Text('本专科教务自动刷新', style: textTheme.titleSmall),
      subtitle: Text(
        '控制教务中心本专科教务摘要和独立课程表页面的自动读取；需要校园网或学校 VPN 与 OA 登录，关闭后仍可在页面中手动刷新',
        style: textTheme.bodySmall,
      ),
      trailing: _buildAutoRefreshControls(
        enabled: academicEamsAutoRefreshEnabled,
        interval: academicEamsAutoRefreshIntervalMinutes,
        onEnabledChanged: onAcademicEamsAutoRefreshChanged,
        onIntervalChanged: onAcademicEamsAutoRefreshIntervalChanged,
      ),
    );
  }

  Widget _buildAutoRefreshControls({
    required bool enabled,
    required int interval,
    required Future<void> Function(bool enabled) onEnabledChanged,
    required Future<void> Function(int minutes) onIntervalChanged,
  }) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Switch(
          value: enabled,
          onChanged: (value) => onEnabledChanged(value),
        ),
        _buildEnabledIntervalDropdown(
          selectedIntervalMinutes: interval,
          enabled: enabled,
          onChanged: onIntervalChanged,
        ),
      ],
    );
  }

  Widget _buildEnabledIntervalDropdown({
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
      child: DropdownButton<int>(
        isExpanded: true,
        value: selectedValue,
        items: enabledIntervalOptions.entries
            .map(
              (entry) => DropdownMenuItem<int>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
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
