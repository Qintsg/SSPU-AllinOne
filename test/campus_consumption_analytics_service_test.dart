import 'package:flutter_test/flutter_test.dart';

import 'package:sspu_allinone/models/campus_card.dart';
import 'package:sspu_allinone/services/campus_consumption_analytics_service.dart';

void main() {
  test('按日聚合支出并避免浮点误差', () {
    final records = [
      const CampusCardTransactionRecord(
        occurredAt: '2026-09-01 08:00',
        amount: -1.10,
        rawCells: [],
      ),
      const CampusCardTransactionRecord(
        occurredAt: '2026年09月01日 12:00',
        amount: -2.20,
        rawCells: [],
      ),
      const CampusCardTransactionRecord(
        occurredAt: '2026-09-02',
        amount: 10,
        rawCells: [],
      ),
    ];
    final trend = CampusConsumptionAnalyticsService.aggregate(
      records: records,
      window: CampusConsumptionWindow.all,
      now: DateTime(2026, 9, 3),
    );
    expect(trend.buckets, hasLength(1));
    expect(trend.buckets.single.totalCents, 330);
    expect(trend.totalAmount, 3.3);
    expect(trend.transactionCount, 2);
  });

  test('近 7 天窗口按今天截断范围', () {
    final records = [
      const CampusCardTransactionRecord(
        occurredAt: '2026-08-27',
        amount: -1,
        rawCells: [],
      ),
      const CampusCardTransactionRecord(
        occurredAt: '2026-08-28',
        amount: -2,
        rawCells: [],
      ),
      const CampusCardTransactionRecord(
        occurredAt: '2026-09-01',
        amount: -3,
        rawCells: [],
      ),
    ];
    final trend = CampusConsumptionAnalyticsService.aggregate(
      records: records,
      window: CampusConsumptionWindow.last7Days,
      now: DateTime(2026, 9, 3),
    );
    expect(trend.buckets.map((bucket) => bucket.start.day), [28, 1]);
    expect(trend.totalCents, 500);
  });

  test('自定义日期范围支持按周和按月聚合', () {
    final records = [
      const CampusCardTransactionRecord(
        occurredAt: '2026-09-01',
        amount: -1,
        rawCells: [],
      ),
      const CampusCardTransactionRecord(
        occurredAt: '2026-09-07',
        amount: -2,
        rawCells: [],
      ),
      const CampusCardTransactionRecord(
        occurredAt: '2026-10-01',
        amount: -3,
        rawCells: [],
      ),
    ];
    final weekly = CampusConsumptionAnalyticsService.aggregate(
      records: records,
      window: CampusConsumptionWindow.custom,
      rangeStart: DateTime(2026, 9, 1),
      rangeEnd: DateTime(2026, 9, 30),
      bucketUnit: CampusConsumptionBucketUnit.week,
    );
    expect(weekly.buckets.map((bucket) => bucket.start), [
      DateTime(2026, 8, 31),
      DateTime(2026, 9, 7),
    ]);
    expect(weekly.totalCents, 300);

    final monthly = CampusConsumptionAnalyticsService.aggregate(
      records: records,
      window: CampusConsumptionWindow.custom,
      rangeStart: DateTime(2026, 9, 1),
      rangeEnd: DateTime(2026, 10, 31),
      bucketUnit: CampusConsumptionBucketUnit.month,
    );
    expect(monthly.buckets.map((bucket) => bucket.start), [
      DateTime(2026, 9),
      DateTime(2026, 10),
    ]);
  });

  test('相同流水号及完全相同的无流水记录只统计一次', () {
    final records = [
      const CampusCardTransactionRecord(
        occurredAt: '2026-09-01 08:00',
        amount: -6.50,
        merchant: '第一食堂',
        transactionId: 'trade-001',
        rawCells: ['trade-001', '第一食堂', '-6.50'],
      ),
      const CampusCardTransactionRecord(
        occurredAt: '2026-09-01 08:00',
        amount: -6.50,
        merchant: '第一食堂',
        transactionId: 'trade-001',
        rawCells: ['trade-001', '第一食堂', '-6.50'],
      ),
      const CampusCardTransactionRecord(
        occurredAt: '2026-09-02 12:00',
        amount: -3,
        merchant: '自动售货机',
        rawCells: ['2026-09-02 12:00', '自动售货机', '-3.00'],
      ),
      const CampusCardTransactionRecord(
        occurredAt: '2026-09-02 12:00',
        amount: -3,
        merchant: '自动售货机',
        rawCells: ['2026-09-02 12:00', '自动售货机', '-3.00'],
      ),
    ];

    final trend = CampusConsumptionAnalyticsService.aggregate(
      records: records,
      window: CampusConsumptionWindow.all,
      now: DateTime(2026, 9, 3),
    );

    expect(trend.transactionCount, 2);
    expect(trend.totalCents, 950);
  });
}
