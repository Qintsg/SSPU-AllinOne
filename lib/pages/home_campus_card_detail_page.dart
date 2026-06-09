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
  CampusCardQueryResult? _queryResult;
  bool _isQuerying = false;
  int _currentPage = 0;
  String? _validationMessage;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialSnapshot;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_queryTransactions(useInputDates: false));
    });
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  int get _totalPages {
    if (_snapshot.records.isEmpty) return 1;
    return (_snapshot.records.length / _pageSize).ceil();
  }

  List<CampusCardTransactionRecord> get _pagedRecords {
    if (_snapshot.records.isEmpty) return const [];
    final safePage = _currentPage.clamp(0, _totalPages - 1);
    final start = safePage * _pageSize;
    final end = (start + _pageSize).clamp(0, _snapshot.records.length);
    return _snapshot.records.sublist(start, end);
  }

  /// 按用户输入日期查询交易记录；日期为空时查询系统默认最近记录。
  Future<void> _queryTransactions({bool useInputDates = true}) async {
    final dateRange = useInputDates
        ? _readDateRange()
        : _CampusCardDateRange.empty();
    if (dateRange == null) return;

    setState(() {
      _isQuerying = true;
      _validationMessage = null;
    });
    final result = await widget.campusCardService.fetchCampusCard(
      startDate: dateRange.start,
      endDate: dateRange.end,
      requireCampusNetwork: false,
      queryTransactions: true,
    );
    if (!mounted) return;
    setState(() {
      _queryResult = result;
      if (result.isSuccess && result.snapshot != null) {
        _snapshot = result.snapshot!;
        _currentPage = 0;
      }
      _isQuerying = false;
    });
  }

  _CampusCardDateRange? _readDateRange() {
    final startText = _startDateController.text.trim();
    final endText = _endDateController.text.trim();
    final start = _parseDate(startText);
    final end = _parseDate(endText);
    if ((startText.isNotEmpty && start == null) ||
        (endText.isNotEmpty && end == null)) {
      setState(() => _validationMessage = '日期格式应为 yyyy-MM-dd。');
      return null;
    }
    if (start != null && end != null && start.isAfter(end)) {
      setState(() => _validationMessage = '开始日期不能晚于结束日期。');
      return null;
    }
    return _CampusCardDateRange(start: start, end: end);
  }

  Future<void> _queryRecent() async {
    _startDateController.clear();
    _endDateController.clear();
    await _queryTransactions(useInputDates: true);
  }

  Future<void> _queryPresetDays(int days) async {
    final now = DateTime.now();
    _startDateController.text = _formatDate(
      DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1)),
    );
    _endDateController.text = _formatDate(now);
    await _queryTransactions(useInputDates: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return FluentPage.scrollable(
      header: FluentPageHeader(
        title: const Text('校园卡详情'),
        commandBar: FluentButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('返回'),
        ),
      ),
      children: [
        _buildOverview(context, theme),
        const SizedBox(height: FluentSpacing.m),
        _buildFilterPanel(context, theme),
        const SizedBox(height: FluentSpacing.m),
        _buildTransactionPanel(context, theme),
      ],
    );
  }

  Widget _buildOverview(BuildContext context, FluentThemeData theme) {
    return FluentSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(FluentSpacing.l),
      child: Wrap(
        spacing: FluentSpacing.l,
        runSpacing: FluentSpacing.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('账户概览', style: theme.typography.bodyStrong),
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

  Widget _buildOverviewValue(FluentThemeData theme, String text) {
    return Text(
      text,
      style: theme.typography.caption?.copyWith(
        color: theme.resources.textFillColorSecondary,
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, FluentThemeData theme) {
    return FluentSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(FluentSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('交易记录', style: theme.typography.bodyStrong),
          const SizedBox(height: FluentSpacing.m),
          Wrap(
            spacing: FluentSpacing.s,
            runSpacing: FluentSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 160,
                child: FluentTextField(
                  controller: _startDateController,
                  placeholder: '开始日期',
                ),
              ),
              SizedBox(
                width: 160,
                child: FluentTextField(
                  controller: _endDateController,
                  placeholder: '结束日期',
                ),
              ),
              FluentButton.subtle(
                size: FluentButtonSize.small,
                onPressed: _isQuerying ? null : _queryRecent,
                child: const Text('最近'),
              ),
              FluentButton.subtle(
                size: FluentButtonSize.small,
                onPressed: _isQuerying ? null : () => _queryPresetDays(7),
                child: const Text('近7天'),
              ),
              FluentButton.subtle(
                size: FluentButtonSize.small,
                onPressed: _isQuerying ? null : () => _queryPresetDays(30),
                child: const Text('近30天'),
              ),
              FluentButton.primary(
                size: FluentButtonSize.small,
                onPressed: _isQuerying ? null : _queryTransactions,
                child: _isQuerying
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: FluentProgressRing(strokeWidth: 2),
                      )
                    : const Text('查询'),
              ),
            ],
          ),
          if (_validationMessage != null) ...[
            const SizedBox(height: FluentSpacing.s),
            _CampusCardInlineWarning(message: _validationMessage!),
          ] else if (_queryResult != null && !_queryResult!.isSuccess) ...[
            const SizedBox(height: FluentSpacing.s),
            _CampusCardInlineWarning(
              message: '${_queryResult!.message}：${_queryResult!.detail}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionPanel(BuildContext context, FluentThemeData theme) {
    return FluentSurface(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: FluentSpacing.xxs),
      child: Column(
        children: [
          if (_snapshot.records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: FluentSpacing.xl),
              child: Text(
                '暂无交易记录',
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorSecondary,
                ),
              ),
            )
          else
            ..._buildTransactionRows(context, theme),
          if (_snapshot.records.isNotEmpty) ...[
            const Divider(),
            _buildPagination(theme),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildTransactionRows(
    BuildContext context,
    FluentThemeData theme,
  ) {
    final rows = <Widget>[];
    final records = _pagedRecords;
    for (var index = 0; index < records.length; index++) {
      if (index > 0) rows.add(const Divider());
      rows.add(_buildTransactionRow(context, theme, records[index]));
    }
    return rows;
  }

  Widget _buildTransactionRow(
    BuildContext context,
    FluentThemeData theme,
    CampusCardTransactionRecord record,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final title = record.title ?? record.type ?? record.merchant ?? '交易';
        final counterparty = record.counterparty ?? record.merchant ?? '-';
        final paymentMethod = record.paymentMethod ?? '-';
        final status = record.status ?? '-';

        if (compact) {
          return Padding(
            padding: const EdgeInsets.all(FluentSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: theme.typography.bodyStrong),
                    ),
                    Text(
                      _formatSignedMoney(record.amount),
                      style: theme.typography.bodyStrong,
                    ),
                  ],
                ),
                const SizedBox(height: FluentSpacing.xs),
                Text(record.occurredAt, style: theme.typography.caption),
                const SizedBox(height: FluentSpacing.xs),
                Text(
                  '对方：$counterparty · 付款方式：$paymentMethod · 状态：$status',
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FluentSpacing.m,
            vertical: FluentSpacing.s,
          ),
          child: Row(
            children: [
              Expanded(flex: 18, child: Text(record.occurredAt)),
              Expanded(
                flex: 18,
                child: Text(title, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 18,
                child: Text(counterparty, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 14,
                child: Text(paymentMethod, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 10,
                child: Text(status, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                width: 96,
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

  Widget _buildPagination(FluentThemeData theme) {
    final statusText =
        '第 ${_currentPage + 1} / $_totalPages 页 · 共 ${_snapshot.records.length} 条';
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FluentIconButton(
            tooltip: '上一页',
            icon: const Icon(FluentIcons.chevronLeft),
            size: 32,
            iconSize: 14,
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage -= 1)
                : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.caption,
            ),
          ),
          FluentIconButton(
            tooltip: '下一页',
            icon: const Icon(FluentIcons.chevronRight),
            size: 32,
            iconSize: 14,
            onPressed: _currentPage < _totalPages - 1
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
    final sign = value > 0 ? '+' : '';
    return '$sign${_formatMoney(value)}';
  }
}

class _CampusCardDateRange {
  const _CampusCardDateRange({this.start, this.end});

  const _CampusCardDateRange.empty() : start = null, end = null;

  final DateTime? start;
  final DateTime? end;
}

class _CampusCardInlineWarning extends StatelessWidget {
  const _CampusCardInlineWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FluentSpacing.s),
      decoration: BoxDecoration(
        color: colors.statusWarningBackground,
        borderRadius: BorderRadius.circular(FluentRadius.medium),
        border: Border.all(
          color: colors.statusWarningForeground.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        message,
        style: type.caption1.copyWith(color: colors.statusWarningForeground),
      ),
    );
  }
}
