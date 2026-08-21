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
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    if (_isCredentialsLoading) {
      return Center(
        child: SizedBox(
          width: theme.layout.statusProgressWidth,
          child: const YhProgress(showPercent: false),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_credentialsLoadFailed) ...[
          YhBanner(
            text: '无法读取本机凭据状态；已保留当前输入和原连接。',
            kind: YhBannerKind.danger,
            action: YhButton(
              label: _isCredentialsReloading ? '重试中' : '重试',
              onTap: _isCredentialsReloading
                  ? null
                  : () => _loadAcademicCredentials(isRetry: true),
              disabled: _isCredentialsReloading,
              variant: YhButtonVariant.text,
            ),
          ),
          SizedBox(height: theme.spacing.l),
        ],
        _buildAcademicCredentialsHeader(context),
        SizedBox(height: compact ? theme.spacing.m : theme.spacing.l),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.layout.formContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YhTextField(
                label: '学工号（OA账号）',
                controller: _oaAccountController,
                hint: '请输入学工号',
                enabled: !_isCredentialOperationBusy,
              ),
              SizedBox(height: theme.spacing.xs),
              Text(
                _credentialsStatus.emailAccount.isEmpty
                    ? '学校邮箱账号将自动使用“学工号@sspu.edu.cn”。'
                    : '学校邮箱账号：${_credentialsStatus.emailAccount}',
                style: theme.typography.caption.copyWith(
                  color: theme.color.muted,
                ),
              ),
              SizedBox(height: theme.spacing.m),
              _buildPasswordCredentialField(
                label: 'OA账号密码',
                controller: _oaPasswordController,
                secret: AcademicCredentialSecret.oaPassword,
              ),
              SizedBox(height: theme.spacing.m),
              _buildPasswordCredentialField(
                label: '体育部查询密码',
                controller: _sportsPasswordController,
                secret: AcademicCredentialSecret.sportsQueryPassword,
              ),
              SizedBox(height: theme.spacing.m),
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
    final theme = context.yhTheme;
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('教务凭据', style: theme.typography.h3),
        SizedBox(height: theme.spacing.xs),
        Text(
          '数据均加密存储在本机，不会上传至云端；密码框留空时不修改已保存密码。',
          style: theme.typography.small.copyWith(color: theme.color.muted),
        ),
      ],
    );
    final actions = Wrap(
      spacing: theme.spacing.s,
      runSpacing: theme.spacing.s,
      children: [
        YhButton(
          label: _isSavingCredentials ? '保存中' : '保存教务凭据',
          onTap: _isCredentialOperationBusy ? null : _saveAcademicCredentials,
          disabled: _isCredentialOperationBusy,
        ),
        YhButton(
          label: _isValidatingAcademicLogin ? '验证中' : '验证登录',
          onTap: _isCredentialOperationBusy ? null : _validateAcademicLogin,
          disabled: _isCredentialOperationBusy,
          variant: YhButtonVariant.secondary,
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
              SizedBox(height: theme.spacing.m),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: summary),
            SizedBox(width: theme.spacing.l),
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
        SizedBox(height: context.yhTheme.spacing.xs),
        YhTextField(
          label: label,
          showLabel: false,
          controller: controller,
          hint: '留空则不修改已保存密码',
          obscure: true,
          enabled: !_isCredentialOperationBusy,
        ),
        SizedBox(height: context.yhTheme.spacing.xs),
        Wrap(
          spacing: context.yhTheme.spacing.s,
          runSpacing: context.yhTheme.spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildSecretStatus(hasSecret),
            if (hasSecret)
              YhButton(
                label: '清除',
                onTap: _isCredentialOperationBusy
                    ? null
                    : () => _clearAcademicSecret(secret),
                disabled: _isCredentialOperationBusy,
                leadingIcon: YhIcons.delete,
                variant: YhButtonVariant.secondary,
              ),
          ],
        ),
      ],
    );
  }

  Widget _credentialFieldLabel(String label, AcademicCredentialSecret secret) {
    final theme = context.yhTheme;
    final labelStyle = theme.typography.small.copyWith(
      color: theme.color.foreground,
      fontWeight: FontWeight.w600,
    );
    final badge = _credentialValidationBadges[secret];
    if (badge == null) return Text(label, style: labelStyle);

    return Wrap(
      spacing: theme.spacing.xs,
      runSpacing: theme.spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label, style: labelStyle),
        _CredentialValidationBadgeView(badge: badge),
      ],
    );
  }

  /// 构建已填写/未填写状态提示。
  Widget _buildSecretStatus(bool hasSecret) {
    final theme = context.yhTheme;
    return Text(
      hasSecret ? '已填写' : '未填写',
      style: theme.typography.caption.copyWith(
        color: hasSecret ? theme.color.brandStrong : theme.color.muted,
      ),
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
    final theme = context.yhTheme;
    final foreground = badge.isSuccess
        ? theme.color.success
        : theme.color.danger;

    return YhTooltip(
      message: badge.message,
      child: Text(
        badge.isSuccess ? '验证通过' : '验证未通过',
        style: theme.typography.small.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
