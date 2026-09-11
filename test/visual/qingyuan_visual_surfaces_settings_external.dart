/*
 * 清源视觉 surface 清单 — 设置、法律与外部内容
 * @Project : SSPU-AllinOne
 * @File : qingyuan_visual_surfaces_settings_external.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'qingyuan_visual_capture_test.dart';

final _settingsAndExternalSurfaces = <_VisualSurface>[
  _VisualSurface(
    'settings.account',
    _settingsAccountContent,
    destination: '设置',
  ),
  _VisualSurface(
    'settings.account',
    _settingsAccountError,
    state: 'error',
    destination: '设置',
  ),
  _VisualSurface(
    'security.password-dialog',
    _passwordDialogVisualHost,
    prepare: _showPasswordDialog,
    destination: '设置',
  ),
  _VisualSurface(
    'security.password-dialog',
    _passwordDialogVisualHost,
    state: 'validation-error',
    prepare: _showPasswordDialogValidationError,
    destination: '设置',
  ),
  _VisualSurface(
    'settings.home-notifications',
    _settingsHomeNotifications,
    prepare: _prepareSettingsHomeNotifications,
    destination: '设置',
  ),
  _VisualSurface(
    'settings.auto-refresh',
    _settingsAutoRefresh,
    destination: '设置',
  ),
  _VisualSurface('settings.appearance', _settingsAppearance),
  _VisualSurface(
    'ai-services.overview',
    _aiServicesOverview,
    destination: 'AI 服务',
  ),
  for (final state in SettingsDataPrivacyState.values)
    _VisualSurface(
      'settings.data-privacy',
      () => _settingsDataPrivacy(state),
      state: state.name,
    ),
  _VisualSurface(
    'settings.confirm-clear-cache',
    () => _dataPrivacyConfirmationVisualHost(
      SettingsDataPrivacyConfirmationKind.clearCampusCache,
    ),
    prepare: _showDataPrivacyConfirmation,
    destination: '设置',
  ),
  _VisualSurface(
    'settings.confirm-disconnect-accounts',
    () => _dataPrivacyConfirmationVisualHost(
      SettingsDataPrivacyConfirmationKind.disconnectAccounts,
    ),
    prepare: _showDataPrivacyConfirmation,
    destination: '设置',
  ),
  _VisualSurface(
    'settings.confirm-clear-all-data',
    () => _dataPrivacyConfirmationVisualHost(
      SettingsDataPrivacyConfirmationKind.clearAllData,
    ),
    prepare: _showDataPrivacyConfirmation,
    destination: '设置',
  ),
  for (final state in SettingsWechatAuthDisplayState.values)
    _VisualSurface(
      'settings.wechat-auth',
      () => _settingsWechatAuth(state),
      state: state.name,
    ),
  for (final state in WxmpLoginPreviewState.values)
    _VisualSurface(
      'settings.wechat-login',
      () => _wechatLogin(state),
      state: _wechatLoginStateName(state),
      prepare: state == WxmpLoginPreviewState.externalConfirmation
          ? _showWechatLoginExternalConfirmation
          : null,
      destination: '设置',
      externalRegionId:
          const [
            WxmpLoginPreviewState.initial,
            WxmpLoginPreviewState.content,
            WxmpLoginPreviewState.partialError,
            WxmpLoginPreviewState.operationLocked,
            WxmpLoginPreviewState.externalError,
          ].contains(state)
          ? 'document'
          : null,
      externalRegionKey:
          const [
            WxmpLoginPreviewState.initial,
            WxmpLoginPreviewState.content,
            WxmpLoginPreviewState.partialError,
            WxmpLoginPreviewState.operationLocked,
            WxmpLoginPreviewState.externalError,
          ].contains(state)
          ? _wechatLoginExternalRegionKey
          : null,
    ),
  _VisualSurface(
    'settings.wechat-config',
    _wechatConfigDialogVisualHost,
    prepare: _showWechatConfigDialog,
    destination: '设置',
  ),
  _VisualSurface(
    'settings.wechat-config',
    _wechatConfigDialogVisualHost,
    state: 'validation-error',
    prepare: _showWechatConfigValidationError,
    destination: '设置',
  ),
  _VisualSurface('settings.update', _settingsUpdateInitial, state: 'initial'),
  _VisualSurface(
    'settings.update',
    _settingsUpdateLoading,
    state: 'loading',
    prepare: _startSettingsUpdateCheck,
  ),
  _VisualSurface(
    'settings.update',
    _settingsUpdateContent,
    prepare: _startSettingsUpdateCheck,
  ),
  _VisualSurface(
    'settings.update',
    _settingsUpdateError,
    state: 'error',
    prepare: _startSettingsUpdateCheck,
  ),
  for (final state in SettingsAboutState.values)
    _VisualSurface(
      'settings.about',
      () => _settingsAbout(state),
      state: state.name,
    ),
  _VisualSurface(
    'settings.about',
    _interactiveSettingsAbout,
    state: 'external-confirmation',
    prepare: _showAboutExternalConfirmation,
  ),
  _VisualSurface(
    'settings.about',
    _interactiveSettingsAbout,
    state: 'external-cancelled',
    prepare: _cancelAboutExternalConfirmation,
    cleanup: _dismissTransientFeedback,
  ),
  _VisualSurface(
    'settings.about',
    _failingSettingsAbout,
    state: 'external-error',
    prepare: _confirmAboutExternalOpen,
  ),
  _VisualSurface(
    'settings.about',
    _pendingSettingsAbout,
    state: 'operation-locked',
    prepare: _confirmAboutExternalOpen,
    cleanup: _completeAboutExternalOpen,
  ),
  _VisualSurface('settings.licenses', _interactiveSettingsLicenses),
  _VisualSurface(
    'settings.licenses',
    _interactiveSettingsLicenses,
    state: 'external-confirmation',
    prepare: _showLicenseExternalConfirmation,
  ),
  _VisualSurface(
    'settings.licenses',
    _interactiveSettingsLicenses,
    state: 'external-cancelled',
    prepare: _cancelLicenseExternalConfirmation,
    cleanup: _dismissTransientFeedback,
  ),
  _VisualSurface(
    'settings.licenses',
    _failingSettingsLicenses,
    state: 'external-error',
    prepare: _confirmLicenseExternalOpen,
  ),
  _VisualSurface(
    'settings.licenses',
    _pendingSettingsLicenses,
    state: 'operation-locked',
    prepare: _confirmLicenseExternalOpen,
    cleanup: _completeLicenseExternalOpen,
  ),
  _VisualSurface(
    'external.webview',
    () => _externalWebViewSurface(loading: true),
    state: 'loading',
  ),
  _VisualSurface(
    'external.webview',
    () => _externalWebViewSurface(loading: false),
    externalRegionId: 'document',
    externalRegionKey: _webViewExternalRegionKey,
  ),
  _VisualSurface(
    'external.webview',
    _externalWebViewFailureSurface,
    state: 'error',
  ),
  _VisualSurface(
    'external.webview',
    _externalWebViewConfirmationSurface,
    state: 'external-confirmation',
    prepare: _showWebViewExternalConfirmation,
  ),
  for (final state in const ['external-error', 'operation-locked'])
    _VisualSurface(
      'external.webview',
      () => _externalWebViewRetainedSurface(state),
      state: state,
      externalRegionId: 'document',
      externalRegionKey: _webViewExternalRegionKey,
    ),
  for (final state in const [
    'loading',
    'content',
    'empty',
    'error',
    'partial-error',
    'operation-locked',
    'external-error',
  ])
    _VisualSurface(
      'external.pdf',
      () => _externalPdfSurface(state),
      state: state,
      prepare: (tester) => _prepareExternalPdfState(tester, state),
      cleanup: (tester) => _cleanupExternalPdfState(tester, state),
      externalRegionId:
          const [
            'content',
            'partial-error',
            'operation-locked',
            'external-error',
          ].contains(state)
          ? 'document'
          : null,
      externalRegionKey:
          const [
            'content',
            'partial-error',
            'operation-locked',
            'external-error',
          ].contains(state)
          ? _pdfExternalRegionKey
          : null,
    ),
  _VisualSurface(
    'external.pdf',
    _externalPdfConfirmationSurface,
    state: 'external-confirmation',
    prepare: _showExternalPdfConfirmation,
  ),
  for (final state in const ['initial', 'content', 'error'])
    _VisualSurface(
      'external.system-auth',
      () => _externalSystemAuthSurface(state),
      state: state,
      externalRegionId: state == 'content' ? 'system-dialog' : null,
      externalRegionKey: state == 'content'
          ? _systemAuthExternalRegionKey
          : null,
    ),
];
