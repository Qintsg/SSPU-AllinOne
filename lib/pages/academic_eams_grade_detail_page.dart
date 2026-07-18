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

    return YhPageScaffold(
      appBar: YhAppBar(
        title: '成绩详情',
        leading: YhIconButton(
          icon: YhIcons.back,
          semanticLabel: '返回',
          variant: YhIconButtonVariant.ghost,
          onTap: () => Navigator.of(context).pop(),
        ),
        actions: [
          YhButton(
            key: const Key('academic-eams-grade-process-entry'),
            label: '过程化成绩',
            leadingIcon: YhIcons.certificate,
            variant: YhButtonVariant.text,
            onTap: _openProcessGrades,
          ),
        ],
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
                _AcademicGradeSummaryBanner(
                  scopeLabel: currentTerm ?? '全部学期',
                  courseCount: records.length,
                  credits: credits,
                  gpa: gpa,
                ),
                SizedBox(height: theme.spacing.m),
                YhCard(
                  child: Wrap(
                    spacing: theme.spacing.s,
                    runSpacing: theme.spacing.s,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      _AcademicExamDropdownField<String>(
                        key: const Key('academic-eams-grade-term-select'),
                        label: '学年学期',
                        width:
                            theme.breakpoint.compact / 3 +
                            theme.spacing.m +
                            theme.spacing.xs,
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
                        height: theme.control.regular,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: YhButton(
                            key: const Key(
                              'academic-eams-grade-detail-refresh',
                            ),
                            label: _isLoading ? '刷新中' : '刷新',
                            leadingIcon: _isLoading ? null : YhIcons.refresh,
                            onTap: _isLoading ? null : _loadGrades,
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
                        const Expanded(child: Text('正在读取成绩...')),
                      ],
                    ),
                  )
                else if (_result == null)
                  YhCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('尚未读取成绩', style: theme.typography.h3),
                        SizedBox(height: theme.spacing.s),
                        const YhBanner(text: '点击“刷新”即可只读获取当前学期与历史成绩。'),
                      ],
                    ),
                  )
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
                        _AcademicGradeTable(records: records),
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

  void _openProcessGrades() {
    Navigator.of(context).push(
      YhPageRoute(
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
    final theme = context.yhTheme;
    final accent = theme.color.serviceAcademic;
    final summary = courseCount == 0
        ? '$scopeLabel · 暂无成绩'
        : '$scopeLabel · $courseCount 门 · ${_formatGradeCredit(credits)} 学分'
              '${gpa == null ? '' : ' · GPA ${gpa!.toStringAsFixed(2)}'}';
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
                  '成绩汇总',
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

class _AcademicGradeTable extends StatelessWidget {
  const _AcademicGradeTable({required this.records});

  static const List<String> _headers = ['课程名称', '学年学期', '学分', '绩点', '总评成绩'];

  final List<AcademicGradeRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (records.isEmpty) {
      return Text(
        '所选学期暂无可展示的成绩。',
        style: theme.typography.caption.copyWith(color: theme.color.muted),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            theme.breakpoint.compact - theme.control.compact) {
          return _AcademicGradeRecordList(records: records);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth:
                  constraints.maxWidth <
                      theme.breakpoint.medium - theme.spacing.xl2
                  ? theme.breakpoint.medium - theme.spacing.xl2
                  : constraints.maxWidth,
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: theme.color.border),
              columnWidths: {
                0: FlexColumnWidth(2),
                1: FixedColumnWidth(theme.breakpoint.compact / 4),
                2: FixedColumnWidth(theme.control.compact * 2),
                3: FixedColumnWidth(theme.control.compact * 2),
                4: FixedColumnWidth(theme.breakpoint.compact / 5),
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
    final theme = context.yhTheme;
    return TableRow(
      decoration: BoxDecoration(color: theme.color.sunken),
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
            _AcademicGradeRecordListItem(record: records[index]),
            if (index != records.length - 1)
              Container(height: theme.layout.divider, color: borderColor),
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
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.all(theme.spacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.courseName,
            style: theme.typography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacing.s),
          Wrap(
            spacing: theme.spacing.l,
            runSpacing: theme.spacing.s,
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
    final theme = context.yhTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: theme.spacing.xl2 * 2,
        maxWidth:
            theme.breakpoint.compact / 3 + theme.spacing.m + theme.spacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.xs),
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
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.s,
        vertical: theme.spacing.s,
      ),
      child: Text(
        _gradeText(text),
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: theme.typography.body.copyWith(
          fontWeight: header ? FontWeight.w700 : null,
        ),
      ),
    );
  }
}
