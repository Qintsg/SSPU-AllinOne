/*
 * 教务中心 — 课程、成绩、考试等教务信息聚合
 * @Project : SSPU-AllinOne
 * @File : academic_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'dart:async';

import '../controllers/card_auto_refresh_controller.dart';
import '../design/fluent_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/academic_eams.dart';
import '../models/academic_term.dart';
import '../models/sports_attendance.dart';
import '../models/student_report.dart';
import '../services/academic_credentials_service.dart';
import '../services/academic_eams_service.dart';
import '../services/academic_term_service.dart';
import '../services/sports_attendance_service.dart';
import '../services/student_report_service.dart';
import '../theme/fluent_tokens.dart';
import '../theme/app_breakpoints.dart';
import '../utils/query_result_messages.dart';
import '../widgets/refresh_feedback_action.dart';
import '../widgets/responsive_layout.dart';
import 'course_schedule_page.dart';

part 'academic_eams_summary_card.dart';
part 'academic_eams_exam_card.dart';
part 'academic_eams_exam_detail_page.dart';
part 'academic_sports_attendance_card.dart';
part 'academic_student_report_card.dart';
part 'academic_student_report_summary.dart';
part 'academic_student_report_detail_page.dart';
part 'academic_student_report_rule_matrix.dart';

/// 仅当缓存考试快照的学期与目标学期一致时才返回该缓存，否则返回 null。
///
/// 避免出现“卡片标题用全局默认学期、考试记录却是旧学期快照”的错位展示。
AcademicEamsQueryResult? displayableExamCacheForTerm(
  AcademicEamsQueryResult? cachedResult,
  AcademicTermChoice? term,
) {
  if (term == null) return null;
  final matches =
      cachedResult?.snapshot?.exams?.selectedSemester?.matchesTerm(term) ??
      false;
  return matches ? cachedResult : null;
}

/// 教务中心页面。
/// 已接入体育部考勤和第二课堂学分，其余教务能力保留规划入口。
class AcademicPage extends StatefulWidget {
  /// 体育部课外活动考勤服务，测试中可替换为 fake。
  final SportsAttendanceClient? sportsAttendanceService;

  /// 学工报表第二课堂学分服务，测试中可替换为 fake。
  final StudentReportClient? studentReportService;

  /// 测试专用：覆盖体育部考勤自动刷新开关，避免读取真实本地设置。
  final bool? sportsAttendanceAutoRefreshEnabledOverride;

  /// 测试专用：覆盖体育部考勤自动刷新间隔。
  final int? sportsAttendanceAutoRefreshIntervalOverride;

  /// 测试专用：覆盖第二课堂学分自动刷新开关。
  final bool? studentReportAutoRefreshEnabledOverride;

  /// 测试专用：覆盖第二课堂学分自动刷新间隔。
  final int? studentReportAutoRefreshIntervalOverride;

  /// 本专科教务只读服务，测试中可替换为 fake。
  final AcademicEamsClient? academicEamsService;

  /// 测试专用：覆盖本专科教务自动刷新开关。
  final bool? academicEamsAutoRefreshEnabledOverride;

  /// 测试专用：覆盖本专科教务自动刷新间隔。
  final int? academicEamsAutoRefreshIntervalOverride;

  const AcademicPage({
    super.key,
    this.sportsAttendanceService,
    this.studentReportService,
    this.sportsAttendanceAutoRefreshEnabledOverride,
    this.sportsAttendanceAutoRefreshIntervalOverride,
    this.studentReportAutoRefreshEnabledOverride,
    this.studentReportAutoRefreshIntervalOverride,
    this.academicEamsService,
    this.academicEamsAutoRefreshEnabledOverride,
    this.academicEamsAutoRefreshIntervalOverride,
  });

  @override
  State<AcademicPage> createState() => _AcademicPageState();
}

class _AcademicPageState extends State<AcademicPage> {
  AcademicEamsQueryResult? _academicEamsResult;
  AcademicEamsQueryResult? _academicExamResult;
  AcademicTermChoice? _academicExamSelectedTerm;
  AcademicEamsSemesterOption? _academicExamSelectedSemester;
  bool _academicEamsLastRefreshHadExamFailure = false;
  late final CardAutoRefreshController<AcademicEamsQueryResult>
  _academicEamsRefreshController;
  late final CardAutoRefreshController<AcademicEamsQueryResult>
  _academicExamRefreshController;

  SportsAttendanceQueryResult? _sportsAttendanceResult;
  late final CardAutoRefreshController<SportsAttendanceQueryResult>
  _sportsAttendanceRefreshController;

  StudentReportQueryResult? _studentReportResult;
  late final CardAutoRefreshController<StudentReportQueryResult>
  _studentReportRefreshController;
  StreamSubscription<int>? _credentialChangeSubscription;

  SportsAttendanceClient get _sportsAttendanceService {
    return widget.sportsAttendanceService ?? SportsAttendanceService.instance;
  }

  StudentReportClient get _studentReportService {
    return widget.studentReportService ?? StudentReportService.instance;
  }

  AcademicEamsClient get _academicEamsService {
    return widget.academicEamsService ?? AcademicEamsService.instance;
  }

  @override
  void initState() {
    super.initState();
    _academicEamsRefreshController =
        CardAutoRefreshController<AcademicEamsQueryResult>(
          refreshTask: _fetchAcademicEamsForController,
          isSuccess: _isAcademicEamsRefreshSuccess,
          applyResult: _applyAcademicEamsResult,
          checkedAt: () => _academicEamsResult?.checkedAt,
          failureReason: _academicEamsRefreshFailureReason,
        )..addListener(_handleRefreshControllerChanged);
    _academicExamRefreshController =
        CardAutoRefreshController<AcademicEamsQueryResult>(
          refreshTask: _fetchAcademicExamForController,
          isSuccess: (result) => result.isSuccess,
          applyResult: _applyAcademicExamResult,
          checkedAt: () => _academicExamResult?.checkedAt,
          failureReason: _academicEamsRefreshFailureReason,
        )..addListener(_handleRefreshControllerChanged);
    _sportsAttendanceRefreshController =
        CardAutoRefreshController<SportsAttendanceQueryResult>(
          refreshTask: _fetchSportsAttendanceForController,
          isSuccess: (result) => result.isSuccess,
          applyResult: _applySportsAttendanceResult,
          checkedAt: () => _sportsAttendanceResult?.checkedAt,
          failureReason: _sportsAttendanceRefreshFailureReason,
        )..addListener(_handleRefreshControllerChanged);
    _studentReportRefreshController =
        CardAutoRefreshController<StudentReportQueryResult>(
          refreshTask: _fetchStudentReportForController,
          isSuccess: (result) => result.isSuccess,
          applyResult: _applyStudentReportResult,
          checkedAt: () => _studentReportResult?.checkedAt,
          failureReason: _studentReportRefreshFailureReason,
        )..addListener(_handleRefreshControllerChanged);
    _credentialChangeSubscription = AcademicCredentialsService.instance.changes
        .listen((_) => _clearAuthenticatedState());
    _loadAcademicEamsCacheAndSettings();
    _loadSportsAttendanceCacheAndSettings();
    _loadStudentReportCacheAndSettings();
  }

  void _handleRefreshControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _clearAuthenticatedState() {
    if (!mounted) return;
    _academicEamsRefreshController.clearTransientState();
    _academicExamRefreshController.clearTransientState();
    _sportsAttendanceRefreshController.clearTransientState();
    _studentReportRefreshController.clearTransientState();
    setState(() {
      _academicEamsResult = null;
      _academicExamResult = null;
      _academicExamSelectedSemester = null;
      _sportsAttendanceResult = null;
      _studentReportResult = null;
    });
  }

  /// 读取本专科教务自动刷新设置；未启用时不主动访问教务系统。
  Future<void> _loadAcademicEamsAutoRefreshSettings() async {
    final service = widget.academicEamsService is AcademicEamsService
        ? widget.academicEamsService as AcademicEamsService
        : AcademicEamsService.instance;
    final enabled =
        widget.academicEamsAutoRefreshEnabledOverride ??
        await service.isAutoRefreshEnabled();
    final interval =
        widget.academicEamsAutoRefreshIntervalOverride ??
        await service.getAutoRefreshIntervalMinutes();
    if (!mounted) return;
    _academicEamsRefreshController.configureAutoRefresh(
      enabled: enabled,
      intervalMinutes: interval,
    );
  }

  /// 先显示本地本专科教务缓存，再按间隔决定是否静默刷新。
  Future<void> _loadAcademicEamsCacheAndSettings() async {
    final cachedResult = await _academicEamsService.readLatestCachedOverview();
    if (mounted && cachedResult != null) {
      setState(() => _academicEamsResult = cachedResult);
    }
    await _loadAcademicExamCacheAndDefaultTerm();
    await _loadAcademicEamsAutoRefreshSettings();
  }

  /// 读取考试安排缓存，并把卡片学期默认到全局查询学期。
  Future<void> _loadAcademicExamCacheAndDefaultTerm() async {
    final cachedResult = await _academicEamsService
        .readLatestCachedExamSchedule();
    final context = await AcademicTermService.instance.getEffectiveContext();
    final defaultTerm = context.effectiveQueryTerm;
    final cachedExams = cachedResult?.snapshot?.exams;
    // 仅当缓存学期与全局默认学期一致时才展示缓存，否则会出现“标题用默认学期、
    // 记录却是旧学期快照”的错位；不一致时清空展示，等刷新按默认学期重新读取。
    final displayableCache = displayableExamCacheForTerm(
      cachedResult,
      defaultTerm,
    );
    if (!mounted) return;
    setState(() {
      _academicExamSelectedTerm = defaultTerm;
      _academicExamResult = displayableCache;
      _academicExamSelectedSemester =
          displayableCache?.snapshot?.exams?.selectedSemester ??
          _findAcademicExamSemesterForTerm(
            cachedExams?.semesterOptions ?? const [],
            defaultTerm,
          );
    });
  }

  /// 读取本专科教务摘要；失败时在卡片中展示明确状态。
  Future<void> _loadAcademicEamsOverview({bool silent = false}) async {
    await _academicEamsRefreshController.runRefresh(silent: silent);
  }

  Future<AcademicEamsQueryResult> _fetchAcademicEamsForController({
    required bool silent,
  }) async {
    _academicEamsLastRefreshHadExamFailure = false;
    final result = await _academicEamsService.fetchOverview(
      requireCampusNetwork: silent,
    );
    if (result.isSuccess || !silent) {
      await _academicExamRefreshController.runRefresh(silent: silent);
      final examResult = _academicExamResult;
      _academicEamsLastRefreshHadExamFailure =
          !silent && examResult != null && !examResult.isSuccess;
    }
    return result;
  }

  bool _isAcademicEamsRefreshSuccess(AcademicEamsQueryResult result) {
    return result.isSuccess && !_academicEamsLastRefreshHadExamFailure;
  }

  void _applyAcademicEamsResult(AcademicEamsQueryResult result) {
    if (!mounted) return;
    setState(() => _academicEamsResult = result);
  }

  Future<AcademicEamsQueryResult> _fetchAcademicExamForController({
    required bool silent,
  }) {
    return _academicEamsService.fetchExamSchedule(
      term: _academicExamSelectedTerm,
      semester: _academicExamSelectedSemester,
      requireCampusNetwork: silent,
    );
  }

  void _applyAcademicExamResult(AcademicEamsQueryResult result) {
    if (!mounted) return;
    final selectedSemester = result.snapshot?.exams?.selectedSemester;
    setState(() {
      _academicExamResult = result;
      if (selectedSemester != null) {
        _academicExamSelectedSemester = selectedSemester;
        _academicExamSelectedTerm =
            selectedSemester.termChoice ?? _academicExamSelectedTerm;
      }
    });
  }

  void _openAcademicExamDetail() {
    Navigator.of(context).push(
      FluentPageRoute(
        builder: (_) => AcademicEamsExamDetailPage(
          academicEamsService: _academicEamsService,
          initialResult: _academicExamResult,
          initialSelectedTerm: _academicExamSelectedTerm,
          initialSelectedSemester: _academicExamSelectedSemester,
          onResultChanged: _applyAcademicExamDetailResult,
        ),
      ),
    );
  }

  void _applyAcademicExamDetailResult(
    AcademicEamsQueryResult result,
    AcademicTermChoice? selectedTerm,
    AcademicEamsSemesterOption? selectedSemester,
  ) {
    if (!mounted) return;
    final resultSemester = result.snapshot?.exams?.selectedSemester;
    setState(() {
      _academicExamResult = result;
      _academicExamSelectedSemester = resultSemester ?? selectedSemester;
      _academicExamSelectedTerm =
          resultSemester?.termChoice ??
          selectedTerm ??
          _academicExamSelectedTerm;
    });
  }

  AcademicEamsSemesterOption? _findAcademicExamSemesterForTerm(
    Iterable<AcademicEamsSemesterOption> options,
    AcademicTermChoice term,
  ) {
    for (final option in options) {
      if (option.matchesTerm(term)) return option;
    }
    return null;
  }

  /// 读取体育部自动刷新设置；未启用时不主动访问体育部系统。
  Future<void> _loadSportsAttendanceAutoRefreshSettings() async {
    final enabled =
        widget.sportsAttendanceAutoRefreshEnabledOverride ??
        await SportsAttendanceService.instance.isAutoRefreshEnabled();
    final interval =
        widget.sportsAttendanceAutoRefreshIntervalOverride ??
        await SportsAttendanceService.instance.getAutoRefreshIntervalMinutes();
    if (!mounted) return;
    _sportsAttendanceRefreshController.configureAutoRefresh(
      enabled: enabled,
      intervalMinutes: interval,
    );
  }

  /// 先显示本地体育部考勤缓存，再按间隔决定是否静默刷新。
  Future<void> _loadSportsAttendanceCacheAndSettings() async {
    final cachedResult = await _sportsAttendanceService
        .readLatestCachedAttendanceSummary();
    if (mounted && cachedResult != null) {
      setState(() => _sportsAttendanceResult = cachedResult);
    }
    await _loadSportsAttendanceAutoRefreshSettings();
  }

  /// 读取体育部课外活动考勤；失败时在卡片内展示明确状态。
  Future<void> _loadSportsAttendance({bool silent = false}) async {
    await _sportsAttendanceRefreshController.runRefresh(silent: silent);
  }

  Future<SportsAttendanceQueryResult> _fetchSportsAttendanceForController({
    required bool silent,
  }) {
    return _sportsAttendanceService.fetchAttendanceSummary(
      requireCampusNetwork: silent,
    );
  }

  void _applySportsAttendanceResult(SportsAttendanceQueryResult result) {
    if (!mounted) return;
    setState(() => _sportsAttendanceResult = result);
  }

  /// 读取第二课堂学分自动刷新设置；未启用时不主动访问学工报表。
  Future<void> _loadStudentReportAutoRefreshSettings() async {
    final enabled =
        widget.studentReportAutoRefreshEnabledOverride ??
        await StudentReportService.instance.isAutoRefreshEnabled();
    final interval =
        widget.studentReportAutoRefreshIntervalOverride ??
        await StudentReportService.instance.getAutoRefreshIntervalMinutes();
    if (!mounted) return;
    _studentReportRefreshController.configureAutoRefresh(
      enabled: enabled,
      intervalMinutes: interval,
    );
  }

  /// 先显示本地第二课堂学分缓存，再按间隔决定是否静默刷新。
  Future<void> _loadStudentReportCacheAndSettings() async {
    final cachedResult = await _studentReportService
        .readLatestCachedSecondClassroomCredits();
    if (mounted && cachedResult != null) {
      setState(() => _studentReportResult = cachedResult);
    }
    await _loadStudentReportAutoRefreshSettings();
  }

  /// 读取第二课堂学分；失败时在卡片内展示明确状态。
  Future<void> _loadStudentReport({bool silent = false}) async {
    await _studentReportRefreshController.runRefresh(silent: silent);
  }

  Future<StudentReportQueryResult> _fetchStudentReportForController({
    required bool silent,
  }) {
    return _studentReportService.fetchSecondClassroomCredits(
      requireCampusNetwork: silent,
    );
  }

  void _applyStudentReportResult(StudentReportQueryResult result) {
    if (!mounted) return;
    setState(() => _studentReportResult = result);
  }

  String _academicEamsRefreshFailureReason(AcademicEamsQueryResult result) {
    final examResult = _academicExamResult;
    if (result.isSuccess &&
        _academicEamsLastRefreshHadExamFailure &&
        examResult != null) {
      return _academicEamsRefreshFailureReason(examResult);
    }
    return switch (result.status) {
      AcademicEamsQueryStatus.success => '',
      AcademicEamsQueryStatus.partialSuccess => '部分数据降级',
      AcademicEamsQueryStatus.missingOaAccount => '未设置OA账号',
      AcademicEamsQueryStatus.missingOaPassword => '未设置OA密码',
      AcademicEamsQueryStatus.campusNetworkUnavailable => '校园网/VPN不可用',
      AcademicEamsQueryStatus.oaLoginRequired => 'OA登录失效',
      AcademicEamsQueryStatus.systemUnavailable => '教务系统不可用',
      AcademicEamsQueryStatus.readOnlyEntryUnavailable => '教务入口不可用',
      AcademicEamsQueryStatus.queryFormUnavailable => '查询表单不可用',
      AcademicEamsQueryStatus.parseFailed ||
      AcademicEamsQueryStatus.networkError ||
      AcademicEamsQueryStatus.unexpectedError => firstNonEmptyText(
        result.detail,
        result.message,
        fallback: '查询失败',
      ),
    };
  }

  String _sportsAttendanceRefreshFailureReason(
    SportsAttendanceQueryResult result,
  ) {
    return switch (result.status) {
      SportsAttendanceQueryStatus.success => '',
      SportsAttendanceQueryStatus.missingStudentId => '未设置学工号',
      SportsAttendanceQueryStatus.missingSportsPassword => '未设置体育密码',
      SportsAttendanceQueryStatus.campusNetworkUnavailable => '校园网/VPN不可用',
      SportsAttendanceQueryStatus.loginPageUnavailable => '登录页不可用',
      SportsAttendanceQueryStatus.credentialsRejected => '体育密码错误',
      SportsAttendanceQueryStatus.sessionUnavailable => '会话失效',
      SportsAttendanceQueryStatus.parseFailed ||
      SportsAttendanceQueryStatus.networkError ||
      SportsAttendanceQueryStatus.unexpectedError => firstNonEmptyText(
        result.detail,
        result.message,
        fallback: '查询失败',
      ),
    };
  }

  String _studentReportRefreshFailureReason(StudentReportQueryResult result) {
    return switch (result.status) {
      StudentReportQueryStatus.success => '',
      StudentReportQueryStatus.missingOaAccount => '未设置OA账号',
      StudentReportQueryStatus.missingOaPassword => '未设置OA密码',
      StudentReportQueryStatus.campusNetworkUnavailable => '校园网/VPN不可用',
      StudentReportQueryStatus.oaLoginRequired => 'OA登录失效',
      StudentReportQueryStatus.reportSystemUnavailable => '学工报表不可用',
      StudentReportQueryStatus.secondClassroomEntryUnavailable => '未找到二课入口',
      StudentReportQueryStatus.parseFailed ||
      StudentReportQueryStatus.networkError ||
      StudentReportQueryStatus.unexpectedError => firstNonEmptyText(
        result.detail,
        result.message,
        fallback: '查询失败',
      ),
    };
  }

  @override
  void dispose() {
    _credentialChangeSubscription?.cancel();
    _academicEamsRefreshController
      ..removeListener(_handleRefreshControllerChanged)
      ..dispose();
    _academicExamRefreshController
      ..removeListener(_handleRefreshControllerChanged)
      ..dispose();
    _sportsAttendanceRefreshController
      ..removeListener(_handleRefreshControllerChanged)
      ..dispose();
    _studentReportRefreshController
      ..removeListener(_handleRefreshControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, constraints) {
        return FluentPage.scrollable(
          header: const FluentPageHeader(title: Text('教务中心')),
          padding: responsivePagePadding(deviceType),
          children: [
            FluentContentWidth(
              child: _AcademicDashboardGrid(
                primary: AcademicEamsSummaryCard(
                  result: _academicEamsResult,
                  isLoading: _academicEamsRefreshController.isLoading,
                  isRefreshActionLoading:
                      _academicEamsRefreshController.isLoading ||
                      _academicExamRefreshController.isLoading,
                  autoRefreshEnabled:
                      _academicEamsRefreshController.autoRefreshEnabled,
                  refreshFeedback: _academicEamsRefreshController.feedback,
                  onRefresh: _loadAcademicEamsOverview,
                  onOpenCourseSchedule: () => Navigator.of(context).push(
                    FluentPageRoute(
                      builder: (_) => CourseSchedulePage(
                        academicEamsService: _academicEamsService,
                        initialResult: _academicEamsResult,
                        autoRefreshEnabledOverride:
                            _academicEamsRefreshController.autoRefreshEnabled,
                        autoRefreshIntervalOverride:
                            _academicEamsRefreshController
                                .autoRefreshIntervalMinutes,
                      ),
                    ),
                  ),
                  examResult: _academicExamResult,
                  examSchedule: AcademicEamsExamCard(
                    result: _academicExamResult,
                    isLoading: _academicExamRefreshController.isLoading,
                    selectedTerm: _academicExamSelectedTerm,
                    onOpenDetail: _openAcademicExamDetail,
                  ),
                ),
                sports: AcademicSportsAttendanceCard(
                  result: _sportsAttendanceResult,
                  isLoading: _sportsAttendanceRefreshController.isLoading,
                  autoRefreshEnabled:
                      _sportsAttendanceRefreshController.autoRefreshEnabled,
                  refreshFeedback: _sportsAttendanceRefreshController.feedback,
                  onRefresh: _loadSportsAttendance,
                ),
                secondClassroom: AcademicStudentReportCard(
                  result: _studentReportResult,
                  isLoading: _studentReportRefreshController.isLoading,
                  autoRefreshEnabled:
                      _studentReportRefreshController.autoRefreshEnabled,
                  refreshFeedback: _studentReportRefreshController.feedback,
                  onRefresh: _loadStudentReport,
                ),
              ),
            ),
            const SizedBox(height: FluentSpacing.m),
            const FluentContentWidth(
              child: FluentInfoBar(
                title: Text('只读边界'),
                content: Text(
                  '本专科教务仅接入个人信息、课表、成绩、考试、培养计划、开课检索和空闲教室等只读能力；'
                  '不提供选课、退课、调课、教学评价、提交申请或任何状态变更入口。',
                ),
                severity: FluentInfoSeverity.info,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AcademicDashboardGrid extends StatelessWidget {
  const _AcademicDashboardGrid({
    required this.primary,
    required this.sports,
    required this.secondClassroom,
  });

  final Widget primary;
  final Widget sports;
  final Widget secondClassroom;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1040) {
          return Column(
            children: [
              _AcademicAnimatedCard(index: 0, child: primary),
              const SizedBox(height: FluentSpacing.m),
              _AcademicEqualHeightRow(
                left: _AcademicAnimatedCard(index: 1, child: sports),
                right: _AcademicAnimatedCard(index: 2, child: secondClassroom),
              ),
            ],
          );
        }

        if (constraints.maxWidth >= 720) {
          return Column(
            children: [
              _AcademicAnimatedCard(index: 0, child: primary),
              const SizedBox(height: FluentSpacing.m),
              _AcademicEqualHeightRow(
                left: _AcademicAnimatedCard(index: 1, child: sports),
                right: _AcademicAnimatedCard(index: 2, child: secondClassroom),
              ),
            ],
          );
        }

        return Column(
          children: [
            _AcademicAnimatedCard(index: 0, child: primary),
            const SizedBox(height: FluentSpacing.m),
            _AcademicAnimatedCard(index: 1, child: sports),
            const SizedBox(height: FluentSpacing.m),
            _AcademicAnimatedCard(index: 2, child: secondClassroom),
          ],
        );
      },
    );
  }
}

class _AcademicEqualHeightRow extends StatelessWidget {
  const _AcademicEqualHeightRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: FluentSpacing.m),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _AcademicAnimatedCard extends StatelessWidget {
  const _AcademicAnimatedCard({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) return child;
    return child
        .animate(delay: FluentDuration.stagger * index)
        .fadeIn(duration: FluentDuration.slow, curve: FluentEasing.decelerate)
        .slideY(begin: 0.05, end: 0);
  }
}
