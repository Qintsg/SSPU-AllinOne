/*
 * 教务中心本专科考试安排详情页 — 展示完整考试记录并支持切换学期
 * @Project : SSPU-AllinOne
 * @File : academic_eams_exam_detail_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

part of 'academic_page.dart';

typedef AcademicExamDetailResultChanged = void Function(
  AcademicEamsQueryResult result,
  AcademicTermChoice? selectedTerm,
  AcademicEamsSemesterOption? selectedSemester,
);

enum _AcademicExamSortOrder { ascending, descending }

/// 本专科教务考试安排详情页。
class AcademicEamsExamDetailPage extends StatefulWidget {
  /// 本专科教务只读服务，测试中可替换为 fake。
  final AcademicEamsClient academicEamsService;

  /// 全局学期解析模块；默认沿用生产单例。
  final AcademicTermService? academicTermService;

  /// 学期解析时钟；为空时使用生产当前时间。
  final DateTime? academicTermNow;

  /// 从教务中心卡片带入的初始考试安排结果。
  final AcademicEamsQueryResult? initialResult;

  /// 初始全局学期选择。
  final AcademicTermChoice? initialSelectedTerm;

  /// 初始 EAMS 学期选择。
  final AcademicEamsSemesterOption? initialSelectedSemester;

  /// 详情页读取到新结果后回写教务中心摘要。
  final AcademicExamDetailResultChanged onResultChanged;

  const AcademicEamsExamDetailPage({
    super.key,
    required this.academicEamsService,
    this.academicTermService,
    this.academicTermNow,
    required this.initialResult,
    required this.initialSelectedTerm,
    required this.initialSelectedSemester,
    required this.onResultChanged,
  });

  @override
  State<AcademicEamsExamDetailPage> createState() =>
      _AcademicEamsExamDetailPageState();
}

class _AcademicEamsExamDetailPageState
    extends State<AcademicEamsExamDetailPage> {
  late final RetainedRefreshController<AcademicEamsQueryResult>
  _refreshController;
  AcademicTermChoice? _selectedTerm;
  AcademicEamsSemesterOption? _selectedSemester;
  String _selectedExamType = '1';
  _AcademicExamSortOrder _sortOrder = _AcademicExamSortOrder.ascending;
  bool _isResolvingDefaultTerm = false;
  int _defaultTermRequest = 0;

  AcademicEamsQueryResult? get _result => _refreshController.result;
  bool get _isLoading =>
      _isResolvingDefaultTerm || _refreshController.isRefreshing;

  /// 缺省考试类型选项，便于尚未读取时也能切换。
  static const Map<String, String> _fallbackExamTypeOptions = {
    '1': '期末考试',
    '2': '期中考试',
    '3': '补考',
    '4': '缓考',
    '5': '平时考试',
  };

  @override
  void initState() {
    super.initState();
    _refreshController = RetainedRefreshController(
      initialResult: widget.initialResult,
      isSuccess: (result) => result.isSuccess,
      hasUsableContent: (result) => result.snapshot?.exams != null,
      failureMessage: (result) => '${result.message}：${result.detail}',
    )..addListener(_handleRefreshChanged);
    final initialExams = widget.initialResult?.snapshot?.exams;
    _selectedSemester =
        widget.initialSelectedSemester ?? initialExams?.selectedSemester;
    _selectedTerm =
        widget.initialSelectedTerm ??
        _selectedSemester?.termChoice ??
        AcademicTermService.defaultTerm;
    _selectedExamType =
        widget.initialResult?.snapshot?.exams?.selectedExamType ?? '1';
    if (widget.initialSelectedTerm == null &&
        _selectedSemester?.termChoice == null) {
      _startDefaultTermLoad(loadIfEmpty: widget.initialResult == null);
    } else if (widget.initialResult == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadExamSchedule());
      });
    }
  }

  @override
  void didUpdateWidget(covariant AcademicEamsExamDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final serviceChanged = !identical(
      oldWidget.academicEamsService,
      widget.academicEamsService,
    );
    final resultChanged = !identical(
      oldWidget.initialResult,
      widget.initialResult,
    );
    final selectionChanged =
        oldWidget.initialSelectedTerm != widget.initialSelectedTerm ||
        oldWidget.initialSelectedSemester != widget.initialSelectedSemester;
    if (serviceChanged || resultChanged || selectionChanged) {
      _defaultTermRequest += 1;
      _isResolvingDefaultTerm = false;
      _refreshController.updateExternalResult(widget.initialResult);
    }
    if (serviceChanged || resultChanged || selectionChanged) {
      final exams = widget.initialResult?.snapshot?.exams;
      _selectedSemester =
          widget.initialSelectedSemester ?? exams?.selectedSemester;
      _selectedTerm =
          widget.initialSelectedTerm ??
          _selectedSemester?.termChoice ??
          AcademicTermService.defaultTerm;
      final options = exams?.examTypeOptions ?? const <String, String>{};
      final preferred = exams?.selectedExamType ?? _selectedExamType;
      _selectedExamType = options.isEmpty || options.containsKey(preferred)
          ? preferred
          : options.keys.first;
      if (widget.initialResult == null) {
        if (widget.initialSelectedTerm == null) {
          _startDefaultTermLoad(loadIfEmpty: true);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(_loadExamSchedule());
          });
        }
      }
    }
  }

  void _handleRefreshChanged() {
    if (mounted) setState(() {});
  }

  /// 在页面仍挂载时提交来自拆分正文的交互状态。
  ///
  /// :param update: 需要在同一渲染帧中提交的页面状态变更。
  void _setAcademicState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  @override
  void dispose() {
    _refreshController
      ..removeListener(_handleRefreshChanged)
      ..dispose();
    super.dispose();
  }

  /// 当前可选考试类型；优先使用网站返回的选项。
  Map<String, String> get _examTypeOptions {
    final options = _result?.snapshot?.exams?.examTypeOptions ?? const {};
    return options.isNotEmpty ? options : _fallbackExamTypeOptions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final snapshot = _result?.snapshot?.exams;
    final records = _academicExamChronologicalRecords(
      snapshot?.records ?? const <AcademicExamRecord>[],
      order: _sortOrder,
    );
    final semesterOptions = _academicExamSemesterOptions(
      snapshot,
      selectedSemester: _selectedSemester,
      selectedTerm: _selectedTerm,
    );
    final currentTerm = _academicExamSelectedTerm(
      snapshot,
      semesterOptions,
      selectedSemester: _selectedSemester,
      selectedTerm: _selectedTerm,
    );
    final years = _academicExamAvailableYears(semesterOptions, currentTerm);
    final seasons = _academicExamAvailableSeasons(semesterOptions, currentTerm);
    return YhTaskPage(
      title: '考试安排',
      kicker: '本学期考试',
      summary: '按时间顺序核对日期、地点与考试类型；待公布和临时说明不会被隐藏。',
      source: '教务考试 · 本地快照',
      sourceSymbol: '学',
      appBarTitle: _academicTaskAppBarTitle('教务考试', _result?.checkedAt),
      sourceTimestamp: _academicDetailTimestamp(_result?.checkedAt),
      primaryActionKey: const Key('academic-eams-exam-detail-search'),
      primaryActionLabel: _isLoading ? '正在刷新…' : '刷新安排',
      onPrimaryAction: _isLoading ? null : () => unawaited(_loadExamSchedule()),
      width: YhTaskPageWidth.constrained,
      rhythm: YhTaskPageRhythm.relaxedCompact,
      body: _buildEvidenceBody(
        context,
        theme,
        snapshot: snapshot,
        records: records,
        semesterOptions: semesterOptions,
        currentTerm: currentTerm,
        years: years,
        seasons: seasons,
      ),
    );
  }

  void _startDefaultTermLoad({required bool loadIfEmpty}) {
    final request = ++_defaultTermRequest;
    _isResolvingDefaultTerm = true;
    unawaited(_loadDefaultTerm(request: request, loadIfEmpty: loadIfEmpty));
  }

  Future<void> _loadDefaultTerm({
    required int request,
    required bool loadIfEmpty,
  }) async {
    final generation = _refreshController.captureGeneration();
    var term = _selectedTerm ?? AcademicTermService.defaultTerm;
    try {
      final context =
          await (widget.academicTermService ?? AcademicTermService.instance)
              .getEffectiveContext(now: widget.academicTermNow);
      term = context.effectiveQueryTerm;
    } catch (_) {
      // 学期服务异常时沿用安全默认值，首次读取仍可展示真实教务结果。
    }
    if (!mounted ||
        request != _defaultTermRequest ||
        !_refreshController.isGenerationCurrent(generation) ||
        widget.initialSelectedTerm != null) {
      return;
    }
    setState(() {
      _isResolvingDefaultTerm = false;
      _selectedTerm = term;
    });
    if (loadIfEmpty && _result == null) await _loadExamSchedule();
  }

  void _handleYearChanged(
    int year,
    List<AcademicEamsSemesterOption> semesterOptions,
    AcademicTermChoice currentTerm,
  ) {
    _handleTermChanged(
      AcademicTermChoice(
        academicYear: year,
        season:
            _academicExamSeasonForYear(
              semesterOptions,
              year,
              currentTerm.season,
            ) ??
            currentTerm.season,
      ),
    );
  }

  void _handleTermChanged(AcademicTermChoice term) {
    final semester = _findSemesterForTerm(
      _result?.snapshot?.exams?.semesterOptions ?? const [],
      term,
    );
    setState(() {
      _selectedTerm = term;
      _selectedSemester = semester;
    });
  }

  Future<void> _loadExamSchedule() async {
    final generation = _refreshController.captureGeneration();
    AcademicEamsQueryResult? fetched;
    await _refreshController.refresh(() async {
      fetched = await widget.academicEamsService.fetchExamSchedule(
        term: _selectedTerm,
        // 传入用户下拉解析出的真实 semester.id；学期列表接口失败时不必再推断。
        semester: _selectedSemester,
        examTypeId: _selectedExamType,
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
    final exams = fetched!.snapshot?.exams;
    final selectedSemester = exams?.selectedSemester;
    final typeOptions = exams?.examTypeOptions ?? const <String, String>{};
    final preferredType = exams?.selectedExamType ?? _selectedExamType;
    setState(() {
      _selectedExamType =
          typeOptions.isEmpty || typeOptions.containsKey(preferredType)
          ? preferredType
          : typeOptions.keys.first;
      if (selectedSemester != null) {
        _selectedSemester = selectedSemester;
        _selectedTerm = selectedSemester.termChoice ?? _selectedTerm;
      }
    });
    widget.onResultChanged(fetched!, _selectedTerm, _selectedSemester);
  }

  AcademicEamsSemesterOption? _findSemesterForTerm(
    Iterable<AcademicEamsSemesterOption> options,
    AcademicTermChoice term,
  ) {
    for (final option in options) {
      if (option.matchesTerm(term)) return option;
    }
    return null;
  }
}

class _AcademicExamDateBlock extends StatelessWidget {
  const _AcademicExamDateBlock({required this.record});

  final AcademicExamRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    final date = record.displayExamDate?.trim() ?? '';
    final parts = date.split('-');
    final dateLabel = record.hasScheduledExamDate && parts.length >= 3
        ? '${parts[parts.length - 2]}·${parts.last}'
        : '待定';
    return SizedBox(
      width:
          theme.control.regular +
          (compact ? theme.spacing.xl : theme.spacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel,
            style: theme.typography.h3.copyWith(
              color: theme.color.serviceAcademic,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            _gradeText(record.displayExamArrange, placeholder: '时间待公布'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
        ],
      ),
    );
  }
}

class _AcademicExamDropdownItem<T> {
  const _AcademicExamDropdownItem({
    required this.key,
    required this.value,
    required this.label,
  });

  final Key key;
  final T value;
  final String label;
}

class _AcademicExamDropdownField<T> extends StatelessWidget {
  const _AcademicExamDropdownField({
    super.key,
    required this.label,
    required this.width,
    required this.value,
    required this.placeholder,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final double width;
  final T? value;
  final String placeholder;
  final List<_AcademicExamDropdownItem<T>> items;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final enabled = onChanged != null && items.isNotEmpty;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.xs),
          YhSelect<T>(
            label: label,
            showLabel: false,
            compact: width < theme.control.regular * 3,
            value: value,
            hint: placeholder,
            options: [
              for (final item in items)
                YhSelectOption<T>(
                  key: item.key,
                  value: item.value,
                  label: item.label,
                ),
            ],
            enabled: enabled,
            onChanged: enabled
                ? (selected) {
                    if (selected != null) onChanged?.call(selected);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

String _academicExamYearLabel(int year) => '$year–${year + 1}';

List<AcademicExamRecord> _academicExamChronologicalRecords(
  List<AcademicExamRecord> records, {
  required _AcademicExamSortOrder order,
}) {
  final indexed = records.indexed.toList();
  indexed.sort((left, right) {
    final leftTime = _academicExamStartTime(left.$2);
    final rightTime = _academicExamStartTime(right.$2);
    if (leftTime == null && rightTime == null) {
      return left.$1.compareTo(right.$1);
    }
    if (leftTime == null) return 1;
    if (rightTime == null) return -1;
    final timeOrder = leftTime.compareTo(rightTime);
    if (timeOrder == 0) return left.$1.compareTo(right.$1);
    return order == _AcademicExamSortOrder.ascending ? timeOrder : -timeOrder;
  });
  return List.unmodifiable(indexed.map((entry) => entry.$2));
}

DateTime? _academicExamStartTime(AcademicExamRecord record) {
  if (!record.hasScheduledExamDate) return null;
  final date = DateTime.tryParse(record.displayExamDate?.trim() ?? '');
  if (date == null) return null;
  final match = RegExp(r'(?<!\d)([01]?\d|2[0-3]):([0-5]\d)')
      .firstMatch(record.displayExamArrange ?? '');
  if (match == null) return date;
  return DateTime(
    date.year,
    date.month,
    date.day,
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
  );
}
