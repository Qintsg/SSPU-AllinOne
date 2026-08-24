/*
 * 设置页安全与数据隐私操作 — 密码认证、危险确认与本地数据清除
 * @Project : SSPU-AllinOne
 * @File : settings_page_security_privacy_actions.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'settings_page.dart';

/// 承载安全验证及本地数据操作，保持其确认、反馈与失败恢复边界独立。
mixin _SettingsPageSecurityPrivacyActions
    on State<SettingsPage>, _SettingsPageActions {
  /// 切换密码保护。
  Future<void> _onPasswordProtectionChanged(bool enabled) async {
    if (enabled) {
      final ok = await showSetPasswordDialog(context);
      if (ok && mounted) {
        setState(() {
          _isPasswordEnabled = true;
          _isQuickAuthEnabled = false;
        });
        _showSuccessBar('密码已设置');
      }
      return;
    }

    final ok = await showRemovePasswordDialog(context);
    if (ok && mounted) {
      setState(() {
        _isPasswordEnabled = false;
        _isQuickAuthEnabled = false;
      });
      _showSuccessBar('密码保护已移除');
    }
  }

  /// 修改密码，并让系统快速验证重新接受当前密码约束。
  Future<void> _onChangePassword() async {
    final ok = await showChangePasswordDialog(context);
    if (ok && mounted) {
      setState(() => _isQuickAuthEnabled = false);
      _showSuccessBar('密码已修改');
    }
  }

  /// 修改系统快速验证开关。
  Future<void> _onQuickAuthChanged(bool enabled) async {
    if (!_isPasswordEnabled || _isQuickAuthBusy) return;

    if (!enabled) {
      await PasswordService.setQuickAuthEnabled(false);
      if (!mounted) return;
      setState(() => _isQuickAuthEnabled = false);
      _showSuccessBar('系统快速验证已关闭');
      return;
    }

    if (!_isQuickAuthAvailable) {
      _showErrorBar('当前平台或设备不支持系统快速验证');
      return;
    }

    final passwordConfirmed = await showConfirmCurrentPasswordDialog(
      context,
      title: '启用系统快速验证',
      message: '请输入当前密码。通过后将调用系统认证完成启用确认。',
      confirmLabel: '继续',
    );
    if (!passwordConfirmed || !mounted) return;

    setState(() => _isQuickAuthBusy = true);
    final authResult = await SystemAuthService.instance.authenticate(
      localizedReason: '验证身份以启用 ${AppDisplayName.of(context)} 系统快速解锁',
    );
    if (!mounted) return;

    if (authResult == SystemAuthResult.success) {
      await PasswordService.setQuickAuthEnabled(true);
      if (!mounted) return;
      setState(() {
        _isQuickAuthEnabled = true;
        _isQuickAuthBusy = false;
      });
      _showSuccessBar('系统快速验证已启用');
      return;
    }

    await PasswordService.setQuickAuthEnabled(false);
    if (!mounted) return;
    setState(() {
      _isQuickAuthEnabled = false;
      _isQuickAuthBusy = false;
    });
    _showErrorBar('系统认证未完成，已保留手动密码解锁');
  }

  /// 清除校园业务缓存，保留账户连接和本机偏好。
  Future<bool> _showClearCampusCacheDialog() async {
    final confirmed = await showSettingsDataPrivacyConfirmation(
      context,
      kind: SettingsDataPrivacyConfirmationKind.clearCampusCache,
    );

    if (!confirmed) return false;
    const stages = ['校园业务缓存', '信息中心消息缓存', '信息中心已读状态'];
    final completed = <String>[];
    try {
      await AuthenticatedDataCacheService.clearAll();
      completed.add(stages[0]);
      await StorageService.remove(MessageChannelKeys.persistedMessages);
      completed.add(stages[1]);
      await StorageService.remove(MessageChannelKeys.readMessageIds);
      completed.add(stages[2]);
    } catch (_) {
      throw _dataPrivacyFailure(stages, completed);
    }
    if (mounted) {
      showYhFeedback(
        context,
        message: '校园缓存已清除',
        severity: AppFeedbackSeverity.success,
      );
    }
    return true;
  }

  /// 断开校园账户与微信公众号连接，保留普通偏好和信息中心缓存。
  Future<bool> _showDisconnectAccountsDialog() async {
    final confirmed = await showSettingsDataPrivacyConfirmation(
      context,
      kind: SettingsDataPrivacyConfirmationKind.disconnectAccounts,
    );

    if (!confirmed) return false;
    const stages = ['OA、体育与邮箱凭据及校园业务缓存', '微信公众号连接'];
    final completed = <String>[];
    try {
      await AcademicCredentialsService.instance.clearAll();
      completed.add(stages[0]);
      await WxmpAuthService.instance.clearAuth();
      completed.add(stages[1]);
      if (mounted) _showSuccessBar('账户连接已断开');
      return true;
    } catch (_) {
      if (mounted) {
        _showErrorBar('断开失败，请确认系统安全存储和本机配置可用');
      }
      throw _dataPrivacyFailure(stages, completed);
    }
  }

  /// 清除所有本地数据并退出。
  Future<bool> _showClearAllDataDialog() async {
    final confirmed = await showSettingsDataPrivacyConfirmation(
      context,
      kind: SettingsDataPrivacyConfirmationKind.clearAllData,
    );

    if (!confirmed) return false;
    const stages = ['OA、体育与邮箱凭据及校园业务缓存', '微信公众号连接', '本机偏好与信息缓存', '退出应用'];
    final completed = <String>[];
    try {
      await AcademicCredentialsService.instance.clearAll();
      completed.add(stages[0]);
      await WxmpAuthService.instance.clearAuth();
      completed.add(stages[1]);
      await StorageService.clearAll();
      completed.add(stages[2]);
      await AppExitService.instance.exit();
      completed.add(stages[3]);
      return true;
    } catch (_) {
      if (mounted) {
        _showErrorBar('清除失败，请确认系统安全存储可用');
      }
      throw _dataPrivacyFailure(stages, completed);
    }
  }

  /// 组合部分完成信息，供数据清除失败对话展示真实可恢复边界。
  ///
  /// :param stages: 全部待完成阶段。
  /// :param completed: 已完成阶段。
  /// :returns: 包含已完成与剩余阶段的数据隐私操作异常。
  SettingsDataPrivacyOperationException _dataPrivacyFailure(
    List<String> stages,
    List<String> completed,
  ) {
    return SettingsDataPrivacyOperationException(
      completedItems: List.unmodifiable(completed),
      remainingItems: List.unmodifiable(
        stages.where((stage) => !completed.contains(stage)),
      ),
    );
  }

  /// 读取设置数据与隐私页的本机状态摘要。
  ///
  /// :returns: 缓存、账户和隐私状态快照。
  Future<SettingsDataPrivacySnapshot> _loadDataPrivacySnapshot() async {
    final hasCampusCache = await AuthenticatedDataCacheService.hasAny();
    final persistedMessages = await StorageService.getString(
      MessageChannelKeys.persistedMessages,
    );
    final readMessageIds = await StorageService.getString(
      MessageChannelKeys.readMessageIds,
    );
    final hasMessageCache =
        persistedMessages?.isNotEmpty == true ||
        readMessageIds?.isNotEmpty == true;
    final credentials = await AcademicCredentialsService.instance.getStatus();
    final wxmp = await WxmpAuthService.instance.getAuthStatus();
    final connections = <String>[
      if (credentials.hasOaPassword) 'OA',
      if (credentials.hasSportsQueryPassword) '体育',
      if (credentials.hasEmailPassword) '邮箱',
      if (wxmp.isUsable) '微信',
    ];
    final cacheStatus = switch ((hasCampusCache, hasMessageCache)) {
      (true, true) => '已保存校园与信息缓存',
      (true, false) => '已保存校园业务缓存',
      (false, true) => '已保存信息中心缓存',
      (false, false) => '当前无校园或信息缓存',
    };
    return SettingsDataPrivacySnapshot(
      cacheStatus: cacheStatus,
      accountStatus: connections.isEmpty
          ? '当前未连接账户'
          : '已连接：${connections.join('、')}',
      privacyStatus: '随应用提供，可离线查看',
    );
  }
}
