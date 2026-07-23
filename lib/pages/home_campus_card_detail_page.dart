/*
 * 主页校园卡详情页 — 校园卡余额与交易记录只读展示
 * @Project : SSPU-AllinOne
 * @File : home_campus_card_detail_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'home_page.dart';

/// 校园卡详情页的确定性展示状态，仅用于视觉 fixture 与状态回归测试。
enum CampusCardDetailDisplayState { content, empty, error }

/// 校园卡余额与交易记录详情页。
class CampusCardDetailPage extends StatefulWidget {
  const CampusCardDetailPage({
    super.key,
    required this.initialSnapshot,
    required this.campusCardService,
    this.nowOverride,
    this.displayStateOverride,
  });

  /// 首页已读取的校园卡快照。
  final CampusCardSnapshot initialSnapshot;

  /// 校园卡查询服务，保留现有页面构造契约供后续条件查询使用。
  final CampusCardBalanceClient campusCardService;

  /// 测试专用：固定相对时间与预设日期的本地时钟。
  final DateTime? nowOverride;

  /// 测试专用：覆盖视觉状态，不改变真实查询结果。
  final CampusCardDetailDisplayState? displayStateOverride;

  @override
  State<CampusCardDetailPage> createState() => _CampusCardDetailPageState();
}

class _CampusCardDetailPageState extends State<CampusCardDetailPage> {
  static const int _pageSize = 20;

  late CampusCardSnapshot _snapshot;
  late List<CampusCardTransactionRecord> _filteredRecords;
  _CampusCardDateRange _lastValidDateRange = const _CampusCardDateRange();
  int _currentPage = 0;
  String? _validationMessage;
  _CampusCardTransactionDirectionFilter _directionFilter =
      _CampusCardTransactionDirectionFilter.all;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime get _now => widget.nowOverride ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialSnapshot;
    _filteredRecords =
        widget.displayStateOverride == CampusCardDetailDisplayState.empty
        ? const []
        : _recordsFor(_lastValidDateRange, _directionFilter);
    if (widget.displayStateOverride == CampusCardDetailDisplayState.error) {
      _startDateController.text = _formatDate(_now);
      _endDateController.text = _formatDate(
        _now.subtract(const Duration(days: 6)),
      );
      _validationMessage = '开始日期不能晚于结束日期；已保留上一次有效筛选结果。';
    }
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  int get _totalPages {
    if (_filteredRecords.isEmpty) return 1;
    return (_filteredRecords.length / _pageSize).ceil();
  }

  List<CampusCardTransactionRecord> get _pagedRecords {
    if (_filteredRecords.isEmpty) return const [];
    final safePage = _currentPage.clamp(0, _totalPages - 1);
    final start = safePage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredRecords.length);
    return _filteredRecords.sublist(start, end);
  }

  List<CampusCardTransactionRecord> _recordsFor(
    _CampusCardDateRange dateRange,
    _CampusCardTransactionDirectionFilter direction,
  ) {
    return _snapshot.records
        .where((record) {
          final occurredAt = _parseRecordDate(record.occurredAt);
          if (dateRange.start != null &&
              occurredAt != null &&
              occurredAt.isBefore(dateRange.start!)) {
            return false;
          }
          if (dateRange.end != null && occurredAt != null) {
            final endExclusive = dateRange.end!.add(const Duration(days: 1));
            if (!occurredAt.isBefore(endExclusive)) return false;
          }
          return switch (direction) {
            _CampusCardTransactionDirectionFilter.all => true,
            _CampusCardTransactionDirectionFilter.income => record.isIncome,
            _CampusCardTransactionDirectionFilter.expense => record.isExpense,
          };
        })
        .toList(growable: false);
  }

  /// 按用户输入条件筛选本地已缓存交易记录。
  void _applyLocalFilters() {
    final validation = _validateDateRange();
    if (validation.error != null) {
      setState(() => _validationMessage = validation.error);
      return;
    }
    setState(() {
      _validationMessage = null;
      _lastValidDateRange = validation.range!;
      _filteredRecords = _recordsFor(_lastValidDateRange, _directionFilter);
      _currentPage = 0;
    });
  }

  _CampusCardDateValidation _validateDateRange() {
    final startText = _startDateController.text.trim();
    final endText = _endDateController.text.trim();
    final start = _parseDate(startText);
    final end = _parseDate(endText);
    if ((startText.isNotEmpty && start == null) ||
        (endText.isNotEmpty && end == null)) {
      return const _CampusCardDateValidation.error(
        '日期格式应为 yyyy-MM-dd；已保留上一次有效筛选结果。',
      );
    }
    if (start != null && end != null && start.isAfter(end)) {
      return const _CampusCardDateValidation.error(
        '开始日期不能晚于结束日期；已保留上一次有效筛选结果。',
      );
    }
    return _CampusCardDateValidation.valid(
      _CampusCardDateRange(start: start, end: end),
    );
  }

  void _queryPresetDays(int days) {
    final today = DateTime(_now.year, _now.month, _now.day);
    _startDateController.text = _formatDate(
      today.subtract(Duration(days: days - 1)),
    );
    _endDateController.text = _formatDate(today);
    _applyLocalFilters();
  }

  void _clearFilters() {
    _startDateController.clear();
    _endDateController.clear();
    setState(() {
      _validationMessage = null;
      _lastValidDateRange = const _CampusCardDateRange();
      _directionFilter = _CampusCardTransactionDirectionFilter.all;
      _filteredRecords = _recordsFor(_lastValidDateRange, _directionFilter);
      _currentPage = 0;
    });
  }

  void _onDirectionChanged(_CampusCardTransactionDirectionFilter value) {
    setState(() {
      _directionFilter = value;
      _filteredRecords = _recordsFor(_lastValidDateRange, value);
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPageScaffold(
      appBar: YhAppBar(
        title: '校园卡详情',
        leading: YhIconButton(
          icon: YhIcons.back,
          semanticLabel: '返回',
          variant: YhIconButtonVariant.ghost,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < theme.breakpoint.medium;
          return SingleChildScrollView(
            child: Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: theme.layout.pageContentWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? theme.spacing.m : theme.spacing.xl,
                    compact
                        ? theme.spacing.m
                        : theme.spacing.xl + theme.spacing.s,
                    compact ? theme.spacing.m : theme.spacing.xl,
                    compact ? theme.spacing.m : theme.spacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPageHeading(theme),
                      SizedBox(height: theme.spacing.l),
                      _buildBalanceHero(theme),
                      SizedBox(height: theme.spacing.m),
                      _buildFilterPanel(theme),
                      SizedBox(height: theme.spacing.m),
                      _buildTransactionPanel(theme),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeading(YhTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '只读校园卡',
          style: theme.typography.caption.copyWith(
            color: theme.color.brandInk,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: theme.spacing.xs),
        Semantics(
          header: true,
          child: Text('余额与交易记录', style: theme.typography.h1),
        ),
        SizedBox(height: theme.spacing.s),
        Text(
          '余额、卡状态和交易明细来自最近一次只读查询；筛选只作用于本机缓存。',
          style: theme.typography.body.copyWith(color: theme.color.muted),
        ),
      ],
    );
  }

  Widget _buildBalanceHero(YhTheme theme) {
    final balance = _snapshot.balance == null
        ? '未读取'
        : _formatMoney(_snapshot.balance!);
    final status = _snapshot.status.trim().isEmpty ? '未读取' : _snapshot.status;
    final semantics =
        '校园卡余额 $balance，卡状态 $status，'
        '${_formatTime(_snapshot.fetchedAt)} 更新';
    return Semantics(
      label: semantics,
      container: true,
      child: ExcludeSemantics(
        child: DecoratedBox(
          key: const Key('campus-card-balance-hero'),
          decoration: BoxDecoration(
            color: theme.color.brandStrong,
            borderRadius: BorderRadius.circular(theme.radius.l),
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '校园卡余额',
                  style: theme.typography.small.copyWith(
                    color: theme.color.onStructural.withValues(alpha: 0.82),
                  ),
                ),
                SizedBox(height: theme.spacing.s),
                Text(
                  balance,
                  style: theme.typography.display.copyWith(
                    color: theme.color.onStructural,
                    fontFamily: YhTypographyTokens.fontFamilyMono,
                  ),
                ),
                SizedBox(height: theme.spacing.s),
                Wrap(
                  spacing: theme.spacing.m,
                  runSpacing: theme.spacing.xs,
                  children:
                      [
                            Text('卡状态 · $status'),
                            Text('${_formatTime(_snapshot.fetchedAt)} 更新'),
                          ]
                          .map((text) {
                            return DefaultTextStyle.merge(
                              style: theme.typography.caption.copyWith(
                                color: theme.color.onStructural.withValues(
                                  alpha: 0.82,
                                ),
                              ),
                              child: text,
                            );
                          })
                          .toList(growable: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel(YhTheme theme) {
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('交易记录', style: theme.typography.h3),
          SizedBox(height: theme.spacing.xs),
          Text(
            '按日期和收支方向筛选本机已缓存记录。',
            style: theme.typography.body.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.s),
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: theme.layout.inlineControlWidth,
                child: YhTextField(
                  key: const Key('campus-card-start-date'),
                  label: '开始日期',
                  showLabel: false,
                  controller: _startDateController,
                  hint: '开始日期',
                ),
              ),
              SizedBox(
                width: theme.layout.inlineControlWidth,
                child: YhTextField(
                  key: const Key('campus-card-end-date'),
                  label: '结束日期',
                  showLabel: false,
                  controller: _endDateController,
                  hint: '结束日期',
                ),
              ),
              YhButton(
                key: const Key('campus-card-recent-seven-days'),
                label: '近 7 天',
                variant: YhButtonVariant.secondary,
                onTap: () => _queryPresetDays(7),
              ),
              YhButton(
                key: const Key('campus-card-apply-filter'),
                label: '筛选',
                onTap: _applyLocalFilters,
              ),
            ],
          ),
          SizedBox(height: theme.spacing.m),
          YhTabs<_CampusCardTransactionDirectionFilter>(
            tabs: const [
              YhTab(
                value: _CampusCardTransactionDirectionFilter.all,
                label: '全部',
              ),
              YhTab(
                value: _CampusCardTransactionDirectionFilter.expense,
                label: '支出',
              ),
              YhTab(
                value: _CampusCardTransactionDirectionFilter.income,
                label: '收入',
              ),
            ],
            value: _directionFilter,
            onChanged: _onDirectionChanged,
          ),
          if (_validationMessage != null) ...[
            SizedBox(height: theme.spacing.m),
            YhBanner(text: _validationMessage!, kind: YhBannerKind.danger),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionPanel(YhTheme theme) {
    if (_filteredRecords.isEmpty) {
      return YhCard(
        child: YhEmptyState(
          icon: YhIcons.finance,
          title: '当前范围没有交易记录',
          message: '余额与卡状态仍然有效；可清除日期或切换收支方向。',
          action: YhButton(
            label: '清除筛选',
            variant: YhButtonVariant.secondary,
            onTap: _clearFilters,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final singleColumn =
                constraints.maxWidth <=
                theme.breakpoint.medium +
                    theme.layout.inlineControlWidth -
                    theme.spacing.xl2;
            final gap = theme.spacing.s;
            final cardWidth = singleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - gap * 2) / 3;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var index = 0; index < _pagedRecords.length; index++)
                  SizedBox(
                    width: cardWidth,
                    child: _buildTransactionCard(
                      theme,
                      _pagedRecords[index],
                      index,
                    ),
                  ),
              ],
            );
          },
        ),
        if (_totalPages > 1) ...[
          SizedBox(height: theme.spacing.m),
          _buildPagination(theme),
        ],
      ],
    );
  }

  Widget _buildTransactionCard(
    YhTheme theme,
    CampusCardTransactionRecord record,
    int index,
  ) {
    final directionLabel = _directionLabel(record);
    return YhCard(
      key: Key('campus-card-transaction-$index'),
      semanticLabel:
          '$directionLabel，${_transactionTitle(record)}，${_formatSignedMoney(record.amount)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              YhStatusPill(
                label: directionLabel,
                kind: record.isIncome
                    ? YhStatusKind.success
                    : YhStatusKind.info,
              ),
              SizedBox(width: theme.spacing.s),
              Expanded(
                child: Text(
                  _formatTransactionTime(record.occurredAt),
                  textAlign: TextAlign.end,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.m),
          Text(
            _transactionTitle(record),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.h3.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            _transactionDetail(record),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.l),
          Text(
            _formatSignedMoney(record.amount),
            textAlign: TextAlign.end,
            style: theme.typography.h2.copyWith(
              color: theme.color.serviceFinance,
              fontFamily: YhTypographyTokens.fontFamilyMono,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(YhTheme theme) {
    final statusText =
        '第 ${_currentPage + 1} / $_totalPages 页 · 共 ${_filteredRecords.length} 条';
    return SizedBox(
      height: theme.control.regular,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          YhIconButton(
            key: const Key('campus-card-prev-page'),
            icon: YhIcons.back,
            semanticLabel: '上一页',
            onTap: _currentPage > 0
                ? () => setState(() => _currentPage -= 1)
                : null,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: theme.layout.inlineControlWidth,
              maxWidth: theme.layout.popoverWidth,
            ),
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.caption,
            ),
          ),
          YhIconButton(
            key: const Key('campus-card-next-page'),
            icon: YhIcons.chevronRight,
            semanticLabel: '下一页',
            onTap: _currentPage < _totalPages - 1
                ? () => setState(() => _currentPage += 1)
                : null,
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmedText);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  DateTime? _parseRecordDate(String text) {
    final match = RegExp(
      r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})',
    ).firstMatch(text.trim());
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  String _formatTransactionTime(String raw) {
    final match = RegExp(
      r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(?:\s+(\d{1,2}):(\d{2}))?',
    ).firstMatch(raw.trim());
    if (match == null) return raw;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = match.group(4)?.padLeft(2, '0');
    final minute = match.group(5);
    final time = hour == null || minute == null ? '' : ' $hour:$minute';
    if (year == _now.year && month == _now.month && day == _now.day) {
      return '今天$time';
    }
    return '$month 月 $day 日$time';
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String _formatMoney(double value) => '¥${value.toStringAsFixed(2)}';

  static String _formatSignedMoney(double value) {
    final sign = value >= 0 ? '+' : '−';
    return '$sign¥${value.abs().toStringAsFixed(2)}';
  }

  static String _directionLabel(CampusCardTransactionRecord record) {
    if (record.isIncome) return '收入';
    if (record.isExpense) return '支出';
    return '未知';
  }

  static String _transactionTitle(CampusCardTransactionRecord record) {
    final explicit = record.title?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final parts = [record.merchant, record.type]
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? '交易' : parts.join(' · ');
  }

  static String _transactionDetail(CampusCardTransactionRecord record) {
    final parts = [record.paymentMethod, record.status]
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? '校园卡 · 已记录' : parts.join(' · ');
  }
}

enum _CampusCardTransactionDirectionFilter { all, income, expense }

class _CampusCardDateRange {
  const _CampusCardDateRange({this.start, this.end});

  final DateTime? start;
  final DateTime? end;
}

class _CampusCardDateValidation {
  const _CampusCardDateValidation.valid(this.range) : error = null;
  const _CampusCardDateValidation.error(this.error) : range = null;

  final _CampusCardDateRange? range;
  final String? error;
}
