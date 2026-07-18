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

  const AcademicEamsGradeProcessPage({
    super.key,
    required this.academicEamsService,
    this.initialTerm,
    this.initialSemester,
  });

  @override
  State<AcademicEamsGradeProcessPage> createState() =>
      _AcademicEamsGradeProcessPageState();
}

class _AcademicEamsGradeProcessPageState
    extends State<AcademicEamsGradeProcessPage> {
  AcademicEamsQueryResult? _result;
  AcademicTermChoice? _selectedTerm;
  AcademicEamsSemesterOption? _selectedSemester;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTerm = widget.initialTerm;
    _selectedSemester = widget.initialSemester;
    unawaited(_loadProcessGrades());
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final snapshot = _result?.snapshot?.gradeProcess;
    final records = snapshot?.records ?? const <AcademicGradeProcessRecord>[];
    final options = _semesterOptions(snapshot);
    final currentSemester = _currentSemester(snapshot, options);

    return YhPageScaffold(
      appBar: YhAppBar(
        title: '过程化成绩',
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
                _AcademicGradeProcessBanner(
                  semesterLabel: currentSemester?.label,
                  courseCount: records.length,
                ),
                SizedBox(height: theme.spacing.m),
                YhCard(
                  child: Wrap(
                    spacing: theme.spacing.s,
                    runSpacing: theme.spacing.s,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      _AcademicExamDropdownField<String>(
                        key: const Key(
                          'academic-eams-grade-process-semester-select',
                        ),
                        label: '学年学期',
                        width:
                            theme.breakpoint.compact / 3 +
                            theme.spacing.m +
                            theme.spacing.xs,
                        value: currentSemester?.id,
                        placeholder: '选择学期',
                        items: [
                          for (final option in options)
                            _AcademicExamDropdownItem<String>(
                              key: Key(
                                'academic-eams-grade-process-semester-option-${option.id}',
                              ),
                              value: option.id,
                              label: option.label,
                            ),
                        ],
                        onChanged: _isLoading || options.isEmpty
                            ? null
                            : (id) => _handleSemesterChanged(id, options),
                      ),
                      SizedBox(
                        height: theme.control.regular,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: YhButton(
                            key: const Key(
                              'academic-eams-grade-process-search',
                            ),
                            label: _isLoading ? '搜索中' : '搜索',
                            leadingIcon: _isLoading ? null : YhIcons.search,
                            onTap: _isLoading ? null : _loadProcessGrades,
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
                        const Expanded(child: Text('正在读取过程化成绩...')),
                      ],
                    ),
                  )
                else if (_result != null &&
                    (!_result!.isSuccess || snapshot == null))
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
                else if (records.isEmpty)
                  YhCard(
                    key: const Key('academic-eams-grade-process-empty'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('暂无过程化成绩', style: theme.typography.h3),
                        SizedBox(height: theme.spacing.s),
                        const YhBanner(text: '所选学期没有可展示的平时成绩记录。'),
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
                        _AcademicGradeProcessList(records: records),
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

  List<AcademicEamsSemesterOption> _semesterOptions(
    AcademicGradeProcessSnapshot? snapshot,
  ) {
    final options = [...?snapshot?.semesterOptions];
    final selected = snapshot?.selectedSemester ?? _selectedSemester;
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
    final selected = snapshot?.selectedSemester ?? _selectedSemester;
    if (selected != null) {
      for (final option in options) {
        if (option.id == selected.id) return option;
      }
      if (selected.id.isNotEmpty) return selected;
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
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final result = await widget.academicEamsService.fetchGradeProcess(
      term: _selectedTerm,
      semester: _selectedSemester,
      requireCampusNetwork: false,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _isLoading = false;
      final selected = result.snapshot?.gradeProcess?.selectedSemester;
      if (selected != null) {
        _selectedSemester = selected;
        _selectedTerm = selected.termChoice ?? _selectedTerm;
      }
    });
  }
}

/// 过程化成绩顶部汇总横幅。
class _AcademicGradeProcessBanner extends StatelessWidget {
  const _AcademicGradeProcessBanner({
    required this.semesterLabel,
    required this.courseCount,
  });

  final String? semesterLabel;
  final int courseCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceAcademic;
    final scope = semesterLabel ?? '过程化成绩';
    final summary = courseCount == 0
        ? '$scope · 暂无平时成绩'
        : '$scope · $courseCount 门课程有平时成绩';
    return YhCard(
      child: Row(
        children: [
          SizedBox.square(
            dimension: theme.control.compact,
            child: Icon(YhIcons.certificate, color: accent),
          ),
          SizedBox(width: theme.spacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '过程化成绩',
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

class _AcademicGradeProcessList extends StatelessWidget {
  const _AcademicGradeProcessList({required this.records});

  final List<AcademicGradeProcessRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final borderColor = theme.color.border;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(theme.radius.input),
      ),
      child: Column(
        children: [
          for (var index = 0; index < records.length; index++) ...[
            _AcademicGradeProcessListItem(record: records[index]),
            if (index != records.length - 1)
              Container(height: theme.layout.divider, color: borderColor),
          ],
        ],
      ),
    );
  }
}

class _AcademicGradeProcessListItem extends StatelessWidget {
  const _AcademicGradeProcessListItem({required this.record});

  final AcademicGradeProcessRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final meta = [
      if ((record.category ?? '').trim().isNotEmpty) record.category!.trim(),
      if (record.credit != null) '${_formatGradeCredit(record.credit!)} 学分',
    ].join(' · ');
    return Padding(
      padding: EdgeInsets.all(theme.spacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  record.courseName,
                  style: theme.typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (meta.isNotEmpty) ...[
                SizedBox(width: theme.spacing.s),
                Text(
                  meta,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: theme.spacing.s),
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            children: [
              for (final item in record.items)
                _AcademicGradeProcessChip(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcademicGradeProcessChip extends StatelessWidget {
  const _AcademicGradeProcessChip({required this.item});

  final AcademicGradeProcessItem item;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceAcademic;
    return Container(
      constraints: BoxConstraints(minHeight: theme.spacing.xl),
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.s,
        vertical: theme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(theme.radius.full),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
          SizedBox(width: theme.spacing.xs),
          Text(
            item.value,
            style: theme.typography.caption.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
