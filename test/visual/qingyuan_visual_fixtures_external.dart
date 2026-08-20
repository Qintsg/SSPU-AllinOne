/*
 * 清源视觉 fixture — WebView、PDF 与系统认证
 * @Project : SSPU-AllinOne
 * @File : qingyuan_visual_fixtures_external.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'qingyuan_visual_capture_test.dart';

const Key _webViewExternalRegionKey = Key('visual-webview-document');
const Key _pdfExternalRegionKey = Key('visual-pdf-document');
const Key _systemAuthExternalRegionKey = Key('visual-system-auth-dialog');

/// 构建 _externalWebViewSurface 对应的确定性视觉场景。
///
/// :param loading: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _externalWebViewSurface({required bool loading}) => WebViewPageFrame(
  title: loading ? '正在打开校园门户' : '校园门户',
  onBackPressed: () {},
  progress: loading ? 0.38 : null,
  actions: [
    YhIconButton(semanticLabel: '刷新', icon: YhIcons.refresh, onTap: () {}),
    YhIconButton(semanticLabel: '在浏览器中打开', icon: YhIcons.open, onTap: () {}),
  ],
  document: _externalDocumentRegion(
    key: _webViewExternalRegionKey,
    icon: YhIcons.open,
    title: loading ? '网页正在加载' : '上海第二工业大学校园门户',
    message: loading
        ? '平台 WebView runner 将在此处加载真实网页。'
        : '网页正文属于外部区域，由 sidecar 标注责任边界。',
    loading: loading,
  ),
);

/// 构建 _externalWebViewFailureSurface 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _externalWebViewFailureSurface() => WebViewPageFrame(
  title: '校园门户',
  onBackPressed: () {},
  actions: [
    YhIconButton(semanticLabel: '刷新', icon: YhIcons.refresh, onTap: () {}),
    YhIconButton(semanticLabel: '在浏览器中打开', icon: YhIcons.open, onTap: () {}),
  ],
  document: WebViewFailureDocument(
    target: 'portal.example.invalid',
    loadError: '校园网或 WebView 运行时暂不可用',
    onRetry: () {},
    onOpenExternal: () {},
  ),
);

/// 构建 _externalWebViewRetainedSurface 对应的确定性视觉场景。
///
/// :param state: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _externalWebViewRetainedSurface(String state) {
  final openingExternal = state == 'operation-locked';
  const externalError = '系统浏览器未能打开校园网页；仍停留在应用内，可检查默认浏览器设置后重试。';
  return WebViewPageFrame(
    title: '校园门户',
    onBackPressed: () {},
    statusBanner: openingExternal
        ? const YhBanner(
            kind: YhBannerKind.info,
            text: '正在交给系统浏览器；完成前已锁定重复外部打开，网页和返回路径保持可用。',
          )
        : state != 'external-error'
        ? null
        : const YhBanner(kind: YhBannerKind.danger, text: externalError),
    actions: [
      YhIconButton(
        semanticLabel: '刷新',
        icon: YhIcons.refresh,
        onTap: openingExternal ? null : () {},
      ),
      YhIconButton(
        semanticLabel: '在浏览器中打开',
        icon: YhIcons.open,
        onTap: openingExternal ? null : () {},
      ),
    ],
    document: _externalDocumentRegion(
      key: _webViewExternalRegionKey,
      icon: YhIcons.open,
      title: '上海第二工业大学校园门户',
      message: '网页正文属于外部区域，由 sidecar 标注责任边界。',
    ),
  );
}

/// 构建 _externalWebViewConfirmationSurface 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _externalWebViewConfirmationSurface() => Builder(
  builder: (context) => WebViewPageFrame(
    title: '校园门户',
    onBackPressed: () {},
    actions: [
      YhIconButton(semanticLabel: '刷新', icon: YhIcons.refresh, onTap: () {}),
      YhIconButton(
        semanticLabel: '在浏览器中打开',
        icon: YhIcons.open,
        onTap: () => unawaited(
          confirmWebViewExternalOpen(
            context,
            Uri.parse('https://portal.example.invalid/'),
          ),
        ),
      ),
    ],
    document: _externalDocumentRegion(
      key: _webViewExternalRegionKey,
      icon: YhIcons.open,
      title: '上海第二工业大学校园门户',
      message: '网页正文属于外部区域，由 sidecar 标注责任边界。',
    ),
  ),
);

/// 准备 _showWebViewExternalConfirmation 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _showWebViewExternalConfirmation(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('在浏览器中打开'));
  await tester.pumpAndSettle();
}

/// 构建 _externalPdfSurface 对应的确定性视觉场景。
///
/// :param state: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _externalPdfSurface(String state) {
  final retained = const [
    'content',
    'partial-error',
    'operation-locked',
    'external-error',
  ].contains(state);
  if (state == 'operation-locked') {
    _externalPdfDownloadCompleter = Completer<void>();
  }
  final source = state == 'empty'
      ? null
      : 'https://jwc.sspu.edu.cn/calendar.pdf';
  return AcademicCalendarPdfPage(
    title: '2025–2026 学年校历',
    pdfUrl: source,
    initialPageCount: retained ? 4 : null,
    initialDocumentState: switch (state) {
      'loading' => AcademicCalendarPdfDocumentState.loading,
      'empty' => AcademicCalendarPdfDocumentState.empty,
      'error' => AcademicCalendarPdfDocumentState.error,
      _ => AcademicCalendarPdfDocumentState.content,
    },
    documentBuilder: state == 'empty'
        ? null
        : (context, current, revision, actions) =>
              _externalPdfDocument(context, state, actions),
    downloadOverride: (current, title) async {
      if (state == 'operation-locked') {
        await _externalPdfDownloadCompleter!.future;
      } else if (state == 'partial-error') {
        throw StateError('deterministic download failure');
      }
    },
    launchExternalOverride: (uri) async => false,
  );
}

Completer<void>? _externalPdfDownloadCompleter;

/// 构建 _externalPdfDocument 对应的确定性视觉场景。
///
/// :param context: 当前视觉场景输入。
/// :param state: 当前视觉场景输入。
/// :param actions: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _externalPdfDocument(
  BuildContext context,
  String state,
  AcademicCalendarPdfDocumentActions actions,
) {
  if (state == 'error') {
    return YhEmptyState(
      icon: YhIcons.warning,
      title: 'PDF 加载失败',
      message: '文件来源：jwc.sspu.edu.cn/calendar.pdf。可重试读取或改用外部应用打开。',
      action: Wrap(
        spacing: context.yhTheme.spacing.s,
        children: [
          YhButton(label: '重试读取', onTap: actions.retry),
          YhButton(
            label: '外部打开',
            variant: YhButtonVariant.secondary,
            onTap: actions.openExternal,
          ),
        ],
      ),
    );
  }
  return _externalDocumentRegion(
    key: _pdfExternalRegionKey,
    icon: YhIcons.library,
    title: state == 'loading' ? '正在加载校历 PDF' : '2025—2026 学年校历正文',
    message: state == 'loading'
        ? '正在准备页面与字体；返回操作始终可用。'
        : 'PDF 正文属于外部区域，由 sidecar 标注责任边界。',
    loading: state == 'loading',
  );
}

/// 准备 _prepareExternalPdfState 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :param state: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareExternalPdfState(WidgetTester tester, String state) async {
  if (state == 'partial-error' || state == 'operation-locked') {
    await tester.tap(find.bySemanticsLabel('下载校历 PDF'));
    if (state == 'partial-error') {
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
    } else {
      await tester.pump();
    }
  } else if (state == 'external-error') {
    await tester.tap(find.bySemanticsLabel('外部打开校历 PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续打开'));
    await tester.pumpAndSettle();
  }
}

/// 准备 _cleanupExternalPdfState 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :param state: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _cleanupExternalPdfState(WidgetTester tester, String state) async {
  if (state == 'partial-error') {
    await tester.pump(const Duration(seconds: 4));
  }
}

/// 构建 _externalPdfConfirmationSurface 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _externalPdfConfirmationSurface() => AcademicCalendarPdfPage(
  title: '2025–2026 学年校历',
  pdfUrl: 'https://jwc.sspu.edu.cn/calendar.pdf',
  initialPageCount: 4,
  initialDocumentState: AcademicCalendarPdfDocumentState.content,
  documentBuilder: (context, source, revision, actions) =>
      _externalDocumentRegion(
        key: _pdfExternalRegionKey,
        icon: YhIcons.library,
        title: '2025—2026 学年校历正文',
        message: 'PDF 正文属于外部区域，由 sidecar 标注责任边界。',
      ),
  launchExternalOverride: (uri) async => true,
);

/// 准备 _showExternalPdfConfirmation 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _showExternalPdfConfirmation(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('外部打开校历 PDF'));
  await tester.pumpAndSettle();
}

/// 构建 _externalSystemAuthSurface 对应的确定性视觉场景。
///
/// :param state: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _externalSystemAuthSurface(String state) => Builder(
  builder: (context) => Stack(
    fit: StackFit.expand,
    children: [
      _lockInitial(),
      ColoredBox(color: context.yhTheme.color.scrim),
      Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final theme = context.yhTheme;
            final width = math.min(
              theme.layout.dialogWidth,
              constraints.maxWidth - theme.spacing.l * 2,
            );
            return KeyedSubtree(
              key: _systemAuthExternalRegionKey,
              child: SizedBox(
                width: width,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: theme.breakpoint.compact / 2,
                  ),
                  child: YhCard(child: _SystemAuthVisualDialog(state: state)),
                ),
              ),
            );
          },
        ),
      ),
    ],
  ),
);

class _SystemAuthVisualDialog extends StatelessWidget {
  /// 创建指定系统认证状态的外部区域视觉替身。
  ///
  /// :param state: 系统认证视觉状态。
  const _SystemAuthVisualDialog({required this.state});

  final String state;

  /// 构建 build 对应的确定性视觉场景。
  ///
  /// :param context: 当前视觉场景输入。
  /// :returns: 可用于视觉采集的界面。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final title = switch (state) {
      'initial' => '准备系统认证',
      'error' => '系统认证未完成',
      _ => '验证身份以解锁工大聚合',
    };
    final message = switch (state) {
      'initial' => '系统即将请求设备 PIN 或生物识别。',
      'error' => '可重试系统认证，或返回应用输入本地密码。',
      _ => '此区域由操作系统绘制，认证信息不会离开设备。',
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < theme.breakpoint.compact;
        final actions = [
          YhButton(
            label: '返回密码',
            variant: YhButtonVariant.secondary,
            minWidth: compact ? theme.breakpoint.compact : null,
            onTap: () {},
          ),
          YhButton(
            label: state == 'error' ? '重试认证' : '继续',
            minWidth: compact ? theme.breakpoint.compact : null,
            onTap: () {},
          ),
        ];
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.color.brandTint,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: theme.control.regular + theme.spacing.m,
                child: Icon(
                  state == 'error' ? YhIcons.warning : YhIcons.fingerprint,
                  color: theme.color.brandInk,
                ),
              ),
            ),
            SizedBox(height: theme.spacing.m),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.typography.h3,
            ),
            SizedBox(height: theme.spacing.s),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.typography.body.copyWith(color: theme.color.muted),
            ),
            SizedBox(height: theme.spacing.m),
            if (compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: double.infinity, child: actions[0]),
                  SizedBox(height: theme.spacing.s),
                  SizedBox(width: double.infinity, child: actions[1]),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  actions[0],
                  SizedBox(width: theme.spacing.s),
                  actions[1],
                ],
              ),
          ],
        );
      },
    );
  }
}

/// 构建 _externalDocumentRegion 对应的确定性视觉场景。
///
/// :param loading: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _externalDocumentRegion({
  required Key key,
  required IconData icon,
  required String title,
  required String message,
  bool loading = false,
}) => Builder(
  builder: (context) => KeyedSubtree(
    key: key,
    child: ColoredBox(
      color: context.yhTheme.color.sunken,
      child: Center(
        child: loading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const YhProgress(showPercent: false),
                  SizedBox(height: context.yhTheme.spacing.m),
                  Text(title),
                  SizedBox(height: context.yhTheme.spacing.xs),
                  Text(message),
                ],
              )
            : YhEmptyState(icon: icon, title: title, message: message),
      ),
    ),
  ),
);
