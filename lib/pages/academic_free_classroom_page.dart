/*
 * 空闲教室查询页 — 按日期与节次查找可用教学空间
 * @Project : SSPU-AllinOne
 * @File : academic_free_classroom_page.dart
 * @Author : Qintsg
 * @Date : 2026-09-08
 */

part of 'academic_page.dart';

/// 教务中心空闲教室只读查询页。
class AcademicFreeClassroomPage extends StatefulWidget {
  const AcademicFreeClassroomPage({
    super.key,
    required this.client,
    this.nowOverride,
  });

  /// 只读空闲教室查询客户端。
  final AcademicFreeClassroomClient client;

  /// 测试用确定性时钟。
  final DateTime? nowOverride;

  @override
  State<AcademicFreeClassroomPage> createState() =>
      _AcademicFreeClassroomPageState();
}

class _AcademicFreeClassroomPageState extends State<AcademicFreeClassroomPage> {
  late final TextEditingController _campusController;
  late final TextEditingController _buildingController;
  late final TextEditingController _dateController;
  AcademicEamsQueryResult? _result;
  AcademicEamsQueryResult? _lastSuccessfulResult;
  int _lessonFrom = 1;
  int _lessonTo = 2;
  int _generation = 0;
  bool _isLoading = false;
  String? _validationMessage;

  DateTime get _now => widget.nowOverride ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _campusController = TextEditingController();
    _buildingController = TextEditingController();
    _dateController = TextEditingController(text: _formatDate(_now));
  }

  @override
  void dispose() {
    _generation++;
    _campusController.dispose();
    _buildingController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = _result?.freeClassrooms;
    return YhTaskPage(
      title: '空闲教室',
      kicker: '学习空间',
      summary: '按日期和节次查找可用教室；结果仅供查看，不执行占用操作。',
      source: '本专科教务 · 空闲教室',
      sourceSymbol: '室',
      sourceTimestamp: _academicDetailTimestamp(search?.fetchedAt),
      appBarTitle: _academicTaskAppBarTitle('空闲教室', search?.fetchedAt),
      primaryActionKey: const Key('free-classroom-search'),
      primaryActionLabel: _isLoading ? '正在查询…' : '查询教室',
      onPrimaryAction: _isLoading ? null : () => unawaited(_search()),
      width: YhTaskPageWidth.constrained,
      rhythm: YhTaskPageRhythm.relaxedCompact,
      bodyFit: YhTaskPageBodyFit.content,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCriteriaCard(context),
        if (_validationMessage != null) ...[
          SizedBox(height: theme.spacing.m),
          YhBanner(kind: YhBannerKind.danger, text: _validationMessage!),
        ],
        SizedBox(height: theme.spacing.l),
        _buildResult(context),
      ],
    );
  }

  Widget _buildCriteriaCard(BuildContext context) {
    final theme = context.yhTheme;
    final lessonOptions = [
      for (var lesson = 1; lesson <= 13; lesson++)
        YhSelectOption(value: lesson, label: '第 $lesson 节'),
    ];
    return YhCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < theme.breakpoint.compact;
          final fieldWidth = compact
              ? constraints.maxWidth
              : (constraints.maxWidth - theme.spacing.m) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('查询条件', style: theme.typography.h2),
              SizedBox(height: theme.spacing.xs),
              Text(
                '校区和楼宇可留空；默认查询今天第 1—2 节。',
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
              SizedBox(height: theme.spacing.m),
              Wrap(
                spacing: theme.spacing.m,
                runSpacing: theme.spacing.m,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: YhTextField(
                      key: const Key('free-classroom-campus'),
                      label: '校区',
                      controller: _campusController,
                      hint: '例如：金海路校区',
                      enabled: !_isLoading,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: YhTextField(
                      key: const Key('free-classroom-building'),
                      label: '楼宇',
                      controller: _buildingController,
                      hint: '例如：综合楼',
                      enabled: !_isLoading,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: YhTextField(
                      key: const Key('free-classroom-date'),
                      label: '日期',
                      controller: _dateController,
                      hint: 'YYYY-MM-DD',
                      helper: '使用校本地日期',
                      enabled: !_isLoading,
                      keyboardType: TextInputType.datetime,
                      onSubmitted: (_) => unawaited(_search()),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: YhSelect<int>(
                            key: const Key('free-classroom-lesson-from'),
                            label: '起始节次',
                            options: lessonOptions,
                            value: _lessonFrom,
                            enabled: !_isLoading,
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _lessonFrom = value);
                                    }
                                  },
                          ),
                        ),
                        SizedBox(width: theme.spacing.s),
                        Expanded(
                          child: YhSelect<int>(
                            key: const Key('free-classroom-lesson-to'),
                            label: '结束节次',
                            options: lessonOptions,
                            value: _lessonTo,
                            enabled: !_isLoading,
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _lessonTo = value);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: theme.spacing.m),
              Wrap(
                spacing: theme.spacing.s,
                runSpacing: theme.spacing.s,
                children: [
                  YhStatusPill(
                    label: '第 $_lessonFrom—$_lessonTo 节',
                    kind: YhStatusKind.info,
                  ),
                  const YhStatusPill(label: '只读查询', kind: YhStatusKind.neutral),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final theme = context.yhTheme;
    final result = _result;
    final search = result?.freeClassrooms;
    if (_isLoading && result == null) {
      return const _AcademicDetailStateCard(
        child: _AcademicDetailLoadingState(title: '正在查找空闲教室', source: '本专科教务'),
      );
    }
    if (result == null) {
      return _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '→',
          title: '选择时间范围后查询',
          message: '结果会在本页原位更新，查询失败时保留上一次有效列表。',
          accent: theme.color.serviceAcademic,
          actionLabel: '查询教室',
          onAction: () => unawaited(_search()),
        ),
      );
    }
    if (!result.isSuccess || search == null) {
      final retained = _lastSuccessfulResult?.freeClassrooms;
      if (retained != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            YhBanner(
              kind: YhBannerKind.danger,
              text:
                  '${_academicEamsFailureDescription(result, fallback: '查询失败，请稍后重试。')}；已保留上一次有效结果。',
            ),
            SizedBox(height: theme.spacing.m),
            _buildSuccessfulResult(context, retained),
          ],
        );
      }
      return _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '!',
          title: '本次查询未完成',
          message: _academicEamsFailureDescription(
            result,
            fallback: '请检查账户、校园网或 VPN 后重试。',
          ),
          accent: theme.color.serviceAcademic,
          actionLabel: '重新查询',
          onAction: () => unawaited(_search()),
        ),
      );
    }
    return _buildSuccessfulResult(context, search);
  }

  Widget _buildSuccessfulResult(
    BuildContext context,
    AcademicFreeClassroomSearchResult search,
  ) {
    final theme = context.yhTheme;
    if (search.records.isEmpty) {
      return _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '○',
          title: '当前条件没有可用教室',
          message: '尝试放宽楼宇条件，或更换节次后再查询。',
          accent: theme.color.serviceAcademic,
          actionLabel: '调整后重试',
          onAction: () => unawaited(_search()),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AcademicEvidenceMetricsPanel(
          metrics: [
            _AcademicEvidenceMetric('${search.records.length} 间', '可用教室'),
            _AcademicEvidenceMetric(
              '第 ${search.criteria.lessonFrom ?? _lessonFrom}—${search.criteria.lessonTo ?? _lessonTo} 节',
              '查询节次',
            ),
            _AcademicEvidenceMetric(
              search.criteria.dateText ?? _dateController.text,
              '查询日期',
            ),
          ],
        ),
        SizedBox(height: theme.spacing.m),
        _buildRoomGrid(context, search.records),
      ],
    );
  }

  Widget _buildRoomGrid(
    BuildContext context,
    List<AcademicFreeClassroomRecord> records,
  ) {
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < theme.breakpoint.medium;
        final cardWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - theme.spacing.m) / 2;
        return Wrap(
          spacing: theme.spacing.m,
          runSpacing: theme.spacing.m,
          children: [
            for (final record in records)
              SizedBox(
                width: cardWidth,
                child: YhCard(
                  key: ValueKey('free-classroom-${record.roomName}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.roomName, style: theme.typography.h2),
                      SizedBox(height: theme.spacing.s),
                      Wrap(
                        spacing: theme.spacing.s,
                        runSpacing: theme.spacing.s,
                        children: [
                          if ((record.campus ?? '').trim().isNotEmpty)
                            YhChip(label: record.campus!),
                          if ((record.building ?? '').trim().isNotEmpty)
                            YhChip(label: record.building!),
                          if (record.capacity != null)
                            YhChip(label: '${record.capacity} 座'),
                          if ((record.lessonText ?? '').trim().isNotEmpty)
                            YhChip(label: '第 ${record.lessonText} 节'),
                        ],
                      ),
                      if ((record.location ?? '').trim().isNotEmpty) ...[
                        SizedBox(height: theme.spacing.s),
                        Text(
                          record.location!,
                          style: theme.typography.small.copyWith(
                            color: theme.color.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _search() async {
    final dateText = _dateController.text.trim();
    final parsedDate = DateTime.tryParse(dateText);
    final validDate = parsedDate != null && _formatDate(parsedDate) == dateText;
    if (!validDate) {
      setState(() => _validationMessage = '请使用 YYYY-MM-DD 格式填写日期。');
      return;
    }
    if (_lessonFrom > _lessonTo) {
      setState(() => _validationMessage = '结束节次不能早于起始节次。');
      return;
    }
    final generation = ++_generation;
    setState(() {
      _validationMessage = null;
      _isLoading = true;
    });
    final criteria = AcademicFreeClassroomSearchCriteria(
      campus: _optionalText(_campusController.text),
      building: _optionalText(_buildingController.text),
      dateText: dateText,
      lessonFrom: _lessonFrom,
      lessonTo: _lessonTo,
    );
    try {
      final result = await widget.client.searchFreeClassrooms(criteria);
      if (!mounted || generation != _generation) return;
      setState(() {
        _result = result;
        if (result.isSuccess && result.freeClassrooms != null) {
          _lastSuccessfulResult = result;
        }
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _result = AcademicEamsQueryResult(
          status: AcademicEamsQueryStatus.unexpectedError,
          message: '空闲教室查询失败',
          detail: '未分类异常：${error.runtimeType}',
          checkedAt: DateTime.now(),
          entranceUri: AcademicEamsService.defaultEntranceUri,
        );
      });
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _isLoading = false);
      }
    }
  }

  static String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
