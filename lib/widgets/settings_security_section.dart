/*
 * 设置页安全分区组件 — 密码保护与数据管理
 * @Project : SSPU-AllinOne
 * @File : settings_security_section.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import 'dart:async';

import '../design/fluent_ui.dart';

import '../models/academic_credentials.dart';
import '../models/email_mailbox.dart';
import '../services/academic_credentials_service.dart';
import '../services/academic_oa_session_prewarm_service.dart';
import '../services/academic_login_validation_service.dart';
import '../services/email_service.dart';
import '../services/sports_attendance_service.dart';
import '../theme/fluent_tokens.dart';
import 'app_feedback.dart';
import 'responsive_layout.dart';
import 'settings_widgets.dart';

part 'settings_security_credentials_section.dart';
part 'settings_security_data_management.dart';

/// 安全设置分区。
class SettingsSecuritySection extends StatefulWidget {
  /// 是否已启用密码保护。
  final bool isPasswordEnabled;

  /// 开关密码保护。
  final ValueChanged<bool> onPasswordProtectionChanged;

  /// 修改密码回调。
  final VoidCallback onChangePassword;

  /// 是否已启用系统快速验证。
  final bool isQuickAuthEnabled;

  /// 当前平台/设备是否可用系统快速验证。
  final bool isQuickAuthAvailable;

  /// 系统快速验证开关是否正在处理。
  final bool isQuickAuthBusy;

  /// 开关系统快速验证。
  final ValueChanged<bool> onQuickAuthChanged;

  /// 立即上锁回调。
  final VoidCallback? onLock;

  /// 清理消息缓存回调。
  final VoidCallback onClearMessageCache;

  /// 清除所有数据回调。
  final VoidCallback onClearAllData;

  /// 可替换的 OA 登录校验服务，便于测试中使用 fake 网关。
  final AcademicLoginValidationService? academicLoginValidationService;

  /// 可替换的 OA 会话与学籍预热服务，便于测试触发链路。
  final AcademicOaSessionPrewarmService? academicOaSessionPrewarmService;

  /// 可替换的体育部登录验证服务，便于测试中使用 fake。
  final SportsAttendanceClient? sportsAttendanceService;

  /// 可替换的邮箱登录验证服务，便于测试中使用 fake。
  final EmailMailboxClient? emailMailboxService;

  const SettingsSecuritySection({
    super.key,
    required this.isPasswordEnabled,
    required this.onPasswordProtectionChanged,
    required this.onChangePassword,
    required this.isQuickAuthEnabled,
    required this.isQuickAuthAvailable,
    required this.isQuickAuthBusy,
    required this.onQuickAuthChanged,
    required this.onLock,
    required this.onClearMessageCache,
    required this.onClearAllData,
    this.academicLoginValidationService,
    this.academicOaSessionPrewarmService,
    this.sportsAttendanceService,
    this.emailMailboxService,
  });

  @override
  State<SettingsSecuritySection> createState() =>
      _SettingsSecuritySectionState();
}

class _SettingsSecuritySectionState extends State<SettingsSecuritySection> {
  final AcademicCredentialsService _academicCredentials =
      AcademicCredentialsService.instance;
  final TextEditingController _oaAccountController = TextEditingController();
  final TextEditingController _oaPasswordController = TextEditingController();
  final TextEditingController _sportsPasswordController =
      TextEditingController();
  final TextEditingController _emailPasswordController =
      TextEditingController();

  AcademicCredentialsStatus _credentialsStatus =
      const AcademicCredentialsStatus.empty();
  Map<AcademicCredentialSecret, _CredentialValidationBadge>
  _credentialValidationBadges = const {};
  bool _isCredentialsLoading = true;
  bool _isSavingCredentials = false;
  bool _isValidatingAcademicLogin = false;

  AcademicLoginValidationService get _academicLoginValidationService {
    return widget.academicLoginValidationService ??
        AcademicLoginValidationService.instance;
  }

  AcademicOaSessionPrewarmService get _academicOaSessionPrewarmService {
    return widget.academicOaSessionPrewarmService ??
        AcademicOaSessionPrewarmService.instance;
  }

  SportsAttendanceClient get _sportsAttendanceService {
    return widget.sportsAttendanceService ?? SportsAttendanceService.instance;
  }

  EmailMailboxClient get _emailMailboxService {
    return widget.emailMailboxService ?? EmailService.instance;
  }

  @override
  void initState() {
    super.initState();
    _loadAcademicCredentials();
  }

  @override
  void dispose() {
    _oaAccountController.dispose();
    _oaPasswordController.dispose();
    _sportsPasswordController.dispose();
    _emailPasswordController.dispose();
    super.dispose();
  }

  /// 加载教务凭据状态，密码输入框始终保持为空。
  Future<void> _loadAcademicCredentials() async {
    try {
      final status = await _academicCredentials.getStatus();
      if (!mounted) return;
      _oaAccountController.text = status.oaAccount;
      _clearPasswordInputs();
      setState(() {
        _credentialsStatus = status;
        _isCredentialsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _credentialsStatus = const AcademicCredentialsStatus.empty();
        _isCredentialsLoading = false;
      });
    }
  }

  /// 保存本次填写的账号和密码。
  Future<void> _saveAcademicCredentials() async {
    if (_isSavingCredentials) return;
    setState(() => _isSavingCredentials = true);

    try {
      final previousStatus = await _academicCredentials.getStatus();
      final enteredOaPassword = _nullablePassword(_oaPasswordController.text);
      await _academicCredentials.saveCredentials(
        oaAccount: _oaAccountController.text,
        oaPassword: enteredOaPassword,
        sportsQueryPassword: _nullablePassword(_sportsPasswordController.text),
        emailPassword: _nullablePassword(_emailPasswordController.text),
      );
      final status = await _academicCredentials.getStatus();
      if (!mounted) return;
      _clearPasswordInputs();
      setState(() {
        _credentialsStatus = status;
        _isSavingCredentials = false;
      });
      unawaited(
        _prewarmAcademicLoginSession(
          status,
          forceRefreshStudentProfile:
              previousStatus.oaAccount.trim() != status.oaAccount.trim() ||
              (enteredOaPassword != null && enteredOaPassword.isNotEmpty),
        ),
      );
      _showCredentialInfoBar('教务凭据已保存', FluentInfoSeverity.success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSavingCredentials = false);
      _showCredentialInfoBar('保存失败，请确认系统安全存储可用', FluentInfoSeverity.error);
    }
  }

  /// 清除指定密码字段。
  Future<void> _clearAcademicSecret(AcademicCredentialSecret secret) async {
    if (_isSavingCredentials) return;
    setState(() => _isSavingCredentials = true);

    try {
      await _academicCredentials.clearSecret(secret);
      final status = await _academicCredentials.getStatus();
      if (!mounted) return;
      _clearPasswordInputs();
      setState(() {
        _credentialsStatus = status;
        _isSavingCredentials = false;
      });
      _showCredentialInfoBar(
        '${_secretLabel(secret)}已清除',
        FluentInfoSeverity.info,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSavingCredentials = false);
      _showCredentialInfoBar('清除失败，请确认系统安全存储可用', FluentInfoSeverity.error);
    }
  }

  /// 使用已保存账号密码执行一次只读聚合登录校验。
  Future<void> _validateAcademicLogin() async {
    if (_isSavingCredentials || _isValidatingAcademicLogin) return;
    setState(() {
      _isValidatingAcademicLogin = true;
      _credentialValidationBadges = const {};
    });

    try {
      final status = await _academicCredentials.getStatus();
      final validations = <Future<_CredentialValidationOutcome>>[];
      if (status.hasOaPassword) {
        validations.add(_validateOaCredential());
      }
      if (status.hasSportsQueryPassword) {
        validations.add(_validateSportsCredential());
      }
      if (status.hasEmailPassword) {
        validations.add(_validateEmailCredential());
      }

      if (validations.isEmpty) {
        if (!mounted) return;
        setState(() => _isValidatingAcademicLogin = false);
        _showCredentialInfoBar('没有可验证的已保存密码', FluentInfoSeverity.warning);
        return;
      }

      final outcomes = await Future.wait(validations);
      if (!mounted) return;
      setState(() {
        _credentialValidationBadges = {
          for (final outcome in outcomes) outcome.secret: outcome.badge,
        };
        _isValidatingAcademicLogin = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isValidatingAcademicLogin = false);
      _showCredentialInfoBar('登录验证失败，请稍后重试', FluentInfoSeverity.error);
    }
  }

  Future<_CredentialValidationOutcome> _validateOaCredential() async {
    final result = await _academicLoginValidationService
        .validateSavedCredentials(requireCampusNetwork: false);
    return _CredentialValidationOutcome(
      secret: AcademicCredentialSecret.oaPassword,
      badge: _CredentialValidationBadge(
        isSuccess: result.isSuccess,
        message: result.message,
      ),
    );
  }

  Future<_CredentialValidationOutcome> _validateSportsCredential() async {
    final result = await _sportsAttendanceService.fetchAttendanceSummary(
      requireCampusNetwork: false,
    );
    return _CredentialValidationOutcome(
      secret: AcademicCredentialSecret.sportsQueryPassword,
      badge: _CredentialValidationBadge(
        isSuccess: result.isSuccess,
        message: result.message,
      ),
    );
  }

  Future<_CredentialValidationOutcome> _validateEmailCredential() async {
    final result = await _emailMailboxService.validateLogin(EmailProtocol.smtp);
    return _CredentialValidationOutcome(
      secret: AcademicCredentialSecret.emailPassword,
      badge: _CredentialValidationBadge(
        isSuccess: result.isSuccess,
        message: result.message,
      ),
    );
  }

  /// 保存凭据后静默准备 OA 会话，避免用户必须手动点击“验证 OA 登录”。
  Future<void> _prewarmAcademicLoginSession(
    AcademicCredentialsStatus status, {
    required bool forceRefreshStudentProfile,
  }) async {
    if (status.oaAccount.trim().isEmpty || !status.hasOaPassword) return;
    try {
      await _academicOaSessionPrewarmService.prewarm(
        forceRefresh: true,
        requireCampusNetwork: false,
        refreshStudentProfile: forceRefreshStudentProfile,
      );
    } catch (_) {
      // 静默预热失败不打断保存流程；用户仍可手动验证查看具体原因。
    }
  }

  /// 空输入表示不修改当前密码。
  String? _nullablePassword(String value) => value.isEmpty ? null : value;

  /// 清空所有密码输入框，避免明文停留在页面控件中。
  void _clearPasswordInputs() {
    _oaPasswordController.clear();
    _sportsPasswordController.clear();
    _emailPasswordController.clear();
  }

  /// 显示教务凭据操作反馈。
  void _showCredentialInfoBar(String message, FluentInfoSeverity severity) {
    showFluentInfoBar(
      context,
      title: Text(message),
      severity: severity,
      actionBuilder: (close) => FluentIconButton(
        icon: const Icon(FluentIcons.clear),
        onPressed: close,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('安全', style: FluentTheme.of(context).typography.subtitle),
            const SizedBox(height: FluentSpacing.l),
            buildResponsiveSettingsRow(
              context: context,
              icon: FluentIcons.lock,
              title: Text(
                '密码保护',
                style: FluentTheme.of(context).typography.bodyStrong,
              ),
              subtitle: Text(
                widget.isPasswordEnabled
                    ? '已开启 — 重新打开应用时需要输入密码'
                    : '未开启 — 任何人可直接进入应用',
                style: FluentTheme.of(context).typography.caption,
              ),
              trailing: FluentSwitch(
                value: widget.isPasswordEnabled,
                onChanged: widget.onPasswordProtectionChanged,
              ),
            ),
            if (widget.isPasswordEnabled && widget.isQuickAuthAvailable) ...[
              const SizedBox(height: FluentSpacing.l),
              buildResponsiveSettingsRow(
                context: context,
                icon: FluentIcons.fingerprint,
                title: Text(
                  '系统快速验证',
                  style: FluentTheme.of(context).typography.bodyStrong,
                ),
                subtitle: Text(
                  widget.isQuickAuthEnabled
                      ? '已开启 — 锁定页会优先请求系统认证，仍可输入密码解锁'
                      : '可使用设备 PIN、生物识别或平台支持的系统认证快速解锁',
                  style: FluentTheme.of(context).typography.caption,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isQuickAuthBusy) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: FluentProgressRing(strokeWidth: 2),
                      ),
                      const SizedBox(width: FluentSpacing.s),
                    ],
                    FluentSwitch(
                      value: widget.isQuickAuthEnabled,
                      onChanged: widget.isQuickAuthBusy
                          ? null
                          : widget.onQuickAuthChanged,
                    ),
                  ],
                ),
              ),
            ] else if (widget.isPasswordEnabled) ...[
              const SizedBox(height: FluentSpacing.l),
              buildResponsiveSettingsRow(
                context: context,
                icon: FluentIcons.fingerprint,
                title: Text(
                  '系统快速验证不可用',
                  style: FluentTheme.of(context).typography.bodyStrong,
                ),
                subtitle: Text(
                  '当前平台、设备或系统认证未配置；仍可使用应用密码手动解锁。',
                  style: FluentTheme.of(context).typography.caption,
                ),
                trailing: const Icon(FluentIcons.info, size: 16),
              ),
            ],
            if (widget.isPasswordEnabled) ...[
              const SizedBox(height: FluentSpacing.m),
              Wrap(
                spacing: FluentSpacing.m,
                runSpacing: FluentSpacing.s,
                children: [
                  FluentButton.outline(
                    onPressed: widget.onChangePassword,
                    child: const Text('修改密码'),
                  ),
                  FluentButton.primary(
                    onPressed: widget.onLock,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.lock, size: 14),
                        SizedBox(width: FluentSpacing.xs + FluentSpacing.xxs),
                        Text('立即上锁'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: FluentSpacing.xl),
            const Divider(),
            const SizedBox(height: FluentSpacing.l),
            _buildAcademicCredentialsSection(context),
            const SizedBox(height: FluentSpacing.xl),
            const Divider(),
            const SizedBox(height: FluentSpacing.l),
            _DataManagementRow(
              onClearMessageCache: widget.onClearMessageCache,
              onClearAllData: widget.onClearAllData,
            ),
          ],
        ),
      ),
    );
  }

  /// 返回密码字段展示名。
  String _secretLabel(AcademicCredentialSecret secret) {
    return switch (secret) {
      AcademicCredentialSecret.oaPassword => 'OA账号密码',
      AcademicCredentialSecret.sportsQueryPassword => '体育部查询密码',
      AcademicCredentialSecret.emailPassword => '邮箱密码',
    };
  }
}
