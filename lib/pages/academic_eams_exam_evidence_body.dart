/*
 * 教务考试证据正文 — 编排筛选、状态恢复与时间轴记录。
 * @Project : SSPU-AllinOne
 * @File : academic_eams_exam_evidence_body.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_page.dart';

extension _AcademicExamEvidenceBody on _AcademicEamsExamDetailPageState {
  /// 构建考试筛选、恢复状态与连续时间轴的证据正文。
  Widget _buildEvidenceBody(
    BuildContext context,
    YhTheme theme, {
    required AcademicExamSnapshot? snapshot,
    required List<AcademicExamRecord> records,
    required List<AcademicEamsSemesterOption> semesterOptions,
    required AcademicTermChoice? currentTerm,
    required List<int> years,
    required List<AcademicTermSeason> seasons,
  }) {
    final gap = MediaQuery.sizeOf(context).width < theme.breakpoint.compact
        ? theme.spacing.m
        : theme.spacing.l;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    final fieldWidth = compact
        ? theme.control.regular * 2 - theme.spacing.xs
        : theme.control.regular * 4;
    final filter = _AcademicEamsFilterPanel(
      children: [
        _AcademicExamDropdownField<int>(
          key: const Key('academic-eams-exam-year-select'),
          label: '学年',
          width: fieldWidth,
          value: currentTerm?.academicYear,
          placeholder: '等待学期',
          items: [
            for (final year in years)
              _AcademicExamDropdownItem<int>(
                key: Key('academic-eams-exam-year-option-$year'),
                value: year,
                label: _academicExamYearLabel(year),
              ),
          ],
          onChanged: _isLoading || currentTerm == null || years.isEmpty
              ? null
              : (year) =>
                    _handleYearChanged(year, semesterOptions, currentTerm),
        ),
        _AcademicExamDropdownField<AcademicTermSeason>(
          key: const Key('academic-eams-exam-season-select'),
          label: '学期',
          width: fieldWidth,
          value: currentTerm?.season,
          placeholder: '等待学期',
          items: [
            for (final season in seasons)
              _AcademicExamDropdownItem<AcademicTermSeason>(
                key: Key('academic-eams-exam-season-option-${season.name}'),
                value: season,
                label: season.label,
              ),
          ],
          onChanged: _isLoading || currentTerm == null
              ? null
              : (season) =>
                    _handleTermChanged(currentTerm.copyWith(season: season)),
        ),
        _AcademicExamDropdownField<String>(
          key: const Key('academic-eams-exam-type-select'),
          label: '考试类型',
          width: fieldWidth,
          value: _examTypeOptions.containsKey(_selectedExamType)
              ? _selectedExamType
              : _examTypeOptions.keys.first,
          placeholder: '考试类型',
          items: [
            for (final entry in _examTypeOptions.entries)
              _AcademicExamDropdownItem<String>(
                key: Key('academic-eams-exam-type-option-${entry.key}'),
                value: entry.key,
                label: entry.value,
              ),
          ],
          onChanged: _isLoading
              ? null
              : (type) => _setAcademicState(() => _selectedExamType = type),
        ),
      ],
    );
    Widget content;
    if (_isLoading && _result == null) {
      content = const _AcademicDetailStateCard(
        child: _AcademicDetailLoadingState(
          title: '正在读取考试安排',
          source: '教务考试 · 本地快照',
        ),
      );
    } else if (_result == null || !_result!.isSuccess || snapshot == null) {
      content = _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '!',
          title: '考试安排暂不可用',
          message: _academicEamsFailureDescription(
            _result,
            fallback: '无法完成本次读取；可在本页重试，已有有效快照不会被清空。',
          ),
          accent: theme.color.serviceAcademic,
          actionLabel: '检查后重试',
          onAction: () => unawaited(_loadExamSchedule()),
        ),
      );
    } else if (records.isEmpty) {
      content = _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '○',
          title: '当前没有考试安排记录',
          message: '当前筛选范围没有可展示的原始记录；可调整学期或稍后在原位置重新读取。',
          accent: theme.color.serviceAcademic,
          actionLabel: '重新读取',
          onAction: () => unawaited(_loadExamSchedule()),
        ),
      );
    } else {
      final scheduledCount = records
          .where((record) => record.hasScheduledExamDate)
          .length;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AcademicEvidenceMetricsPanel(
            metrics: [
              _AcademicEvidenceMetric('${records.length}', '考试课程'),
              _AcademicEvidenceMetric('$scheduledCount', '已经排期'),
              _AcademicEvidenceMetric(
                '${records.length - scheduledCount}',
                '等待公布',
              ),
            ],
          ),
          SizedBox(height: theme.spacing.m),
          _AcademicEvidenceRecordsPanel(
            kicker: _sortOrder == _AcademicExamSortOrder.ascending
                ? '连续时间正序'
                : '连续时间倒序',
            title: '考试时间轴',
            trailing:
                snapshot.selectedExamTypeLabel ??
                _examTypeOptions[_selectedExamType] ??
                '考试安排',
            action: YhSegmented<_AcademicExamSortOrder>(
              key: const Key('academic-eams-exam-sort'),
              options: const [
                YhSegmentedOption(
                  value: _AcademicExamSortOrder.ascending,
                  label: '正序',
                ),
                YhSegmentedOption(
                  value: _AcademicExamSortOrder.descending,
                  label: '倒序',
                ),
              ],
              value: _sortOrder,
              onChanged: _isLoading
                  ? null
                  : (order) => _setAcademicState(() => _sortOrder = order),
            ),
            children: [
              for (final record in records)
                _AcademicEvidenceRecord(
                  leading: _AcademicExamDateBlock(record: record),
                  title: record.courseName,
                  meta: _gradeText(
                    record.displayExamLocation,
                    placeholder: '地点待公布',
                  ),
                  detail: [
                    if ((record.semesterLabel ?? '').trim().isNotEmpty)
                      record.semesterLabel!.trim(),
                    if ((record.examType ?? '').trim().isNotEmpty)
                      record.examType!.trim(),
                    if ((record.displayExamSituation ?? '').trim().isNotEmpty)
                      record.displayExamSituation!.trim(),
                    if ((record.displayOtherExplanation ??
                            record.otherExplanation ??
                            '')
                        .trim()
                        .isNotEmpty)
                      (record.displayOtherExplanation ??
                              record.otherExplanation ??
                              '')
                          .trim(),
                  ].join(' · '),
                  value: record.hasScheduledExamDate ? '已排期' : '待公布',
                  status: _gradeText(record.courseSequence),
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
          const YhBanner(text: '正在刷新安排；当前筛选范围和有效记录保持可用，完成前已锁定重复请求与范围切换。'),
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
}
