/*
 * 校园卡详情布局测试 — 校验账本收束、紧凑操作协同与恢复状态宽度
 * @Project : SSPU-AllinOne
 * @File : home_campus_card_detail_layout_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/models/campus_card.dart';
import 'package:sspu_allinone/pages/home_page.dart';
import 'package:sspu_allinone/services/campus_card_service.dart';

/// 在给定尺寸和展示状态下构建确定性的校园卡详情页面。
///
/// :param tester: 当前 Widget 测试器。
/// :param size: 目标逻辑视口。
/// :param state: 固定展示状态。
/// :returns: 页面挂载完成时结束。
Future<void> _pumpCampusCardDetail(
  WidgetTester tester, {
  required Size size,
  CampusCardDetailDisplayState state = CampusCardDetailDisplayState.content,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    YhApp(
      home: CampusCardDetailPage(
        initialSnapshot: _campusCardSnapshot,
        campusCardService: CampusCardService.instance,
        nowOverride: DateTime(2026, 7, 18, 9, 30),
        displayStateOverride: state,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  tearDown(() {});

  testWidgets('扩展端将余额账本签与查询账本并置且不拉满余额卡', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpCampusCardDetail(tester, size: const Size(1200, 900));

    final balance = find.byKey(const Key('campus-card-balance-hero'));
    final dateField = find.byKey(const Key('campus-card-start-date'));
    final theme = tester.element(balance).yhTheme;
    final balanceRect = tester.getRect(balance);
    final dateRect = tester.getRect(dateField);

    expect(balanceRect.width, closeTo(theme.layout.popoverWidth, 0.1));
    expect(dateRect.left, greaterThan(balanceRect.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('紧凑端将日期、查询和同步组织为连续且可触控的操作流程', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpCampusCardDetail(tester, size: const Size(360, 800));

    final startDate = find.byKey(const Key('campus-card-start-date'));
    final endDate = find.byKey(const Key('campus-card-end-date'));
    final query = find.byKey(const Key('campus-card-apply-filter'));
    final sync = find.byKey(const Key('campus-card-sync-all'));
    final recent = find.byKey(const Key('campus-card-recent-seven-days'));

    expect(
      tester.getTopLeft(endDate).dy,
      greaterThan(tester.getTopLeft(startDate).dy),
    );
    expect(
      tester.getTopLeft(sync).dy,
      closeTo(tester.getTopLeft(query).dy, 0.1),
    );
    expect(tester.getSize(recent).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(query).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(sync).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('扩展端终端错误左锚定为紧凑恢复条并保留双行动', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpCampusCardDetail(
      tester,
      size: const Size(1200, 900),
      state: CampusCardDetailDisplayState.error,
    );

    final panel = find.byKey(const Key('campus-card-terminal-error'));
    final heading = find.text('只读校园卡');
    final retry = find.byKey(const Key('campus-card-retry-query'));
    final returnHome = find.widgetWithText(YhButton, '返回首页');
    final theme = tester.element(panel).yhTheme;

    expect(
      tester.getSize(panel).width,
      lessThanOrEqualTo(theme.layout.formContentWidth),
    );
    expect(
      tester.getRect(panel).left,
      closeTo(tester.getRect(heading).left, 0.1),
    );
    expect(tester.getSize(panel).height, lessThan(theme.control.touch * 3));
    expect(
      tester.getSize(retry).height,
      greaterThanOrEqualTo(theme.control.touch),
    );
    expect(
      tester.getSize(returnHome).height,
      greaterThanOrEqualTo(theme.control.touch),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('紧凑端终端错误标题不拆行且双恢复操作连续可达', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpCampusCardDetail(
      tester,
      size: const Size(360, 800),
      state: CampusCardDetailDisplayState.error,
    );

    final title = find.text('暂时无法读取校园卡记录');
    final retry = find.byKey(const Key('campus-card-retry-query'));
    final returnHome = find.widgetWithText(YhButton, '返回首页');
    final theme = tester.element(title).yhTheme;

    expect(tester.getSize(title).height, lessThan(theme.control.touch));
    expect(
      tester.getTopLeft(returnHome).dy,
      closeTo(tester.getTopLeft(retry).dy, 0.1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('空交易结果在扩展端左锚定为紧凑的筛选恢复条', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpCampusCardDetail(
      tester,
      size: const Size(1200, 900),
      state: CampusCardDetailDisplayState.empty,
    );

    final panel = find.byKey(const Key('campus-card-empty-panel'));
    final balance = find.byKey(const Key('campus-card-balance-hero'));
    final clear = find.widgetWithText(YhButton, '清除筛选');
    final theme = tester.element(panel).yhTheme;

    expect(
      tester.getRect(panel).left,
      closeTo(tester.getRect(balance).left, 0.1),
    );
    expect(
      tester.getSize(panel).width,
      lessThanOrEqualTo(theme.layout.formContentWidth),
    );
    expect(tester.getSize(panel).height, lessThan(theme.control.touch * 3));
    expect(
      tester.getSize(clear).height,
      greaterThanOrEqualTo(theme.control.touch),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('空交易结果在紧凑端保持纵向说明与可触控恢复操作', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpCampusCardDetail(
      tester,
      size: const Size(360, 800),
      state: CampusCardDetailDisplayState.empty,
    );

    final panel = find.byKey(const Key('campus-card-empty-panel'));
    final clear = find.widgetWithText(YhButton, '清除筛选');

    expect(
      tester.getTopLeft(clear).dy,
      greaterThan(tester.getTopLeft(panel).dy),
    );
    expect(tester.getSize(clear).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });
}

final CampusCardSnapshot _campusCardSnapshot = CampusCardSnapshot(
  balance: 128.5,
  status: '正常',
  fetchedAt: DateTime(2026, 7, 18, 9, 30),
  sourceUri: Uri.parse('https://card.example.invalid/'),
  records: const [
    CampusCardTransactionRecord(
      occurredAt: '2026-07-18 08:12',
      amount: -18.5,
      title: '一食堂 · POS 消费',
      paymentMethod: '校园卡',
      status: '成功',
      rawCells: ['2026-07-18 08:12', '-18.50'],
    ),
  ],
);
