/*
 * 清源视觉 surface 清单 — 课表、资讯、邮箱与快捷入口
 * @Project : SSPU-AllinOne
 * @File : qingyuan_visual_surfaces_content.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'qingyuan_visual_capture_test.dart';

final _contentSurfaces = <_VisualSurface>[
  _VisualSurface(
    'schedule.calendar',
    _scheduleInitial,
    state: 'initial',
    destination: '课表',
  ),
  _VisualSurface(
    'schedule.calendar',
    _scheduleLoading,
    state: 'loading',
    prepare: _startScheduleLoading,
    destination: '课表',
  ),
  _VisualSurface('schedule.calendar', _scheduleContent, destination: '课表'),
  _VisualSurface(
    'schedule.calendar',
    _scheduleEmpty,
    state: 'empty',
    destination: '课表',
  ),
  _VisualSurface(
    'schedule.calendar',
    _scheduleStale,
    state: 'stale',
    destination: '课表',
  ),
  _VisualSurface(
    'schedule.calendar',
    _scheduleError,
    state: 'error',
    destination: '课表',
  ),
  _VisualSurface(
    'schedule.calendar',
    _scheduleOperationLocked,
    state: 'operation-locked',
    prepare: _startScheduleLoading,
    destination: '课表',
  ),
  _VisualSurface(
    'info.feed',
    () => _infoPage(InfoPageDisplayState.initial),
    state: 'initial',
    destination: '信息',
  ),
  _VisualSurface(
    'info.feed',
    () => _infoPage(InfoPageDisplayState.loading),
    state: 'loading',
    destination: '信息',
  ),
  _VisualSurface(
    'info.feed',
    () => _infoPage(InfoPageDisplayState.content, withMessages: true),
    destination: '信息',
  ),
  _VisualSurface(
    'info.feed',
    () => _infoPage(InfoPageDisplayState.empty),
    state: 'empty',
    destination: '信息',
  ),
  _VisualSurface(
    'info.feed',
    () => _infoPage(InfoPageDisplayState.stale, withMessages: true),
    state: 'stale',
    destination: '信息',
  ),
  _VisualSurface(
    'info.feed',
    () => _infoPage(InfoPageDisplayState.error),
    state: 'error',
    destination: '信息',
  ),
  _VisualSurface(
    'info.filters',
    () => _infoPage(InfoPageDisplayState.content, withMessages: true),
    destination: '信息',
  ),
  _VisualSurface(
    'info.filters',
    () => _infoPage(
      InfoPageDisplayState.content,
      withMessages: true,
      filterEmpty: true,
    ),
    state: 'empty',
    destination: '信息',
  ),
  _VisualSurface(
    'mail.inbox',
    _mailInitial,
    state: 'initial',
    destination: '邮箱',
  ),
  _VisualSurface(
    'mail.inbox',
    _mailLoading,
    state: 'loading',
    prepare: _startMailLoading,
    destination: '邮箱',
  ),
  _VisualSurface('mail.inbox', _mailContent, destination: '邮箱'),
  _VisualSurface('mail.inbox', _mailEmpty, state: 'empty', destination: '邮箱'),
  _VisualSurface('mail.inbox', _mailStale, state: 'stale', destination: '邮箱'),
  _VisualSurface('mail.inbox', _mailError, state: 'error', destination: '邮箱'),
  _VisualSurface(
    'mail.message-detail',
    () => EmailMessageDetailPage(
      message: qingyuanEmailMessages.first,
      nowOverride: qingyuanVisualNow,
    ),
  ),
  _VisualSurface(
    'mail.compose',
    _mailContent,
    state: 'initial',
    prepare: _openMailCompose,
    destination: '邮箱',
  ),
  _VisualSurface(
    'mail.compose',
    _mailContent,
    prepare: _prepareMailComposeContent,
    destination: '邮箱',
  ),
  _VisualSurface(
    'mail.compose',
    _mailComposeLoading,
    state: 'loading',
    prepare: _prepareMailComposeLoading,
    destination: '邮箱',
  ),
  _VisualSurface(
    'mail.compose',
    _mailComposeError,
    state: 'error',
    prepare: _prepareMailComposeError,
    cleanup: _clearMailFeedback,
    destination: '邮箱',
  ),
  _VisualSurface('links.directory', _quickLinksContent, destination: '跳转'),
  _VisualSurface(
    'links.directory',
    _quickLinksLoading,
    state: 'loading',
    destination: '跳转',
  ),
  _VisualSurface(
    'links.directory',
    _quickLinksEmpty,
    state: 'empty',
    destination: '跳转',
  ),
  _VisualSurface(
    'links.directory',
    _quickLinksError,
    state: 'error',
    destination: '跳转',
  ),
  _VisualSurface(
    'links.external-confirmation',
    _externalLinkConfirmationContent,
  ),
  _VisualSurface(
    'links.external-confirmation',
    _externalLinkConfirmationError,
    state: 'error',
  ),
  _VisualSurface('legal.notice', _legalNoticeSurface),
  _VisualSurface('legal.notice', _legalNoticeLoadingSurface, state: 'loading'),
  _VisualSurface('legal.notice', _legalNoticeErrorSurface, state: 'error'),
  _VisualSurface('legal.agreement', _legalAgreementSurface),
  _VisualSurface(
    'legal.agreement',
    _legalAgreementLoadingSurface,
    state: 'loading',
  ),
  _VisualSurface(
    'legal.agreement',
    _legalAgreementErrorSurface,
    state: 'error',
  ),
  _VisualSurface('legal.privacy', _legalPrivacySurface),
  _VisualSurface(
    'legal.privacy',
    _legalPrivacyLoadingSurface,
    state: 'loading',
  ),
  _VisualSurface('legal.privacy', _legalPrivacyErrorSurface, state: 'error'),
];
