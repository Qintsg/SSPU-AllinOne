/*
 * 教务中心本专科考试安排卡片 — 展示 EAMS 考试安排紧凑预览
 * @Project : SSPU-AllinOne
 * @File : academic_eams_exam_card.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

part of 'academic_page.dart';

/// 教务中心本专科考试安排子卡片。
class AcademicEamsExamCard extends StatelessWidget {
  /// 最近一次考试安排查询结果。
  final AcademicEamsQueryResult? result;

  /// 当前是否正在读取考试安排。
  final bool isLoading;

  /// 默认使用的全局学期。
  final AcademicTermChoice? selectedTerm;

  /// 打开考试安排详情页。
  final VoidCallback onOpenDetail;

  const AcademicEamsExamCard({
    super.key,
    required this.result,
    required this.isLoading,
    required this.selectedTerm,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final snapshot = result?.snapshot?.exams;
    final records = snapshot?.records ?? const <AcademicExamRecord>[];
    final scheduledRecords = records
        .where((record) => record.hasScheduledExamDate)
        .toList();
    final currentTerm = _academicExamSelectedTerm(
      snapshot,
      snapshot?.semesterOptions ?? const [],
      selectedTerm: selectedTerm,
      selectedSemester: snapshot?.selectedSemester,
    );
    return YhCard(
      key: const Key('academic-eams-exam-card'),
      padding: EdgeInsets.all(theme.spacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AcademicExamCardHeader(
            totalCount: records.length,
            scheduledCount: scheduledRecords.length,
            examTypeLabel: snapshot?.selectedExamTypeLabel,
            isLoading: isLoading,
            selectedTerm: currentTerm,
            onOpenDetail: onOpenDetail,
          ),
          SizedBox(height: theme.spacing.m),
          if (isLoading)
            Row(
              children: [
                SizedBox(
                  width: theme.spacing.xl2 * 2,
                  child: const YhProgress(showPercent: false),
                ),
                SizedBox(width: theme.spacing.s),
                const Expanded(child: Text('正在读取考试安排...')),
              ],
            )
          else if (result == null)
            Text(
              currentTerm == null
                  ? '选择学年和学期后随本专科教务刷新读取。'
                  : '${currentTerm.label} 的考试安排尚未读取。',
              style: theme.typography.body.copyWith(color: theme.color.muted),
            )
          else if (result!.isSuccess && snapshot != null)
            _AcademicExamPreview(
              scheduledRecords: scheduledRecords,
              totalCount: records.length,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result!.message,
                  style: theme.typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.s),
                YhBanner(
                  text: result!.detail,
                  kind: _examBannerKind(result!.status),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AcademicExamCardHeader extends StatelessWidget {
  const _AcademicExamCardHeader({
    required this.totalCount,
    required this.scheduledCount,
    required this.examTypeLabel,
    required this.isLoading,
    required this.selectedTerm,
    required this.onOpenDetail,
  });

  final int totalCount;
  final int scheduledCount;
  final String? examTypeLabel;
  final bool isLoading;
  final AcademicTermChoice? selectedTerm;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceAcademic;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: theme.control.compact,
          child: Icon(YhIcons.calendar, color: accent),
        ),
        SizedBox(width: theme.spacing.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('考试安排', style: theme.typography.h3),
              SizedBox(height: theme.spacing.xs),
              Text(
                _subtitle,
                style: theme.typography.caption.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: theme.spacing.s),
        YhTooltip(
          message: '查看考试安排详情',
          child: YhIconButton(
            key: const Key('academic-eams-exam-detail'),
            icon: YhIcons.chevronRight,
            semanticLabel: '查看考试安排详情',
            onTap: onOpenDetail,
          ),
        ),
      ],
    );
  }

  String get _subtitle {
    if (isLoading) return '正在同步考试安排';
    final type = examTypeLabel ?? '期末考试';
    final base = totalCount == 0
        ? '$type · 暂无考试'
        : scheduledCount == 0
        ? '$type · $totalCount 门待公布时间'
        : '$type · 共 $totalCount 门，$scheduledCount 门已排期';
    final term = selectedTerm?.label;
    return term == null ? base : '$term · $base';
  }
}

class _AcademicExamPreview extends StatelessWidget {
  const _AcademicExamPreview({
    required this.scheduledRecords,
    required this.totalCount,
  });

  /// 已公布考试时间的记录，用于预览。
  final List<AcademicExamRecord> scheduledRecords;

  /// 当前学期考试总门数（含未公布时间的）。
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (totalCount == 0) {
      return Text(
        '当前学期暂无可展示的考试信息。',
        style: theme.typography.caption.copyWith(color: theme.color.muted),
      );
    }
    // 全部考试都未公布时间时，给出明确提示而非空白。
    if (scheduledRecords.isEmpty) {
      return Text(
        '$totalCount 门考试尚未公布时间，进入详情查看课程与说明。',
        style: theme.typography.body,
      );
    }

    final visibleRecords = scheduledRecords.take(2).toList();
    final remaining = totalCount - visibleRecords.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < visibleRecords.length; index++) ...[
          _AcademicExamPreviewItem(record: visibleRecords[index]),
          if (index != visibleRecords.length - 1)
            Padding(
              padding: EdgeInsets.symmetric(vertical: theme.spacing.s),
              child: Container(height: 1, color: theme.color.border),
            ),
        ],
        if (remaining > 0) ...[
          SizedBox(height: theme.spacing.s),
          Text(
            '还有 $remaining 门考试信息，进入详情查看完整内容。',
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
        ],
      ],
    );
  }
}

class _AcademicExamPreviewItem extends StatelessWidget {
  const _AcademicExamPreviewItem({required this.record});

  final AcademicExamRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final metas = [
      if ((record.displayExamDate ?? '').trim().isNotEmpty)
        record.displayExamDate!,
      if ((record.displayExamArrange ?? '').trim().isNotEmpty)
        record.displayExamArrange!,
      if ((record.displayExamLocation ?? '').trim().isNotEmpty)
        record.displayExamLocation!,
      if ((record.displayExamSituation ?? '').trim().isNotEmpty)
        record.displayExamSituation!,
      if ((record.displayOtherExplanation ?? '').trim().isNotEmpty)
        record.displayOtherExplanation!,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          record.courseName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.typography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: theme.spacing.xs),
        Text(
          metas.isEmpty ? '暂无具体考试安排' : metas.join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.typography.caption.copyWith(color: theme.color.muted),
        ),
      ],
    );
  }
}

List<AcademicEamsSemesterOption> _academicExamSemesterOptions(
  AcademicExamSnapshot? snapshot, {
  AcademicEamsSemesterOption? selectedSemester,
  AcademicTermChoice? selectedTerm,
}) {
  final options = [...?snapshot?.semesterOptions];
  final selected = snapshot?.selectedSemester ?? selectedSemester;
  if (selected != null && !options.any((option) => option.id == selected.id)) {
    options.insert(0, selected);
  }
  if (options.isEmpty && selectedTerm != null) {
    options.add(
      AcademicEamsSemesterOption(
        id: '',
        label: selectedTerm.label,
        academicYear: selectedTerm.academicYear,
        termCode: _academicExamTermCodeForSeason(selectedTerm.season),
        termChoice: selectedTerm,
      ),
    );
  }
  return List.unmodifiable(options);
}

AcademicTermChoice? _academicExamSelectedTerm(
  AcademicExamSnapshot? snapshot,
  List<AcademicEamsSemesterOption> options, {
  AcademicEamsSemesterOption? selectedSemester,
  AcademicTermChoice? selectedTerm,
}) {
  if (selectedTerm != null) return selectedTerm;
  final selected = _academicExamSelectedSemester(
    snapshot,
    options,
    selectedSemester: selectedSemester,
    selectedTerm: selectedTerm,
  );
  if (selected?.termChoice != null) return selected!.termChoice;
  if (options.isEmpty) return null;
  return options.first.termChoice;
}

AcademicEamsSemesterOption? _academicExamSelectedSemester(
  AcademicExamSnapshot? snapshot,
  List<AcademicEamsSemesterOption> options, {
  AcademicEamsSemesterOption? selectedSemester,
  AcademicTermChoice? selectedTerm,
}) {
  if (selectedSemester != null) {
    for (final option in options) {
      if (option.id == selectedSemester.id) return option;
    }
  }
  if (selectedTerm != null) {
    for (final option in options) {
      if (option.matchesTerm(selectedTerm)) return option;
    }
  }
  final selected = snapshot?.selectedSemester;
  if (selected != null) {
    for (final option in options) {
      if (option.id == selected.id) return option;
    }
  }
  return options.isEmpty ? null : options.first;
}

List<int> _academicExamAvailableYears(
  List<AcademicEamsSemesterOption> options,
  AcademicTermChoice? currentTerm,
) {
  final years = <int>{
    if (currentTerm != null) currentTerm.academicYear,
    for (final option in options)
      if (option.academicYear != null) option.academicYear!,
  }.toList()..sort();
  return years.isEmpty ? [DateTime.now().year] : years;
}

List<AcademicTermSeason> _academicExamAvailableSeasons(
  List<AcademicEamsSemesterOption> options,
  AcademicTermChoice? currentTerm,
) {
  return AcademicTermSeason.values;
}

AcademicTermSeason? _academicExamSeasonForYear(
  List<AcademicEamsSemesterOption> options,
  int year,
  AcademicTermSeason? preferred,
) {
  if (preferred != null &&
      options.any(
        (option) =>
            option.academicYear == year &&
            option.termChoice?.season == preferred,
      )) {
    return preferred;
  }
  for (final season in AcademicTermSeason.values) {
    if (options.any(
      (option) =>
          option.academicYear == year && option.termChoice?.season == season,
    )) {
      return season;
    }
  }
  return preferred;
}

String _academicExamTermCodeForSeason(AcademicTermSeason season) {
  return switch (season) {
    AcademicTermSeason.fall => '1',
    AcademicTermSeason.spring => '2',
    AcademicTermSeason.summer => '3',
  };
}

YhBannerKind _examBannerKind(AcademicEamsQueryStatus status) {
  return switch (status) {
    AcademicEamsQueryStatus.success => YhBannerKind.success,
    AcademicEamsQueryStatus.partialSuccess ||
    AcademicEamsQueryStatus.missingOaAccount ||
    AcademicEamsQueryStatus.missingOaPassword ||
    AcademicEamsQueryStatus.campusNetworkUnavailable => YhBannerKind.warn,
    _ => YhBannerKind.danger,
  };
}

class _AcademicExamTable extends StatelessWidget {
  const _AcademicExamTable({required this.records});

  static const List<String> _headers = [
    '考试类型',
    '课程序号',
    '课程名称',
    '考试日期',
    '考试安排',
    '考试地点',
    '考试情况',
    '其它说明',
  ];

  final List<AcademicExamRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (records.isEmpty) {
      return Text(
        '当前学期暂无可展示的考试信息。',
        style: theme.typography.caption.copyWith(color: theme.color.muted),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            theme.breakpoint.compact + theme.control.compact) {
          return _AcademicExamRecordList(records: records);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth:
                  constraints.maxWidth <
                      theme.breakpoint.expanded - theme.spacing.xl
                  ? theme.breakpoint.expanded - theme.spacing.xl
                  : constraints.maxWidth,
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: theme.color.border),
              columnWidths: const {
                0: FixedColumnWidth(104),
                1: FixedColumnWidth(128),
                2: FlexColumnWidth(1.4),
                3: FixedColumnWidth(140),
                4: FlexColumnWidth(1.2),
                5: FixedColumnWidth(150),
                6: FixedColumnWidth(120),
                7: FlexColumnWidth(),
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
      decoration: BoxDecoration(color: context.yhTheme.color.sunken),
      children: [
        for (final header in _headers)
          _AcademicExamTableCell(header, header: true, center: true),
      ],
    );
  }

  TableRow _recordRow(AcademicExamRecord record) {
    return TableRow(
      children: [
        _AcademicExamTableCell(record.examType ?? '', center: true),
        _AcademicExamTableCell(record.courseSequence ?? '', center: true),
        _AcademicExamTableCell(record.courseName),
        _AcademicExamTableCell(
          record.displayExamDate ?? '',
          center: true,
          emptyPlaceholder: '',
        ),
        _AcademicExamTableCell(record.displayExamArrange ?? ''),
        _AcademicExamTableCell(record.displayExamLocation ?? ''),
        _AcademicExamTableCell(record.displayExamSituation ?? '', center: true),
        _AcademicExamTableCell(record.displayOtherExplanation ?? ''),
      ],
    );
  }
}

class _AcademicExamRecordList extends StatelessWidget {
  const _AcademicExamRecordList({required this.records});

  final List<AcademicExamRecord> records;

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
            _AcademicExamRecordListItem(record: records[index]),
            if (index != records.length - 1)
              Container(height: 1, color: borderColor),
          ],
        ],
      ),
    );
  }
}

class _AcademicExamRecordListItem extends StatelessWidget {
  const _AcademicExamRecordListItem({required this.record});

  final AcademicExamRecord record;

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
              _AcademicExamRecordField(label: '考试类型', value: record.examType),
              _AcademicExamRecordField(
                label: '课程序号',
                value: record.courseSequence,
              ),
              _AcademicExamRecordField(
                label: '考试日期',
                value: record.displayExamDate,
              ),
              _AcademicExamRecordField(
                label: '考试安排',
                value: record.displayExamArrange,
              ),
              _AcademicExamRecordField(
                label: '考试地点',
                value: record.displayExamLocation,
              ),
              _AcademicExamRecordField(
                label: '考试情况',
                value: record.displayExamSituation,
              ),
              _AcademicExamRecordField(
                label: '其它说明',
                value: record.displayOtherExplanation,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcademicExamRecordField extends StatelessWidget {
  const _AcademicExamRecordField({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: theme.control.regular * 2,
        maxWidth: theme.breakpoint.compact / 3 + theme.spacing.l,
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
          Text(_examText(value), style: theme.typography.body),
        ],
      ),
    );
  }
}

class _AcademicExamTableCell extends StatelessWidget {
  const _AcademicExamTableCell(
    this.text, {
    this.header = false,
    this.center = false,
    this.emptyPlaceholder = '-',
  });

  final String text;
  final bool header;
  final bool center;
  final String emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.s,
        vertical: theme.spacing.s,
      ),
      child: Text(
        _examText(text, placeholder: emptyPlaceholder),
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: theme.typography.body.copyWith(
          fontWeight: header ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

String _examText(String? value, {String placeholder = '-'}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? placeholder : text;
}
