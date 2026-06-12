/*
 * 设置页教务凭据区域 — 账号、密码与 OA 登录校验展示
 * @Project : SSPU-AllinOne
 * @File : settings_security_credentials_section.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'settings_security_section.dart';

extension _SettingsSecurityCredentialsSection on _SettingsSecuritySectionState {
  /// 构建教务系统账号与密码保存区域。
  Widget _buildAcademicCredentialsSection(BuildContext context) {
    final theme = FluentTheme.of(context);
    if (_isCredentialsLoading) {
      return const Center(child: FluentProgressRing());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAcademicCredentialsHeader(context),
        const SizedBox(height: FluentSpacing.l),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FluentInfoLabel(
                label: '学工号（OA账号）',
                child: FluentTextField(
                  controller: _oaAccountController,
                  placeholder: '请输入学工号',
                ),
              ),
              const SizedBox(height: FluentSpacing.xs),
              Text(
                _credentialsStatus.emailAccount.isEmpty
                    ? '学校邮箱账号将自动使用“学工号@sspu.edu.cn”。'
                    : '学校邮箱账号：${_credentialsStatus.emailAccount}',
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorSecondary,
                ),
              ),
              const SizedBox(height: FluentSpacing.m),
              _buildPasswordCredentialField(
                label: 'OA账号密码',
                controller: _oaPasswordController,
                secret: AcademicCredentialSecret.oaPassword,
              ),
              const SizedBox(height: FluentSpacing.m),
              _buildPasswordCredentialField(
                label: '体育部查询密码',
                controller: _sportsPasswordController,
                secret: AcademicCredentialSecret.sportsQueryPassword,
              ),
              const SizedBox(height: FluentSpacing.m),
              _buildPasswordCredentialField(
                label: '邮箱密码',
                controller: _emailPasswordController,
                secret: AcademicCredentialSecret.emailPassword,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicCredentialsHeader(BuildContext context) {
    final theme = FluentTheme.of(context);
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('教务凭据', style: theme.typography.subtitle),
        const SizedBox(height: FluentSpacing.xs),
        Text(
          '数据均加密存储在本地，不会上传至云端；密码框留空时不修改已保存密码。',
          style: theme.typography.caption,
        ),
      ],
    );
    final actions = Wrap(
      spacing: FluentSpacing.s,
      runSpacing: FluentSpacing.s,
      children: [
        FluentButton.primary(
          onPressed: _isSavingCredentials ? null : _saveAcademicCredentials,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSavingCredentials) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: FluentProgressRing(strokeWidth: 2),
                ),
              ] else ...[
                const Icon(FluentIcons.save, size: 14),
              ],
              const SizedBox(width: 6),
              const Text('保存教务凭据'),
            ],
          ),
        ),
        FluentButton.outline(
          onPressed: _isSavingCredentials || _isValidatingAcademicLogin
              ? null
              : _validateAcademicLogin,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isValidatingAcademicLogin) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: FluentProgressRing(strokeWidth: 2),
                ),
              ] else ...[
                const Icon(FluentIcons.plugConnected, size: 14),
              ],
              const SizedBox(width: 6),
              const Text('验证登录'),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack = shouldStackSettingsControls(constraints);
        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summary,
              const SizedBox(height: FluentSpacing.m),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: summary),
            const SizedBox(width: FluentSpacing.l),
            actions,
          ],
        );
      },
    );
  }

  /// 构建单个密码输入框和填写状态。
  Widget _buildPasswordCredentialField({
    required String label,
    required TextEditingController controller,
    required AcademicCredentialSecret secret,
  }) {
    final hasSecret = _credentialsStatus.hasSecret(secret);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _credentialFieldLabel(label, secret),
        SizedBox(height: context.fluentSpacing.xs),
        FluentTextField(
          controller: controller,
          placeholder: '留空则不修改已保存密码',
          obscureText: true,
          prefixIcon: FluentIcons.lock,
        ),
        const SizedBox(height: FluentSpacing.xs),
        Wrap(
          spacing: FluentSpacing.s,
          runSpacing: FluentSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildSecretStatus(hasSecret),
            if (hasSecret)
              FluentButton.outline(
                onPressed: _isSavingCredentials
                    ? null
                    : () => _clearAcademicSecret(secret),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.delete, size: 14),
                    SizedBox(width: 6),
                    Text('清除'),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _credentialFieldLabel(String label, AcademicCredentialSecret secret) {
    final colors = context.fluentColors;
    final labelStyle = context.fluentType.caption1Strong.copyWith(
      color: colors.neutralForeground1,
    );
    final badge = _credentialValidationBadges[secret];
    if (badge == null) return Text(label, style: labelStyle);

    return Wrap(
      spacing: FluentSpacing.xs,
      runSpacing: FluentSpacing.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label, style: labelStyle),
        _CredentialValidationBadgeView(badge: badge),
      ],
    );
  }

  /// 构建已填写/未填写状态提示。
  Widget _buildSecretStatus(bool hasSecret) {
    final theme = FluentTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(hasSecret ? FluentIcons.checkMark : FluentIcons.blocked, size: 14),
        const SizedBox(width: FluentSpacing.xs),
        Text(hasSecret ? '已填写' : '未填写', style: theme.typography.caption),
      ],
    );
  }
}

class _CredentialValidationBadge {
  const _CredentialValidationBadge({
    required this.isSuccess,
    required this.message,
  });

  final bool isSuccess;
  final String message;
}

class _CredentialValidationOutcome {
  const _CredentialValidationOutcome({
    required this.secret,
    required this.badge,
  });

  final AcademicCredentialSecret secret;
  final _CredentialValidationBadge badge;
}

class _CredentialValidationBadgeView extends StatelessWidget {
  const _CredentialValidationBadgeView({required this.badge});

  final _CredentialValidationBadge badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final foreground = badge.isSuccess
        ? colors.statusSuccessForeground
        : colors.statusDangerForeground;

    return Tooltip(
      message: badge.message,
      child: Text(
        badge.isSuccess ? '验证通过' : '验证未通过',
        style: context.fluentType.caption1Strong.copyWith(color: foreground),
      ),
    );
  }
}
