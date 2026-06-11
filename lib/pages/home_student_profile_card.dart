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
    final theme = FluentTheme.of(context);
    final profile = _studentProfile;
    final hasCredentials =
        _credentialsStatus.oaAccount.trim().isNotEmpty &&
        _credentialsStatus.hasOaPassword;
    final state = !hasCredentials
        ? FluentDataState.notConfigured
        : _isLoadingStudentProfile && profile == null
        ? FluentDataState.loading
        : profile == null || !profile.hasAnyValue
        ? FluentDataState.degraded
        : FluentDataState.ready;

    return FluentDashboardTile(
      key: const Key('home-student-profile-card'),
      title: '学籍信息',
      subtitle: '本专科教务',
      icon: FluentIcons.contact,
      state: state,
      accentColor: context.fluentAccents.academic,
      actions: !hasCredentials
          ? [
              FluentButton.primary(
                onPressed: widget.onOpenSettings,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.settings, size: 14),
                    SizedBox(width: FluentSpacing.xs),
                    Text('前往设置'),
                  ],
                ),
              ),
            ]
          : null,
      child: !hasCredentials
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('需要先保存 OA 账号密码', style: theme.typography.bodyStrong),
                const SizedBox(height: FluentSpacing.xs),
                Text(
                  '学籍信息会在保存后自动读取',
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
              ],
            )
          : _isLoadingStudentProfile && profile == null
          ? const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: FluentProgressRing(strokeWidth: 2),
                ),
                SizedBox(width: FluentSpacing.s),
                Text('正在读取学籍信息...'),
              ],
            )
          : profile == null || !profile.hasAnyValue
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('暂未读取到学籍信息', style: theme.typography.bodyStrong),
                const SizedBox(height: FluentSpacing.xs),
                Text(
                  '应用会在启动或更新 OA 凭据后自动尝试补全',
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
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
    final theme = FluentTheme.of(context);
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
            Expanded(child: Text(name, style: theme.typography.subtitle)),
            Text(studentId, style: theme.typography.bodyStrong),
          ],
        ),
        const SizedBox(height: FluentSpacing.m),
        Text(
          department,
          style: theme.typography.body?.copyWith(
            color: theme.resources.textFillColorSecondary,
          ),
        ),
        const SizedBox(height: FluentSpacing.xs),
        Row(
          children: [
            Expanded(child: Text(major)),
            const SizedBox(width: FluentSpacing.s),
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
