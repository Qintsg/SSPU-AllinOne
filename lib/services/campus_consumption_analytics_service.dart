import '../models/campus_card.dart';
import '../models/campus_consumption_trend.dart';

enum CampusConsumptionWindow { all, last7Days, last30Days, custom }

/// 消费趋势时间桶粒度。
enum CampusConsumptionBucketUnit { day, week, month }

/// 在本地对校园卡支出记录进行定点金额聚合。
class CampusConsumptionAnalyticsService {
  const CampusConsumptionAnalyticsService._();

  static CampusConsumptionTrend aggregate({
    required Iterable<CampusCardTransactionRecord> records,
    required CampusConsumptionWindow window,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    CampusConsumptionBucketUnit bucketUnit = CampusConsumptionBucketUnit.day,
    DateTime? now,
  }) {
    final seenRecordIds = <String>{};
    final parsed = records
        .map((record) => (record: record, date: _parseDate(record.occurredAt)))
        .where(
          (item) =>
              item.date != null &&
              item.record.isExpense &&
              seenRecordIds.add(_recordIdentity(item.record)),
        )
        .toList();
    if (parsed.isEmpty) {
      return const CampusConsumptionTrend(start: null, end: null, buckets: []);
    }
    if (window == CampusConsumptionWindow.custom &&
        (rangeStart == null || rangeEnd == null)) {
      return const CampusConsumptionTrend(start: null, end: null, buckets: []);
    }
    parsed.sort((a, b) => a.date!.compareTo(b.date!));
    final today = _dateOnly(now ?? DateTime.now());
    final first = switch (window) {
      CampusConsumptionWindow.last7Days => today.subtract(
        const Duration(days: 6),
      ),
      CampusConsumptionWindow.last30Days => today.subtract(
        const Duration(days: 29),
      ),
      CampusConsumptionWindow.all => _dateOnly(parsed.first.date!),
      CampusConsumptionWindow.custom => _dateOnly(
        rangeStart ?? parsed.first.date!,
      ),
    };
    final end = switch (window) {
      CampusConsumptionWindow.all => _dateOnly(parsed.last.date!),
      CampusConsumptionWindow.custom => _dateOnly(rangeEnd ?? today),
      _ => today,
    };
    if (first.isAfter(end)) {
      return const CampusConsumptionTrend(start: null, end: null, buckets: []);
    }
    final buckets = <DateTime, _MutableBucket>{};
    for (final item in parsed) {
      final date = _dateOnly(item.date!);
      if (date.isBefore(first) || date.isAfter(end)) continue;
      final cents = (item.record.amount.abs() * 100).round();
      final bucketStart = _bucketStart(date, bucketUnit);
      final bucket = buckets.putIfAbsent(bucketStart, _MutableBucket.new);
      bucket.totalCents += cents;
      bucket.count++;
    }
    final ordered = buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return CampusConsumptionTrend(
      start: first,
      end: end,
      buckets: List.unmodifiable([
        for (final entry in ordered)
          CampusConsumptionTrendBucket(
            start: entry.key,
            totalCents: entry.value.totalCents,
            transactionCount: entry.value.count,
          ),
      ]),
    );
  }

  static DateTime _bucketStart(
    DateTime date,
    CampusConsumptionBucketUnit unit,
  ) {
    final day = _dateOnly(date);
    return switch (unit) {
      CampusConsumptionBucketUnit.day => day,
      CampusConsumptionBucketUnit.week => day.subtract(
        Duration(days: day.weekday - DateTime.monday),
      ),
      CampusConsumptionBucketUnit.month => DateTime(day.year, day.month),
    };
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime? _parseDate(String source) {
    final match = RegExp(
      r'(20\d{2})[-年./](\d{1,2})[-月./](\d{1,2})',
    ).firstMatch(source);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  /// 流水号优先；旧记录没有流水号时，用完整展示字段构造稳定签名。
  static String _recordIdentity(CampusCardTransactionRecord record) {
    final transactionId = record.transactionId?.trim();
    if (transactionId != null && transactionId.isNotEmpty) {
      return 'transaction:$transactionId';
    }
    final cents = (record.amount * 100).round();
    return <Object?>[
      record.occurredAt.trim(),
      cents,
      record.merchant?.trim(),
      record.type?.trim(),
      record.balanceAfter == null ? null : (record.balanceAfter! * 100).round(),
      record.title?.trim(),
      record.counterparty?.trim(),
      record.paymentMethod?.trim(),
      record.status?.trim(),
      record.direction?.trim(),
      record.rawCells.join('\u001f'),
    ].join('\u001e');
  }
}

class _MutableBucket {
  int totalCents = 0;
  int count = 0;
}
