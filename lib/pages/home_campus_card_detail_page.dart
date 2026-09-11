/*
 * 主页校园卡详情页 — 校园卡余额与交易记录只读状态和请求协同
 * @Project : SSPU-AllinOne
 * @File : home_campus_card_detail_page.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'home_page.dart';

/// 校园卡详情页的确定性展示状态，仅用于视觉 fixture 与状态回归测试。
enum CampusCardDetailDisplayState {
  content,
  empty,
  stale,
  error,
  partialError,
  operationLocked,
  validationError,
}

enum _CampusCardRemoteOperation { rangeQuery, fullSync }

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

/// 协调校园卡快照、日期筛选与远端只读请求的页面状态。
class _CampusCardDetailPageState extends State<CampusCardDetailPage> {
  static const int _pageSize = 20;

  late CampusCardSnapshot _snapshot;
  late List<CampusCardTransactionRecord> _filteredRecords;
  late final RetainedRefreshController<CampusCardQueryResult>
  _refreshController;
  StreamSubscription<int>? _credentialChangeSubscription;
  _CampusCardDateRange _lastValidDateRange = const _CampusCardDateRange();
  int _currentPage = 0;
  String? _validationMessage;
  String? _activeOperationLabel;
  _CampusCardRemoteOperation _lastRemoteOperation =
      _CampusCardRemoteOperation.fullSync;
  bool _credentialsInvalidated = false;
  _CampusCardTransactionDirectionFilter _directionFilter =
      _CampusCardTransactionDirectionFilter.all;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime get _now => widget.nowOverride ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialSnapshot;
    _refreshController = RetainedRefreshController<CampusCardQueryResult>(
      initialResult: _resultForSnapshot(_snapshot),
      isSuccess: (result) => result.isSuccess && result.snapshot != null,
      hasUsableContent: _hasUsableContent,
      failureMessage: _failureMessage,
    )..addListener(_handleRefreshChanged);
    _credentialChangeSubscription = AcademicCredentialsService
        .instance
        .oaChanges
        .listen(_handleCredentialGenerationChanged);
    _filteredRecords =
        widget.displayStateOverride == CampusCardDetailDisplayState.empty
        ? const []
        : _recordsFor(_lastValidDateRange, _directionFilter);
  }

  @override
  void didUpdateWidget(CampusCardDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.campusCardService, widget.campusCardService) ||
        !identical(oldWidget.initialSnapshot, widget.initialSnapshot)) {
      _credentialsInvalidated = false;
      _snapshot = widget.initialSnapshot;
      _validationMessage = null;
      _filteredRecords = _recordsFor(_lastValidDateRange, _directionFilter);
      _currentPage = _currentPage.clamp(0, _totalPages - 1);
      _refreshController.updateExternalResult(_resultForSnapshot(_snapshot));
    }
  }

  @override
  void dispose() {
    _credentialChangeSubscription?.cancel();
    _refreshController
      ..removeListener(_handleRefreshChanged)
      ..dispose();
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

  /// 按日期和收支方向筛选当前快照，并保持时间倒序。
  List<CampusCardTransactionRecord> _recordsFor(
    _CampusCardDateRange dateRange,
    _CampusCardTransactionDirectionFilter direction,
  ) {
    final records = _snapshot.records.where((record) {
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
    }).toList();
    records.sort((left, right) {
      final leftDate = _parseRecordDateTime(left.occurredAt);
      final rightDate = _parseRecordDateTime(right.occurredAt);
      if (leftDate == null && rightDate == null) return 0;
      if (leftDate == null) return 1;
      if (rightDate == null) return -1;
      return rightDate.compareTo(leftDate);
    });
    return List.unmodifiable(records);
  }

  /// 应用本地日期筛选，错误时保留最近一次有效结果。
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

  /// 验证输入的日期范围，避免无效输入覆盖有效筛选上下文。
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

  /// 将快捷日期写入输入框并立即应用本地筛选，不访问远端服务。
  void _queryPresetDays(int days) {
    if (_refreshController.isRefreshing) return;
    final today = DateTime(_now.year, _now.month, _now.day);
    _startDateController.text = _formatDate(
      today.subtract(Duration(days: days - 1)),
    );
    _endDateController.text = _formatDate(today);
    _applyLocalFilters();
  }

  /// 以当前有效日期范围发起一次远端只读查询。
  Future<void> _queryRemoteRecords() async {
    final validation = _validateDateRange();
    if (validation.error != null) {
      setState(() => _validationMessage = validation.error);
      return;
    }
    setState(() => _validationMessage = null);
    final adopted = await _runRemoteOperation(
      operation: _CampusCardRemoteOperation.rangeQuery,
      label: '正在只读查询指定日期记录',
      task: () => widget.campusCardService.fetchCampusCard(
        startDate: validation.range!.start,
        endDate: validation.range!.end,
        requireCampusNetwork: true,
        queryTransactions: true,
      ),
    );
    if (!adopted || !mounted) return;
    setState(() {
      _lastValidDateRange = validation.range!;
      _filteredRecords = _recordsFor(_lastValidDateRange, _directionFilter);
      _currentPage = 0;
    });
  }

  /// 同步全部可读取交易记录，复用与日期查询相同的单飞锁。
  Future<void> _syncAllRecords() {
    return _runRemoteOperation(
      operation: _CampusCardRemoteOperation.fullSync,
      label: '正在只读同步全部记录',
      task: () => widget.campusCardService.fetchCampusCard(
        requireCampusNetwork: true,
        queryTransactions: true,
        syncAllTransactions: true,
      ),
    );
  }

  /// 执行可保留旧内容的远端只读操作，并拒绝重复或过期凭据请求。
  Future<bool> _runRemoteOperation({
    required _CampusCardRemoteOperation operation,
    required String label,
    required Future<CampusCardQueryResult> Function() task,
  }) async {
    if (_credentialsInvalidated || _refreshController.isRefreshing) {
      return false;
    }
    final generation = _refreshController.captureGeneration();
    CampusCardQueryResult? completedResult;
    _lastRemoteOperation = operation;
    if (mounted) setState(() => _activeOperationLabel = label);
    await _refreshController.refresh(() async {
      try {
        completedResult = await task();
      } on Object {
        completedResult = CampusCardQueryResult(
          status: CampusCardQueryStatus.unexpectedError,
          message: '校园卡服务出现未知异常',
          detail: '只读操作未完成，可在当前页面重试。',
          checkedAt: _now,
          entranceUri: _snapshot.sourceUri,
        );
      }
      return completedResult;
    });
    if (mounted && !_refreshController.isRefreshing) {
      setState(() => _activeOperationLabel = null);
    }
    return _refreshController.isGenerationCurrent(generation) &&
        completedResult?.isSuccess == true &&
        completedResult?.snapshot != null;
  }

  /// 接纳当前代的成功快照，避免过期结果污染正在浏览的筛选上下文。
  void _handleRefreshChanged() {
    if (!mounted) return;
    final result = _refreshController.result;
    final nextSnapshot = result?.isSuccess == true ? result?.snapshot : null;
    setState(() {
      if (nextSnapshot != null && !identical(nextSnapshot, _snapshot)) {
        _snapshot = nextSnapshot;
        _filteredRecords = _recordsFor(_lastValidDateRange, _directionFilter);
        _currentPage = _currentPage.clamp(0, _totalPages - 1);
      }
    });
  }

  /// 在 OA 身份切换时停止使用旧账户快照。
  void _handleCredentialGenerationChanged(int _) {
    if (!mounted) return;
    _credentialsInvalidated = true;
    _activeOperationLabel = null;
    _refreshController.updateExternalResult(null);
  }

  /// 为现有首页快照构造可由保留控制器管理的成功结果。
  CampusCardQueryResult _resultForSnapshot(CampusCardSnapshot snapshot) {
    return CampusCardQueryResult(
      status: CampusCardQueryStatus.success,
      message: '已保留首页校园卡快照。',
      detail: '',
      checkedAt: snapshot.fetchedAt,
      entranceUri: snapshot.sourceUri,
      finalUri: snapshot.sourceUri,
      snapshot: snapshot,
    );
  }

  /// 判断查询结果是否包含可继续展示的余额或交易内容。
  bool _hasUsableContent(CampusCardQueryResult result) {
    final snapshot = result.snapshot;
    return snapshot != null &&
        (snapshot.balance != null || snapshot.records.isNotEmpty);
  }

  /// 为保留旧快照的失败状态提供与最近操作一致的恢复文案。
  String _failureMessage(CampusCardQueryResult result) {
    final reason = _failureReason(result);
    final verb = _lastRemoteOperation == _CampusCardRemoteOperation.rangeQuery
        ? '查询'
        : '同步';
    return '只读$verb未完成：$reason；当前余额、记录和筛选已保留。';
  }

  /// 将校园卡服务结果映射为用户可据此恢复的具体原因。
  String _failureReason(CampusCardQueryResult result) {
    return switch (result.status) {
      CampusCardQueryStatus.success => '',
      CampusCardQueryStatus.fetchDisabled => '已在设置中停止获取',
      CampusCardQueryStatus.missingOaAccount => '未设置 OA 账号',
      CampusCardQueryStatus.missingOaPassword => '未设置 OA 密码',
      CampusCardQueryStatus.campusNetworkUnavailable => '校园网 / VPN 不可用',
      CampusCardQueryStatus.oaLoginRequired => 'OA 登录状态已失效',
      CampusCardQueryStatus.cardSystemUnavailable => '校园卡系统暂不可用',
      CampusCardQueryStatus.parseFailed => '校园卡页面结构暂时无法解析',
      CampusCardQueryStatus.networkError => '网络请求失败或超时',
      CampusCardQueryStatus.unexpectedError => firstNonEmptyText(
        result.detail,
        result.message,
        fallback: '校园卡服务出现未知异常',
      ),
    };
  }

  /// 清空本地筛选条件并回到全部交易记录。
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

  /// 切换只作用于本机快照的收支方向筛选。
  void _onDirectionChanged(_CampusCardTransactionDirectionFilter value) {
    setState(() {
      _directionFilter = value;
      _filteredRecords = _recordsFor(_lastValidDateRange, value);
      _currentPage = 0;
    });
  }

  /// 返回上一页，并保持当前筛选与快照不变。
  void _showPreviousPage() {
    if (_currentPage == 0) return;
    setState(() => _currentPage -= 1);
  }

  /// 前往下一页，并保持当前筛选与快照不变。
  void _showNextPage() {
    if (_currentPage >= _totalPages - 1) return;
    setState(() => _currentPage += 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final displayState = _effectiveDisplayState;
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
                        ? theme.spacing.m + theme.spacing.s
                        : theme.spacing.xl + theme.spacing.s,
                    compact ? theme.spacing.m : theme.spacing.xl,
                    compact ? theme.spacing.m : theme.spacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPageHeading(theme),
                      SizedBox(height: theme.spacing.l),
                      if (displayState ==
                          CampusCardDetailDisplayState.error) ...[
                        _buildTerminalErrorPanel(theme),
                      ] else ...[
                        if (displayState ==
                                CampusCardDetailDisplayState.stale ||
                            displayState ==
                                CampusCardDetailDisplayState.partialError ||
                            displayState ==
                                CampusCardDetailDisplayState
                                    .operationLocked) ...[
                          _buildStateBanner(displayState),
                          SizedBox(height: theme.spacing.m),
                        ],
                        _buildPrimaryContent(theme, displayState),
                        SizedBox(height: theme.spacing.m),
                        _buildTransactionPanel(theme),
                      ],
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

  /// 依据保留控制器、凭据代次与本地筛选推导页面可视状态。
  CampusCardDetailDisplayState get _effectiveDisplayState {
    final override = widget.displayStateOverride;
    if (override != null) return override;
    if (_credentialsInvalidated) return CampusCardDetailDisplayState.error;
    if (_refreshController.isRefreshing) {
      return CampusCardDetailDisplayState.operationLocked;
    }
    if (_refreshController.retainedFailure != null) {
      return CampusCardDetailDisplayState.partialError;
    }
    final result = _refreshController.result;
    if (result != null && !result.isSuccess) {
      return CampusCardDetailDisplayState.error;
    }
    if (_validationMessage != null) {
      return CampusCardDetailDisplayState.validationError;
    }
    if (_now.difference(_snapshot.fetchedAt) >= const Duration(hours: 1)) {
      return CampusCardDetailDisplayState.stale;
    }
    if (_filteredRecords.isEmpty) return CampusCardDetailDisplayState.empty;
    return CampusCardDetailDisplayState.content;
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
