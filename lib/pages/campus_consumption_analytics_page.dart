import '../design/qingyuan/qingyuan_ui.dart';
import '../models/campus_card.dart';
import '../models/campus_consumption_trend.dart';
import '../services/campus_consumption_analytics_service.dart';

/// 校园卡消费趋势页，仅对已缓存交易做本地统计。
class CampusConsumptionAnalyticsPage extends StatefulWidget {
  const CampusConsumptionAnalyticsPage({
    super.key,
    required this.snapshot,
    this.nowOverride,
  });

  final CampusCardSnapshot snapshot;
  final DateTime? nowOverride;

  @override
  State<CampusConsumptionAnalyticsPage> createState() =>
      _CampusConsumptionAnalyticsPageState();
}

class _CampusConsumptionAnalyticsPageState
    extends State<CampusConsumptionAnalyticsPage> {
  CampusConsumptionWindow _window = CampusConsumptionWindow.all;
  CampusConsumptionBucketUnit _bucketUnit = CampusConsumptionBucketUnit.day;
  final TextEditingController _customStartController = TextEditingController();
  final TextEditingController _customEndController = TextEditingController();
  DateTime? _appliedCustomStart;
  DateTime? _appliedCustomEnd;
  CampusConsumptionWindow _lastNonCustomWindow = CampusConsumptionWindow.all;
  String? _customRangeError;

  CampusConsumptionTrend get _trend {
    final hasAppliedCustomRange =
        _appliedCustomStart != null && _appliedCustomEnd != null;
    return CampusConsumptionAnalyticsService.aggregate(
      records: widget.snapshot.records,
      window:
          _window == CampusConsumptionWindow.custom && !hasAppliedCustomRange
          ? _lastNonCustomWindow
          : _window,
      rangeStart: _appliedCustomStart,
      rangeEnd: _appliedCustomEnd,
      bucketUnit: _bucketUnit,
      now: widget.nowOverride,
    );
  }

  @override
  void dispose() {
    _customStartController.dispose();
    _customEndController.dispose();
    super.dispose();
  }

  void _applyCustomRange() {
    final startText = _customStartController.text.trim();
    final endText = _customEndController.text.trim();
    final start = _parseDate(startText);
    final end = _parseDate(endText);
    String? error;
    if (start == null || end == null) {
      error = '请输入完整日期，格式为 yyyy-MM-dd。';
    } else if (start.isAfter(end)) {
      error = '开始日期不能晚于结束日期。';
    }
    setState(() {
      _customRangeError = error;
      if (error == null) {
        _appliedCustomStart = start;
        _appliedCustomEnd = end;
      }
    });
  }

  void _selectWindow(CampusConsumptionWindow window) {
    setState(() {
      _window = window;
      _customRangeError = null;
      if (window != CampusConsumptionWindow.custom) {
        _lastNonCustomWindow = window;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final trend = _trend;
    final maxCents = trend.buckets.fold<int>(
      0,
      (max, bucket) => bucket.totalCents > max ? bucket.totalCents : max,
    );
    return YhPageScaffold(
      appBar: YhAppBar(
        title: '消费趋势',
        leading: YhIconButton(
          icon: YhIcons.back,
          semanticLabel: '返回',
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: theme.layout.pageContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.all(theme.spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('本地消费统计', style: theme.typography.h1),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    '仅使用已缓存的支出记录，不会发起网络请求。',
                    style: theme.typography.body.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                  SizedBox(height: theme.spacing.l),
                  Wrap(
                    spacing: theme.spacing.s,
                    children: [
                      for (final window in CampusConsumptionWindow.values)
                        YhButton(
                          label: _windowLabel(window),
                          variant: window == _window
                              ? YhButtonVariant.primary
                              : YhButtonVariant.secondary,
                          onTap: () => _selectWindow(window),
                        ),
                    ],
                  ),
                  if (_window == CampusConsumptionWindow.custom) ...[
                    SizedBox(height: theme.spacing.m),
                    Wrap(
                      spacing: theme.spacing.s,
                      runSpacing: theme.spacing.s,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        SizedBox(
                          width: theme.layout.compactContentWidth,
                          child: YhTextField(
                            label: '开始日期',
                            controller: _customStartController,
                            hint: '2026-09-01',
                            prefixIcon: YhIcons.calendar,
                            errorText: _customRangeError,
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                        SizedBox(
                          width: theme.layout.compactContentWidth,
                          child: YhTextField(
                            label: '结束日期',
                            controller: _customEndController,
                            hint: '2026-09-30',
                            prefixIcon: YhIcons.calendar,
                            errorText: _customRangeError,
                            keyboardType: TextInputType.datetime,
                            onSubmitted: (_) => _applyCustomRange(),
                          ),
                        ),
                        YhButton(label: '应用日期范围', onTap: _applyCustomRange),
                      ],
                    ),
                  ],
                  SizedBox(height: theme.spacing.m),
                  Wrap(
                    spacing: theme.spacing.s,
                    children: [
                      for (final unit in CampusConsumptionBucketUnit.values)
                        YhButton(
                          label: _bucketUnitLabel(unit),
                          variant: unit == _bucketUnit
                              ? YhButtonVariant.primary
                              : YhButtonVariant.secondary,
                          onTap: () => setState(() => _bucketUnit = unit),
                        ),
                    ],
                  ),
                  SizedBox(height: theme.spacing.l),
                  YhCard(
                    child: trend.buckets.isEmpty
                        ? const _AnalyticsEmptyState()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '共 ${trend.transactionCount} 笔 · ¥${trend.totalAmount.toStringAsFixed(2)}',
                                style: theme.typography.h3,
                              ),
                              SizedBox(height: theme.spacing.m),
                              for (final bucket in trend.buckets) ...[
                                Row(
                                  children: [
                                    SizedBox(
                                      width: theme.spacing.xl2,
                                      child: Text(
                                        _formatDate(bucket.start),
                                        style: theme.typography.small,
                                      ),
                                    ),
                                    SizedBox(width: theme.spacing.s),
                                    Expanded(
                                      child: Container(
                                        height: theme.spacing.s,
                                        decoration: BoxDecoration(
                                          color: theme.color.sunken,
                                          borderRadius: BorderRadius.circular(
                                            theme.radius.s,
                                          ),
                                        ),
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: FractionallySizedBox(
                                          widthFactor: maxCents == 0
                                              ? 0
                                              : bucket.totalCents / maxCents,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: theme.color.serviceFinance,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    theme.radius.s,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: theme.spacing.s),
                                    Text(
                                      '¥${bucket.totalAmount.toStringAsFixed(2)}',
                                      style: theme.typography.small,
                                    ),
                                  ],
                                ),
                                SizedBox(height: theme.spacing.s),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _windowLabel(CampusConsumptionWindow window) => switch (window) {
    CampusConsumptionWindow.all => '全部',
    CampusConsumptionWindow.last7Days => '近 7 天',
    CampusConsumptionWindow.last30Days => '近 30 天',
    CampusConsumptionWindow.custom => '自定义',
  };

  String _bucketUnitLabel(CampusConsumptionBucketUnit unit) => switch (unit) {
    CampusConsumptionBucketUnit.day => '按日',
    CampusConsumptionBucketUnit.week => '按周',
    CampusConsumptionBucketUnit.month => '按月',
  };

  String _formatDate(DateTime value) => '${value.month}/${value.day}';

  DateTime? _parseDate(String source) {
    final match = RegExp(
      r'^(20\d{2})-(\d{1,2})-(\d{1,2})$',
    ).firstMatch(source.trim());
    if (match == null) return null;
    final value = DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    if (value.year != int.parse(match.group(1)!) ||
        value.month != int.parse(match.group(2)!) ||
        value.day != int.parse(match.group(3)!)) {
      return null;
    }
    return value;
  }
}

class _AnalyticsEmptyState extends StatelessWidget {
  const _AnalyticsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.all(theme.spacing.l),
      child: Column(
        children: [
          Text('暂无可统计的消费记录', style: theme.typography.h3),
          SizedBox(height: theme.spacing.xs),
          Text(
            '同步校园卡交易记录后，这里会按日期展示消费趋势。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
