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
    final theme = FluentTheme.of(context);
    final accent = context.fluentAccents.academic;
    final snapshot = _result?.snapshot?.gradeProcess;
    final records = snapshot?.records ?? const <AcademicGradeProcessRecord>[];
    final options = _semesterOptions(snapshot);
    final currentSemester = _currentSemester(snapshot, options);

    return FluentPage.scrollable(
      header: FluentPageHeader(
        title: const Text('过程化成绩'),
        commandBar: FluentButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('返回'),
        ),
      ),
      children: [
        _AcademicGradeProcessBanner(
          semesterLabel: currentSemester?.label,
          courseCount: records.length,
          accent: accent,
        ),
        const SizedBox(height: FluentSpacing.m),
        FluentSurface(
          padding: const EdgeInsets.all(FluentSpacing.l),
          child: Wrap(
            spacing: FluentSpacing.s,
            runSpacing: FluentSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _AcademicExamDropdownField<String>(
                key: const Key('academic-eams-grade-process-semester-select'),
                label: '学年学期',
                width: 220,
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
                height: 48,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FluentButton.primaryIcon(
                    key: const Key('academic-eams-grade-process-search'),
                    onPressed: _isLoading ? null : _loadProcessGrades,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: FluentProgressRing(strokeWidth: 2),
                          )
                        : const Icon(FluentIcons.search, size: 14),
                    label: const Text('搜索'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FluentSpacing.m),
        if (_isLoading && _result == null)
          const FluentSurface(
            padding: EdgeInsets.all(FluentSpacing.xl),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: FluentProgressRing(strokeWidth: 2),
                ),
                SizedBox(width: FluentSpacing.s),
                Text('正在读取过程化成绩...'),
              ],
            ),
          )
        else if (_result != null && (!_result!.isSuccess || snapshot == null))
          FluentInfoBar(
            title: Text(_result!.message),
            content: Text(_result!.detail),
            severity: _examSeverity(_result!.status),
          )
        else if (records.isEmpty)
          const FluentInfoBar(
            key: Key('academic-eams-grade-process-empty'),
            title: Text('暂无过程化成绩'),
            content: Text('所选学期没有可展示的平时成绩记录。'),
            severity: FluentInfoSeverity.info,
          )
        else
          FluentSurface(
            padding: const EdgeInsets.all(FluentSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('完整内容', style: theme.typography.bodyStrong),
                const SizedBox(height: FluentSpacing.m),
                _AcademicGradeProcessList(records: records),
              ],
            ),
          ),
      ],
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
    required this.accent,
  });

  final String? semesterLabel;
  final int courseCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final scope = semesterLabel ?? '过程化成绩';
    final summary = courseCount == 0
        ? '$scope · 暂无平时成绩'
        : '$scope · $courseCount 门课程有平时成绩';
    return FluentSurface(
      accentColor: accent,
      padding: const EdgeInsets.all(FluentSpacing.l),
      child: Row(
        children: [
          FluentSurfaceIcon(
            icon: FluentIcons.certificate,
            color: accent,
            size: 36,
          ),
          const SizedBox(width: FluentSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '过程化成绩',
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
                const SizedBox(height: FluentSpacing.xxs),
                Text(
                  summary,
                  style: theme.typography.subtitle?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
    final borderColor = context.fluentColors.neutralStroke1;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(context.fluentRadii.medium),
      ),
      child: Column(
        children: [
          for (var index = 0; index < records.length; index++) ...[
            _AcademicGradeProcessListItem(record: records[index]),
            if (index != records.length - 1)
              Container(height: 1, color: borderColor),
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
    final theme = FluentTheme.of(context);
    final meta = [
      if ((record.category ?? '').trim().isNotEmpty) record.category!.trim(),
      if (record.credit != null) '${_formatGradeCredit(record.credit!)} 学分',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.all(FluentSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  record.courseName,
                  style: theme.typography.bodyStrong,
                ),
              ),
              if (meta.isNotEmpty)
                Text(
                  meta,
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: FluentSpacing.s),
          Wrap(
            spacing: FluentSpacing.s,
            runSpacing: FluentSpacing.s,
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
    final theme = FluentTheme.of(context);
    final accent = context.fluentAccents.academic;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.s,
        vertical: FluentSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: context.fluentRadii.smallBorder,
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
          const SizedBox(width: FluentSpacing.xs),
          Text(
            item.value,
            style: theme.typography.caption?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
