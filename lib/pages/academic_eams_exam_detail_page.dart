/*
 * 教务中心本专科考试安排详情页 — 展示完整考试记录并支持切换学期
 * @Project : SSPU-AllinOne
 * @File : academic_eams_exam_detail_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

part of 'academic_page.dart';

typedef AcademicExamDetailResultChanged =
    void Function(
      AcademicEamsQueryResult result,
      AcademicTermChoice? selectedTerm,
      AcademicEamsSemesterOption? selectedSemester,
    );

/// 本专科教务考试安排详情页。
class AcademicEamsExamDetailPage extends StatefulWidget {
  /// 本专科教务只读服务，测试中可替换为 fake。
  final AcademicEamsClient academicEamsService;

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
  AcademicEamsQueryResult? _result;
  AcademicTermChoice? _selectedTerm;
  AcademicEamsSemesterOption? _selectedSemester;
  String _selectedExamType = '1';
  bool _isLoading = false;

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
    _result = widget.initialResult;
    _selectedTerm =
        widget.initialSelectedTerm ?? AcademicTermService.defaultTerm;
    _selectedSemester = widget.initialSelectedSemester;
    _selectedExamType =
        widget.initialResult?.snapshot?.exams?.selectedExamType ?? '1';
    if (widget.initialSelectedTerm == null) {
      unawaited(_loadDefaultTerm());
    }
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
    final records = snapshot?.records ?? const <AcademicExamRecord>[];
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

    return YhPageScaffold(
      appBar: YhAppBar(
        title: '考试安排详情',
        leading: YhButton(
          label: '返回',
          leadingIcon: YhIcons.back,
          variant: YhButtonVariant.text,
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
                _AcademicExamSummaryBanner(
                  scopeLabel: currentTerm?.label ?? '考试安排',
                  examTypeLabel: snapshot?.selectedExamTypeLabel,
                  totalCount: records.length,
                  scheduledCount: records
                      .where((record) => record.hasScheduledExamDate)
                      .length,
                ),
                SizedBox(height: theme.spacing.m),
                YhCard(
                  child: Wrap(
                    spacing: theme.spacing.s,
                    runSpacing: theme.spacing.s,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      _AcademicExamDropdownField<int>(
                        key: const Key('academic-eams-exam-year-select'),
                        label: '学年',
                        width:
                            theme.breakpoint.compact / 3 -
                            theme.spacing.s -
                            theme.spacing.xs / 2,
                        value: currentTerm?.academicYear,
                        placeholder: '等待全局学期',
                        items: [
                          for (final year in years)
                            _AcademicExamDropdownItem<int>(
                              key: Key('academic-eams-exam-year-option-$year'),
                              value: year,
                              label: _academicExamYearLabel(year),
                            ),
                        ],
                        onChanged:
                            _isLoading || currentTerm == null || years.isEmpty
                            ? null
                            : (year) => _handleYearChanged(
                                year,
                                semesterOptions,
                                currentTerm,
                              ),
                      ),
                      _AcademicExamDropdownField<AcademicTermSeason>(
                        key: const Key('academic-eams-exam-season-select'),
                        label: '学期',
                        width:
                            theme.breakpoint.compact / 3 -
                            theme.spacing.l +
                            theme.spacing.xs,
                        value: currentTerm?.season,
                        placeholder: '等待全局学期',
                        items: [
                          for (final season in seasons)
                            _AcademicExamDropdownItem<AcademicTermSeason>(
                              key: Key(
                                'academic-eams-exam-season-option-${season.name}',
                              ),
                              value: season,
                              label: season.label,
                            ),
                        ],
                        onChanged: _isLoading || currentTerm == null
                            ? null
                            : (season) => _handleTermChanged(
                                currentTerm.copyWith(season: season),
                              ),
                      ),
                      _AcademicExamDropdownField<String>(
                        key: const Key('academic-eams-exam-type-select'),
                        label: '考试类型',
                        width:
                            theme.breakpoint.compact / 3 -
                            theme.spacing.l +
                            theme.spacing.xs,
                        value: _examTypeOptions.containsKey(_selectedExamType)
                            ? _selectedExamType
                            : _examTypeOptions.keys.first,
                        placeholder: '考试类型',
                        items: [
                          for (final entry in _examTypeOptions.entries)
                            _AcademicExamDropdownItem<String>(
                              key: Key(
                                'academic-eams-exam-type-option-${entry.key}',
                              ),
                              value: entry.key,
                              label: entry.value,
                            ),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (type) =>
                                  setState(() => _selectedExamType = type),
                      ),
                      SizedBox(
                        height: theme.control.regular,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: YhButton(
                            key: const Key('academic-eams-exam-detail-search'),
                            label: _isLoading ? '搜索中' : '搜索',
                            leadingIcon: _isLoading ? null : YhIcons.search,
                            onTap: _isLoading ? null : _loadExamSchedule,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: theme.spacing.m),
                if (_isLoading && _result == null)
                  YhCard(
                    child: Row(
                      children: [
                        SizedBox(
                          width: theme.spacing.xl2 * 2,
                          child: const YhProgress(showPercent: false),
                        ),
                        SizedBox(width: theme.spacing.s),
                        const Expanded(child: Text('正在读取考试安排...')),
                      ],
                    ),
                  )
                else if (_result == null)
                  const YhBanner(text: '尚未读取考试安排：选择学年和学期后点击“搜索”即可只读获取考试安排。')
                else if (!_result!.isSuccess || snapshot == null)
                  YhCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_result!.message, style: theme.typography.h3),
                        SizedBox(height: theme.spacing.s),
                        YhBanner(
                          text: _result!.detail,
                          kind: _examBannerKind(_result!.status),
                        ),
                      ],
                    ),
                  )
                else
                  YhCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('完整内容', style: theme.typography.h3),
                        SizedBox(height: theme.spacing.m),
                        _AcademicExamTable(records: records),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadDefaultTerm() async {
    final context = await AcademicTermService.instance.getEffectiveContext();
    if (!mounted || widget.initialSelectedTerm != null) return;
    setState(() => _selectedTerm = context.effectiveQueryTerm);
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
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final result = await widget.academicEamsService.fetchExamSchedule(
      term: _selectedTerm,
      // 传入用户下拉解析出的真实 semester.id；学期列表接口失败时不必再推断。
      semester: _selectedSemester,
      examTypeId: _selectedExamType,
      requireCampusNetwork: false,
    );
    if (!mounted) return;
    final exams = result.snapshot?.exams;
    final selectedSemester = exams?.selectedSemester;
    setState(() {
      _result = result;
      _isLoading = false;
      _selectedExamType = exams?.selectedExamType ?? _selectedExamType;
      if (selectedSemester != null) {
        _selectedSemester = selectedSemester;
        _selectedTerm = selectedSemester.termChoice ?? _selectedTerm;
      }
    });
    widget.onResultChanged(result, _selectedTerm, _selectedSemester);
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

String _academicExamYearLabel(int year) => '$year-${year + 1} 学年';

/// 考试详情顶部汇总横幅。
class _AcademicExamSummaryBanner extends StatelessWidget {
  const _AcademicExamSummaryBanner({
    required this.scopeLabel,
    required this.examTypeLabel,
    required this.totalCount,
    required this.scheduledCount,
  });

  final String scopeLabel;
  final String? examTypeLabel;
  final int totalCount;
  final int scheduledCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceAcademic;
    final type = examTypeLabel ?? '期末考试';
    final summary = totalCount == 0
        ? '$scopeLabel · $type · 暂无考试'
        : scheduledCount == 0
        ? '$scopeLabel · $type · $totalCount 门待公布时间'
        : '$scopeLabel · $type · 共 $totalCount 门，$scheduledCount 门已排期';
    return YhCard(
      child: Row(
        children: [
          SizedBox.square(
            dimension: theme.control.compact,
            child: Icon(YhIcons.calendar, color: accent),
          ),
          SizedBox(width: theme.spacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '考试汇总',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(summary, style: theme.typography.h3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
