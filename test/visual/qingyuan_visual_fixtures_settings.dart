/*
 * 清源视觉 fixture — 设置、认证配置与更新
 * @Project : SSPU-AllinOne
 * @File : qingyuan_visual_fixtures_settings.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'qingyuan_visual_capture_test.dart';

const Key _wechatLoginExternalRegionKey = Key('visual-wechat-login-document');

/// 构建 AI 服务 MCP 管理页的确定性视觉场景。
Widget _aiServicesOverview() => const AiServicesPage();

/// 构建 _settingsAppearance 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _settingsAppearance() => _stateReferenceShell(
  SettingsAppearancePage(
    themeMode: YhThemeMode.system,
    onChanged: (_) {},
    onApply: () {},
  ),
);

/// 构建 _stateReferenceShell 对应的确定性视觉场景。
///
/// :param page: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _stateReferenceShell(Widget page) => Builder(
  builder: (context) {
    final theme = context.yhTheme;
    final media = MediaQuery.of(context);
    final shellMedia = media.copyWith(
      size: Size(
        math.min(
          media.size.width,
          theme.breakpoint.expanded - theme.layout.divider,
        ),
        media.size.height,
      ),
    );
    return ColoredBox(
      color: theme.color.background,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.l,
          vertical: theme.spacing.l + theme.spacing.m,
        ),
        child: MediaQuery(
          data: shellMedia,
          child: AppShell(
            initialDestinationIndex: _destinationIndex('设置'),
            destinationOverrides: {'设置': page},
          ),
        ),
      ),
    );
  },
);

/// 构建 _legalNoticeSurface 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _legalNoticeSurface() => _legalReferenceSurface(
  title: '法律声明',
  kicker: '法律与许可',
  summary: '正文从应用内确定性资源加载，加载失败仍保留返回和重试。',
  primaryActionLabel: '返回设置',
  sectionTitles: const ['非学校官方应用', '数据来源说明', '责任边界'],
);

/// 构建法律声明加载状态的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _legalNoticeLoadingSurface() => _legalReferenceSurface(
  title: '法律声明',
  kicker: '法律与许可',
  summary: '正文从应用内确定性资源加载，加载失败仍保留返回和重试。',
  primaryActionLabel: '返回设置',
  loadLegalNotice: (_) => Completer<String>().future,
);

/// 构建法律声明读取失败的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _legalNoticeErrorSurface() => _legalReferenceSurface(
  title: '法律声明',
  kicker: '法律与许可',
  summary: '正文从应用内确定性资源加载，加载失败仍保留返回和重试。',
  primaryActionLabel: '返回设置',
  loadLegalNotice: (_) async => throw StateError('法律资源不可用'),
);

/// 构建 _legalPrivacySurface 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _legalPrivacySurface() => _legalReferenceSurface(
  title: '隐私说明',
  kicker: '法律与隐私',
  summary: '按数据类型说明收集目的、存储位置、联网时机和删除方式。',
  primaryActionLabel: '管理本地数据',
  sectionTitles: const ['账户凭据', '校园数据缓存', '诊断信息'],
);

/// 构建隐私说明加载状态的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _legalPrivacyLoadingSurface() => _legalReferenceSurface(
  title: '隐私说明',
  kicker: '法律与隐私',
  summary: '按数据类型说明收集目的、存储位置、联网时机和删除方式。',
  primaryActionLabel: '管理本地数据',
  loadLegalNotice: (_) => Completer<String>().future,
);

/// 构建隐私说明读取失败的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _legalPrivacyErrorSurface() => _legalReferenceSurface(
  title: '隐私说明',
  kicker: '法律与隐私',
  summary: '按数据类型说明收集目的、存储位置、联网时机和删除方式。',
  primaryActionLabel: '管理本地数据',
  loadLegalNotice: (_) async => throw StateError('法律资源不可用'),
);

/// 构建 _legalAgreementSurface 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _legalAgreementSurface() => _legalReferenceSurface(
  title: '用户协议',
  kicker: '法律与协议',
  summary: '说明只读聚合、用户责任和外部服务边界，首次确认后仍可再次阅读。',
  primaryActionLabel: '返回',
  sectionTitles: const ['服务范围', '使用规则', '协议变更'],
);

/// 构建用户协议加载状态的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _legalAgreementLoadingSurface() => _legalReferenceSurface(
  title: '用户协议',
  kicker: '法律与协议',
  summary: '说明只读聚合、用户责任和外部服务边界，首次确认后仍可再次阅读。',
  primaryActionLabel: '返回',
  loadLegalNotice: (_) => Completer<String>().future,
);

/// 构建用户协议读取失败的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _legalAgreementErrorSurface() => _legalReferenceSurface(
  title: '用户协议',
  kicker: '法律与协议',
  summary: '说明只读聚合、用户责任和外部服务边界，首次确认后仍可再次阅读。',
  primaryActionLabel: '返回',
  loadLegalNotice: (_) async => throw StateError('法律资源不可用'),
);

/// 构建 _legalReferenceSurface 对应的确定性视觉场景。
///
/// :param sectionTitles: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _legalReferenceSurface({
  required String title,
  required String kicker,
  required String summary,
  required String primaryActionLabel,
  List<String>? sectionTitles,
  Future<String> Function(Locale? locale)? loadLegalNotice,
}) => Builder(
  builder: (context) {
    final theme = context.yhTheme;
    final media = MediaQuery.of(context);
    final shellMedia = media.copyWith(
      size: Size(
        math.min(
          media.size.width,
          theme.breakpoint.expanded - theme.layout.divider,
        ),
        media.size.height,
      ),
    );
    final page = loadLegalNotice == null
        ? LegalNoticePage(
            title: title,
            kicker: kicker,
            summary: summary,
            source: '随应用发布的文本',
            sourceTimestamp: '2026-07-18 · 09:30',
            primaryActionLabel: primaryActionLabel,
            sections: [
              for (var index = 0; index < sectionTitles!.length; index++)
                LegalNoticeSection(
                  title: sectionTitles[index],
                  body: '${index + 1}. 本节说明该数据与功能的使用边界、保存位置和用户可执行的管理方式。',
                ),
            ],
          )
        : LegalNoticePage(
            title: title,
            kicker: kicker,
            summary: summary,
            source: '随应用发布的文本',
            sourceTimestamp: '2026-07-18 · 09:30',
            primaryActionLabel: primaryActionLabel,
            loadLegalNotice: loadLegalNotice,
          );
    return ColoredBox(
      color: theme.color.background,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.l,
          vertical: theme.spacing.l + theme.spacing.m,
        ),
        child: MediaQuery(
          data: shellMedia,
          child: AppShell(
            initialDestinationIndex: _destinationIndex('设置'),
            destinationOverrides: {'设置': page},
          ),
        ),
      ),
    );
  },
);

/// 构建 _settingsHomeNotifications 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _settingsHomeNotifications() =>
    const SettingsPage(initializedForTesting: true);

/// 准备 _prepareSettingsHomeNotifications 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareSettingsHomeNotifications(WidgetTester tester) async {
  final homeCard = find.byKey(const Key('settings-home-display-card'));
  expect(homeCard, findsOneWidget);
  await tester.pump();
}

/// 构建 _settingsAutoRefresh 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _settingsAutoRefresh() => SettingsPage(
  initializedForTesting: true,
  landingRequest: SettingsLandingRequest(SettingsLandingSection.autoRefresh),
);

/// 构建 _settingsAccountContent 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _settingsAccountContent() => SettingsPage(
  onLock: () {},
  initializedForTesting: true,
  landingRequest: SettingsLandingRequest(SettingsLandingSection.security),
  securityControlsEnabledForTesting: true,
  credentialsStatusLoaderForTesting: () async =>
      const AcademicCredentialsStatus.empty(),
);

/// 构建 _settingsAccountError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _settingsAccountError() => SettingsPage(
  onLock: () {},
  initializedForTesting: true,
  landingRequest: SettingsLandingRequest(SettingsLandingSection.security),
  securityControlsEnabledForTesting: true,
  credentialsStatusLoaderForTesting: () async =>
      throw StateError('视觉夹具：本机安全存储不可用'),
);

/// 构建 _passwordDialogVisualHost 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _passwordDialogVisualHost() => Builder(
  builder: (context) => YhPageScaffold(
    body: Center(
      child: YhButton(
        key: const Key('visual-open-password-dialog'),
        label: '设置本地密码',
        onTap: () => unawaited(showSetPasswordDialog(context)),
      ),
    ),
  ),
);

/// 从真实密码设置入口打开 content 状态。
Future<void> _showPasswordDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('visual-open-password-dialog')));
  await tester.pumpAndSettle();
}

/// 从真实密码设置入口触发不一致校验并保留输入。
Future<void> _showPasswordDialogValidationError(WidgetTester tester) async {
  await _showPasswordDialog(tester);
  await tester.enterText(find.byType(EditableText).at(0), 'qingyuan-demo');
  await tester.enterText(find.byType(EditableText).at(1), 'qingyuan');
  await tester.tap(find.text('设置密码').last);
  await tester.pumpAndSettle();
}

/// 构建 _wechatConfigDialogVisualHost 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _wechatConfigDialogVisualHost() => Builder(
  builder: (context) => YhPageScaffold(
    body: Center(
      child: YhButton(
        key: const Key('visual-open-wechat-config-dialog'),
        label: '编辑认证配置',
        onTap: () => unawaited(
          showSettingsWechatConfigDialog(
            context: context,
            initialConfig: WxmpConfig.defaults(),
          ),
        ),
      ),
    ),
  ),
);

/// 从真实公众号配置入口打开 content 状态。
Future<void> _showWechatConfigDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('visual-open-wechat-config-dialog')));
  await tester.pumpAndSettle();
}

/// 从真实公众号配置入口触发数值范围校验并保留字段。
Future<void> _showWechatConfigValidationError(WidgetTester tester) async {
  await _showWechatConfigDialog(tester);
  await tester.enterText(find.byType(EditableText).at(4), '0');
  await tester.tap(find.text('保存配置'));
  await tester.pumpAndSettle();
}

/// 构建 _settingsDataPrivacy 对应的确定性视觉场景。
///
/// :param state: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _settingsDataPrivacy(SettingsDataPrivacyState state) =>
    _stateReferenceShell(
      SettingsDataPrivacyPage(
        state: state,
        sourceTimestamp: '2026-07-18 · 09:30',
        onClearCampusCache: () async => true,
        onDisconnectAccounts: () async => true,
        onOpenPrivacy: () {},
      ),
    );

/// 构建可从生产入口打开指定数据危险确认的视觉宿主。
///
/// :param kind: 需要展示的确认任务。
/// :returns: 带确定性打开按钮的设置任务页。
Widget _dataPrivacyConfirmationVisualHost(
  SettingsDataPrivacyConfirmationKind kind,
) => Builder(
  builder: (context) => YhPageScaffold(
    body: Center(
      child: YhButton(
        key: const Key('visual-open-data-privacy-confirmation'),
        label: '管理本机数据',
        onTap: () =>
            unawaited(showSettingsDataPrivacyConfirmation(context, kind: kind)),
      ),
    ),
  ),
);

/// 从真实数据危险确认入口打开 content 状态。
///
/// :param tester: 当前视觉 Widget 测试器。
/// :returns: 模态进入稳定帧时结束。
Future<void> _showDataPrivacyConfirmation(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const Key('visual-open-data-privacy-confirmation')),
  );
  await tester.pumpAndSettle();
}

/// 构建 _settingsWechatAuth 对应的确定性视觉场景。
///
/// :param state: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _settingsWechatAuth(SettingsWechatAuthDisplayState state) =>
    _stateReferenceShell(
      SettingsWechatAuthPage(
        previewState: state,
        sourceTimestamp: '2026-07-18 · 09:30',
        previewStatusMessage: switch (state) {
          SettingsWechatAuthDisplayState.initial => '尚未连接公众号平台账号。',
          SettingsWechatAuthDisplayState.loading =>
            '正在从微信公众号连接恢复数据；已有页面框架与输入保持可用。',
          SettingsWechatAuthDisplayState.content => '认证有效，可获取已关注公众号推文。',
          SettingsWechatAuthDisplayState.error =>
            '无法从微信公众号连接完成本次操作；生成登录二维码仍保持原有状态，可检查条件后重试。',
        },
      ),
    );

/// 构建 _wechatLogin 对应的生产扫码登录视觉场景。
///
/// :param state: 需要展示的确定性登录状态。
/// :returns: 使用生产 WxmpLoginPage 结构的视觉页面。
Widget _wechatLogin(WxmpLoginPreviewState state) =>
    WxmpLoginPage(previewState: state, launchUrlOverride: (_) async => false);

/// 打开生产扫码登录页的系统浏览器确认模态。
///
/// :param tester: 当前视觉 Widget 测试器。
/// :returns: 模态稳定后结束。
Future<void> _showWechatLoginExternalConfirmation(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('在系统浏览器打开微信登录页'));
  await tester.pumpAndSettle();
}

/// 将登录预览枚举转换为视觉清单使用的 kebab-case 状态名。
///
/// :param state: 生产页面预览状态。
/// :returns: 清单与文件名使用的状态标识。
String _wechatLoginStateName(WxmpLoginPreviewState state) => switch (state) {
  WxmpLoginPreviewState.loading => 'loading',
  WxmpLoginPreviewState.initial => 'initial',
  WxmpLoginPreviewState.content => 'content',
  WxmpLoginPreviewState.error => 'error',
  WxmpLoginPreviewState.partialError => 'partial-error',
  WxmpLoginPreviewState.operationLocked => 'operation-locked',
  WxmpLoginPreviewState.externalConfirmation => 'external-confirmation',
  WxmpLoginPreviewState.externalError => 'external-error',
};

/// 构建 _settingsAbout 对应的确定性视觉场景。
///
/// :param state: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _settingsAbout(SettingsAboutState state) => _stateReferenceShell(
  SettingsAboutPage(
    previewState: state,
    sourceTimestamp: '2026-07-18 · 09:30',
    previewSnapshot: const SettingsAboutSnapshot(version: '1.0.0'),
  ),
);

Completer<bool>? _aboutExternalOpen;
Completer<bool>? _licenseExternalOpen;

/// 构建 _interactiveSettingsAbout 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _interactiveSettingsAbout() =>
    _settingsAboutWithLauncher((_) async => true);

/// 构建 _failingSettingsAbout 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _failingSettingsAbout() =>
    _settingsAboutWithLauncher((_) async => false);

/// 构建 _pendingSettingsAbout 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _pendingSettingsAbout() {
  _aboutExternalOpen = Completer<bool>();
  return _settingsAboutWithLauncher((_) => _aboutExternalOpen!.future);
}

/// 构建 _settingsAboutWithLauncher 对应的确定性视觉场景。
///
/// :param launcher: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _settingsAboutWithLauncher(Future<bool> Function(Uri) launcher) =>
    _stateReferenceShell(
      SettingsAboutPage(
        loader: () async => const SettingsAboutSnapshot(version: '1.0.0'),
        sourceTimestamp: '2026-07-18 · 09:30',
        launchUrlOverride: launcher,
      ),
    );

/// 准备 _showAboutExternalConfirmation 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _showAboutExternalConfirmation(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('更多操作'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('打开 GitHub 仓库'));
  await tester.pumpAndSettle();
}

/// 准备 _cancelAboutExternalConfirmation 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _cancelAboutExternalConfirmation(WidgetTester tester) async {
  await _showAboutExternalConfirmation(tester);
  await tester.tap(find.text('取消'));
  await tester.pumpAndSettle();
}

/// 准备 _confirmAboutExternalOpen 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _confirmAboutExternalOpen(WidgetTester tester) async {
  await _showAboutExternalConfirmation(tester);
  await tester.tap(find.text('继续打开'));
  await tester.pumpAndSettle();
}

/// 准备 _completeAboutExternalOpen 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _completeAboutExternalOpen(WidgetTester tester) async {
  final pending = _aboutExternalOpen;
  if (pending != null && !pending.isCompleted) pending.complete(true);
  await tester.pumpAndSettle();
}

/// 构建 _interactiveSettingsLicenses 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _interactiveSettingsLicenses() =>
    _settingsLicensesWithLauncher((_) async => true);

/// 构建 _failingSettingsLicenses 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _failingSettingsLicenses() =>
    _settingsLicensesWithLauncher((_) async => false);

/// 构建 _pendingSettingsLicenses 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _pendingSettingsLicenses() {
  _licenseExternalOpen = Completer<bool>();
  return _settingsLicensesWithLauncher((_) => _licenseExternalOpen!.future);
}

/// 构建 _settingsLicensesWithLauncher 对应的确定性视觉场景。
///
/// :param launcher: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _settingsLicensesWithLauncher(Future<bool> Function(Uri) launcher) =>
    _stateReferenceShell(OpenSourceLicensesPage(launchUrlOverride: launcher));

/// 准备 _showLicenseExternalConfirmation 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _showLicenseExternalConfirmation(WidgetTester tester) async {
  final target = find.bySemanticsLabel('打开 Flutter');
  final detector = tester.widget<FocusableActionDetector>(
    find.descendant(of: target, matching: find.byType(FocusableActionDetector)),
  );
  detector.focusNode?.requestFocus();
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

/// 准备 _cancelLicenseExternalConfirmation 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _cancelLicenseExternalConfirmation(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('打开 Flutter'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('取消'));
  await tester.pumpAndSettle();
}

/// 准备 _confirmLicenseExternalOpen 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _confirmLicenseExternalOpen(WidgetTester tester) async {
  await _showLicenseExternalConfirmation(tester);
  await tester.tap(find.text('继续打开'));
  await tester.pumpAndSettle();
}

/// 准备 _completeLicenseExternalOpen 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _completeLicenseExternalOpen(WidgetTester tester) async {
  final pending = _licenseExternalOpen;
  if (pending != null && !pending.isCompleted) pending.complete(true);
  await tester.pumpAndSettle();
}

/// 准备 _dismissTransientFeedback 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _dismissTransientFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
}

/// 构建 _settingsUpdateInitial 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _settingsUpdateInitial() => _settingsUpdateSurface(
  _VisualUpdateService(() async => _visualUpdateResult),
);

/// 构建 _settingsUpdateLoading 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _settingsUpdateLoading() => _settingsUpdateSurface(
  _VisualUpdateService(() => Completer<AppUpdateCheckResult>().future),
);

/// 构建 _settingsUpdateContent 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _settingsUpdateContent() => _settingsUpdateSurface(
  _VisualUpdateService(() async => _visualUpdateResult),
);

/// 构建 _settingsUpdateError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _settingsUpdateError() => _settingsUpdateSurface(
  _VisualUpdateService(
    () => Future.error(
      DioException(
        requestOptions: RequestOptions(path: '/releases'),
        type: DioExceptionType.connectionError,
        error: 'network unavailable',
      ),
    ),
  ),
);

/// 构建 _settingsUpdateSurface 对应的确定性视觉场景。
///
/// :param service: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _settingsUpdateSurface(AppUpdateService service) => _stateReferenceShell(
  SettingsUpdatePage(
    updateService: service,
    launchUrlOverride: (_) async => true,
  ),
);

/// 准备 _startSettingsUpdateCheck 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _startSettingsUpdateCheck(WidgetTester tester) async {
  await tester.tap(find.text('检查更新').last);
  await tester.pump();
  await tester.pump();
}

class _VisualUpdateService extends AppUpdateService {
  /// 创建使用确定性更新结果的视觉服务。
  ///
  /// :param loader: 更新检查结果加载器。
  _VisualUpdateService(this.loader);

  final Future<AppUpdateCheckResult> Function() loader;

  /// 准备 loadCurrentVersion 对应的确定性视觉状态。
  ///
  /// :returns: 对应的确定性测试值。
  @override
  Future<String> loadCurrentVersion() async => '1.0.0';

  /// 准备 checkForUpdates 对应的确定性视觉状态。
  ///
  /// :param channel: 当前视觉场景输入。
  /// :returns: 对应的确定性测试值。
  @override
  Future<AppUpdateCheckResult> checkForUpdates({
    AppUpdateChannel channel = AppUpdateChannel.stable,
  }) => loader();
}

const AppUpdateCheckResult _visualUpdateResult = AppUpdateCheckResult(
  status: AppUpdateStatus.upToDate,
  currentVersion: '1.0.0',
  channel: AppUpdateChannel.stable,
  release: null,
  recommendedAsset: null,
  message: '当前已是正式版最新版本。',
);
