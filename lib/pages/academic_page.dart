/*
 * 教务中心 — 课程、成绩、考试等教务信息聚合
 * @Project : SSPU-AllinOne
 * @File : academic_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'dart:async';
import 'dart:math' as math;

import '../controllers/card_auto_refresh_controller.dart';
import '../controllers/retained_refresh_controller.dart';
import '../design/qingyuan/qingyuan_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/academic_eams.dart';
import '../models/academic_credentials.dart';
import '../models/academic_term.dart';
import '../models/sports_attendance.dart';
import '../models/student_report.dart';
import '../services/academic_credentials_service.dart';
import '../services/academic_eams_service.dart';
import '../services/academic_term_service.dart';
import '../services/sports_attendance_service.dart';
import '../services/student_report_service.dart';
import '../utils/query_result_messages.dart';
import '../widgets/refresh_feedback_action.dart';
import 'course_schedule_page.dart';

part 'academic_eams_summary_card.dart';
part 'academic_detail_refresh_controller.dart';
part 'academic_eams_evidence_widgets.dart';
part 'academic_eams_exam_card.dart';
part 'academic_eams_exam_detail_page.dart';
part 'academic_eams_exam_evidence_body.dart';
part 'academic_eams_grade_card.dart';
part 'academic_eams_grade_detail_page.dart';
part 'academic_eams_grade_process_page.dart';
part 'academic_sports_attendance_card.dart';
part 'academic_sports_attendance_detail_page.dart';
part 'academic_student_report_card.dart';
part 'academic_student_report_summary.dart';
part 'academic_student_report_progress_helpers.dart';
part 'academic_student_report_detail_page.dart';
part 'academic_student_report_rules_page.dart';
part 'academic_student_report_rule_matrix.dart';
part 'academic_student_report_rule_ledger.dart';
part 'academic_overview_view.dart';
part 'academic_overview_page_layout.dart';
part 'academic_overview_content_grid.dart';
part 'academic_overview_cards.dart';
part 'academic_overview_state_panel.dart';
part 'academic_overview_legacy_sources.dart';

part 'academic_page_display_utils.dart';
part 'academic_page_life_sources.dart';
part 'academic_page_eams_sources.dart';
part 'academic_page_navigation.dart';
part 'academic_dashboard_layout.dart';

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

  /// 全局学期解析模块；视觉 fixture 可注入完全离线的校历 adapter。
  final AcademicTermService? academicTermService;

  /// 学期解析时钟；为空时使用生产当前时间。
  final DateTime? academicTermNow;

  /// 测试专用：覆盖本专科教务自动刷新开关。
  final bool? academicEamsAutoRefreshEnabledOverride;

  /// 测试专用：覆盖本专科教务自动刷新间隔。
  final int? academicEamsAutoRefreshIntervalOverride;

  /// 凭据缺失时进入账户与连接的宿主导航回调。
  final VoidCallback? onOpenAccountConnections;

  /// 空数据时进入全局学期设置的宿主导航回调。
  final VoidCallback? onAdjustAcademicTerm;

  /// 测试与离线视觉 fixture 可注入确定性的凭据状态；生产读取安全存储。
  final AcademicCredentialsStatus? credentialsStatusOverride;

  const AcademicPage({
    super.key,
    this.sportsAttendanceService,
    this.studentReportService,
    this.sportsAttendanceAutoRefreshEnabledOverride,
    this.sportsAttendanceAutoRefreshIntervalOverride,
    this.studentReportAutoRefreshEnabledOverride,
    this.studentReportAutoRefreshIntervalOverride,
    this.academicEamsService,
    this.academicTermService,
    this.academicTermNow,
    this.academicEamsAutoRefreshEnabledOverride,
    this.academicEamsAutoRefreshIntervalOverride,
    this.onOpenAccountConnections,
    this.onAdjustAcademicTerm,
    this.credentialsStatusOverride,
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
  AcademicEamsQueryResult? _academicGradeResult;
  late final CardAutoRefreshController<AcademicEamsQueryResult>
  _academicGradeRefreshController;

  SportsAttendanceQueryResult? _sportsAttendanceResult;
  late final CardAutoRefreshController<SportsAttendanceQueryResult>
  _sportsAttendanceRefreshController;

  StudentReportQueryResult? _studentReportResult;
  late final CardAutoRefreshController<StudentReportQueryResult>
  _studentReportRefreshController;
  StreamSubscription<int>? _credentialChangeSubscription;
  Future<void>? _coordinatedRefreshFuture;
  bool _isCoordinatedRefresh = false;
  Set<String> _failedAcademicSources = const {};
  AcademicCredentialsStatus? _credentialsStatus;
  Future<AcademicCredentialsStatus>? _credentialsStatusFuture;
  int _credentialGeneration = 0;
  final GlobalKey _academicLegacySourcesKey = GlobalKey();
  final FocusNode _academicLegacySourcesFocusNode = FocusNode(
    debugLabel: 'academic-legacy-sources',
  );

  SportsAttendanceClient get _sportsAttendanceService {
    return widget.sportsAttendanceService ?? SportsAttendanceService.instance;
  }

  StudentReportClient get _studentReportService {
    return widget.studentReportService ?? StudentReportService.instance;
  }

  AcademicEamsClient get _academicEamsService {
    return widget.academicEamsService ?? AcademicEamsService.instance;
  }

  AcademicTermService get _academicTermService {
    return widget.academicTermService ?? AcademicTermService.instance;
  }

  /// 读取当前考试查询使用的学期，避免与展示辅助函数重名。
  ///
  /// :returns: 当前服务查询学期。
  AcademicTermChoice? _readAcademicExamTermSelection() {
    return _academicExamSelectedTerm;
  }

  /// 写入当前考试查询使用的学期。
  ///
  /// :param value: 要用于后续查询的学期。
  void _writeAcademicExamTermSelection(AcademicTermChoice? value) {
    _academicExamSelectedTerm = value;
  }

  /// 读取当前考试查询使用的服务端学期选项。
  ///
  /// :returns: 当前服务端学期选项。
  AcademicEamsSemesterOption? _readAcademicExamSemesterSelection() {
    return _academicExamSelectedSemester;
  }

  /// 写入当前考试查询使用的服务端学期选项。
  ///
  /// :param value: 服务端确认的学期选项。
  void _writeAcademicExamSemesterSelection(AcademicEamsSemesterOption? value) {
    _academicExamSelectedSemester = value;
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
    _academicGradeRefreshController =
        CardAutoRefreshController<AcademicEamsQueryResult>(
          refreshTask: _fetchAcademicGradeForController,
          isSuccess: (result) => result.isSuccess,
          applyResult: _applyAcademicGradeResult,
          checkedAt: () => _academicGradeResult?.checkedAt,
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

  /// 在教务页面状态类内部统一提交拆分模块的状态更新。
  ///
  /// :param update: 需要在一次 rebuild 中应用的状态变更。
  void _setAcademicState(void Function() update) {
    if (!mounted) return;
    setState(update);
  }

  void _clearAuthenticatedState() {
    if (!mounted) return;
    _credentialGeneration++;
    _academicEamsRefreshController.clearTransientState(stopAutoRefresh: true);
    _academicExamRefreshController.clearTransientState(stopAutoRefresh: true);
    _academicGradeRefreshController.clearTransientState(stopAutoRefresh: true);
    _sportsAttendanceRefreshController.clearTransientState(
      stopAutoRefresh: true,
    );
    _studentReportRefreshController.clearTransientState(stopAutoRefresh: true);
    _credentialsStatusFuture = null;
    _coordinatedRefreshFuture = null;
    setState(() {
      _isCoordinatedRefresh = false;
      _failedAcademicSources = const {};
      _credentialsStatus = null;
      _academicEamsResult = null;
      _academicExamResult = null;
      _academicExamSelectedSemester = null;
      _academicGradeResult = null;
      _sportsAttendanceResult = null;
      _studentReportResult = null;
    });
    unawaited(_reloadAcademicSourcesAfterCredentialChange());
  }

  Future<AcademicCredentialsStatus> _loadCredentialsStatus() {
    final active = _credentialsStatusFuture;
    if (active != null) return active;
    final generation = _credentialGeneration;
    final future = () async {
      AcademicCredentialsStatus status;
      try {
        status =
            widget.credentialsStatusOverride ??
            await AcademicCredentialsService.instance.getStatus();
      } catch (_) {
        status = const AcademicCredentialsStatus.empty();
      }
      if (mounted && generation == _credentialGeneration) {
        setState(() => _credentialsStatus = status);
      }
      return status;
    }();
    _credentialsStatusFuture = future;
    return future;
  }

  Future<void> _reloadAcademicSourcesAfterCredentialChange() async {
    await Future.wait<void>([
      _loadAcademicEamsCacheAndSettings(),
      _loadSportsAttendanceCacheAndSettings(),
      _loadStudentReportCacheAndSettings(),
    ]);
  }

  Future<void> _refreshAllAcademicSources() {
    final active = _coordinatedRefreshFuture;
    if (active != null) return active;
    final future = _performCoordinatedRefresh();
    _coordinatedRefreshFuture = future;
    return future.whenComplete(() {
      if (identical(_coordinatedRefreshFuture, future)) {
        _coordinatedRefreshFuture = null;
      }
    });
  }

  Future<void> _performCoordinatedRefresh() async {
    if (!mounted || _anyAcademicSourceLoading) return;
    final generation = _credentialGeneration;
    await _loadCredentialsStatus();
    if (!mounted || generation != _credentialGeneration) return;
    final refreshAcademic = _academicOaCredentialsReady;
    final refreshSports = _academicSportsCredentialsReady;
    if (!refreshAcademic && !refreshSports) {
      showYhFeedback(
        context,
        message: '请先完成教务账户连接',
        details: '未发起任何校园服务请求。',
        severity: AppFeedbackSeverity.warning,
      );
      return;
    }
    final requestedSourceCount =
        (refreshAcademic ? 4 : 0) + (refreshSports ? 1 : 0);
    final hadContentBeforeRefresh = _academicOverviewHasContent;
    setState(() {
      _isCoordinatedRefresh = true;
      _failedAcademicSources = const {};
    });

    CardRefreshOutcome<AcademicEamsQueryResult>? overviewOutcome;
    CardRefreshOutcome<AcademicEamsQueryResult>? examOutcome;
    CardRefreshOutcome<AcademicEamsQueryResult>? gradeOutcome;
    CardRefreshOutcome<SportsAttendanceQueryResult>? sportsOutcome;
    CardRefreshOutcome<StudentReportQueryResult>? reportOutcome;
    try {
      await Future.wait<void>([
        if (refreshAcademic) ...[
          _academicEamsRefreshController
              .runRefresh(silent: true)
              .then((value) => overviewOutcome = value),
          _academicExamRefreshController
              .runRefresh(silent: true)
              .then((value) => examOutcome = value),
          _academicGradeRefreshController
              .runRefresh(silent: true)
              .then((value) => gradeOutcome = value),
          _studentReportRefreshController
              .runRefresh(silent: true)
              .then((value) => reportOutcome = value),
        ],
        if (refreshSports)
          _sportsAttendanceRefreshController
              .runRefresh(silent: true)
              .then((value) => sportsOutcome = value),
      ]);
    } finally {
      if (mounted && generation == _credentialGeneration) {
        final failedSources = {
          if (refreshAcademic && overviewOutcome?.success != true) '教务摘要',
          if (refreshAcademic && examOutcome?.success != true) '考试',
          if (refreshAcademic && gradeOutcome?.success != true) '成绩',
          if (refreshSports && sportsOutcome?.success != true) '体育考勤',
          if (refreshAcademic && reportOutcome?.success != true) '第二课堂',
        };
        final unavailableSources = {
          if (!refreshAcademic) ...['教务摘要', '考试', '成绩', '第二课堂'],
          if (!refreshSports) '体育考勤',
        };
        final failedSourcesWithoutFallback = failedSources
            .where((source) => !_academicSourceHasFallbackData(source))
            .toSet();
        final retainedFailedSources = failedSources.difference(
          failedSourcesWithoutFallback,
        );
        setState(() {
          _failedAcademicSources = failedSources;
          _isCoordinatedRefresh = false;
        });
        if (failedSources.isEmpty) {
          showYhFeedback(
            context,
            message: unavailableSources.isEmpty ? '教务数据已刷新' : '可用教务数据已刷新',
            details: unavailableSources.isEmpty
                ? null
                : '${unavailableSources.join('、')}未连接，本次未请求。',
            severity: AppFeedbackSeverity.success,
          );
        } else if (failedSources.length == requestedSourceCount) {
          showYhFeedback(
            context,
            message: unavailableSources.isEmpty ? '教务数据刷新失败' : '可用教务数据刷新失败',
            details:
                '${['${failedSources.join('、')}均未完成', if (unavailableSources.isNotEmpty) '${unavailableSources.join('、')}未连接，本次未请求', if (retainedFailedSources.isNotEmpty) '${retainedFailedSources.join('、')}继续显示最后有效数据', if (failedSourcesWithoutFallback.isNotEmpty) '${failedSourcesWithoutFallback.join('、')}暂无可保留数据', if (!hadContentBeforeRefresh || failedSourcesWithoutFallback.isNotEmpty) '请检查校园网/VPN 或稍后重试'].join('；')}。',
            severity: AppFeedbackSeverity.error,
          );
        } else {
          showYhFeedback(
            context,
            message: '教务数据部分更新',
            details:
                '${['${failedSources.join('、')}未完成', if (unavailableSources.isNotEmpty) '${unavailableSources.join('、')}未连接，本次未请求', if (retainedFailedSources.isNotEmpty) '${retainedFailedSources.join('、')}继续显示最后有效数据', if (failedSourcesWithoutFallback.isNotEmpty) '${failedSourcesWithoutFallback.join('、')}暂无可保留数据，可稍后分别重试'].join('；')}。',
            severity: AppFeedbackSeverity.warning,
          );
        }
      }
    }
  }

  Future<void> _openAcademicLegacySources() async {
    final targetContext = _academicLegacySourcesKey.currentContext;
    if (targetContext == null || _isCoordinatedRefresh) return;
    final theme = context.yhTheme;
    await Scrollable.ensureVisible(
      targetContext,
      duration: theme.motion.effective(
        theme.motion.slow,
        disableAnimations: MediaQuery.disableAnimationsOf(context),
      ),
      curve: theme.motion.curve,
      alignment: 0,
    );
    if (mounted) _academicLegacySourcesFocusNode.requestFocus();
  }

  bool get _anyAcademicSourceLoading =>
      _academicEamsRefreshController.isLoading ||
      _academicExamRefreshController.isLoading ||
      _academicGradeRefreshController.isLoading ||
      _sportsAttendanceRefreshController.isLoading ||
      _studentReportRefreshController.isLoading;

  bool get _academicOaCredentialsReady {
    final status = _credentialsStatus;
    if (status == null ||
        status.oaAccount.trim().isEmpty ||
        !status.hasOaPassword) {
      return false;
    }
    bool missing(AcademicEamsQueryResult? result) =>
        result?.status == AcademicEamsQueryStatus.missingOaAccount ||
        result?.status == AcademicEamsQueryStatus.missingOaPassword;
    return !missing(_academicEamsResult) &&
        !missing(_academicGradeResult) &&
        !missing(_academicExamResult);
  }

  bool get _academicSportsCredentialsReady {
    final status = _credentialsStatus;
    if (status == null ||
        status.oaAccount.trim().isEmpty ||
        !status.hasSportsQueryPassword) {
      return false;
    }
    return _sportsAttendanceResult?.status !=
            SportsAttendanceQueryStatus.missingStudentId &&
        _sportsAttendanceResult?.status !=
            SportsAttendanceQueryStatus.missingSportsPassword;
  }

  int get _academicAvailableRefreshSourceCount =>
      (_academicOaCredentialsReady ? 4 : 0) +
      (_academicSportsCredentialsReady ? 1 : 0);

  @override
  void dispose() {
    _credentialChangeSubscription?.cancel();
    _academicLegacySourcesFocusNode.dispose();
    _academicEamsRefreshController
      ..removeListener(_handleRefreshControllerChanged)
      ..dispose();
    _academicExamRefreshController
      ..removeListener(_handleRefreshControllerChanged)
      ..dispose();
    _academicGradeRefreshController
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
    return _buildAcademicOverview(context);
  }
}
