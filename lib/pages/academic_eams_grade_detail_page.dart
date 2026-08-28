/*
 * 教务中心本专科成绩详情页 — 标题下汇总横幅 + 按学期前端分组的完整成绩
 * @Project : SSPU-AllinOne
 * @File : academic_eams_grade_detail_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-14
 */

part of 'academic_page.dart';

typedef AcademicGradeDetailResultChanged = void Function(
  AcademicEamsQueryResult result,
);

/// 本专科教务成绩详情页。
class AcademicEamsGradeDetailPage extends StatefulWidget {
  /// 本专科教务只读服务，测试中可替换为 fake。
  final AcademicEamsClient academicEamsService;

  /// 从教务中心卡片带入的初始成绩结果。
  final AcademicEamsQueryResult? initialResult;

  /// 详情页读取到新结果后回写教务中心摘要。
  final AcademicGradeDetailResultChanged onResultChanged;

  const AcademicEamsGradeDetailPage({
    super.key,
    required this.academicEamsService,
    required this.initialResult,
    required this.onResultChanged,
  });

  @override
  State<AcademicEamsGradeDetailPage> createState() =>
      _AcademicEamsGradeDetailPageState();
}

class _AcademicEamsGradeDetailPageState
    extends State<AcademicEamsGradeDetailPage> {
  late final RetainedRefreshController<AcademicEamsQueryResult>
  _refreshController;

  /// 当前选中学期；null 表示展示全部学期（默认）。
  String? _selectedTerm;
  AcademicEamsQueryResult? get _result => _refreshController.result;
  bool get _isLoading => _refreshController.isRefreshing;

  /// "全部学期" 在下拉中的占位值。
  static const String _allTermsValue = '';

  @override
  void initState() {
    super.initState();
    _refreshController = RetainedRefreshController(
      initialResult: widget.initialResult,
      isSuccess: (result) => result.isSuccess,
      hasUsableContent: (result) => result.snapshot?.grades != null,
      failureMessage: (result) => '${result.message}：${result.detail}',
    )..addListener(_handleRefreshChanged);
    if (widget.initialResult == null) {
      unawaited(_loadGrades());
    }
  }

  @override
  void didUpdateWidget(covariant AcademicEamsGradeDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final serviceChanged = !identical(
      oldWidget.academicEamsService,
      widget.academicEamsService,
    );
    final resultChanged = !identical(
      oldWidget.initialResult,
      widget.initialResult,
    );
    if (serviceChanged || resultChanged) {
      _refreshController.updateExternalResult(widget.initialResult);
      final terms =
          widget.initialResult?.snapshot?.grades?.availableTerms ??
          const <String>[];
      if (_selectedTerm != null && !terms.contains(_selectedTerm)) {
        _selectedTerm = null;
      }
      if (serviceChanged && widget.initialResult == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_loadGrades());
        });
      }
    }
  }

  void _handleRefreshChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _refreshController
      ..removeListener(_handleRefreshChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final snapshot = _result?.snapshot?.grades;
    final terms = snapshot?.availableTerms ?? const <String>[];
    final currentTerm = _selectedTerm != null && terms.contains(_selectedTerm)
        ? _selectedTerm
        : null;
    final records = snapshot == null
        ? const <AcademicGradeRecord>[]
        : currentTerm == null
        ? snapshot.recordsByTermDesc
        : snapshot.recordsForTerm(currentTerm);
    final gpa = snapshot?.weightedGpaForTerm(currentTerm);
    final credits = snapshot?.creditsForTerm(currentTerm) ?? 0;
    return YhTaskPage(
      title: '课程成绩',
      kicker: '成绩证据',
      summary: '按学期核对成绩、学分与绩点；原始分值保持原样，不在本机推断。',
      source: '教务成绩 · 本地快照',
      sourceSymbol: '学',
      appBarTitle: _academicTaskAppBarTitle('教务成绩', _result?.checkedAt),
      sourceTimestamp: _academicDetailTimestamp(_result?.checkedAt),
      primaryActionKey: const Key('academic-eams-grade-detail-refresh'),
      primaryActionLabel: _isLoading ? '正在刷新…' : '刷新成绩',
      onPrimaryAction: _isLoading ? null : () => unawaited(_loadGrades()),
      width: YhTaskPageWidth.constrained,
      rhythm: YhTaskPageRhythm.relaxedCompact,
      body: _buildEvidenceBody(
        context,
        theme,
        snapshot: snapshot,
        terms: terms,
        currentTerm: currentTerm,
        records: records,
        gpa: gpa,
        credits: credits,
      ),
    );
  }

  Widget _buildEvidenceBody(
    BuildContext context,
    YhTheme theme, {
    required AcademicGradeSnapshot? snapshot,
    required List<String> terms,
    required String? currentTerm,
    required List<AcademicGradeRecord> records,
    required double? gpa,
    required double credits,
  }) {
    final gap = MediaQuery.sizeOf(context).width < theme.breakpoint.compact
        ? theme.spacing.m
        : theme.spacing.l;
    final filter = _AcademicEamsFilterPanel(
      children: [
        _AcademicExamDropdownField<String>(
          key: const Key('academic-eams-grade-term-select'),
          label: '学年学期',
          width: MediaQuery.sizeOf(context).width < theme.breakpoint.compact
              ? theme.control.regular * 3 + theme.spacing.l
              : theme.control.regular * 5,
          value: currentTerm ?? _allTermsValue,
          placeholder: '全部学期',
          items: [
            const _AcademicExamDropdownItem<String>(
              key: Key('academic-eams-grade-term-option-all'),
              value: _allTermsValue,
              label: '全部学期',
            ),
            for (final term in terms)
              _AcademicExamDropdownItem<String>(
                key: Key('academic-eams-grade-term-option-$term'),
                value: term,
                label: term,
              ),
          ],
          onChanged: _isLoading
              ? null
              : (term) => setState(
                  () => _selectedTerm = term == _allTermsValue ? null : term,
                ),
        ),
        SizedBox(
          width: theme.control.regular * 2 + theme.spacing.m,
          height: theme.control.regular,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: YhButton(
              key: const Key('academic-eams-grade-process-entry'),
              label: '过程化成绩',
              variant: YhButtonVariant.secondary,
              onTap: _isLoading ? null : _openProcessGrades,
            ),
          ),
        ),
      ],
    );
    Widget content;
    if (_isLoading && _result == null) {
      content = const _AcademicDetailStateCard(
        child: _AcademicDetailLoadingState(
          title: '正在读取课程成绩',
          source: '教务成绩 · 本地快照',
        ),
      );
    } else if (_result == null || !_result!.isSuccess || snapshot == null) {
      content = _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '!',
          title: '课程成绩暂不可用',
          message: _academicEamsFailureDescription(
            _result,
            fallback: '无法完成本次读取；可在本页重试，已有有效快照不会被清空。',
          ),
          accent: theme.color.serviceAcademic,
          actionLabel: '检查后重试',
          onAction: () => unawaited(_loadGrades()),
        ),
      );
    } else if (records.isEmpty) {
      content = _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '○',
          title: '当前没有课程成绩记录',
          message: '当前筛选范围没有可展示的原始记录；可调整学期或稍后在原位置重新读取。',
          accent: theme.color.serviceAcademic,
          actionLabel: currentTerm == null ? '重新读取' : '显示全部学期',
          onAction: currentTerm == null
              ? () => unawaited(_loadGrades())
              : () => setState(() => _selectedTerm = null),
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AcademicEvidenceMetricsPanel(
            metrics: [
              _AcademicEvidenceMetric(gpa?.toStringAsFixed(1) ?? '—', '当前 GPA'),
              _AcademicEvidenceMetric(_formatGradeCredit(credits), '已获学分'),
              _AcademicEvidenceMetric('${records.length} 门', '课程成绩'),
            ],
          ),
          SizedBox(height: theme.spacing.m),
          _AcademicEvidenceRecordsPanel(
            kicker: '原始成绩证据',
            title: '课程成绩',
            trailing: '${records.length} 门课程',
            children: [
              for (final record in records)
                _AcademicEvidenceRecord(
                  title: record.courseName,
                  meta: [
                    if ((record.termName ?? '').trim().isNotEmpty)
                      record.termName!.replaceAll('-', '–'),
                    if (record.credit != null)
                      '${_formatGradeCredit(record.credit!)} 学分',
                  ].join(' · '),
                  detail: record.gradePoint == null
                      ? null
                      : '绩点 ${record.gradePoint!.toStringAsFixed(1)}',
                  value: _gradeText(record.totalScoreText),
                  status: '总评',
                ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoading && _result != null) ...[
          const YhBanner(text: '正在刷新成绩；当前筛选范围和有效记录保持可用，完成前已锁定重复请求与范围切换。'),
          SizedBox(height: gap),
        ] else if (_refreshController.retainedFailure case final failure?) ...[
          YhBanner(text: failure, kind: YhBannerKind.danger),
          SizedBox(height: gap),
        ] else if (_isAcademicEamsStale(_result)) ...[
          YhBanner(
            text: _academicEamsSnapshotNotice(_result!),
            kind: YhBannerKind.warn,
          ),
          SizedBox(height: gap),
        ],
        filter,
        SizedBox(height: gap),
        content,
      ],
    );
  }

  void _openProcessGrades() {
    Navigator.of(context).push(
      YhPageRoute(
        builder: (_) => AcademicEamsGradeProcessPage(
          academicEamsService: widget.academicEamsService,
          initialCheckedAt: _result?.checkedAt,
        ),
      ),
    );
  }

  Future<void> _loadGrades() async {
    final generation = _refreshController.captureGeneration();
    AcademicEamsQueryResult? fetched;
    await _refreshController.refresh(() async {
      fetched = await widget.academicEamsService.fetchGrades(
        requireCampusNetwork: false,
      );
      return fetched;
    });
    if (!mounted ||
        !_refreshController.isGenerationCurrent(generation) ||
        fetched == null ||
        !identical(_result, fetched)) {
      return;
    }
    setState(() {
      final terms =
          fetched!.snapshot?.grades?.availableTerms ?? const <String>[];
      if (_selectedTerm != null && !terms.contains(_selectedTerm)) {
        _selectedTerm = null;
      }
    });
    widget.onResultChanged(fetched!);
  }
}
