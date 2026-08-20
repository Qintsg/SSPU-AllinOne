/*
 * 清源视觉 fixture — 应用壳、协议与锁屏
 * @Project : SSPU-AllinOne
 * @File : qingyuan_visual_fixtures_global.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'qingyuan_visual_capture_test.dart';

/// 构建 _shellNavigation 对应的确定性视觉场景。
///
/// :param initialDestinationIndex: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _shellNavigation({int initialDestinationIndex = 0}) {
  final page = const YhPageScaffold(
    appBar: YhAppBar(title: '清源导航'),
    body: YhEmptyState(
      icon: YhIcons.home,
      title: '校园服务都在这里',
      message: '主目的地随窗口宽度切换为底栏、紧凑导航轨或扩展导航轨。',
    ),
  );
  return AppShell(
    initialDestinationIndex: initialDestinationIndex,
    destinationOverrides: {
      for (final name in const ['主页', '教务', '课表', '信息', '邮箱', '跳转', '设置'])
        name: page,
    },
  );
}

/// 构建 _moreDrawerSurface 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _moreDrawerSurface() => Builder(
  builder: (context) {
    final shell = _shellNavigation(initialDestinationIndex: 4);
    final media = MediaQuery.of(context);
    final usesCompactNavigation =
        media.size.width < context.yhTheme.breakpoint.medium;
    if (!usesCompactNavigation) {
      return shell;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        shell,
        ColoredBox(color: context.yhTheme.color.scrim),
        Align(
          alignment: Alignment.bottomCenter,
          child: YhBottomDrawer(
            title: '更多',
            child: AppMoreDestinationsContent(
              items: [
                AppMoreDestination(
                  label: '邮箱',
                  icon: YhIcons.mail,
                  selected: true,
                  onSelected: () {},
                ),
                AppMoreDestination(
                  label: '跳转',
                  icon: YhIcons.link,
                  onSelected: () {},
                ),
                AppMoreDestination(
                  label: '设置',
                  icon: YhIcons.settings,
                  onSelected: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  },
);

/// 构建 _closeConfirmationSurface 对应的确定性视觉场景。
///
/// :param displayState: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _closeConfirmationSurface([
  AppCloseConfirmationDisplayState displayState =
      AppCloseConfirmationDisplayState.content,
]) => _modalSurface(
  background: _shellNavigation(),
  modal: AppCloseConfirmationDialog(
    onCancel: () {},
    onMinimize: (_) async {},
    onExit: (_) async {},
    initialDisplayState: displayState,
  ),
);

/// 构建 _consentInitial 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _consentInitial() => _modalSurface(
  background: const AppStartupStatus(progressLabel: '正在准备法律与隐私说明'),
  modal: LegalConsentDialog(
    onAccept: () {},
    onDecline: () {},
    loadLegalNotice: (_) => Completer<String>().future,
  ),
);

/// 构建 _consentContent 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _consentContent() => _modalSurface(
  background: const AppStartupStatus(progressLabel: '正在准备法律与隐私说明'),
  modal: LegalConsentDialog(
    onAccept: () {},
    onDecline: () {},
    loadLegalNotice: (_) async => _visualLegalNotice,
  ),
);

/// 构建 _consentError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _consentError() => _modalSurface(
  background: const AppStartupStatus(progressLabel: '正在准备法律与隐私说明'),
  modal: LegalConsentDialog(
    onAccept: () {},
    onDecline: () {},
    loadLegalNotice: (_) =>
        Future<String>.error(StateError('visual legal notice unavailable')),
  ),
);

/// 构建 _consentOperationLocked 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _consentOperationLocked() =>
    _consentWithAction(() => Completer<void>().future);

/// 构建 _consentPersistenceError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _consentPersistenceError() => _consentWithAction(
  () => Future<void>.error(StateError('visual storage unavailable')),
);

/// 构建 _consentWithAction 对应的确定性视觉场景。
///
/// :param onAccept: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _consentWithAction(LegalConsentAction onAccept) => _modalSurface(
  background: const AppStartupStatus(progressLabel: '正在准备法律与隐私说明'),
  modal: LegalConsentDialog(
    onAccept: onAccept,
    onDecline: () {},
    loadLegalNotice: (_) async => _visualLegalNotice,
  ),
);

/// 准备 _prepareConsentAccept 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareConsentAccept(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('legal-consent-accept')));
  await tester.pump();
  await tester.pump();
}

/// 构建 _modalSurface 对应的确定性视觉场景。
///
/// :param modal: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _modalSurface({required Widget background, required Widget modal}) =>
    Builder(
      builder: (context) => Stack(
        fit: StackFit.expand,
        children: [
          background,
          ColoredBox(color: context.yhTheme.color.scrim),
          modal,
        ],
      ),
    );

const String _visualLegalNotice = '''
工大聚合法律与隐私说明

一、独立工具，不代表学校官方

二、仅供本人校园学习与生活使用

三、凭据与缓存只保存在本机

四、第三方能力遵循各自许可
''';

/// 构建 _lockInitial 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _lockInitial() => LockPage(
  onUnlocked: () {},
  authentication: _VisualLockAuthentication(
    verification: Future<bool>.value(false),
  ),
);

/// 构建 _lockLoading 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _lockLoading() => LockPage(
  onUnlocked: () {},
  authentication: _VisualLockAuthentication(
    verification: Completer<bool>().future,
  ),
);

/// 构建 _lockError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _lockError() => LockPage(
  onUnlocked: () {},
  authentication: _VisualLockAuthentication(
    verification: Future<bool>.value(false),
  ),
);

/// 准备 _prepareLockLoading 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareLockLoading(WidgetTester tester) async {
  await tester.enterText(find.byType(YhTextField), 'visual-password');
  await tester.tap(find.text('解锁'));
  await tester.pump();
  if (find.text('正在验证…').evaluate().isEmpty) {
    throw StateError('锁屏未进入 loading 状态');
  }
}

/// 准备 _prepareLockError 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareLockError(WidgetTester tester) async {
  await tester.enterText(find.byType(YhTextField), 'wrong-password');
  await tester.tap(find.text('解锁'));
  await tester.pump();
  await tester.pump();
  if (find.text('密码错误，请重试').evaluate().isEmpty) {
    throw StateError('锁屏未进入 error 状态');
  }
}

class _VisualLockAuthentication implements LockAuthenticationAdapter {
  /// 创建使用确定性验证结果的锁屏认证适配器。
  ///
  /// :param verification: 密码验证结果。
  const _VisualLockAuthentication({required this.verification});

  final Future<bool> verification;

  /// 准备 verifyPassword 对应的确定性视觉状态。
  ///
  /// :param password: 当前视觉场景输入。
  /// :returns: 对应的确定性测试值。
  @override
  Future<bool> verifyPassword(String password) => verification;

  /// 准备 isQuickAuthEnabled 对应的确定性视觉状态。
  ///
  /// :returns: 对应的确定性测试值。
  @override
  Future<bool> isQuickAuthEnabled() async => false;

  /// 准备 isSystemAuthAvailable 对应的确定性视觉状态。
  ///
  /// :returns: 对应的确定性测试值。
  @override
  Future<bool> isSystemAuthAvailable() async => false;

  /// 准备 authenticate 对应的确定性视觉状态。
  ///
  /// :param localizedReason: 当前视觉场景输入。
  /// :returns: 对应的确定性测试值。
  @override
  Future<SystemAuthResult> authenticate(String localizedReason) async =>
      SystemAuthResult.unavailable;
}

enum _AcademicOverviewScenario {
  initial,
  loading,
  content,
  empty,
  stale,
  error,
  partialError,
  credentialsRequired,
  credentialsPartial,
  operationLocked,
}
