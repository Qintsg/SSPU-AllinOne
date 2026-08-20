/*
 * 清源视觉 fixture — 主页、课表、资讯、邮箱与快捷入口
 * @Project : SSPU-AllinOne
 * @File : qingyuan_visual_fixtures_content.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'qingyuan_visual_capture_test.dart';

const _qingyuanHomeQuickLinks = <QuickLinkItemConfig>[
  QuickLinkItemConfig(
    name: '统一身份认证',
    url: 'https://oa.example.invalid/',
    icon: 'security',
  ),
  QuickLinkItemConfig(
    name: '图书馆',
    url: 'https://library.example.invalid/',
    icon: 'library',
  ),
  QuickLinkItemConfig(
    name: '学校官网',
    url: 'https://www.example.invalid/',
    icon: 'globe',
  ),
];

/// 构建 _homeDashboardPage 对应的确定性视觉场景。
///
/// :param state: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _homeDashboardPage(HomeDashboardDisplayState state) =>
    _homeCampusCardPage(
      HomeCampusCardDisplayState.content,
      dashboardState: state,
    );

/// 构建 _homeCampusCardPage 对应的确定性视觉场景。
///
/// :param state: 当前视觉场景输入。
/// :param dashboardState: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _homeCampusCardPage(
  HomeCampusCardDisplayState state, {
  HomeDashboardDisplayState dashboardState = HomeDashboardDisplayState.content,
}) {
  final result = switch (state) {
    HomeCampusCardDisplayState.empty => qingyuanCampusCardEmptyResult,
    HomeCampusCardDisplayState.stale => qingyuanCampusCardStaleResult,
    HomeCampusCardDisplayState.error => qingyuanCampusCardErrorResult,
    HomeCampusCardDisplayState.loading ||
    HomeCampusCardDisplayState.content ||
    HomeCampusCardDisplayState.operationLocked =>
      qingyuanCampusCardContentResult,
  };
  return HomePage(
    campusCardService: QingyuanVisualCampusCardClient(result: result),
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: qingyuanHomeAcademicResult,
      cachedResult: qingyuanHomeAcademicResult,
      cachedOverviewResult: qingyuanHomeAcademicResult,
    ),
    sportsAttendanceService: QingyuanVisualSportsAttendanceClient(
      qingyuanHomeSportsResult,
    ),
    studentReportService: QingyuanVisualStudentReportClient(
      qingyuanHomeStudentReportResult,
    ),
    emailService: QingyuanVisualEmailClient(
      cachedResult: qingyuanHomeEmailResult,
    ),
    campusNetworkStatusService: _visualCampusNetworkStatusService(),
    campusCardAutoRefreshEnabledOverride: false,
    campusCardResultOverride: result,
    campusCardDisplayStateOverride: state,
    nowOverride: qingyuanVisualNow,
    messagesOverride: qingyuanHomeMessages,
    homeUpdatedAtOverride: DateTime(2026, 7, 18, 8, 42),
    homeCountdownMinutesOverride: 42,
    homeCourseTimeOverrides: const {'数据结构': '10:00'},
    dashboardDisplayStateOverride: dashboardState,
    courseTableResultOverride: qingyuanHomeAcademicResult,
    academicOverviewResultOverride: qingyuanHomeAcademicResult,
    sportsAttendanceResultOverride: qingyuanHomeSportsResult,
    emailResultOverride: qingyuanHomeEmailResult,
    studentReportResultOverride: qingyuanHomeStudentReportResult,
    quickLinkFavoritesOverride: _qingyuanHomeQuickLinks,
  );
}

CampusNetworkStatusService _visualCampusNetworkStatusService() {
  return CampusNetworkStatusService(
    probe: (uri, timeout) async => CampusNetworkProbeResult(
      reachable: uri != CampusNetworkStatusService.defaultVpnProbeUri,
      statusCode: 200,
      detail: '视觉 fixture 已连接 ${uri.host}',
    ),
  );
}

/// 准备 _prepareHomeCampusCard 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareHomeCampusCard(WidgetTester tester) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find
        .byKey(const Key('home-campus-card-balance-card'))
        .evaluate()
        .isNotEmpty) {
      break;
    }
  }
  if (find
      .byKey(const Key('home-campus-card-balance-card'))
      .evaluate()
      .isEmpty) {
    throw StateError('校园卡 fixture 未在固定等待窗口内完成加载');
  }
  await _centerInScrollable(
    tester,
    find.byKey(const Key('home-campus-card-balance-card')),
    alignment:
        MediaQuery.sizeOf(
              tester.element(
                find.byKey(const Key('home-campus-card-balance-card')),
              ),
            ).width <
            768
        ? 0.557
        : MediaQuery.sizeOf(
                tester.element(
                  find.byKey(const Key('home-campus-card-balance-card')),
                ),
              ).width <
              900
        ? 0.5
        : 0.5,
  );
  await tester.pump();
}

/// 准备 _prepareHomeDashboard 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareHomeDashboard(WidgetTester tester) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text('高等数学').evaluate().isNotEmpty) return;
  }
  throw StateError('首页确定性 fixture 未在预期时间内完成加载');
}

/// 构建 _campusCardDetailPage 对应的确定性视觉场景。
///
/// :param state: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _campusCardDetailPage(CampusCardDetailDisplayState state) {
  final snapshot = state == CampusCardDetailDisplayState.empty
      ? qingyuanCampusCardContentResult.snapshot!.copyWith(records: const [])
      : qingyuanCampusCardContentResult.snapshot!;
  return CampusCardDetailPage(
    initialSnapshot: snapshot,
    campusCardService: QingyuanVisualCampusCardClient(
      result: qingyuanCampusCardContentResult,
    ),
    nowOverride: qingyuanVisualNow,
    displayStateOverride: state,
  );
}

/// 准备 _prepareCampusCardDetailContent 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareCampusCardDetailContent(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('campus-card-recent-seven-days')));
  await tester.pump();
}

/// 准备 _prepareCampusCardDetailEmpty 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareCampusCardDetailEmpty(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('campus-card-recent-seven-days')));
  await tester.pump();
  final target = find.byKey(const Key('campus-card-empty-panel'));
  final width = MediaQuery.sizeOf(tester.element(target)).width;
  await _centerInScrollable(tester, target);
  final correction = width < 768
      ? 16.0
      : width < 1000
      ? 16.0
      : width < 1400
      ? 16.0
      : 0.0;
  if (correction > 0) {
    await tester.drag(
      find.ancestor(of: target, matching: find.byType(SingleChildScrollView)),
      Offset(0, correction),
    );
    await tester.pump();
  }
}

/// 准备 _prepareCampusCardDetailError 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareCampusCardDetailError(WidgetTester tester) async {
  await _centerInScrollable(
    tester,
    find.byKey(const Key('campus-card-terminal-error')),
  );
}

/// 准备 _prepareCampusCardDetailValidationError 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareCampusCardDetailValidationError(
  WidgetTester tester,
) async {
  await tester.enterText(
    find.byKey(const Key('campus-card-start-date')),
    '2026-07-19',
  );
  await tester.enterText(
    find.byKey(const Key('campus-card-end-date')),
    '2026-07-18',
  );
  await tester.tap(find.byKey(const Key('campus-card-apply-filter')));
  await tester.pump();
  await _revealAtViewportEnd(
    tester,
    find.byKey(const Key('campus-card-validation-banner')),
  );
}

/// 准备 _revealAtViewportEnd 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :param finder: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _revealAtViewportEnd(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 1,
    alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    duration: Duration.zero,
  );
}

/// 构建 _infoPage 对应的确定性视觉场景。
///
/// :param state: 当前视觉场景输入。
/// :param withMessages: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _infoPage(
  InfoPageDisplayState state, {
  bool withMessages = false,
  bool filterEmpty = false,
}) => InfoPage(
  displayStateOverride: state,
  messagesOverride: withMessages ? qingyuanInfoMessages : const [],
  wechatSourceConfiguredOverride: true,
  nowOverride: qingyuanVisualNow,
  messageRenderLimitOverride: 3,
  filterEmptyOverride: filterEmpty,
);

/// 构建 _schedulePage 对应的确定性视觉场景。
///
/// :param initialResult: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _schedulePage({
  required QingyuanVisualAcademicEamsClient service,
  AcademicEamsQueryResult? initialResult,
}) {
  return CourseSchedulePage(
    academicEamsService: service,
    initialResult: initialResult,
    autoRefreshEnabledOverride: false,
    nowOverride: qingyuanVisualNow,
    termLabelOverride: '2025-2026 第2学期',
  );
}

/// 构建 _scheduleInitial 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _scheduleInitial() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleContentResult,
  ),
);

/// 构建 _scheduleLoading 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _scheduleLoading() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleContentResult,
    pendingCourseTable: Completer<AcademicEamsQueryResult>(),
  ),
);

/// 准备 _startScheduleLoading 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _startScheduleLoading(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('course-schedule-refresh')));
}

/// 构建 _scheduleContent 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _scheduleContent() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleContentResult,
  ),
  initialResult: qingyuanScheduleContentResult,
);

/// 构建 _scheduleEmpty 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _scheduleEmpty() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleEmptyResult,
  ),
  initialResult: qingyuanScheduleEmptyResult,
);

/// 构建 _scheduleStale 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _scheduleStale() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleStaleResult,
  ),
  initialResult: qingyuanScheduleStaleResult,
);

/// 构建 _scheduleError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _scheduleError() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleErrorResult,
  ),
  initialResult: qingyuanScheduleErrorResult,
);

/// 构建 _scheduleOperationLocked 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _scheduleOperationLocked() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleContentResult,
    pendingCourseTable: Completer<AcademicEamsQueryResult>(),
  ),
  initialResult: qingyuanScheduleContentResult,
);

/// 构建 _mailPage 对应的确定性视觉场景。
///
/// :param service: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _mailPage(QingyuanVisualEmailClient service) {
  return EmailPage(
    emailService: service,
    emailAutoRefreshEnabledOverride: false,
    emailAutoRefreshIntervalOverride: 30,
    nowOverride: qingyuanVisualNow,
  );
}

/// 构建 _mailInitial 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _mailInitial() => _mailPage(QingyuanVisualEmailClient());

/// 构建 _mailLoading 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _mailLoading() => _mailPage(
  QingyuanVisualEmailClient(pendingFetch: Completer<EmailMailboxQueryResult>()),
);

/// 准备 _startMailLoading 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _startMailLoading(WidgetTester tester) async {
  await tester.tap(find.text('读取最近邮件').first);
}

/// 构建 _mailContent 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _mailContent() => _mailPage(
  QingyuanVisualEmailClient(cachedResult: qingyuanEmailContentResult),
);

/// 构建 _mailEmpty 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _mailEmpty() => _mailPage(
  QingyuanVisualEmailClient(cachedResult: qingyuanEmailEmptyResult),
);

/// 构建 _mailStale 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _mailStale() => _mailPage(
  QingyuanVisualEmailClient(cachedResult: qingyuanEmailStaleResult),
);

/// 构建 _mailError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _mailError() => _mailPage(
  QingyuanVisualEmailClient(cachedResult: qingyuanEmailErrorResult),
);

/// 准备 _openMailCompose 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _openMailCompose(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('email-compose-open')));
  await tester.pump();
}

/// 准备 _prepareMailComposeContent 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareMailComposeContent(WidgetTester tester) async {
  await _openMailCompose(tester);
  await _fillMailCompose(tester);
}

/// 准备 _fillMailCompose 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _fillMailCompose(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(YhTextField, '收件人'),
    'advisor@example.invalid',
  );
  await tester.enterText(find.widgetWithText(YhTextField, '主题'), '课程安排确认');
  await tester.enterText(
    find.widgetWithText(YhTextField, '正文'),
    '老师您好，我已核对本学期课程安排，谢谢。',
  );
}

/// 构建 _mailComposeLoading 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _mailComposeLoading() => _mailPage(
  QingyuanVisualEmailClient(
    cachedResult: qingyuanEmailContentResult,
    pendingSend: Completer<EmailSendResult>(),
  ),
);

/// 构建 _mailComposeError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _mailComposeError() => _mailPage(
  QingyuanVisualEmailClient(
    cachedResult: qingyuanEmailContentResult,
    sendResult: qingyuanEmailSendErrorResult,
  ),
);

/// 准备 _prepareMailComposeSending 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareMailComposeSending(WidgetTester tester) async {
  await _openMailCompose(tester);
  await _fillMailCompose(tester);
  final sendButton = tester.widget<YhButton>(
    find.widgetWithText(YhButton, '发送邮件'),
  );
  sendButton.onTap?.call();
}

/// 准备 _prepareMailComposeLoading 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareMailComposeLoading(WidgetTester tester) async {
  await _prepareMailComposeSending(tester);
  await tester.pump();
}

/// 准备 _prepareMailComposeError 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareMailComposeError(WidgetTester tester) async {
  await _prepareMailComposeSending(tester);
  await tester.pump();
  await tester.pump();
}

/// 准备 _centerInScrollable 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :param finder: 当前视觉场景输入。
/// :param alignment: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _centerInScrollable(
  WidgetTester tester,
  Finder finder, {
  double alignment = 0.5,
}) async {
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: alignment,
    duration: Duration.zero,
  );
}

/// 准备 _clearMailFeedback 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _clearMailFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
}

const _quickLinkGroups = <QuickLinkGroupConfig>[
  QuickLinkGroupConfig(
    category: '学习与教务',
    items: [
      QuickLinkItemConfig(
        name: '教务系统',
        url: 'https://academic.example.invalid',
        icon: 'education',
      ),
      QuickLinkItemConfig(
        name: '超星学习通',
        url: 'https://learning.example.invalid',
        icon: 'education',
      ),
    ],
  ),
  QuickLinkGroupConfig(
    category: '校园服务',
    items: [
      QuickLinkItemConfig(
        name: '图书馆',
        url: 'https://library.example.invalid',
        icon: 'library',
      ),
      QuickLinkItemConfig(
        name: '校园卡服务',
        url: 'https://card.example.invalid',
        icon: 'finance',
      ),
    ],
  ),
  QuickLinkGroupConfig(
    category: '学校信息',
    items: [
      QuickLinkItemConfig(
        name: '学校官网',
        url: 'https://www.example.invalid',
        icon: 'globe',
      ),
      QuickLinkItemConfig(
        name: '统一身份认证',
        url: 'https://sso.example.invalid',
        icon: 'security',
      ),
    ],
  ),
];

/// 构建 _quickLinksContent 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _quickLinksContent() => QuickLinksPage(
  groupsLoader: () async => _quickLinkGroups,
  onOpenUrl: (_) async {},
);

/// 构建 _quickLinksLoading 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _quickLinksLoading() {
  final pending = Completer<List<QuickLinkGroupConfig>>();
  return QuickLinksPage(groupsLoader: () => pending.future);
}

/// 构建 _quickLinksEmpty 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _quickLinksEmpty() => QuickLinksPage(groupsLoader: () async => const []);

/// 构建 _quickLinksError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _quickLinksError() => QuickLinksPage(
  groupsLoader: () => Future.error(StateError('fixture load failed')),
);

/// 构建 _externalLinkConfirmationContent 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _externalLinkConfirmationContent() => ExternalLinkConfirmationPage(
  displayName: '统一身份认证',
  uri: Uri.parse('https://auth.example.invalid/login'),
  authenticationRequired: true,
  authenticationReady: true,
);

/// 构建 _externalLinkConfirmationError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _externalLinkConfirmationError() => ExternalLinkConfirmationPage(
  displayName: '统一身份认证',
  uri: Uri.parse('https://auth.example.invalid/login'),
  authenticationRequired: true,
  authenticationReady: false,
);
