/// 校园卡消费趋势的单个时间桶。
class CampusConsumptionTrendBucket {
  const CampusConsumptionTrendBucket({
    required this.start,
    required this.totalCents,
    required this.transactionCount,
  });

  final DateTime start;
  final int totalCents;
  final int transactionCount;

  double get totalAmount => totalCents / 100;
}

/// 一段时间内的本地消费趋势。
class CampusConsumptionTrend {
  const CampusConsumptionTrend({
    required this.start,
    required this.end,
    required this.buckets,
  });

  final DateTime? start;
  final DateTime? end;
  final List<CampusConsumptionTrendBucket> buckets;

  int get totalCents =>
      buckets.fold(0, (sum, bucket) => sum + bucket.totalCents);
  double get totalAmount => totalCents / 100;
  int get transactionCount =>
      buckets.fold(0, (sum, bucket) => sum + bucket.transactionCount);
}
