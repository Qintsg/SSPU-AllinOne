/*
 * 清源数据与隐私任务页测试
 * @Project : SSPU-AllinOne
 * @File : settings_data_privacy_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/settings_data_privacy_page.dart';
import 'package:sspu_allinone/widgets/settings_security_section.dart';

void main() {
  testWidgets('数据与隐私任务页呈现三项本地数据任务并保留真实行动', (tester) async {
    var clearedCache = false;
    var disconnected = false;
    var openedPrivacy = false;

    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          onClearCampusCache: () async {
            clearedCache = true;
            return true;
          },
          onDisconnectAccounts: () async {
            disconnected = true;
            return true;
          },
          onOpenPrivacy: () => openedPrivacy = true,
        ),
      ),
    );

    expect(find.text('数据与隐私'), findsOneWidget);
    expect(find.text('本机存储'), findsWidgets);
    expect(find.text('清除校园缓存'), findsOneWidget);
    expect(find.text('断开账户连接'), findsOneWidget);
    expect(find.text('查看隐私说明'), findsOneWidget);
    expect(find.text('清除'), findsOneWidget);
    expect(find.text('断开'), findsOneWidget);
    expect(find.text('查看'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('清除：清除校园缓存'));
    await tester.pump();
    expect(clearedCache, isTrue);
    expect(disconnected, isFalse);
    expect(openedPrivacy, isFalse);
  });

  testWidgets('管理本地数据先打开任务选择而不直接执行清理', (tester) async {
    var clearedCache = false;

    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          onClearCampusCache: () async {
            clearedCache = true;
            return true;
          },
          onDisconnectAccounts: () async => true,
          onOpenPrivacy: () {},
          onClearAllData: () async => true,
        ),
      ),
    );

    await tester.tap(find.text('管理本地数据'));
    await tester.pumpAndSettle();

    expect(clearedCache, isFalse);
    expect(find.text('本地数据操作'), findsOneWidget);
    expect(find.text('清除校园缓存'), findsNWidgets(2));
    expect(find.text('清除全部本地数据'), findsOneWidget);
  });

  testWidgets('旧安全分区只保留数据与隐私摘要入口', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacySummary(onOpenDetails: () => opened = true),
      ),
    );

    expect(find.text('本机数据与账户连接'), findsOneWidget);
    expect(find.text('清除校园缓存'), findsNothing);
    await tester.tap(find.text('打开数据与隐私'));
    await tester.pump();
    expect(opened, isTrue);
  });

  testWidgets('结构化任务账本在大屏使用流体面板', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          onClearCampusCache: () async => true,
          onDisconnectAccounts: () async => true,
          onOpenPrivacy: () {},
        ),
      ),
    );

    final sectionSize = tester.getSize(find.byType(SettingsDataPrivacySection));
    expect(
      sectionSize.width,
      greaterThan(YhTheme.light.layout.pageContentWidth),
    );
    expect(sectionSize.height, lessThan(360));
  });

  testWidgets('本地数据操作执行中禁用全部入口并在完成后恢复', (tester) async {
    final completion = Completer<bool>();
    var operationCount = 0;
    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          onClearCampusCache: () {
            operationCount += 1;
            return completion.future;
          },
          onDisconnectAccounts: () async => true,
          onOpenPrivacy: () {},
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('清除：清除校园缓存'));
    await tester.pump();

    expect(find.text('处理中'), findsNWidgets(3));
    await tester.tap(find.bySemanticsLabel('管理本地数据'));
    await tester.pumpAndSettle();
    expect(find.text('本地数据操作'), findsOneWidget);
    final disabledClearButton = find.byWidgetPredicate(
      (widget) => widget is YhButton && widget.label == '清除校园缓存',
    );
    expect(
      tester.getSemantics(disabledClearButton).flagsCollection.isEnabled,
      Tristate.isFalse,
    );
    expect(operationCount, 1);

    Navigator.of(tester.element(find.text('本地数据操作'))).pop();
    await tester.pumpAndSettle();

    completion.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('清除'), findsOneWidget);
    expect(find.text('断开'), findsOneWidget);
    expect(find.text('查看'), findsOneWidget);
  });

  testWidgets('取消危险确认后不标记完成也不进入错误态', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          onClearCampusCache: () async => false,
          onDisconnectAccounts: () async => true,
          onOpenPrivacy: () {},
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('清除：清除校园缓存'));
    await tester.pumpAndSettle();

    expect(find.text('清除'), findsOneWidget);
    expect(find.text('断开'), findsOneWidget);
    expect(find.text('查看'), findsOneWidget);
    expect(find.textContaining('已完成：'), findsNothing);
    expect(find.textContaining('本次操作未完成'), findsNothing);
  });

  testWidgets('本地数据操作失败进入可重试错误态', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          onClearCampusCache: () async => throw StateError('storage failed'),
          onDisconnectAccounts: () async => true,
          onOpenPrivacy: () {},
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('清除：清除校园缓存'));
    await tester.pumpAndSettle();

    expect(find.textContaining('本次操作未完成'), findsOneWidget);
    expect(find.text('未完成：清除校园缓存'), findsOneWidget);
    expect(find.bySemanticsLabel('重试：清除校园缓存'), findsOneWidget);
  });

  testWidgets('生产状态加载后每行展示实际缓存与连接摘要', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          onClearCampusCache: () async => true,
          onDisconnectAccounts: () async => true,
          onOpenPrivacy: () {},
          loadSnapshot: () async => const SettingsDataPrivacySnapshot(
            cacheStatus: '已保存校园与信息缓存',
            accountStatus: '已连接：OA、邮箱',
            privacyStatus: '随应用提供，可离线查看',
          ),
        ),
      ),
    );

    expect(find.text('正在读取本机数据与账户状态。'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('已保存校园与信息缓存'), findsOneWidget);
    expect(find.text('已连接：OA、邮箱'), findsOneWidget);
    expect(find.text('随应用提供，可离线查看'), findsOneWidget);
  });

  testWidgets('多步数据操作失败逐项披露已完成与未完成内容', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          onClearCampusCache: () async =>
              throw const SettingsDataPrivacyOperationException(
                completedItems: ['校园业务缓存'],
                remainingItems: ['信息中心消息缓存', '信息中心已读状态'],
              ),
          onDisconnectAccounts: () async => true,
          onOpenPrivacy: () {},
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('清除：清除校园缓存'));
    await tester.pumpAndSettle();

    expect(find.textContaining('已完成：校园业务缓存'), findsOneWidget);
    expect(find.textContaining('未完成：信息中心消息缓存、信息中心已读状态'), findsOneWidget);
  });

  testWidgets('已完成项的查看行为只打开结果而不重复清除', (tester) async {
    var clearCount = 0;
    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          state: SettingsDataPrivacyState.error,
          onClearCampusCache: () async {
            clearCount += 1;
            return true;
          },
          onDisconnectAccounts: () async => true,
          onOpenPrivacy: () {},
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('查看：清除校园缓存'));
    await tester.pumpAndSettle();

    expect(clearCount, 0);
    expect(find.text('已完成项目'), findsOneWidget);
    expect(find.text('清除校园缓存'), findsWidgets);
  });

  testWidgets('操作成功后重载状态并保持单次执行', (tester) async {
    var loadCount = 0;
    var operationCount = 0;
    Future<SettingsDataPrivacySnapshot> loadSnapshot() async {
      loadCount += 1;
      return SettingsDataPrivacySnapshot(
        cacheStatus: loadCount == 1 ? '已保存校园缓存' : '当前无校园或信息缓存',
        accountStatus: '当前未连接账户',
        privacyStatus: '随应用提供，可离线查看',
      );
    }

    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          onClearCampusCache: () async {
            operationCount += 1;
            return true;
          },
          onDisconnectAccounts: () async => true,
          onOpenPrivacy: () {},
          loadSnapshot: loadSnapshot,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('清除：清除校园缓存'));
    await tester.pumpAndSettle();

    expect(operationCount, 1);
    expect(loadCount, 2);
    expect(find.text('当前无校园或信息缓存'), findsOneWidget);
  });

  testWidgets('状态读取失败时隐私说明仍可直接打开', (tester) async {
    var openedPrivacy = false;
    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          onClearCampusCache: () async => true,
          onDisconnectAccounts: () async => true,
          onOpenPrivacy: () => openedPrivacy = true,
          loadSnapshot: () async => throw StateError('unavailable'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('无法读取本机数据'), findsOneWidget);
    expect(find.text('状态暂不可用'), findsNWidgets(2));
    expect(find.textContaining('未完成：'), findsNothing);
    await tester.tap(find.bySemanticsLabel('查看：查看隐私说明'));
    await tester.pump();
    expect(openedPrivacy, isTrue);
  });

  testWidgets('操作成功但状态刷新失败时不允许重复删除', (tester) async {
    var loadCount = 0;
    var operationCount = 0;
    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          onClearCampusCache: () async {
            operationCount += 1;
            return true;
          },
          onDisconnectAccounts: () async => true,
          onOpenPrivacy: () {},
          loadSnapshot: () async {
            loadCount += 1;
            if (loadCount > 1) throw StateError('refresh failed');
            return const SettingsDataPrivacySnapshot(
              cacheStatus: '已保存校园缓存',
              accountStatus: '当前未连接账户',
              privacyStatus: '随应用提供，可离线查看',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('清除：清除校园缓存'));
    await tester.pumpAndSettle();

    expect(operationCount, 1);
    expect(find.textContaining('操作已完成，但未能刷新'), findsOneWidget);
    expect(find.bySemanticsLabel('查看：清除校园缓存'), findsOneWidget);
    expect(find.bySemanticsLabel('重试：清除校园缓存'), findsNothing);
  });

  testWidgets('状态加载器换代后采用新快照且旧结果不得回写', (tester) async {
    final oldSnapshot = Completer<SettingsDataPrivacySnapshot>();
    Future<bool> stableClear() async => true;
    Future<bool> stableDisconnect() async => true;
    void stableOpenPrivacy() {}

    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          loadSnapshot: () => oldSnapshot.future,
          onClearCampusCache: stableClear,
          onDisconnectAccounts: stableDisconnect,
          onOpenPrivacy: stableOpenPrivacy,
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacyPage(
          loadSnapshot: () async => const SettingsDataPrivacySnapshot(
            cacheStatus: '新快照缓存',
            accountStatus: '新快照账户',
            privacyStatus: '新快照隐私说明',
          ),
          onClearCampusCache: stableClear,
          onDisconnectAccounts: stableDisconnect,
          onOpenPrivacy: stableOpenPrivacy,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('新快照缓存'), findsOneWidget);

    oldSnapshot.complete(
      const SettingsDataPrivacySnapshot(
        cacheStatus: '旧快照缓存',
        accountStatus: '旧快照账户',
        privacyStatus: '旧快照隐私说明',
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('新快照缓存'), findsOneWidget);
    expect(find.text('旧快照缓存'), findsNothing);
  });
}
