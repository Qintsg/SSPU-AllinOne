/*
 * 主页学籍信息卡片 — 展示本专科教务学籍摘要
 * @Project : SSPU-AllinOne
 * @File : home_student_profile_card.dart
 * @Author : Qintsg
 * @Date : 2026-06-09
 */

part of 'home_page.dart';

extension _HomeStudentProfileCard on _HomePageState {
  /// 构建首页学籍信息卡片。
  Widget _buildStudentProfileCard(BuildContext context) {
    final theme = context.yhTheme;
    final profile = _studentProfile;
    final hasCredentials =
        _credentialsStatus.oaAccount.trim().isNotEmpty &&
        _credentialsStatus.hasOaPassword;
    final state = !hasCredentials
        ? YhDataState.notConfigured
        : _isLoadingStudentProfile && profile == null
        ? YhDataState.loading
        : profile == null || !profile.hasAnyValue
        ? YhDataState.degraded
        : YhDataState.ready;

    return YhDashboardTile(
      key: const Key('home-student-profile-card'),
      title: '学籍信息',
      subtitle: '本专科教务',
      icon: YhIcons.profile,
      state: state,
      accentColor: theme.color.serviceAcademic,
      actions: !hasCredentials
          ? [
              YhButton(
                label: '前往设置',
                leadingIcon: YhIcons.settings,
                onTap: widget.onOpenSettings,
              ),
            ]
          : const [],
      child: !hasCredentials
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '需要先保存 OA 账号密码',
                  style: theme.typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  '学籍信息会在保存后自动读取',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            )
          : _isLoadingStudentProfile && profile == null
          ? Row(
              children: [
                SizedBox(
                  width: theme.spacing.xl2 * 2,
                  child: const YhProgress(showPercent: false),
                ),
                SizedBox(width: theme.spacing.s),
                const Text('正在读取学籍信息...'),
              ],
            )
          : profile == null || !profile.hasAnyValue
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '暂未读取到学籍信息',
                  style: theme.typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  '应用会在启动或更新 OA 凭据后自动尝试补全',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            )
          : _buildStudentProfileSummary(context, profile),
    );
  }

  Widget _buildStudentProfileSummary(
    BuildContext context,
    AcademicEamsProfile profile,
  ) {
    final theme = context.yhTheme;
    final name = _profileValue(profile.name);
    final studentId = _profileValue(profile.studentId);
    final department = _profileValue(profile.department);
    final major = _profileValue(profile.major);
    final className = _profileValue(profile.className);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(name, style: theme.typography.h3)),
            Text(
              studentId,
              style: theme.typography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: theme.spacing.m),
        Text(
          department,
          style: theme.typography.body.copyWith(color: theme.color.muted),
        ),
        SizedBox(height: theme.spacing.xs),
        Row(
          children: [
            Expanded(child: Text(major)),
            SizedBox(width: theme.spacing.s),
            Text(className),
          ],
        ),
      ],
    );
  }

  String _profileValue(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? '未读取' : normalized;
  }
}
