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
import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:sspu_allinone/models/message_item.dart';
import 'package:sspu_allinone/pages/info_page.dart';
import 'package:sspu_allinone/services/message_state_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/services/wxmp_config_service.dart';
import 'package:sspu_allinone/theme/app_theme.dart';
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

  Future<void> configureView(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(size);
  }

  Future<void> resetView(WidgetTester tester) async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  }

  Future<void> pumpInfoPage(
    WidgetTester tester, {
    required Size size,
    int messageCount = 45,
  }) async {
    await configureView(tester, size: size);
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

    await tester.pumpWidget(
      FluentApp(
        theme: AppTheme.build(Brightness.light),
        home: const InfoPage(),
      ),
    );

    await _pumpUntilFound(tester, find.byKey(const Key('info-message-list')));
  }

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

      expect(tester.getSize(controls).height, lessThanOrEqualTo(144));
      expect(tester.getSize(pagination).height, lessThanOrEqualTo(56));
      expect(tester.getSize(list).height, greaterThanOrEqualTo(430));
      expect(find.byType(MessageTile), findsAtLeastNWidgets(5));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetView(tester);
    }
  });

  testWidgets('信息页桌面端保留完整筛选操作区', (tester) async {
    try {
      await pumpInfoPage(tester, size: const Size(1200, 900));

      expect(find.text('消息操作'), findsOneWidget);
      expect(find.byKey(const Key('info-mobile-controls')), findsNothing);
      expect(find.byKey(const Key('info-mobile-pagination')), findsNothing);
      expect(find.byKey(const Key('info-message-list')), findsOneWidget);
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
