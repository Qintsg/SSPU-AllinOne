/*
 * 教务中心本专科成绩详情页 — 标题下汇总横幅 + 按学期前端分组的完整成绩
 * @Project : SSPU-AllinOne
 * @File : academic_eams_grade_detail_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-14
 */

part of 'academic_page.dart';

typedef AcademicGradeDetailResultChanged =
    void Function(AcademicEamsQueryResult result);

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
  AcademicEamsQueryResult? _result;

  /// 当前选中学期；null 表示展示全部学期（默认）。
  String? _selectedTerm;
  bool _isLoading = false;

  /// "全部学期" 在下拉中的占位值。
  static const String _allTermsValue = '';

  @override
  void initState() {
    super.initState();
    _result = widget.initialResult;
    if (widget.initialResult == null) {
      unawaited(_loadGrades());
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return FluentPage.scrollable(
      header: FluentPageHeader(
        title: const Text('成绩详情'),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FluentButton.outline(
              key: const Key('academic-eams-grade-process-entry'),
              onPressed: _openProcessGrades,
              child: const Text('过程化成绩'),
            ),
            const SizedBox(width: FluentSpacing.s),
            FluentButton.outline(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
      children: [
        _AcademicGradeSummaryBanner(
          scopeLabel: currentTerm ?? '全部学期',
          courseCount: records.length,
          credits: credits,
          gpa: gpa,
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
                key: const Key('academic-eams-grade-term-select'),
                label: '学年学期',
                width: 220,
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
                        () => _selectedTerm = term == _allTermsValue
                            ? null
                            : term,
                      ),
              ),
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FluentButton.primaryIcon(
                    key: const Key('academic-eams-grade-detail-refresh'),
                    onPressed: _isLoading ? null : _loadGrades,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: FluentProgressRing(strokeWidth: 2),
                          )
                        : const Icon(FluentIcons.refresh, size: 14),
                    label: const Text('刷新'),
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
                Text('正在读取成绩...'),
              ],
            ),
          )
        else if (_result == null)
          const FluentInfoBar(
            title: Text('尚未读取成绩'),
            content: Text('点击“刷新”即可只读获取当前学期与历史成绩。'),
            severity: FluentInfoSeverity.info,
          )
        else if (!_result!.isSuccess || snapshot == null)
          FluentInfoBar(
            title: Text(_result!.message),
            content: Text(_result!.detail),
            severity: _examSeverity(_result!.status),
          )
        else
          FluentSurface(
            padding: const EdgeInsets.all(FluentSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '完整内容',
                  style: FluentTheme.of(context).typography.bodyStrong,
                ),
                const SizedBox(height: FluentSpacing.m),
                _AcademicGradeTable(records: records),
              ],
            ),
          ),
      ],
    );
  }

  void _openProcessGrades() {
    Navigator.of(context).push(
      FluentPageRoute(
        builder: (_) => AcademicEamsGradeProcessPage(
          academicEamsService: widget.academicEamsService,
        ),
      ),
    );
  }

  Future<void> _loadGrades() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final result = await widget.academicEamsService.fetchGrades(
      requireCampusNetwork: false,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _isLoading = false;
      final terms = result.snapshot?.grades?.availableTerms ?? const <String>[];
      if (_selectedTerm != null && !terms.contains(_selectedTerm)) {
        _selectedTerm = null;
      }
    });
    widget.onResultChanged(result);
  }
}

/// 成绩详情顶部汇总横幅。
class _AcademicGradeSummaryBanner extends StatelessWidget {
  const _AcademicGradeSummaryBanner({
    required this.scopeLabel,
    required this.courseCount,
    required this.credits,
    required this.gpa,
  });

  final String scopeLabel;
  final int courseCount;
  final double credits;
  final double? gpa;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final accent = context.fluentAccents.academic;
    final summary = courseCount == 0
        ? '$scopeLabel · 暂无成绩'
        : '$scopeLabel · $courseCount 门 · ${_formatGradeCredit(credits)} 学分'
              '${gpa == null ? '' : ' · GPA ${gpa!.toStringAsFixed(2)}'}';
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
                  '成绩汇总',
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

class _AcademicGradeTable extends StatelessWidget {
  const _AcademicGradeTable({required this.records});

  static const List<String> _headers = ['课程名称', '学年学期', '学分', '绩点', '总评成绩'];

  final List<AcademicGradeRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Text(
        '所选学期暂无可展示的成绩。',
        style: FluentTheme.of(context).typography.caption?.copyWith(
          color: FluentTheme.of(context).resources.textFillColorSecondary,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return _AcademicGradeRecordList(records: records);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth < 720 ? 720 : constraints.maxWidth,
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(
                color: context.fluentColors.neutralStroke1,
              ),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FixedColumnWidth(150),
                2: FixedColumnWidth(80),
                3: FixedColumnWidth(80),
                4: FixedColumnWidth(120),
              },
              children: [
                _headerRow(context),
                for (final record in records) _recordRow(record),
              ],
            ),
          ),
        );
      },
    );
  }

  TableRow _headerRow(BuildContext context) {
    return TableRow(
      decoration: BoxDecoration(
        color: FluentTheme.of(context).resources.controlAltFillColorSecondary,
      ),
      children: [
        for (final header in _headers)
          _AcademicGradeTableCell(header, header: true, center: true),
      ],
    );
  }

  TableRow _recordRow(AcademicGradeRecord record) {
    return TableRow(
      children: [
        _AcademicGradeTableCell(record.courseName),
        _AcademicGradeTableCell(record.termName ?? '', center: true),
        _AcademicGradeTableCell(
          record.credit == null ? '' : _formatGradeCredit(record.credit!),
          center: true,
        ),
        _AcademicGradeTableCell(
          record.gradePoint == null
              ? ''
              : record.gradePoint!.toStringAsFixed(1),
          center: true,
        ),
        _AcademicGradeTableCell(record.totalScoreText ?? '', center: true),
      ],
    );
  }
}

class _AcademicGradeRecordList extends StatelessWidget {
  const _AcademicGradeRecordList({required this.records});

  final List<AcademicGradeRecord> records;

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
            _AcademicGradeRecordListItem(record: records[index]),
            if (index != records.length - 1)
              Container(height: 1, color: borderColor),
          ],
        ],
      ),
    );
  }
}

class _AcademicGradeRecordListItem extends StatelessWidget {
  const _AcademicGradeRecordListItem({required this.record});

  final AcademicGradeRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(FluentSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(record.courseName, style: theme.typography.bodyStrong),
          const SizedBox(height: FluentSpacing.s),
          Wrap(
            spacing: FluentSpacing.l,
            runSpacing: FluentSpacing.s,
            children: [
              _AcademicGradeRecordField(label: '学年学期', value: record.termName),
              _AcademicGradeRecordField(
                label: '学分',
                value: record.credit == null
                    ? null
                    : _formatGradeCredit(record.credit!),
              ),
              _AcademicGradeRecordField(
                label: '绩点',
                value: record.gradePoint?.toStringAsFixed(1),
              ),
              _AcademicGradeRecordField(
                label: '总评成绩',
                value: record.totalScoreText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcademicGradeRecordField extends StatelessWidget {
  const _AcademicGradeRecordField({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 96, maxWidth: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
          const SizedBox(height: FluentSpacing.xxs),
          Text(_gradeText(value), style: theme.typography.body),
        ],
      ),
    );
  }
}

class _AcademicGradeTableCell extends StatelessWidget {
  const _AcademicGradeTableCell(
    this.text, {
    this.header = false,
    this.center = false,
  });

  final String text;
  final bool header;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.s,
        vertical: FluentSpacing.s,
      ),
      child: Text(
        _gradeText(text),
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: (header ? theme.typography.bodyStrong : theme.typography.body)
            ?.copyWith(fontWeight: header ? FontWeight.w700 : null),
      ),
    );
  }
}
