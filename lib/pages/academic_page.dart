/*
 * 教务中心 — 课程、成绩、考试等教务信息聚合
 * @Project : SSPU-AllinOne
 * @File : academic_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'dart:async';

import '../design/fluent_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/academic_eams.dart';
import '../models/sports_attendance.dart';
import '../models/student_report.dart';
import '../services/academic_credentials_service.dart';
import '../services/academic_eams_service.dart';
import '../services/sports_attendance_service.dart';
import '../services/student_report_service.dart';
import '../theme/fluent_tokens.dart';
import '../widgets/responsive_layout.dart';
import 'course_schedule_page.dart';

part 'academic_eams_summary_card.dart';
part 'academic_sports_attendance_card.dart';
part 'academic_student_report_card.dart';

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
  bool _isLoadingAcademicEams = false;
  bool _academicEamsAutoRefreshEnabled = false;
  int _academicEamsAutoRefreshIntervalMinutes =
      AcademicEamsService.defaultAutoRefreshIntervalMinutes;
  Timer? _academicEamsAutoRefreshTimer;

  SportsAttendanceQueryResult? _sportsAttendanceResult;
  bool _isLoadingSportsAttendance = false;
  bool _sportsAttendanceAutoRefreshEnabled = false;
  Timer? _sportsAttendanceAutoRefreshTimer;

  StudentReportQueryResult? _studentReportResult;
  bool _isLoadingStudentReport = false;
  bool _studentReportAutoRefreshEnabled = false;
  Timer? _studentReportAutoRefreshTimer;
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
    _credentialChangeSubscription = AcademicCredentialsService.instance.changes
        .listen((_) => _clearAuthenticatedState());
    _loadAcademicEamsCacheAndSettings();
    _loadSportsAttendanceCacheAndSettings();
    _loadStudentReportCacheAndSettings();
  }

  void _clearAuthenticatedState() {
    if (!mounted) return;
    setState(() {
      _academicEamsResult = null;
      _sportsAttendanceResult = null;
      _studentReportResult = null;
      _isLoadingAcademicEams = false;
      _isLoadingSportsAttendance = false;
      _isLoadingStudentReport = false;
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
    setState(() {
      _academicEamsAutoRefreshEnabled = enabled;
      _academicEamsAutoRefreshIntervalMinutes = interval;
    });
    _restartAcademicEamsAutoRefreshTimer(enabled, interval);
    if (enabled &&
        _shouldAutoRefresh(_academicEamsResult?.checkedAt, interval)) {
      unawaited(_loadAcademicEamsOverview(silent: true));
    }
  }

  void _restartAcademicEamsAutoRefreshTimer(bool enabled, int intervalMinutes) {
    _academicEamsAutoRefreshTimer?.cancel();
    _academicEamsAutoRefreshTimer = null;
    if (!enabled || intervalMinutes <= 0) return;
    _academicEamsAutoRefreshTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) {
        if (_shouldAutoRefresh(
          _academicEamsResult?.checkedAt,
          intervalMinutes,
        )) {
          unawaited(_loadAcademicEamsOverview(silent: true));
        }
      },
    );
  }

  /// 先显示本地本专科教务缓存，再按间隔决定是否静默刷新。
  Future<void> _loadAcademicEamsCacheAndSettings() async {
    final cachedResult = await _academicEamsService.readLatestCachedOverview();
    if (mounted && cachedResult != null) {
      setState(() => _academicEamsResult = cachedResult);
    }
    await _loadAcademicEamsAutoRefreshSettings();
  }

  /// 读取本专科教务摘要；失败时在卡片中展示明确状态。
  Future<void> _loadAcademicEamsOverview({bool silent = false}) async {
    if (_isLoadingAcademicEams) return;
    if (!silent) setState(() => _isLoadingAcademicEams = true);

    final result = await _academicEamsService.fetchOverview(
      requireCampusNetwork: silent,
    );
    if (!mounted) return;
    if (silent && !result.isSuccess) return;
    setState(() {
      _academicEamsResult = result;
      if (!silent) _isLoadingAcademicEams = false;
    });
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
    setState(() => _sportsAttendanceAutoRefreshEnabled = enabled);
    _restartSportsAttendanceAutoRefreshTimer(enabled, interval);
    if (enabled &&
        _shouldAutoRefresh(_sportsAttendanceResult?.checkedAt, interval)) {
      unawaited(_loadSportsAttendance(silent: true));
    }
  }

  void _restartSportsAttendanceAutoRefreshTimer(
    bool enabled,
    int intervalMinutes,
  ) {
    _sportsAttendanceAutoRefreshTimer?.cancel();
    _sportsAttendanceAutoRefreshTimer = null;
    if (!enabled || intervalMinutes <= 0) return;
    _sportsAttendanceAutoRefreshTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) {
        if (_shouldAutoRefresh(
          _sportsAttendanceResult?.checkedAt,
          intervalMinutes,
        )) {
          unawaited(_loadSportsAttendance(silent: true));
        }
      },
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
    if (_isLoadingSportsAttendance) return;
    if (!silent) setState(() => _isLoadingSportsAttendance = true);

    final result = await _sportsAttendanceService.fetchAttendanceSummary(
      requireCampusNetwork: silent,
    );
    if (!mounted) return;
    if (silent && !result.isSuccess) return;
    setState(() {
      _sportsAttendanceResult = result;
      if (!silent) _isLoadingSportsAttendance = false;
    });
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
    setState(() => _studentReportAutoRefreshEnabled = enabled);
    _restartStudentReportAutoRefreshTimer(enabled, interval);
    if (enabled &&
        _shouldAutoRefresh(_studentReportResult?.checkedAt, interval)) {
      unawaited(_loadStudentReport(silent: true));
    }
  }

  void _restartStudentReportAutoRefreshTimer(
    bool enabled,
    int intervalMinutes,
  ) {
    _studentReportAutoRefreshTimer?.cancel();
    _studentReportAutoRefreshTimer = null;
    if (!enabled || intervalMinutes <= 0) return;
    _studentReportAutoRefreshTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) {
        if (_shouldAutoRefresh(
          _studentReportResult?.checkedAt,
          intervalMinutes,
        )) {
          unawaited(_loadStudentReport(silent: true));
        }
      },
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
    if (_isLoadingStudentReport) return;
    if (!silent) setState(() => _isLoadingStudentReport = true);

    final result = await _studentReportService.fetchSecondClassroomCredits(
      requireCampusNetwork: silent,
    );
    if (!mounted) return;
    if (silent && !result.isSuccess) return;
    setState(() {
      _studentReportResult = result;
      if (!silent) _isLoadingStudentReport = false;
    });
  }

  bool _shouldAutoRefresh(DateTime? fetchedAt, int intervalMinutes) {
    if (intervalMinutes <= 0) return false;
    if (fetchedAt == null) return true;
    return DateTime.now().difference(fetchedAt) >=
        Duration(minutes: intervalMinutes);
  }

  @override
  void dispose() {
    _credentialChangeSubscription?.cancel();
    _academicEamsAutoRefreshTimer?.cancel();
    _sportsAttendanceAutoRefreshTimer?.cancel();
    _studentReportAutoRefreshTimer?.cancel();
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
            AcademicEamsSummaryCard(
                  result: _academicEamsResult,
                  isLoading: _isLoadingAcademicEams,
                  autoRefreshEnabled: _academicEamsAutoRefreshEnabled,
                  onRefresh: _loadAcademicEamsOverview,
                  onOpenCourseSchedule: () => Navigator.of(context).push(
                    FluentPageRoute(
                      builder: (_) => CourseSchedulePage(
                        academicEamsService: _academicEamsService,
                        initialResult: _academicEamsResult,
                        autoRefreshEnabledOverride:
                            _academicEamsAutoRefreshEnabled,
                        autoRefreshIntervalOverride:
                            _academicEamsAutoRefreshIntervalMinutes,
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(
                  duration: FluentDuration.slow,
                  curve: FluentEasing.decelerate,
                )
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: FluentSpacing.m),
            AcademicSportsAttendanceCard(
                  result: _sportsAttendanceResult,
                  isLoading: _isLoadingSportsAttendance,
                  autoRefreshEnabled: _sportsAttendanceAutoRefreshEnabled,
                  onRefresh: _loadSportsAttendance,
                )
                .animate(delay: FluentDuration.stagger)
                .fadeIn(
                  duration: FluentDuration.slow,
                  curve: FluentEasing.decelerate,
                )
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: FluentSpacing.m),
            AcademicStudentReportCard(
                  result: _studentReportResult,
                  isLoading: _isLoadingStudentReport,
                  autoRefreshEnabled: _studentReportAutoRefreshEnabled,
                  onRefresh: _loadStudentReport,
                )
                .animate(delay: FluentDuration.stagger * 2)
                .fadeIn(
                  duration: FluentDuration.slow,
                  curve: FluentEasing.decelerate,
                )
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: FluentSpacing.m),
            const FluentInfoBar(
              title: Text('只读边界'),
              content: Text(
                '本专科教务仅接入个人信息、课表、成绩、考试、培养计划、开课检索和空闲教室等只读能力；'
                '不提供选课、退课、调课、教学评价、提交申请或任何状态变更入口。',
              ),
              severity: FluentInfoSeverity.info,
            ),
          ],
        );
      },
    );
  }
}
