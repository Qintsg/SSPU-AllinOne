/*
 * 培养方案详情页 — 模块完成度与课程要求浏览
 * @Project : SSPU-AllinOne
 * @File : academic_program_plan_page.dart
 * @Author : Qintsg
 * @Date : 2026-09-08
 */

part of 'academic_page.dart';

typedef AcademicProgramPlanResultChanged =
    void Function(AcademicEamsQueryResult result);

/// 教务中心培养方案只读详情页。
class AcademicProgramPlanPage extends StatefulWidget {
  const AcademicProgramPlanPage({
    super.key,
    required this.client,
    required this.initialResult,
    this.onResultChanged,
  });

  final AcademicProgramPlanClient client;
  final AcademicEamsQueryResult? initialResult;
  final AcademicProgramPlanResultChanged? onResultChanged;

  @override
  State<AcademicProgramPlanPage> createState() =>
      _AcademicProgramPlanPageState();
}

class _AcademicProgramPlanPageState extends State<AcademicProgramPlanPage> {
  late final RetainedRefreshController<AcademicEamsQueryResult>
  _refreshController;
  String? _selectedModule;

  AcademicEamsQueryResult? get _result => _refreshController.result;
  bool get _isLoading => _refreshController.isRefreshing;

  @override
  void initState() {
    super.initState();
    _refreshController = RetainedRefreshController(
      initialResult: widget.initialResult,
      isSuccess: (result) => result.isSuccess,
      hasUsableContent: (result) => result.snapshot?.programPlan != null,
      failureMessage: (result) => '${result.message}：${result.detail}',
    )..addListener(_handleChanged);
    if (widget.initialResult?.snapshot?.programPlan == null) {
      unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    _refreshController
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final plan = _result?.snapshot?.programPlan;
    return YhTaskPage(
      title: '培养方案',
      kicker: '学程地图',
      summary: '按模块核对已修学分与待完成课程；课程要求以教务原始方案为准。',
      source: '本专科教务 · ${plan?.planName ?? '培养方案'}',
      sourceSymbol: '学',
      sourceTimestamp: _academicDetailTimestamp(plan?.fetchedAt),
      appBarTitle: _academicTaskAppBarTitle('培养方案', plan?.fetchedAt),
      primaryActionKey: const Key('academic-program-plan-refresh'),
      primaryActionLabel: _isLoading ? '正在刷新…' : '刷新方案',
      onPrimaryAction: _isLoading ? null : () => unawaited(_refresh()),
      width: YhTaskPageWidth.constrained,
      rhythm: YhTaskPageRhythm.relaxedCompact,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = context.yhTheme;
    final result = _result;
    final plan = result?.snapshot?.programPlan;
    final completion = result?.snapshot?.programCompletion;
    if (_isLoading && plan == null) {
      return const _AcademicDetailStateCard(
        child: _AcademicDetailLoadingState(title: '正在读取培养方案', source: '本专科教务'),
      );
    }
    if (result == null || !result.isSuccess || plan == null) {
      return _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '!',
          title: '培养方案暂不可用',
          message: _academicEamsFailureDescription(
            result,
            fallback: '暂无可展示的方案快照，可在本页重试。',
          ),
          accent: theme.color.serviceAcademic,
          actionLabel: '检查后重试',
          onAction: () => unawaited(_refresh()),
        ),
      );
    }

    if (plan.courses.isEmpty) {
      return _AcademicDetailStateCard(
        key: const Key('academic-program-plan-empty'),
        child: _AcademicDetailMessageState(
          symbol: '○',
          title: '当前没有培养方案课程',
          message: '教务系统未返回可展示的课程要求；可在本页重新读取。',
          accent: theme.color.serviceAcademic,
          actionLabel: '重新读取',
          onAction: () => unawaited(_refresh()),
        ),
      );
    }

    final modules = <String>{
      for (final course in plan.courses)
        if ((course.moduleName ?? '').trim().isNotEmpty)
          course.moduleName!.trim(),
    }.toList()..sort();
    if (_selectedModule != null && !modules.contains(_selectedModule)) {
      _selectedModule = null;
    }
    final courses = _selectedModule == null
        ? plan.courses
        : plan.courses
              .where((course) => course.moduleName?.trim() == _selectedModule)
              .toList();
    final totalCredits = completion == null
        ? plan.courses.fold<double>(
            0,
            (sum, course) => sum + (course.credit ?? 0),
          )
        : completion.completedCredits + completion.pendingCredits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AcademicEvidenceMetricsPanel(
          metrics: [
            _AcademicEvidenceMetric(
              '${_credit(completion?.completedCredits ?? 0)}/${_credit(totalCredits)}',
              '学分进度',
            ),
            _AcademicEvidenceMetric(
              '${completion?.completedCourseCount ?? 0} 门',
              '已完成课程',
            ),
            _AcademicEvidenceMetric(
              '${completion?.pendingCourseCount ?? plan.courses.length} 门',
              '待完成课程',
            ),
          ],
        ),
        if (completion?.moduleProgress.isNotEmpty == true) ...[
          SizedBox(height: theme.spacing.m),
          _buildModuleProgress(context, completion!.moduleProgress),
        ],
        SizedBox(height: theme.spacing.m),
        YhCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('课程要求', style: theme.typography.h2),
              SizedBox(height: theme.spacing.m),
              YhSelect<String>(
                key: const Key('academic-program-plan-module-filter'),
                label: '培养模块',
                hint: '全部模块',
                value: _selectedModule,
                options: [
                  for (final module in modules)
                    YhSelectOption(value: module, label: module),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _selectedModule = value),
              ),
            ],
          ),
        ),
        SizedBox(height: theme.spacing.m),
        if (courses.isEmpty)
          _AcademicDetailStateCard(
            child: _AcademicDetailMessageState(
              symbol: '○',
              title: '当前模块没有课程',
              message: '可切换培养模块或刷新教务原始方案。',
              accent: theme.color.serviceAcademic,
              actionLabel: '显示全部模块',
              onAction: () => setState(() => _selectedModule = null),
            ),
          )
        else
          _AcademicEvidenceRecordsPanel(
            kicker: '教务原始要求',
            title: _selectedModule ?? '全部课程',
            trailing: '${courses.length} 门课程',
            children: [
              for (final course in courses)
                _AcademicEvidenceRecord(
                  title: course.courseName,
                  meta: [
                    if ((course.courseCode ?? '').trim().isNotEmpty)
                      course.courseCode!,
                    if ((course.suggestedTerm ?? '').trim().isNotEmpty)
                      '建议第 ${course.suggestedTerm} 学期',
                  ].join(' · '),
                  detail: (course.moduleName ?? '').trim(),
                  value: course.credit == null
                      ? '—'
                      : '${_credit(course.credit!)} 学分',
                  status: (course.category ?? '培养要求').trim(),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildModuleProgress(
    BuildContext context,
    List<AcademicProgramModuleProgress> modules,
  ) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('模块进度', style: theme.typography.h2),
          SizedBox(height: theme.spacing.m),
          for (var index = 0; index < modules.length; index++) ...[
            if (index > 0) SizedBox(height: theme.spacing.m),
            _ProgramModuleProgressRow(progress: modules[index]),
          ],
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    await _refreshController.refresh(() async {
      final result = await widget.client.fetchProgramPlan(
        requireCampusNetwork: false,
      );
      if (result.isSuccess) widget.onResultChanged?.call(result);
      return result;
    });
  }

  static String _credit(double value) => value.toStringAsFixed(1);
}

class _ProgramModuleProgressRow extends StatelessWidget {
  const _ProgramModuleProgressRow({required this.progress});

  final AcademicProgramModuleProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final ratio = progress.totalCredits <= 0
        ? 0.0
        : (progress.completedCredits / progress.totalCredits).clamp(0.0, 1.0);
    final summary =
        '${progress.completedCourseCount}/${progress.totalCourseCount} 门 · '
        '${progress.completedCredits.toStringAsFixed(1)}/${progress.totalCredits.toStringAsFixed(1)} 学分';
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 460;
        final heading = compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(progress.moduleName, style: theme.typography.body),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    summary,
                    style: theme.typography.small.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      progress.moduleName,
                      style: theme.typography.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: theme.spacing.s),
                  Flexible(
                    child: Text(
                      summary,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.small.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ),
                ],
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            SizedBox(height: theme.spacing.s),
            YhProgressBar(
              value: ratio,
              semanticLabel: '${progress.moduleName}完成度',
            ),
          ],
        );
      },
    );
  }
}
