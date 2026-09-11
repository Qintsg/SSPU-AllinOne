import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/models/campus_card.dart';
import 'package:sspu_allinone/pages/campus_consumption_analytics_page.dart';

void main() {
  final snapshot = CampusCardSnapshot(
    balance: 42,
    status: '正常',
    fetchedAt: DateTime(2026, 9, 30),
    sourceUri: Uri.parse('https://example.invalid/card'),
    records: [
      CampusCardTransactionRecord(
        occurredAt: '2026-09-01',
        amount: -1.5,
        rawCells: [],
      ),
      CampusCardTransactionRecord(
        occurredAt: '2026-09-15',
        amount: -2.5,
        rawCells: [],
      ),
    ],
  );

  testWidgets('消费趋势支持自定义范围和聚合粒度切换', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: CampusConsumptionAnalyticsPage(
          snapshot: snapshot,
          nowOverride: DateTime(2026, 9, 30),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('自定义'));
    await tester.pump();
    final fields = find.byType(EditableText);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), '2026-09-01');
    await tester.enterText(fields.at(1), '2026-09-30');
    await tester.tap(find.text('应用日期范围'));
    await tester.pump();
    expect(find.text('共 2 笔 · ¥4.00'), findsOneWidget);

    await tester.tap(find.text('按月'));
    await tester.pump();
    expect(find.text('9/1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('非法自定义范围保留上一次有效趋势', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: CampusConsumptionAnalyticsPage(
          snapshot: snapshot,
          nowOverride: DateTime(2026, 9, 30),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('自定义'));
    await tester.pump();
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), '2026-09-01');
    await tester.enterText(fields.at(1), '2026-09-30');
    await tester.tap(find.text('应用日期范围'));
    await tester.pump();
    expect(find.text('共 2 笔 · ¥4.00'), findsOneWidget);

    await tester.enterText(fields.at(0), '2026-10-01');
    await tester.enterText(fields.at(1), '2026-09-30');
    await tester.tap(find.text('应用日期范围'));
    await tester.pump();

    expect(find.text('开始日期不能晚于结束日期。'), findsNWidgets(2));
    expect(find.text('共 2 笔 · ¥4.00'), findsOneWidget);
  });
}
