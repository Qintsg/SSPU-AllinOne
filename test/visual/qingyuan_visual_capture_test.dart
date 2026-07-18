/* 清源 Flutter 视觉候选采集 — 四档视口、亮暗主题、六类组件面板。 */

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/app.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/email_mailbox.dart';
import 'package:sspu_allinone/pages/about_page.dart';
import 'package:sspu_allinone/pages/course_schedule_page.dart';
import 'package:sspu_allinone/pages/email_page.dart';
import 'package:sspu_allinone/pages/external_link_confirmation_page.dart';
import 'package:sspu_allinone/pages/legal_notice_page.dart';
import 'package:sspu_allinone/pages/quick_links_page.dart';
import 'package:sspu_allinone/pages/webview_page.dart';
import 'package:sspu_allinone/services/quick_links_config_service.dart';

import '../support/qingyuan_visual_fixtures.dart';

const _captureEnabled = bool.fromEnvironment('QINGYUAN_VISUAL_CAPTURE');
const _platform = String.fromEnvironment(
  'QINGYUAN_VISUAL_PLATFORM',
  defaultValue: 'local',
);

const _viewports = <Size>[
  Size(360, 800),
  Size(768, 900),
  Size(1200, 900),
  Size(1600, 1000),
];

const _fontAssets = <String>[
  'assets/fonts/MiSans-Regular.ttf',
  'assets/fonts/MiSans-Medium.ttf',
  'assets/fonts/MiSans-Semibold.ttf',
  'assets/fonts/MiSans-Bold.ttf',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_captureEnabled) setUpAll(_loadVisualFonts);
  for (final surface in _surfaces) {
    for (final viewport in _viewports) {
      for (final mode in [YhThemeMode.light, YhThemeMode.dark]) {
        final themeName = mode == YhThemeMode.light ? 'light' : 'dark';
        testWidgets('采集 ${surface.id} ${surface.state} $themeName '
            '${viewport.width.toInt()}x${viewport.height.toInt()}', (
          tester,
        ) async {
          debugDefaultTargetPlatformOverride = _targetPlatform;
          try {
            final output = Directory('build/visual/$_platform')
              ..createSync(recursive: true);
            await tester.binding.setSurfaceSize(viewport);
            final themeName = mode == YhThemeMode.light ? 'light' : 'dark';
            final boundaryKey = GlobalKey();
            final page = surface.builder();
            final content = surface.destination == null
                ? page
                : AppShell(
                    initialDestinationIndex: _destinationIndex(
                      surface.destination!,
                    ),
                    destinationOverrides: {surface.destination!: page},
                  );
            await tester.pumpWidget(
              YhApp(
                themeMode: mode,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: viewport,
                    devicePixelRatio: 1,
                    disableAnimations: true,
                    platformBrightness: mode == YhThemeMode.light
                        ? Brightness.light
                        : Brightness.dark,
                  ),
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: SizedBox.expand(child: content),
                  ),
                ),
              ),
            );
            await tester.pump(YhTheme.light.motion.slow);
            await surface.prepare?.call(tester);
            await tester.pump();
            final target = File(
              '${output.path}/${surface.id}--${surface.state}--$themeName--'
              '${viewport.width.toInt()}x${viewport.height.toInt()}.png',
            );
            await _capture(tester, boundaryKey, target, viewport);
            expect(target.lengthSync(), greaterThan(0));
            await surface.cleanup?.call(tester);
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        }, skip: !_captureEnabled);
      }
    }
  }
}

TargetPlatform get _targetPlatform => switch (_platform) {
  'android' => TargetPlatform.android,
  'ios' => TargetPlatform.iOS,
  'macos' => TargetPlatform.macOS,
  'linux' => TargetPlatform.linux,
  _ => TargetPlatform.windows,
};

Future<void> _loadVisualFonts() async {
  final loader = FontLoader(YhTypographyTokens.fontFamilyBody);
  for (final asset in _fontAssets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
  final regularIcons =
      FontLoader(
        'packages/fluentui_system_icons/FluentSystemIcons-Regular',
      )..addFont(
        rootBundle.load(
          'packages/fluentui_system_icons/fonts/FluentSystemIcons-Regular.ttf',
        ),
      );
  final filledIcons =
      FontLoader('packages/fluentui_system_icons/FluentSystemIcons-Filled')
        ..addFont(
          rootBundle.load(
            'packages/fluentui_system_icons/fonts/FluentSystemIcons-Filled.ttf',
          ),
        );
  await Future.wait([regularIcons.load(), filledIcons.load()]);
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundaryKey,
  File target,
  Size viewport,
) async {
  final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  final result = await tester.runAsync<_CapturedPng>(() async {
    final captured = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await captured.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Flutter 截图编码失败：${target.path}');
      }
      return _CapturedPng(
        width: captured.width,
        height: captured.height,
        bytes: bytes.buffer.asUint8List(),
      );
    } finally {
      captured.dispose();
    }
  });
  if (result == null) throw StateError('Flutter 截图任务未返回：${target.path}');
  expect(result.width, viewport.width.toInt());
  expect(result.height, viewport.height.toInt());
  target.writeAsBytesSync(result.bytes, flush: true);
}

class _CapturedPng {
  const _CapturedPng({
    required this.width,
    required this.height,
    required this.bytes,
  });

  final int width;
  final int height;
  final Uint8List bytes;
}

class _VisualSurface {
  const _VisualSurface(
    this.id,
    this.builder, {
    this.state = 'content',
    this.prepare,
    this.cleanup,
    this.destination,
  });

  final String id;
  final String state;
  final Widget Function() builder;
  final Future<void> Function(WidgetTester tester)? prepare;
  final Future<void> Function(WidgetTester tester)? cleanup;
  final String? destination;
}

int _destinationIndex(String destination) => switch (destination) {
  '主页' => 0,
  '教务' => 1,
  '课表' => 2,
  '信息' => 3,
  '邮箱' => 4,
  '跳转' => 5,
  '设置' => 6,
  _ => throw ArgumentError.value(destination, 'destination'),
};

final _surfaces = <_VisualSurface>[
  _VisualSurface('components.actions', _actionsPanel),
  _VisualSurface('components.inputs', _inputsPanel),
  _VisualSurface('components.feedback', _feedbackPanel),
  _VisualSurface('components.navigation', _navigationPanel),
  _VisualSurface('components.data', _dataPanel),
  _VisualSurface('components.domain', _domainPanel),
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
  _VisualSurface('legal.notice', () => const LegalNoticePage()),
  _VisualSurface('settings.about', () => const AboutPage()),
  _VisualSurface(
    'external.webview',
    () => const WebViewPage(url: 'invalid-url', initialTitle: '校园服务'),
    state: 'error',
  ),
];

Widget _schedulePage({
  required QingyuanVisualAcademicEamsClient service,
  AcademicEamsQueryResult? initialResult,
}) {
  return CourseSchedulePage(
    academicEamsService: service,
    initialResult: initialResult,
    autoRefreshEnabledOverride: false,
    nowOverride: qingyuanVisualNow,
  );
}

Widget _scheduleInitial() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleContentResult,
  ),
);

Widget _scheduleLoading() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleContentResult,
    pendingCourseTable: Completer<AcademicEamsQueryResult>(),
  ),
);

Future<void> _startScheduleLoading(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('course-schedule-refresh')));
}

Widget _scheduleContent() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleContentResult,
  ),
  initialResult: qingyuanScheduleContentResult,
);

Widget _scheduleEmpty() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleEmptyResult,
  ),
  initialResult: qingyuanScheduleEmptyResult,
);

Widget _scheduleStale() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleStaleResult,
  ),
  initialResult: qingyuanScheduleStaleResult,
);

Widget _scheduleError() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleErrorResult,
  ),
  initialResult: qingyuanScheduleErrorResult,
);

Widget _mailPage(QingyuanVisualEmailClient service) {
  return EmailPage(
    emailService: service,
    emailAutoRefreshEnabledOverride: false,
    emailAutoRefreshIntervalOverride: 30,
    nowOverride: qingyuanVisualNow,
  );
}

Widget _mailInitial() => _mailPage(QingyuanVisualEmailClient());

Widget _mailLoading() => _mailPage(
  QingyuanVisualEmailClient(pendingFetch: Completer<EmailMailboxQueryResult>()),
);

Future<void> _startMailLoading(WidgetTester tester) async {
  await tester.tap(find.text('读取最近邮件').first);
}

Widget _mailContent() => _mailPage(
  QingyuanVisualEmailClient(cachedResult: qingyuanEmailContentResult),
);

Widget _mailEmpty() => _mailPage(
  QingyuanVisualEmailClient(cachedResult: qingyuanEmailEmptyResult),
);

Widget _mailStale() => _mailPage(
  QingyuanVisualEmailClient(cachedResult: qingyuanEmailStaleResult),
);

Widget _mailError() => _mailPage(
  QingyuanVisualEmailClient(cachedResult: qingyuanEmailErrorResult),
);

Future<void> _openMailCompose(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('email-compose-open')));
  await tester.pump();
}

Future<void> _prepareMailComposeContent(WidgetTester tester) async {
  await _openMailCompose(tester);
  await _fillMailCompose(tester);
}

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

Widget _mailComposeLoading() => _mailPage(
  QingyuanVisualEmailClient(
    cachedResult: qingyuanEmailContentResult,
    pendingSend: Completer<EmailSendResult>(),
  ),
);

Widget _mailComposeError() => _mailPage(
  QingyuanVisualEmailClient(
    cachedResult: qingyuanEmailContentResult,
    sendResult: qingyuanEmailSendErrorResult,
  ),
);

Future<void> _prepareMailComposeSending(WidgetTester tester) async {
  await _openMailCompose(tester);
  await _fillMailCompose(tester);
  final sendButton = tester.widget<YhButton>(
    find.widgetWithText(YhButton, '发送邮件'),
  );
  sendButton.onTap?.call();
}

Future<void> _prepareMailComposeLoading(WidgetTester tester) async {
  await _prepareMailComposeSending(tester);
  await tester.pump();
  await _centerInScrollable(tester, find.text('正在发送'));
  await tester.pump();
}

Future<void> _prepareMailComposeError(WidgetTester tester) async {
  await _prepareMailComposeSending(tester);
  await tester.pump();
  await tester.pump();
  await _centerInScrollable(tester, find.text('邮件未发送').first);
  await tester.pump();
}

Future<void> _centerInScrollable(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.5,
    duration: Duration.zero,
  );
}

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

Widget _quickLinksContent() => QuickLinksPage(
  groupsLoader: () async => _quickLinkGroups,
  onOpenUrl: (_) async {},
);

Widget _quickLinksLoading() {
  final pending = Completer<List<QuickLinkGroupConfig>>();
  return QuickLinksPage(groupsLoader: () => pending.future);
}

Widget _quickLinksEmpty() => QuickLinksPage(groupsLoader: () async => const []);

Widget _quickLinksError() => QuickLinksPage(
  groupsLoader: () => Future.error(StateError('fixture load failed')),
);

Widget _externalLinkConfirmationContent() => ExternalLinkConfirmationPage(
  displayName: '统一身份认证',
  uri: Uri.parse('https://auth.example.invalid/login'),
  authenticationRequired: true,
  authenticationReady: true,
);

Widget _externalLinkConfirmationError() => ExternalLinkConfirmationPage(
  displayName: '统一身份认证',
  uri: Uri.parse('https://auth.example.invalid/login'),
  authenticationRequired: true,
  authenticationReady: false,
);

Widget _panel(String title, List<Widget> children) => YhPageScaffold(
  appBar: YhAppBar(title: title),
  body: Builder(
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.all(context.yhTheme.spacing.l),
      child: Wrap(
        spacing: context.yhTheme.spacing.m,
        runSpacing: context.yhTheme.spacing.m,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    ),
  ),
);

Widget _actionsPanel() => _panel('操作组件', [
  YhButton(label: '主要操作', onTap: () {}),
  YhButton(label: '次要操作', variant: YhButtonVariant.secondary, onTap: () {}),
  const YhButton(label: '禁用操作', disabled: true),
  YhIconButton(icon: YhIcons.refresh, semanticLabel: '刷新', onTap: () {}),
  YhFab(icon: YhIcons.add, semanticLabel: '新建', label: '新建', onTap: () {}),
  YhSegmented<String>(
    options: const [
      YhSegmentedOption(value: 'day', label: '日'),
      YhSegmentedOption(value: 'week', label: '周'),
      YhSegmentedOption(value: 'month', label: '月'),
    ],
    value: 'week',
    onChanged: (_) {},
  ),
  YhChip(label: '已选择', selected: true, onTap: () {}),
  YhChip(label: '筛选项', onTap: () {}),
  YhSwitch(value: true, semanticLabel: '通知', onChanged: (_) {}),
  YhCheckbox(label: '同意协议', value: true, onChanged: (_) {}),
  YhRadio<String>(
    label: '校内服务',
    value: 'campus',
    groupValue: 'campus',
    onChanged: (_) {},
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: YhSlider(value: 0.68, label: '透明度', onChanged: (_) {}),
  ),
  SizedBox(
    width: YhTheme.light.layout.formContentWidth,
    child: YhStepper(
      steps: const ['填写', '确认', '完成'],
      currentStep: 1,
      onStepSelected: (_) {},
    ),
  ),
]);

Widget _inputsPanel() => _panel('输入组件', [
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: const YhTextField(label: '姓名', hint: '请输入姓名'),
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: const YhSearch(hint: '搜索课程、邮件或资讯'),
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: const YhTextarea(label: '备注', hint: '补充说明', maxLines: 3),
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: YhSelect<String>(
      label: '学期',
      options: const [
        YhSelectOption(value: '2026-summer', label: '2026 夏季学期'),
        YhSelectOption(value: '2026-spring', label: '2026 春季学期'),
      ],
      value: '2026-summer',
      onChanged: (_) {},
    ),
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: YhDatePicker(label: '查询日期', value: '2026-07-19', onTap: () {}),
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: YhOtp(controller: TextEditingController(text: '260719')),
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: const YhTextField(label: '邮箱', errorText: '邮箱格式不正确'),
  ),
]);

Widget _feedbackPanel() => _panel('容器与反馈', [
  const SizedBox(width: 260, child: YhCard(child: Text('用于组织关联内容的清源卡片'))),
  const SizedBox(width: 260, child: YhTile(child: Text('可选择的内容磁贴'))),
  const SizedBox(
    width: 320,
    child: YhListItem(title: '校园通知', subtitle: '刚刚更新'),
  ),
  const SizedBox(
    width: 420,
    child: YhAccordion(
      title: '查看说明',
      content: Text('折叠内容遵循清源间距与焦点规范。'),
      initiallyExpanded: true,
    ),
  ),
  const SizedBox(width: 420, child: YhBanner(text: '数据已在 09:30 更新')),
  const YhToast(message: '设置已保存', actionLabel: '撤销'),
  const SizedBox(width: 320, child: YhSkeleton()),
  const SizedBox(
    width: 360,
    child: YhEmptyState(
      icon: YhIcons.inbox,
      title: '暂无内容',
      message: '完成同步后将在这里显示。',
    ),
  ),
  YhDialog(
    title: '确认操作',
    content: const Text('该操作会更新本地显示设置。'),
    actions: [
      YhButton(label: '取消', variant: YhButtonVariant.secondary, onTap: () {}),
      YhButton(label: '确认', onTap: () {}),
    ],
  ),
]);

Widget _navigationPanel() => _panel('导航组件', [
  SizedBox(
    width: YhTheme.light.layout.formContentWidth,
    child: YhTabs<String>(
      tabs: const [
        YhTab(value: 'overview', label: '总览', icon: YhIcons.home),
        YhTab(value: 'detail', label: '详情', icon: YhIcons.info),
      ],
      value: 'overview',
      onChanged: (_) {},
    ),
  ),
  YhPagination(page: 3, pageCount: 8, onChanged: (_) {}),
  SizedBox(
    width: YhTheme.light.layout.formContentWidth,
    child: YhBottomNav(
      items: const [
        YhNavigationItem(icon: YhIcons.home, label: '主页'),
        YhNavigationItem(icon: YhIcons.academic, label: '教务'),
        YhNavigationItem(icon: YhIcons.calendar, label: '课表'),
      ],
      index: 0,
      onChanged: (_) {},
    ),
  ),
  SizedBox(
    height: YhTheme.light.layout.bottomNavigationHeight * 4,
    child: YhNavRail(
      items: const [
        YhNavigationItem(icon: YhIcons.home, label: '主页'),
        YhNavigationItem(icon: YhIcons.settings, label: '设置'),
      ],
      index: 0,
      onChanged: (_) {},
    ),
  ),
]);

Widget _dataPanel() => _panel('数据展示', [
  const YhBadge(label: '12'),
  const YhStatusPill(label: '运行正常', kind: YhStatusKind.success),
  const YhStatusPill(label: '需要关注', kind: YhStatusKind.warning),
  const YhAvatar(semanticLabel: '清源用户', initials: '清'),
  const SizedBox(
    width: 260,
    child: YhMetricCard(label: '平均绩点', value: '3.82', caption: '较上学期 +0.12'),
  ),
  const SizedBox(width: 260, child: YhProgress(value: 0.76)),
  const YhRing(value: 0.82, label: '培养进度'),
  const SizedBox(
    width: 420,
    child: YhFeedItem(
      title: '夏季学期选课确认',
      summary: '请在规定时间内登录教务系统确认选课结果。',
      source: '教务处',
      timestamp: '09:30',
    ),
  ),
  const YhSourceBadge(label: '学校官网', icon: YhIcons.globe),
]);

Widget _domainPanel() => _panel('校园域组件', [
  const SizedBox(
    width: 360,
    child: YhTodayCard(
      title: '今天',
      subtitle: '7 月 19 日 · 星期日',
      child: Text('2 节课程 · 1 项待办'),
    ),
  ),
  const SizedBox(
    width: 300,
    child: YhCourseBlock(
      name: '高等数学',
      time: '08:00–09:35',
      location: '教学楼 310',
    ),
  ),
  const SizedBox(
    width: 360,
    child: YhAiMessage(
      message: '已为你整理今天的课程与待办。',
      role: YhMessageRole.assistant,
    ),
  ),
  const SizedBox(
    width: 280,
    child: YhBalanceModule(
      label: '校园卡余额',
      balance: '¥ 88.00',
      caption: '更新于 09:30',
    ),
  ),
  SizedBox(
    width: 220,
    child: YhQuickLink(
      icon: YhIcons.library,
      label: '图书馆',
      subtitle: '馆藏与借阅',
      color: YhTheme.light.color.serviceQuickLink,
      onTap: () {},
    ),
  ),
  const SizedBox(
    width: 360,
    child: YhAttendanceItem(
      title: '体育考勤',
      detail: '操场 · 07:30',
      status: '已签到',
      kind: YhStatusKind.success,
    ),
  ),
]);
