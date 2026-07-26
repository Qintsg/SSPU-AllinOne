/*
 * 信息页布局测试 — 覆盖移动端紧凑控制区与分页高度
 * @Project : SSPU-AllinOne
 * @File : info_page_layout_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/models/message_item.dart';
import 'package:sspu_allinone/pages/info_page.dart';
import 'package:sspu_allinone/services/message_state_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/services/wxmp_config_service.dart';
import 'package:sspu_allinone/widgets/message_tile.dart';

void main() {
  late Directory configDirectory;

  setUp(() async {
    configDirectory = await Directory.systemTemp.createTemp(
      'info_page_layout_config_',
    );
    WxmpConfigService.instance.debugSetConfigPathForTesting(
      '${configDirectory.path}${Platform.pathSeparator}wxmp_config.toml',
    );
  });

  Future<void> configureView(
    WidgetTester tester, {
    required Size size,
    double topPadding = 0,
    double bottomPadding = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = FakeViewPadding(
      top: topPadding,
      bottom: bottomPadding,
    );
    tester.view.viewPadding = FakeViewPadding(
      top: topPadding,
      bottom: bottomPadding,
    );
    await tester.binding.setSurfaceSize(size);
  }

  Future<void> resetView(WidgetTester tester) async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetPadding();
    tester.view.resetViewPadding();
    await tester.binding.setSurfaceSize(null);
  }

  Future<void> pumpInfoPage(
    WidgetTester tester, {
    required Size size,
    int messageCount = 45,
    double topPadding = 0,
    double bottomPadding = 0,
  }) async {
    await configureView(
      tester,
      size: size,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
    );
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    final messageStateService = MessageStateService.instance;
    await messageStateService.setChannelEnabled('latest_info', true);
    await messageStateService.setChannelEnabled('notice', true);
    await messageStateService.setCategoryEnabled(
      MessageCategory.latestInfo.name,
      true,
    );
    await messageStateService.setCategoryEnabled(
      MessageCategory.notice.name,
      true,
    );
    await messageStateService.saveMessages(_buildMessages(messageCount));
    expect(await messageStateService.loadMessages(), hasLength(messageCount));

    await tester.pumpWidget(const YhApp(home: InfoPage()));

    await _pumpUntilFound(tester, find.byKey(const Key('info-message-list')));
    expect(tester.takeException(), isNull);
  }

  Future<void> pumpInfoFixture(
    WidgetTester tester, {
    required Size size,
    required InfoPageDisplayState displayState,
    List<MessageItem>? messages,
    VoidCallback? onOpenSourceSettings,
    bool filterEmptyOverride = false,
  }) async {
    await configureView(tester, size: size);
    await tester.pumpWidget(
      YhApp(
        home: InfoPage(
          displayStateOverride: displayState,
          messagesOverride: messages ?? const [],
          wechatSourceConfiguredOverride: true,
          nowOverride: DateTime(2026, 7, 18, 9, 30),
          onOpenSourceSettings: onOpenSourceSettings,
          filterEmptyOverride: filterEmptyOverride,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  testWidgets('资讯内容态按断点切换来源条与桌面来源面板', (tester) async {
    try {
      final messages = _buildMessages(3);
      await pumpInfoFixture(
        tester,
        size: const Size(390, 844),
        displayState: InfoPageDisplayState.content,
        messages: messages,
      );

      expect(find.text('校园资讯'), findsOneWidget);
      expect(find.byKey(const Key('info-status-row')), findsOneWidget);
      expect(
        find.byKey(const Key('info-compact-source-strip')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('info-source-panel')), findsNothing);
      expect(find.byKey(const Key('info-message-list')), findsOneWidget);

      await pumpInfoFixture(
        tester,
        size: const Size(1200, 900),
        displayState: InfoPageDisplayState.content,
        messages: messages,
      );
      expect(find.byKey(const Key('info-source-panel')), findsOneWidget);
      expect(find.byKey(const Key('info-compact-source-strip')), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetView(tester);
    }
  });

  testWidgets('资讯六类展示状态与筛选空态具有独立文案', (tester) async {
    try {
      const expected = <InfoPageDisplayState, String>{
        InfoPageDisplayState.initial: '尚未读取校园资讯',
        InfoPageDisplayState.loading: '正在读取校园资讯',
        InfoPageDisplayState.empty: '尚未认证可用的资讯来源',
        InfoPageDisplayState.error: '无法刷新校园资讯',
      };
      for (final entry in expected.entries) {
        await pumpInfoFixture(
          tester,
          size: const Size(768, 900),
          displayState: entry.key,
        );
        expect(find.text(entry.value), findsOneWidget);
        if (entry.key == InfoPageDisplayState.loading) {
          expect(find.byType(YhRing), findsOneWidget);
          expect(find.byType(YhProgress), findsNothing);
        } else {
          expect(find.byKey(const Key('info-state-icon')), findsOneWidget);
        }
      }

      await pumpInfoFixture(
        tester,
        size: const Size(768, 900),
        displayState: InfoPageDisplayState.stale,
        messages: _buildMessages(3),
      );
      expect(find.byKey(const Key('info-stale-banner')), findsOneWidget);
      expect(find.byKey(const Key('info-message-list')), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, '不存在的资讯');
      await tester.pump();
      expect(find.text('当前筛选没有结果'), findsOneWidget);
      expect(find.byKey(const Key('info-message-list')), findsNothing);

      await pumpInfoFixture(
        tester,
        size: const Size(768, 900),
        displayState: InfoPageDisplayState.content,
        messages: _buildMessages(3),
        filterEmptyOverride: true,
      );
      expect(find.byKey(const Key('info-filter-empty')), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
      );
      final theme = tester
          .element(find.byKey(const Key('info-filter-empty')))
          .yhTheme;
      expect(
        tester.getSize(find.byKey(const Key('info-filter-empty'))).height,
        theme.layout.popoverWidth + theme.spacing.xl,
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetView(tester);
    }
  });

  testWidgets('资讯未认证空态打开来源设置而非误触刷新', (tester) async {
    var openedSettings = false;
    try {
      await pumpInfoFixture(
        tester,
        size: const Size(390, 844),
        displayState: InfoPageDisplayState.empty,
        onOpenSourceSettings: () => openedSettings = true,
      );

      await tester.tap(find.text('来源与认证设置'));
      await tester.pump();

      expect(openedSettings, isTrue);
      final action = tester.widget<YhButton>(
        find.widgetWithText(YhButton, '来源与认证设置'),
      );
      expect(action.variant, YhButtonVariant.secondary);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetView(tester);
    }
  });

  tearDown(() async {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    WxmpConfigService.instance.debugSetConfigPathForTesting(null);
    SharedPreferences.setMockInitialValues({});
    await _deleteDirectoryWithRetry(configDirectory);
  });

  testWidgets('信息页移动端使用紧凑控制区并保留更多列表空间', (tester) async {
    try {
      await pumpInfoPage(tester, size: const Size(390, 844));

      final controls = find.byKey(const Key('info-mobile-controls'));
      final list = find.byKey(const Key('info-message-list'));
      final pagination = find.byKey(const Key('info-mobile-pagination'));

      expect(controls, findsOneWidget);
      expect(list, findsOneWidget);
      expect(pagination, findsOneWidget);
      expect(find.text('消息操作'), findsNothing);
      expect(
        tester.widget<Row>(controls).crossAxisAlignment,
        CrossAxisAlignment.start,
      );

      expect(tester.getSize(controls).height, lessThanOrEqualTo(160));
      expect(tester.getSize(pagination).height, 48);
      expect(tester.getSize(list).height, greaterThanOrEqualTo(280));
      expect(find.byType(MessageTile), findsAtLeastNWidgets(2));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetView(tester);
    }
  });

  testWidgets('信息页桌面端保留完整筛选操作区', (tester) async {
    try {
      await pumpInfoPage(tester, size: const Size(1200, 900));

      final controls = find.byKey(const Key('info-regular-controls'));
      final list = find.byKey(const Key('info-message-list'));
      final pagination = find.byKey(const Key('info-regular-pagination'));

      final title = find.text('校园资讯');

      expect(title, findsOneWidget);
      expect(find.text('消息操作'), findsNothing);
      expect(controls, findsOneWidget);
      expect(pagination, findsOneWidget);
      expect(find.byKey(const Key('info-mobile-controls')), findsNothing);
      expect(find.byKey(const Key('info-mobile-pagination')), findsNothing);
      expect(list, findsOneWidget);
      expect(
        tester.widget<Row>(controls).crossAxisAlignment,
        CrossAxisAlignment.start,
      );
      expect(tester.getSize(controls).height, lessThanOrEqualTo(144));
      expect(tester.getSize(pagination).height, 48);
      expect(tester.getSize(list).height, greaterThanOrEqualTo(380));
      expect(tester.getTopLeft(pagination).dy, greaterThan(760));
      expect(find.bySemanticsLabel('刷新校园资讯'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetView(tester);
    }
  });

  testWidgets('信息页移动端筛选弹窗不会触发滚动条控制器异常', (tester) async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    try {
      await pumpInfoPage(
        tester,
        size: const Size(390, 844),
        topPadding: 44,
        bottomPadding: 34,
      );

      final filterButton = find.byKey(const Key('info-mobile-filter-button'));
      await tester.ensureVisible(filterButton);
      await tester.pump();
      await tester.tap(filterButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('筛选消息'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
      await resetView(tester);
    }
  });

  testWidgets('信息页搜索与全部已读保持原有业务状态契约', (tester) async {
    try {
      await pumpInfoPage(tester, size: const Size(1200, 900), messageCount: 8);

      await tester.enterText(find.byType(EditableText).first, '测试消息 1');
      await tester.pump();
      expect(find.byType(MessageTile), findsOneWidget);

      await tester.tap(find.byKey(const Key('info-regular-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('全部标为已读'));
      await tester.pumpAndSettle();

      expect(MessageStateService.instance.isRead('layout-message-0'), isTrue);
      expect(find.textContaining('全部标为已读 (1)'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetView(tester);
    }
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> _deleteDirectoryWithRetry(Directory directory) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    if (!await directory.exists()) return;
    try {
      await directory.delete(recursive: true);
      return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
  }
}

List<MessageItem> _buildMessages(int count) {
  return [
    for (var i = 0; i < count; i++)
      MessageItem(
        id: 'layout-message-$i',
        title: '信息页移动端布局测试消息 ${i + 1}：这是一条用于验证列表可视面积的通知标题',
        date: '2026-06-${(i % 7 + 1).toString().padLeft(2, '0')}',
        url: 'https://www.sspu.edu.cn/layout-test-$i',
        sourceType: MessageSourceType.schoolWebsite,
        sourceName: MessageSourceName.infoDisclosure,
        category: i.isEven
            ? MessageCategory.latestInfo
            : MessageCategory.notice,
        timestamp: DateTime(
          2026,
          6,
          i % 7 + 1,
          12,
          i % 60,
        ).millisecondsSinceEpoch,
      ),
  ];
}
