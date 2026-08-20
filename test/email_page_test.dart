/*
 * 学校邮箱页面测试 — 校验收信、正文详情、SMTP 校验与发信入口
 * @Project : SSPU-AllinOne
 * @File : email_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/models/email_mailbox.dart';
import 'package:sspu_allinone/pages/email_page.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/email_service.dart';

/// 等待目标组件出现，覆盖异步收信和动画后的首帧。
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> pumpEmailPage(
  WidgetTester tester, {
  required EmailMailboxClient emailService,
  required bool emailAutoRefreshEnabledOverride,
  int emailAutoRefreshIntervalOverride = 30,
  DateTime? nowOverride,
}) async {
  await tester.pumpWidget(
    YhApp(
      home: EmailPage(
        emailService: emailService,
        emailAutoRefreshEnabledOverride: emailAutoRefreshEnabledOverride,
        emailAutoRefreshIntervalOverride: emailAutoRefreshIntervalOverride,
        nowOverride: nowOverride,
      ),
    ),
  );
}

Future<void> openEmailConnectionDrawer(WidgetTester tester) async {
  await tester.ensureVisible(find.text('邮箱连接设置'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('邮箱连接设置'));
  await tester.pumpAndSettle();
  expect(find.text('邮箱连接与协议'), findsOneWidget);
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('邮箱页面可读取 IMAP 邮件并进入正文详情', (tester) async {
    final service = _FakeEmailClient();
    await pumpEmailPage(
      tester,
      emailService: service,
      emailAutoRefreshEnabledOverride: false,
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('收件箱'), findsOneWidget);
    expect(find.text('写邮件'), findsOneWidget);
    expect(find.byKey(const Key('email-compose-panel')), findsNothing);
    expect(find.text('尚未读取邮箱'), findsOneWidget);

    await tester.ensureVisible(find.text('读取最近邮件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('读取最近邮件'));
    await pumpUntilFound(tester, find.text('教务通知'));

    expect(service.fetchCount, 1);
    expect(find.text('IMAP 已连接'), findsOneWidget);
    expect(find.text('1 封邮件'), findsOneWidget);
    expect(find.text('教务处'), findsOneWidget);

    await tester.ensureVisible(find.text('教务通知'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('教务通知'));
    await tester.pumpAndSettle();

    expect(find.text('邮件正文'), findsOneWidget);
    expect(find.text('请查看最新通知。'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 120));
  });

  testWidgets('邮件正文详情使用清源阅读排版与弱化前景', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: EmailMessageDetailPage(
          message: _message,
          nowOverride: DateTime(2026, 7, 18, 9, 30),
        ),
      ),
    );

    final selectable = tester.widget<YhSelectableText>(
      find.byType(YhSelectableText),
    );
    final theme = tester.element(find.byType(YhSelectableText)).yhTheme;
    expect(selectable.style?.fontSize, theme.typography.reading.fontSize);
    expect(selectable.style?.height, theme.typography.reading.height);
    expect(selectable.style?.color, theme.color.muted);
  });

  testWidgets('邮箱页面可触发 SMTP 登录校验但不读取邮件', (tester) async {
    final service = _FakeEmailClient();
    await pumpEmailPage(
      tester,
      emailService: service,
      emailAutoRefreshEnabledOverride: false,
    );
    await tester.pump(const Duration(milliseconds: 100));

    await openEmailConnectionDrawer(tester);
    await tester.tap(find.text('校验 SMTP'));
    await pumpUntilFound(tester, find.text('SMTP 登录校验通过'));

    expect(service.validateCount, 1);
    expect(service.lastValidatedProtocol, EmailProtocol.smtp);
    expect(service.fetchCount, 0);
    expect(find.byKey(const Key('app-feedback-toast')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 120));
  });

  testWidgets('凭据变更后邮箱页丢弃未完成的协议校验结果', (tester) async {
    final service = _FakeEmailClient(deferValidation: true);
    await pumpEmailPage(
      tester,
      emailService: service,
      emailAutoRefreshEnabledOverride: false,
    );
    await tester.pump(const Duration(milliseconds: 100));

    await openEmailConnectionDrawer(tester);
    await tester.tap(find.text('校验 SMTP'));
    await tester.pump();

    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'new-mail-pass',
    );
    await tester.pump();
    service.completeValidation();
    await tester.pumpAndSettle();

    expect(service.validateCount, 1);
    expect(find.text('SMTP 登录校验通过'), findsNothing);
    expect(find.byKey(const Key('app-feedback-toast')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 120));
  });

  testWidgets('邮箱页面可通过撰写面板触发 SMTP 发信', (tester) async {
    final service = _FakeEmailClient();
    await pumpEmailPage(
      tester,
      emailService: service,
      emailAutoRefreshEnabledOverride: false,
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('email-compose-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-compose-panel')), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(YhTextField, '收件人'),
      'to@example.com',
    );
    await tester.enterText(
      find.widgetWithText(YhTextField, '抄送'),
      'cc@example.com',
    );
    await tester.enterText(
      find.widgetWithText(YhTextField, '密送'),
      'bcc@example.com',
    );
    await tester.enterText(find.widgetWithText(YhTextField, '主题'), '测试主题');
    await tester.enterText(find.widgetWithText(YhTextField, '正文'), '测试正文');
    await tester.ensureVisible(find.text('发送邮件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('发送邮件'));
    await pumpUntilFound(tester, find.text('邮件已提交发送'));

    expect(service.sendCount, 1);
    expect(service.lastComposeRequest?.to, ['to@example.com']);
    expect(service.lastComposeRequest?.cc, ['cc@example.com']);
    expect(service.lastComposeRequest?.bcc, ['bcc@example.com']);
    expect(service.lastComposeRequest?.subject, '测试主题');
    expect(find.byKey(const Key('email-compose-panel')), findsNothing);
    expect(find.byKey(const Key('app-feedback-toast')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 120));
  });

  testWidgets('邮箱撰写面板在窄屏下不溢出', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    });

    final service = _FakeEmailClient();
    await pumpEmailPage(
      tester,
      emailService: service,
      emailAutoRefreshEnabledOverride: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('email-compose-open')));
    await tester.pumpAndSettle();

    expect(find.text('撰写邮件'), findsOneWidget);
    expect(find.byKey(const Key('email-compose-action-dock')), findsOneWidget);
    final detail = tester.widget<Text>(
      find.text('仅在点击发送后提交普通文本；不保存草稿，不在后台重试。'),
    );
    final theme = tester
        .element(find.byKey(const Key('email-compose-panel')))
        .yhTheme;
    expect(detail.style?.fontSize, theme.typography.small.fontSize);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 120));
  });

  testWidgets('邮箱紧凑撰写将取消和发送固定在表单滚动区之外', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakeEmailClient();
    await pumpEmailPage(
      tester,
      emailService: service,
      emailAutoRefreshEnabledOverride: false,
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('email-compose-open')));
    await tester.pumpAndSettle();
    final dock = find.byKey(const Key('email-compose-action-dock'));
    expect(dock, findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('发送邮件'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    expect(dock, findsOneWidget);
    expect(tester.getBottomRight(dock).dy, lessThanOrEqualTo(800));

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-compose-panel')), findsNothing);
    expect(service.sendCount, 0);
  });

  testWidgets('邮箱紧凑提交坞在发送中锁定取消、发送与表单', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakeEmailClient(deferSend: true);
    await pumpEmailPage(
      tester,
      emailService: service,
      emailAutoRefreshEnabledOverride: false,
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('email-compose-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('发送邮件'));
    await tester.pump();

    expect(service.sendCount, 1);
    expect(find.text('正在发送'), findsOneWidget);
    final dockButtons = tester.widgetList<YhButton>(
      find.descendant(
        of: find.byKey(const Key('email-compose-action-dock')),
        matching: find.byType(YhButton),
      ),
    );
    expect(dockButtons, hasLength(2));
    expect(dockButtons.every((button) => button.onTap == null), isTrue);
    final fields = tester.widgetList<YhTextField>(find.byType(YhTextField));
    expect(fields.every((field) => !field.enabled), isTrue);

    service.completeSend();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-compose-panel')), findsNothing);
  });

  testWidgets('邮箱发送中字段保持可读外观与禁用语义', (tester) async {
    final controllers = List.generate(5, (_) => TextEditingController());
    for (final controller in controllers) {
      addTearDown(controller.dispose);
    }

    await tester.pumpWidget(
      YhApp(
        home: SingleChildScrollView(
          child: EmailComposePanel(
            toController: controllers[0],
            ccController: controllers[1],
            bccController: controllers[2],
            subjectController: controllers[3],
            bodyController: controllers[4],
            isSending: true,
            severityOf: (_) => YhBannerKind.info,
            onSend: () {},
          ),
        ),
      ),
    );

    final fields = tester.widgetList<YhTextField>(find.byType(YhTextField));
    expect(fields, hasLength(5));
    expect(fields.every((field) => !field.enabled), isTrue);
    expect(fields.every((field) => !field.showDisabledAppearance), isTrue);
  });

  testWidgets('邮箱页面桌面端使用列表详情双栏布局', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    });

    final service = _FakeEmailClient(cachedResult: _cachedMailboxResult);
    await pumpEmailPage(
      tester,
      emailService: service,
      emailAutoRefreshEnabledOverride: false,
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('email-desktop-client-layout')),
    );

    expect(find.byKey(const Key('email-sidebar')), findsNothing);
    expect(find.byKey(const Key('email-mailbox-list-pane')), findsOneWidget);
    expect(find.text('缓存通知'), findsWidgets);

    await tester.tap(find.byKey(const Key('email-compose-open')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email-compose-panel')), findsOneWidget);
    expect(find.byKey(const Key('email-compose-action-dock')), findsNothing);
    expect(find.text('撰写邮件'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 120));
  });

  testWidgets('邮箱撰写地址字段在 900dp 内单列并在宽屏双列', (tester) async {
    Future<(Offset, Offset)> fieldPositionsAt(Size size) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.binding.setSurfaceSize(size);
      await pumpEmailPage(
        tester,
        emailService: _FakeEmailClient(),
        emailAutoRefreshEnabledOverride: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
      final composeOpen = find.byKey(const Key('email-compose-open'));
      if (composeOpen.evaluate().isNotEmpty) {
        await tester.tap(composeOpen);
      }
      await tester.pumpAndSettle();
      return (
        tester.getTopLeft(find.widgetWithText(YhTextField, '抄送')),
        tester.getTopLeft(find.widgetWithText(YhTextField, '密送')),
      );
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final medium = await fieldPositionsAt(const Size(768, 900));
    expect(medium.$1.dy, lessThan(medium.$2.dy));

    final expanded = await fieldPositionsAt(const Size(1200, 900));
    expect(expanded.$1.dy, expanded.$2.dy);
  });

  testWidgets('邮箱自动刷新开启时会主动读取 IMAP 邮件', (tester) async {
    final service = _FakeEmailClient();
    await pumpEmailPage(
      tester,
      emailService: service,
      emailAutoRefreshEnabledOverride: true,
      emailAutoRefreshIntervalOverride: 1,
    );

    await pumpUntilFound(tester, find.text('教务通知'));

    expect(service.fetchCount, 1);
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    expect(service.fetchCount, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 120));
  });

  testWidgets('邮箱页面进入时优先展示本地邮件缓存', (tester) async {
    final service = _FakeEmailClient(cachedResult: _cachedMailboxResult);
    await pumpEmailPage(
      tester,
      emailService: service,
      emailAutoRefreshEnabledOverride: true,
      emailAutoRefreshIntervalOverride: 30,
    );

    await pumpUntilFound(tester, find.text('缓存通知'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('IMAP 已连接'), findsOneWidget);
    expect(find.text('1 封邮件'), findsOneWidget);
    expect(service.fetchCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 120));
  });

  testWidgets('邮箱页面通过固定时钟标记超时本地缓存', (tester) async {
    await pumpEmailPage(
      tester,
      emailService: _FakeEmailClient(cachedResult: _staleMailboxResult),
      emailAutoRefreshEnabledOverride: false,
      emailAutoRefreshIntervalOverride: 30,
      nowOverride: DateTime(2026, 7, 18, 9, 30),
    );
    await pumpUntilFound(tester, find.text('缓存通知'));

    expect(find.textContaining('本地邮件缓存'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 120));
  });

  testWidgets('邮箱紧凑状态卡按内容收束并保留清源品牌图标', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEmailPage(
      tester,
      emailService: _FakeEmailClient(),
      emailAutoRefreshEnabledOverride: false,
    );
    await tester.pump(const Duration(milliseconds: 200));

    final card = find.byKey(const Key('email-mailbox-state-card'));
    final icon = find.byKey(const Key('email-mailbox-state-icon'));
    final theme = tester.element(card).yhTheme;
    expect(card, findsOneWidget);
    expect(icon, findsOneWidget);
    expect(tester.getSize(icon), Size.square(theme.control.regular));
    expect(
      tester.getSize(card).height,
      lessThan(theme.layout.popoverWidth + theme.spacing.xl),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('邮箱读取中使用紧凑环形活动指示器与说明', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEmailPage(
      tester,
      emailService: _FakeEmailClient(deferFetch: true),
      emailAutoRefreshEnabledOverride: false,
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('读取最近邮件').first);
    await tester.pump();

    final ring = find.byType(YhRing);
    final theme = tester.element(ring).yhTheme;
    expect(ring, findsOneWidget);
    expect(find.byType(YhProgress), findsNothing);
    expect(tester.getSize(ring), Size.square(theme.control.compact));
    expect(find.text('正在读取最近邮件'), findsOneWidget);
    expect(find.textContaining('IMAP'), findsOneWidget);
    expect(find.bySemanticsLabel('正在读取最近邮件'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('邮箱紧凑邮件行保持双倍常规控件高度', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEmailPage(
      tester,
      emailService: _FakeEmailClient(cachedResult: _cachedMailboxResult),
      emailAutoRefreshEnabledOverride: false,
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('email-message-IMAP:cached')),
    );

    final row = find.byKey(const Key('email-message-IMAP:cached'));
    final theme = tester.element(row).yhTheme;
    expect(
      tester.getSize(row).height,
      closeTo(theme.control.regular * 2 - theme.layout.divider / 2, 0.1),
    );
    final preview = tester.widget<Text>(find.text('缓存邮件内容。'));
    expect(preview.style?.color, theme.color.muted);
    expect(preview.style?.height, theme.typography.body.height);
  });

  testWidgets('邮箱列表暴露互斥选择语义并支持上下方向键漫游', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEmailPage(
      tester,
      emailService: _FakeEmailClient(cachedResult: _twoMessageMailboxResult),
      emailAutoRefreshEnabledOverride: false,
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('email-message-IMAP:second')),
    );

    final firstRow = find.byKey(const Key('email-message-IMAP:cached'));
    final secondRow = find.byKey(const Key('email-message-IMAP:second'));
    final firstPressable = find.ancestor(
      of: firstRow,
      matching: find.byType(YhPressable),
    );
    final secondPressable = find.ancestor(
      of: secondRow,
      matching: find.byType(YhPressable),
    );
    expect(
      tester.getSemantics(firstPressable).flagsCollection.isSelected,
      Tristate.isTrue,
    );

    final firstDetector = tester.widget<FocusableActionDetector>(
      find
          .ancestor(
            of: firstRow,
            matching: find.byType(FocusableActionDetector),
          )
          .first,
    );
    firstDetector.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(
      tester.getSemantics(secondPressable).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('邮件正文'), findsOneWidget);
    expect(find.text('第二封邮件'), findsOneWidget);
    semantics.dispose();
  });
}

class _FakeEmailClient implements EmailMailboxClient {
  _FakeEmailClient({
    this.cachedResult,
    this.deferValidation = false,
    this.deferFetch = false,
    this.deferSend = false,
  });

  final EmailMailboxQueryResult? cachedResult;
  final bool deferValidation;
  final bool deferFetch;
  final bool deferSend;
  Completer<void>? _validationCompleter;
  Completer<void>? _sendCompleter;
  int fetchCount = 0;
  int validateCount = 0;
  int sendCount = 0;
  EmailProtocol? lastValidatedProtocol;
  EmailComposeRequest? lastComposeRequest;

  @override
  Future<EmailMailboxQueryResult?> readLatestCachedMessages(
    EmailProtocol protocol,
  ) async {
    return cachedResult;
  }

  @override
  Future<EmailMailboxQueryResult> fetchMessages({
    required EmailProtocol protocol,
    int messageCount = 10,
  }) async {
    fetchCount++;
    if (deferFetch) {
      await Completer<void>().future;
    }
    return EmailMailboxQueryResult(
      status: EmailQueryStatus.success,
      protocol: protocol,
      message: '${protocol.label} 邮件读取完成',
      detail: '已读取最近邮件。',
      checkedAt: DateTime(2026, 5, 1, 9, 30),
      endpoint: _endpoint,
      snapshot: EmailMailboxSnapshot(
        protocol: protocol,
        account: 'student@sspu.edu.cn',
        messages: const [_message],
        fetchedAt: DateTime(2026, 5, 1, 9, 30),
        endpoint: _endpoint,
      ),
    );
  }

  @override
  Future<EmailLoginValidationResult> validateLogin(
    EmailProtocol protocol,
  ) async {
    validateCount++;
    lastValidatedProtocol = protocol;
    if (deferValidation) {
      _validationCompleter = Completer<void>();
      await _validationCompleter!.future;
    }
    return EmailLoginValidationResult(
      status: EmailQueryStatus.success,
      protocol: protocol,
      message: '${protocol.label} 登录校验通过',
      detail: protocol == EmailProtocol.smtp
          ? 'SMTP 仅完成认证与连通性校验，未发送邮件。'
          : '${protocol.label} 已完成登录校验，未修改邮件状态。',
      checkedAt: DateTime(2026, 5, 1, 9, 30),
      endpoint: _endpoint,
    );
  }

  @override
  Future<EmailSendResult> sendMessage(EmailComposeRequest request) async {
    sendCount++;
    lastComposeRequest = request;
    if (deferSend) {
      _sendCompleter = Completer<void>();
      await _sendCompleter!.future;
    }
    return EmailSendResult(
      status: EmailQueryStatus.success,
      message: '邮件已提交发送',
      detail: '已通过 SMTP 提交普通文本邮件。',
      checkedAt: DateTime(2026, 5, 1, 9, 30),
      endpoint: _smtpEndpoint,
      recipientsCount: request.recipientCount,
    );
  }

  void completeValidation() {
    final completer = _validationCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete();
  }

  /// 完成被延迟的 SMTP 发送，用于验证提交中的单飞锁。
  void completeSend() {
    final completer = _sendCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete();
  }
}

const EmailServerEndpoint _endpoint = EmailServerEndpoint(
  host: 'imap.exmail.qq.com',
  port: 993,
  isSecure: true,
);

const EmailServerEndpoint _smtpEndpoint = EmailServerEndpoint(
  host: 'smtp.exmail.qq.com',
  port: 465,
  isSecure: true,
);

const EmailMessageSnapshot _message = EmailMessageSnapshot(
  id: 'IMAP:1',
  subject: '教务通知',
  senderName: '教务处',
  senderAddress: 'notice@sspu.edu.cn',
  preview: '请查看最新通知。',
  body: '请查看最新通知。',
  receivedAt: null,
);

final EmailMailboxQueryResult _cachedMailboxResult = EmailMailboxQueryResult(
  status: EmailQueryStatus.success,
  protocol: EmailProtocol.imap,
  message: '已显示本地邮箱缓存',
  detail: '显示最近一次成功读取并保存的 IMAP 邮件快照。',
  checkedAt: DateTime.now(),
  endpoint: _endpoint,
  snapshot: EmailMailboxSnapshot(
    protocol: EmailProtocol.imap,
    account: 'student@sspu.edu.cn',
    messages: const [
      EmailMessageSnapshot(
        id: 'IMAP:cached',
        subject: '缓存通知',
        senderName: '教务处',
        senderAddress: 'notice@sspu.edu.cn',
        preview: '缓存邮件内容。',
        body: '缓存邮件内容。',
        receivedAt: null,
      ),
    ],
    fetchedAt: DateTime.now(),
    endpoint: _endpoint,
  ),
);

final EmailMailboxQueryResult _twoMessageMailboxResult =
    EmailMailboxQueryResult(
      status: EmailQueryStatus.success,
      protocol: EmailProtocol.imap,
      message: '已显示本地邮箱缓存',
      detail: '显示最近一次成功读取并保存的 IMAP 邮件快照。',
      checkedAt: DateTime.now(),
      endpoint: _endpoint,
      snapshot: EmailMailboxSnapshot(
        protocol: EmailProtocol.imap,
        account: 'student@sspu.edu.cn',
        messages: const [
          EmailMessageSnapshot(
            id: 'IMAP:cached',
            subject: '缓存通知',
            senderName: '教务处',
            senderAddress: 'notice@sspu.edu.cn',
            preview: '缓存邮件内容。',
            body: '缓存邮件内容。',
            receivedAt: null,
          ),
          EmailMessageSnapshot(
            id: 'IMAP:second',
            subject: '第二封邮件',
            senderName: '图书馆',
            senderAddress: 'library@sspu.edu.cn',
            preview: '第二封邮件内容。',
            body: '第二封邮件内容。',
            receivedAt: null,
          ),
        ],
        fetchedAt: DateTime.now(),
        endpoint: _endpoint,
      ),
    );

final EmailMailboxQueryResult _staleMailboxResult = EmailMailboxQueryResult(
  status: EmailQueryStatus.success,
  protocol: EmailProtocol.imap,
  message: '已显示本地邮箱缓存',
  detail: '显示最近一次成功读取并保存的 IMAP 邮件快照。',
  checkedAt: DateTime(2026, 7, 17, 18),
  endpoint: _endpoint,
  snapshot: EmailMailboxSnapshot(
    protocol: EmailProtocol.imap,
    account: 'student@sspu.edu.cn',
    messages: const [
      EmailMessageSnapshot(
        id: 'IMAP:cached',
        subject: '缓存通知',
        senderName: '教务处',
        senderAddress: 'notice@sspu.edu.cn',
        preview: '缓存邮件内容。',
        body: '缓存邮件内容。',
        receivedAt: null,
      ),
    ],
    fetchedAt: DateTime(2026, 7, 17, 18),
    endpoint: _endpoint,
  ),
);
