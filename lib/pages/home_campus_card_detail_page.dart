/*
 * 主页校园卡详情页 — 校园卡余额与交易记录只读展示
 * @Project : SSPU-AllinOne
 * @File : home_campus_card_detail_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'home_page.dart';

/// 校园卡余额与交易记录详情页。
class CampusCardDetailPage extends StatefulWidget {
  /// 首页已读取的校园卡快照。
  final CampusCardSnapshot initialSnapshot;

  /// 校园卡查询服务，继续用于交易记录条件查询。
  final CampusCardBalanceClient campusCardService;

  const CampusCardDetailPage({
    super.key,
    required this.initialSnapshot,
    required this.campusCardService,
  });

  @override
  State<CampusCardDetailPage> createState() => _CampusCardDetailPageState();
}

class _CampusCardDetailPageState extends State<CampusCardDetailPage> {
  static const int _pageSize = 20;

  late CampusCardSnapshot _snapshot;
  int _currentPage = 0;
  String? _validationMessage;
  _CampusCardTransactionDirectionFilter _directionFilter =
      _CampusCardTransactionDirectionFilter.all;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialSnapshot;
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  int get _totalPages {
    final count = _filteredRecords.length;
    if (count == 0) return 1;
    return (count / _pageSize).ceil();
  }

  List<CampusCardTransactionRecord> get _pagedRecords {
    final filteredRecords = _filteredRecords;
    if (filteredRecords.isEmpty) return const [];
    final safePage = _currentPage.clamp(0, _totalPages - 1);
    final start = safePage * _pageSize;
    final end = (start + _pageSize).clamp(0, filteredRecords.length);
    return filteredRecords.sublist(start, end);
  }

  List<CampusCardTransactionRecord> get _filteredRecords {
    final dateRange = _readDateRange(updateState: false);
    if (dateRange == null) return const [];
    return _snapshot.records.where((record) {
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
      return switch (_directionFilter) {
        _CampusCardTransactionDirectionFilter.all => true,
        _CampusCardTransactionDirectionFilter.income => record.isIncome,
        _CampusCardTransactionDirectionFilter.expense => record.isExpense,
      };
    }).toList();
  }

  /// 按用户输入条件筛选本地已缓存交易记录。
  void _applyLocalFilters() {
    final dateRange = _readDateRange();
    if (dateRange == null) return;
    setState(() {
      _currentPage = 0;
    });
  }

  _CampusCardDateRange? _readDateRange({bool updateState = true}) {
    final startText = _startDateController.text.trim();
    final endText = _endDateController.text.trim();
    final start = _parseDate(startText);
    final end = _parseDate(endText);
    if ((startText.isNotEmpty && start == null) ||
        (endText.isNotEmpty && end == null)) {
      if (updateState) {
        setState(() => _validationMessage = '日期格式应为 yyyy-MM-dd。');
      }
      return null;
    }
    if (start != null && end != null && start.isAfter(end)) {
      if (updateState) setState(() => _validationMessage = '开始日期不能晚于结束日期。');
      return null;
    }
    if (updateState) _validationMessage = null;
    return _CampusCardDateRange(start: start, end: end);
  }

  void _queryRecent() {
    _startDateController.clear();
    _endDateController.clear();
    _applyLocalFilters();
  }

  void _queryPresetDays(int days) {
    final now = DateTime.now();
    _startDateController.text = _formatDate(
      DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1)),
    );
    _endDateController.text = _formatDate(now);
    _applyLocalFilters();
  }

  void _onDirectionChanged(_CampusCardTransactionDirectionFilter? value) {
    if (value == null) return;
    setState(() {
      _directionFilter = value;
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
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.spacing.m),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: theme.breakpoint.expanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDetailHeaderTitle(context, theme),
                SizedBox(height: theme.spacing.m),
                _buildFilterPanel(context, theme),
                SizedBox(height: theme.spacing.m),
                _buildTransactionPanel(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailHeaderTitle(BuildContext context, YhTheme theme) {
    return YhCard(
      child: Wrap(
        spacing: theme.spacing.l,
        runSpacing: theme.spacing.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('账户概览', style: theme.typography.h3),
          _buildOverviewValue(
            theme,
            '余额：${_snapshot.balance == null ? '未读取' : _formatMoney(_snapshot.balance!)}',
          ),
          if (_snapshot.status.trim().isNotEmpty)
            _buildOverviewValue(theme, '卡状态：${_snapshot.status}'),
          _buildOverviewValue(
            theme,
            '最近刷新：${_formatDateTime(_snapshot.fetchedAt)}',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewValue(YhTheme theme, String text) {
    return Text(
      text,
      style: theme.typography.caption.copyWith(color: theme.color.muted),
    );
  }

  Widget _buildFilterPanel(BuildContext context, YhTheme theme) {
    final fieldWidth =
        theme.breakpoint.compact / 4 + theme.spacing.s + theme.spacing.xs / 2;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(end: theme.spacing.s),
                child: Text('交易记录', style: theme.typography.h3),
              ),
              SizedBox(
                width: fieldWidth,
                child: YhTextField(
                  key: const Key('campus-card-start-date'),
                  label: '开始日期',
                  showLabel: false,
                  controller: _startDateController,
                  hint: '开始日期',
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: YhTextField(
                  key: const Key('campus-card-end-date'),
                  label: '结束日期',
                  showLabel: false,
                  controller: _endDateController,
                  hint: '结束日期',
                ),
              ),
              YhButton(
                label: '最近',
                variant: YhButtonVariant.text,
                onTap: _queryRecent,
              ),
              YhButton(
                label: '近7天',
                variant: YhButtonVariant.text,
                onTap: () => _queryPresetDays(7),
              ),
              YhButton(
                label: '近30天',
                variant: YhButtonVariant.text,
                onTap: () => _queryPresetDays(30),
              ),
              YhButton(
                label: '筛选',
                leadingIcon: YhIcons.filter,
                onTap: _applyLocalFilters,
              ),
              SizedBox(
                width: theme.breakpoint.compact / 5,
                child: YhSelect<_CampusCardTransactionDirectionFilter>(
                  label: '收支方向',
                  showLabel: false,
                  value: _directionFilter,
                  hint: '全部',
                  onChanged: _onDirectionChanged,
                  options: const [
                    YhSelectOption(
                      value: _CampusCardTransactionDirectionFilter.all,
                      label: '全部',
                    ),
                    YhSelectOption(
                      value: _CampusCardTransactionDirectionFilter.income,
                      label: '收入',
                    ),
                    YhSelectOption(
                      value: _CampusCardTransactionDirectionFilter.expense,
                      label: '支出',
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_validationMessage != null) ...[
            SizedBox(height: theme.spacing.s),
            _CampusCardInlineWarning(message: _validationMessage!),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionPanel(BuildContext context, YhTheme theme) {
    return YhCard(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
      child: Column(
        children: [
          if (_filteredRecords.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: theme.spacing.xl),
              child: Text(
                '暂无交易记录',
                style: theme.typography.caption.copyWith(
                  color: theme.color.muted,
                ),
              ),
            )
          else ...[
            _buildTransactionHeader(context, theme),
            ..._buildTransactionRows(context, theme),
          ],
          if (_filteredRecords.isNotEmpty) ...[
            Container(height: 1, color: theme.color.border),
            _buildPagination(theme),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildTransactionRows(BuildContext context, YhTheme theme) {
    final rows = <Widget>[];
    final records = _pagedRecords;
    for (var index = 0; index < records.length; index++) {
      rows.add(Container(height: 1, color: theme.color.border));
      rows.add(_buildTransactionRow(context, theme, records[index]));
    }
    return rows;
  }

  Widget _buildTransactionHeader(BuildContext context, YhTheme theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            theme.breakpoint.compact + theme.control.compact) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              theme.spacing.m,
              theme.spacing.m,
              theme.spacing.m,
              theme.spacing.s,
            ),
            child: Text('交易明细', style: theme.typography.caption),
          );
        }
        final style = theme.typography.caption.copyWith(
          color: theme.color.muted,
        );
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.m,
            vertical: theme.spacing.s,
          ),
          child: Row(
            children: [
              Expanded(flex: 16, child: Text('时间', style: style)),
              Expanded(flex: 16, child: Text('名称', style: style)),
              Expanded(flex: 16, child: Text('对方', style: style)),
              Expanded(flex: 12, child: Text('付款方式', style: style)),
              Expanded(flex: 10, child: Text('状态', style: style)),
              SizedBox(
                width: theme.spacing.xl2 + theme.spacing.s,
                child: Text('收支', style: style),
              ),
              SizedBox(
                width:
                    theme.spacing.xl2 * 2 + theme.spacing.s + theme.spacing.xs,
                child: Text('金额变动', textAlign: TextAlign.end, style: style),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    YhTheme theme,
    CampusCardTransactionRecord record,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth <
            theme.breakpoint.compact + theme.control.compact;
        final title = record.title ?? record.type ?? record.merchant ?? '交易';
        final counterparty = record.counterparty ?? record.merchant ?? '-';
        final paymentMethod = record.paymentMethod ?? '-';
        final status = record.status ?? '-';
        final directionLabel = _directionLabel(record);

        if (compact) {
          return Padding(
            padding: EdgeInsets.all(theme.spacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.typography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _formatSignedMoney(record.amount),
                      style: theme.typography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: theme.spacing.xs),
                Text(record.occurredAt, style: theme.typography.caption),
                SizedBox(height: theme.spacing.xs),
                Text(
                  '收支：$directionLabel · 对方：$counterparty · 付款方式：$paymentMethod · 状态：$status',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.m,
            vertical: theme.spacing.s,
          ),
          child: Row(
            children: [
              Expanded(flex: 16, child: Text(record.occurredAt)),
              Expanded(
                flex: 16,
                child: Text(title, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 16,
                child: Text(counterparty, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 12,
                child: Text(paymentMethod, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 10,
                child: Text(status, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                width: theme.spacing.xl2 + theme.spacing.s,
                child: Text(directionLabel),
              ),
              SizedBox(
                width:
                    theme.spacing.xl2 * 2 + theme.spacing.s + theme.spacing.xs,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(_formatSignedMoney(record.amount)),
                ),
              ),
            ],
          ),
        );
      },
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
              minWidth:
                  theme.breakpoint.compact / 4 +
                  theme.spacing.s +
                  theme.spacing.xs / 2,
              maxWidth:
                  theme.breakpoint.compact / 2 -
                  theme.spacing.xl -
                  theme.spacing.s,
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

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String _formatMoney(double value) {
    return '¥${value.toStringAsFixed(2)}';
  }

  static String _formatSignedMoney(double value) {
    final sign = value >= 0 ? '+' : '-';
    return '$sign￥${value.abs().toStringAsFixed(2)}';
  }

  static String _directionLabel(CampusCardTransactionRecord record) {
    if (record.isIncome) return '收入';
    if (record.isExpense) return '支出';
    return '未知';
  }
}

enum _CampusCardTransactionDirectionFilter { all, income, expense }

class _CampusCardDateRange {
  const _CampusCardDateRange({this.start, this.end});

  final DateTime? start;
  final DateTime? end;
}

class _CampusCardInlineWarning extends StatelessWidget {
  const _CampusCardInlineWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(theme.spacing.s),
      decoration: BoxDecoration(
        color: theme.color.warningTint,
        borderRadius: BorderRadius.circular(theme.radius.input),
        border: Border.all(color: theme.color.warning.withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: theme.typography.caption.copyWith(color: theme.color.warning),
      ),
    );
  }
}
