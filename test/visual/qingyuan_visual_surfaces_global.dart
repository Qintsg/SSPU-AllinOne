/*
 * 清源视觉 surface 清单 — 组件、全局与主页
 * @Project : SSPU-AllinOne
 * @File : qingyuan_visual_surfaces_global.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'qingyuan_visual_capture_test.dart';

final _globalAndHomeSurfaces = <_VisualSurface>[
  _VisualSurface('components.actions', componentActionsPanel),
  _VisualSurface('components.inputs', componentInputsPanel),
  _VisualSurface('components.feedback', componentFeedbackPanel),
  _VisualSurface('components.navigation', componentNavigationPanel),
  _VisualSurface('components.data', componentDataPanel),
  _VisualSurface('components.domain', componentDomainPanel),
  _VisualSurface(
    'shell.startup',
    () => const AppStartupStatus(progressLabel: '读取本地设置'),
    state: 'loading',
  ),
  _VisualSurface(
    'shell.startup',
    () => AppStartupStatus(errorMessage: '本地存储不可用；', onRetry: () {}),
    state: 'error',
  ),
  _VisualSurface('shell.navigation', _shellNavigation),
  _VisualSurface('shell.more-drawer', _moreDrawerSurface),
  _VisualSurface('shell.close-confirmation', _closeConfirmationSurface),
  _VisualSurface(
    'shell.close-confirmation',
    () => _closeConfirmationSurface(
      AppCloseConfirmationDisplayState.operationLocked,
    ),
    state: 'operation-locked',
  ),
  _VisualSurface(
    'shell.close-confirmation',
    () => _closeConfirmationSurface(AppCloseConfirmationDisplayState.error),
    state: 'error',
  ),
  _VisualSurface('consent.first-run', _consentInitial, state: 'initial'),
  _VisualSurface('consent.first-run', _consentContent),
  _VisualSurface('consent.first-run', _consentError, state: 'error'),
  _VisualSurface(
    'consent.first-run',
    _consentOperationLocked,
    state: 'operation-locked',
    prepare: _prepareConsentAccept,
  ),
  _VisualSurface(
    'consent.first-run',
    _consentPersistenceError,
    state: 'partial-error',
    prepare: _prepareConsentAccept,
  ),
  _VisualSurface('security.lock', _lockInitial, state: 'initial'),
  _VisualSurface(
    'security.lock',
    _lockLoading,
    state: 'loading',
    prepare: _prepareLockLoading,
  ),
  _VisualSurface(
    'security.lock',
    _lockError,
    state: 'error',
    prepare: _prepareLockError,
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.initial),
    state: 'initial',
    destination: '主页',
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.loading),
    state: 'loading',
    destination: '主页',
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.content),
    prepare: _prepareHomeDashboard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.stale),
    state: 'stale',
    prepare: _prepareHomeDashboard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.error),
    state: 'error',
    destination: '主页',
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.partialError),
    state: 'partial-error',
    prepare: _prepareHomeDashboard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.credentialsPartial),
    state: 'credentials-partial',
    prepare: _prepareHomeDashboard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.operationLocked),
    state: 'operation-locked',
    prepare: _prepareHomeDashboard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card',
    () => _homeCampusCardPage(HomeCampusCardDisplayState.loading),
    state: 'loading',
    prepare: _prepareHomeCampusCard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card',
    () => _homeCampusCardPage(HomeCampusCardDisplayState.content),
    prepare: _prepareHomeCampusCard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card',
    () => _homeCampusCardPage(HomeCampusCardDisplayState.empty),
    state: 'empty',
    prepare: _prepareHomeCampusCard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card',
    () => _homeCampusCardPage(HomeCampusCardDisplayState.stale),
    state: 'stale',
    prepare: _prepareHomeCampusCard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card',
    () => _homeCampusCardPage(HomeCampusCardDisplayState.error),
    state: 'error',
    prepare: _prepareHomeCampusCard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card',
    () => _homeCampusCardPage(HomeCampusCardDisplayState.operationLocked),
    state: 'operation-locked',
    prepare: _prepareHomeCampusCard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card-detail',
    () => _campusCardDetailPage(CampusCardDetailDisplayState.content),
    prepare: _prepareCampusCardDetailContent,
  ),
  _VisualSurface(
    'home.campus-card-detail',
    () => _campusCardDetailPage(CampusCardDetailDisplayState.empty),
    state: 'empty',
    prepare: _prepareCampusCardDetailEmpty,
  ),
  _VisualSurface(
    'home.campus-card-detail',
    () => _campusCardDetailPage(CampusCardDetailDisplayState.stale),
    state: 'stale',
    prepare: _prepareCampusCardDetailContent,
  ),
  _VisualSurface(
    'home.campus-card-detail',
    () => _campusCardDetailPage(CampusCardDetailDisplayState.error),
    state: 'error',
    prepare: _prepareCampusCardDetailError,
  ),
  _VisualSurface(
    'home.campus-card-detail',
    () => _campusCardDetailPage(CampusCardDetailDisplayState.partialError),
    state: 'partial-error',
    prepare: _prepareCampusCardDetailContent,
  ),
  _VisualSurface(
    'home.campus-card-detail',
    () => _campusCardDetailPage(CampusCardDetailDisplayState.operationLocked),
    state: 'operation-locked',
    prepare: _prepareCampusCardDetailContent,
  ),
  _VisualSurface(
    'home.campus-card-detail',
    () => _campusCardDetailPage(CampusCardDetailDisplayState.validationError),
    state: 'validation-error',
    prepare: _prepareCampusCardDetailValidationError,
  ),
];
