/*
 * 设置页自动刷新分区组件 — 校园网检测频率与刷新设置快捷入口
 * @Project : SSPU-AllinOne
 * @File : settings_auto_refresh_section.dart
 * @Author : Qintsg
 * @Date : 2026-04-27
 */

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCampusNetworkIntervalCard(context),
        const SizedBox(height: AppSpacing.lg),
        _buildRefreshShortcutCard(context),
      ],
    );
  }

  Widget _buildCampusNetworkIntervalCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card.filled(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('自动刷新设置', style: textTheme.titleMedium)),
            const SizedBox(height: AppSpacing.md),
            buildResponsiveSettingsRow(
              context: context,
              icon: Icons.power_outlined,
              title: Text('校园网 / VPN 状态检测', style: textTheme.titleSmall),
              subtitle: Text(
                '控制导航栏状态徽标的自动检测频率；关闭后仍可点击徽标手动检测',
                style: textTheme.bodySmall,
              ),
              trailing: _buildIntervalComboBox(),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSportsAttendanceAutoRefreshRow(context),
            const SizedBox(height: AppSpacing.md),
            _buildCampusCardAutoRefreshRow(context),
            const SizedBox(height: AppSpacing.md),
            _buildEmailAutoRefreshRow(context),
            const SizedBox(height: AppSpacing.md),
            _buildStudentReportAutoRefreshRow(context),
            const SizedBox(height: AppSpacing.md),
            _buildAcademicEamsAutoRefreshRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshShortcutCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card.filled(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('消息自动刷新快捷入口', style: textTheme.titleMedium)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '以下入口会跳转到对应分区顶部的自动刷新设置面板。',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildShortcutRow(
              context: context,
              icon: Icons.school_outlined,
              title: '职能部门',
              description: '配置职能部门官网消息的自动刷新频率和抓取条数',
              onPressed: onOpenDepartmentRefreshSettings,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildShortcutRow(
              context: context,
              icon: Icons.local_library_outlined,
              title: '教学单位',
              description: '配置学院、中心等教学单位消息的自动刷新频率和抓取条数',
              onPressed: onOpenTeachingRefreshSettings,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildShortcutRow(
              context: context,
              icon: Icons.chat_outlined,
              title: '微信推文',
              description: '配置公众号平台推文的自动刷新频率和抓取条数',
              onPressed: onOpenWechatRefreshSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalComboBox() {
    final selectedValue =
        kIntervalOptions.containsKey(campusNetworkDetectionIntervalMinutes)
        ? campusNetworkDetectionIntervalMinutes
        : 15;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: DropdownButton<int>(
        isExpanded: true,
        value: selectedValue,
        items: kIntervalOptions.entries
            .map(
              (entry) => DropdownMenuItem<int>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
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
    final textTheme = Theme.of(context).textTheme;
    return buildResponsiveSettingsRow(
      context: context,
      icon: icon,
      title: Text(title, style: textTheme.titleSmall),
      subtitle: Text(description, style: textTheme.bodySmall),
      trailing: OutlinedButton(onPressed: onPressed, child: const Text('前往设置')),
    );
  }
}
