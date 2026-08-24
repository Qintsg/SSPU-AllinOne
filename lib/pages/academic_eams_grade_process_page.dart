/*
 * 教务中心本专科过程化成绩页 — 按学期请求并展示平时成绩明细
 * @Project : SSPU-AllinOne
 * @File : academic_eams_grade_process_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-15
 */

part of 'academic_page.dart';

/// 本专科教务过程化成绩页（成绩详情的三级页）。
class AcademicEamsGradeProcessPage extends StatefulWidget {
  /// 本专科教务只读服务，测试中可替换为 fake。
  final AcademicEamsClient academicEamsService;

  /// 进入时的全局学期。
  final AcademicTermChoice? initialTerm;

  /// 进入时的 EAMS 学期。
  final AcademicEamsSemesterOption? initialSemester;

  /// 上一级快照时间；首次自动读取期间用于保持来源上下文连续。
  final DateTime? initialCheckedAt;

  const AcademicEamsGradeProcessPage({
    super.key,
    required this.academicEamsService,
    this.initialTerm,
    this.initialSemester,
    this.initialCheckedAt,
  });

  @override
  State<AcademicEamsGradeProcessPage> createState() =>
      _AcademicEamsGradeProcessPageState();
}

class _AcademicEamsGradeProcessPageState
    extends State<AcademicEamsGradeProcessPage> {
  late final RetainedRefreshController<AcademicEamsQueryResult>
  _refreshController;
  AcademicTermChoice? _selectedTerm;
  AcademicEamsSemesterOption? _selectedSemester;

  AcademicEamsQueryResult? get _result => _refreshController.result;
  bool get _isLoading => _refreshController.isRefreshing;

  @override
  void initState() {
    super.initState();
    _refreshController = RetainedRefreshController(
      initialResult: null,
      isSuccess: (result) => result.isSuccess,
      hasUsableContent: (result) => result.snapshot?.gradeProcess != null,
      failureMessage: (result) => '${result.message}：${result.detail}',
    )..addListener(_handleRefreshChanged);
    _selectedTerm = widget.initialTerm;
    _selectedSemester = widget.initialSemester;
    unawaited(_loadProcessGrades());
  }

  void _handleRefreshChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant AcademicEamsGradeProcessPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final serviceChanged = !identical(
      oldWidget.academicEamsService,
      widget.academicEamsService,
    );
    final selectionChanged =
        oldWidget.initialTerm != widget.initialTerm ||
        oldWidget.initialSemester != widget.initialSemester;
    if (!serviceChanged && !selectionChanged) return;
    _selectedTerm = widget.initialTerm;
    _selectedSemester = widget.initialSemester;
    _refreshController.updateExternalResult(null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadProcessGrades());
    });
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
    final checkedAt = _result?.checkedAt ?? widget.initialCheckedAt;
    final snapshot = _result?.snapshot?.gradeProcess;
    final records = snapshot?.records ?? const <AcademicGradeProcessRecord>[];
    final options = _semesterOptions(snapshot);
    final currentSemester = _currentSemester(snapshot, options);
    return YhTaskPage(
      title: '过程化成绩',
      kicker: '课程内评价',
      summary: '按学期核对课堂表现、作业与测验等原始评价证据，不与总评成绩混算。',
      source: '过程化成绩 · 本地快照',
      sourceSymbol: '学',
      appBarTitle: _academicTaskAppBarTitle('过程化成绩', checkedAt),
      sourceTimestamp: _academicDetailTimestamp(checkedAt),
      primaryActionKey: const Key('academic-eams-grade-process-search'),
      primaryActionLabel: _isLoading && _result != null ? '正在刷新…' : '刷新明细',
      onPrimaryAction: _isLoading
          ? null
          : () => unawaited(_loadProcessGrades()),
      width: YhTaskPageWidth.constrained,
      rhythm: YhTaskPageRhythm.relaxedCompact,
      body: _buildEvidenceBody(
        context,
        theme,
        snapshot: snapshot,
        records: records,
        options: options,
        currentSemester: currentSemester,
      ),
    );
  }

  Widget _buildEvidenceBody(
    BuildContext context,
    YhTheme theme, {
    required AcademicGradeProcessSnapshot? snapshot,
    required List<AcademicGradeProcessRecord> records,
    required List<AcademicEamsSemesterOption> options,
    required AcademicEamsSemesterOption? currentSemester,
  }) {
    final gap = MediaQuery.sizeOf(context).width < theme.breakpoint.compact
        ? theme.spacing.m
        : theme.spacing.l;
    final filter = _AcademicEamsFilterPanel(
      children: [
        _AcademicExamDropdownField<String>(
          key: const Key('academic-eams-grade-process-semester-select'),
          label: '学年学期',
          width: MediaQuery.sizeOf(context).width < theme.breakpoint.compact
              ? theme.breakpoint.compact / 2 - theme.spacing.xs
              : theme.control.regular * 5,
          value: currentSemester?.id,
          placeholder: '选择学期',
          items: [
            for (final option in options)
              _AcademicExamDropdownItem<String>(
                key: Key(
                  'academic-eams-grade-process-semester-option-${option.id}',
                ),
                value: option.id,
                label: _academicProcessSemesterLabel(option),
              ),
          ],
          onChanged: _isLoading || options.isEmpty
              ? null
              : (id) => _handleSemesterChanged(id, options),
        ),
      ],
    );
    Widget content;
    if (_isLoading && _result == null) {
      content = const _AcademicDetailStateCard(
        child: _AcademicDetailLoadingState(
          title: '正在读取过程化成绩',
          source: '过程化成绩 · 本地快照',
        ),
      );
    } else if (_result == null || !_result!.isSuccess || snapshot == null) {
      content = _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '!',
          title: '过程化成绩暂不可用',
          message: _academicEamsFailureDescription(
            _result,
            fallback: '无法完成本次读取；可在本页重试，已有有效快照不会被清空。',
          ),
          accent: theme.color.serviceAcademic,
          actionLabel: '检查后重试',
          onAction: () => unawaited(_loadProcessGrades()),
        ),
      );
    } else if (records.isEmpty) {
      content = _AcademicDetailStateCard(
        key: const Key('academic-eams-grade-process-empty'),
        child: _AcademicDetailMessageState(
          symbol: '○',
          title: '当前没有过程化成绩记录',
          message: '当前筛选范围没有可展示的原始记录；可调整学期或稍后在原位置重新读取。',
          accent: theme.color.serviceAcademic,
          actionLabel: '重新读取',
          onAction: () => unawaited(_loadProcessGrades()),
        ),
      );
    } else {
      final evidenceCount = records.fold<int>(
        0,
        (total, record) => total + record.items.length,
      );
      final credits = records.fold<double>(
        0,
        (total, record) => total + (record.credit ?? 0),
      );
      final hasUnknownCredits = records.any((record) => record.credit == null);
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AcademicEvidenceMetricsPanel(
            metrics: [
              _AcademicEvidenceMetric('${records.length}', '有记录课程'),
              _AcademicEvidenceMetric('$evidenceCount', '评价证据'),
              _AcademicEvidenceMetric(
                _formatGradeCredit(credits),
                hasUnknownCredits ? '已知课程学分' : '课程学分',
              ),
            ],
          ),
          SizedBox(height: theme.spacing.m),
          _AcademicEvidenceRecordsPanel(
            kicker: '课程内原始评价',
            title: '过程证据',
            trailing: currentSemester == null
                ? '当前学期'
                : _academicProcessSemesterLabel(currentSemester),
            children: [
              for (final record in records)
                _AcademicEvidenceRecord(
                  title: record.courseName,
                  meta: [
                    if ((record.category ?? '').trim().isNotEmpty)
                      record.category!.trim(),
                    if (record.credit != null)
                      '${_formatGradeCredit(record.credit!)} 学分',
                  ].join(' · '),
                  value: record.credit == null
                      ? '—'
                      : '${_formatGradeCredit(record.credit!)} 学分',
                  status: record.termName ?? '原始记录',
                  extra: _AcademicEvidenceChips(items: record.items),
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
          const YhBanner(text: '正在刷新明细；当前筛选范围和有效记录保持可用，完成前已锁定重复请求与范围切换。'),
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

  List<AcademicEamsSemesterOption> _semesterOptions(
    AcademicGradeProcessSnapshot? snapshot,
  ) {
    final options = [...?snapshot?.semesterOptions];
    final selected = snapshot == null ? _selectedSemester : null;
    if (selected != null &&
        selected.id.isNotEmpty &&
        !options.any((option) => option.id == selected.id)) {
      options.insert(0, selected);
    }
    return List.unmodifiable(options);
  }

  AcademicEamsSemesterOption? _currentSemester(
    AcademicGradeProcessSnapshot? snapshot,
    List<AcademicEamsSemesterOption> options,
  ) {
    for (final selected in [_selectedSemester, snapshot?.selectedSemester]) {
      if (selected == null) continue;
      for (final option in options) {
        if (option.id == selected.id) return option;
      }
    }
    return options.isEmpty ? null : options.first;
  }

  void _handleSemesterChanged(
    String id,
    List<AcademicEamsSemesterOption> options,
  ) {
    for (final option in options) {
      if (option.id == id) {
        setState(() {
          _selectedSemester = option;
          _selectedTerm = option.termChoice ?? _selectedTerm;
        });
        return;
      }
    }
  }

  Future<void> _loadProcessGrades() async {
    final generation = _refreshController.captureGeneration();
    AcademicEamsQueryResult? fetched;
    await _refreshController.refresh(() async {
      fetched = await widget.academicEamsService.fetchGradeProcess(
        term: _selectedTerm,
        semester: _selectedSemester,
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
      final snapshot = fetched!.snapshot?.gradeProcess;
      final options = snapshot?.semesterOptions ?? const [];
      final preferred = snapshot?.selectedSemester;
      AcademicEamsSemesterOption? selected;
      for (final candidate in [preferred, _selectedSemester]) {
        if (candidate == null) continue;
        for (final option in options) {
          if (option.id == candidate.id) {
            selected = option;
            break;
          }
        }
        if (selected != null) break;
      }
      selected ??= options.isEmpty ? null : options.first;
      _selectedSemester = selected;
      if (selected != null) {
        _selectedTerm = selected.termChoice ?? _selectedTerm;
      }
    });
  }
}

String _academicProcessSemesterLabel(AcademicEamsSemesterOption option) {
  final term = option.termChoice;
  if (term == null) return option.label;
  return '${term.academicYear}–${term.academicYear + 1} 学年${term.season.label}';
}
