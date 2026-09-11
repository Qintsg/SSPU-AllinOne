/*
 * 教务页面生活数据源 — 体育、第二课堂与失败归因
 * @Project : SSPU-AllinOne
 * @File : academic_page_life_sources.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'academic_page.dart';

extension _AcademicPageLifeSources on _AcademicPageState {
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
    final generation = _credentialGeneration;
    final enabled =
        widget.sportsAttendanceAutoRefreshEnabledOverride ??
        await SportsAttendanceService.instance.isAutoRefreshEnabled();
    final interval =
        widget.sportsAttendanceAutoRefreshIntervalOverride ??
        await SportsAttendanceService.instance.getAutoRefreshIntervalMinutes();
    final fetchEnabled =
        widget.sportsAttendanceFetchEnabledOverride ??
        await DataModulePreferences.instance.isFetchEnabled(
          CampusDataModule.sportsAttendance,
        );
    final credentials = await _loadCredentialsStatus();
    final credentialsReady =
        credentials.oaAccount.trim().isNotEmpty &&
        credentials.hasSportsQueryPassword;
    if (!mounted || generation != _credentialGeneration) return;
    _sportsAttendanceRefreshController.configureAutoRefresh(
      enabled: enabled && credentialsReady && fetchEnabled,
      intervalMinutes: interval,
    );
  }

  /// 先显示本地体育部考勤缓存，再按间隔决定是否静默刷新。
  Future<void> _loadSportsAttendanceCacheAndSettings() async {
    final generation = _credentialGeneration;
    final cachedResult = await _sportsAttendanceService
        .readLatestCachedAttendanceSummary();
    if (!mounted || generation != _credentialGeneration) return;
    if (cachedResult != null) {
      _setAcademicState(() => _sportsAttendanceResult = cachedResult);
    }
    await _loadSportsAttendanceAutoRefreshSettings();
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
    _setAcademicState(() {
      _sportsAttendanceResult = result;
      _updateAcademicSourceFailure('体育考勤', failed: !result.isSuccess);
    });
  }

  /// 读取第二课堂学分自动刷新设置；未启用时不主动访问学工报表。
  Future<void> _loadStudentReportAutoRefreshSettings() async {
    final generation = _credentialGeneration;
    final enabled =
        widget.studentReportAutoRefreshEnabledOverride ??
        await StudentReportService.instance.isAutoRefreshEnabled();
    final interval =
        widget.studentReportAutoRefreshIntervalOverride ??
        await StudentReportService.instance.getAutoRefreshIntervalMinutes();
    final fetchEnabled =
        widget.studentReportFetchEnabledOverride ??
        await DataModulePreferences.instance.isFetchEnabled(
          CampusDataModule.studentReport,
        );
    final credentials = await _loadCredentialsStatus();
    final credentialsReady =
        credentials.oaAccount.trim().isNotEmpty && credentials.hasOaPassword;
    if (!mounted || generation != _credentialGeneration) return;
    _studentReportRefreshController.configureAutoRefresh(
      enabled: enabled && credentialsReady && fetchEnabled,
      intervalMinutes: interval,
    );
  }

  /// 先显示本地第二课堂学分缓存，再按间隔决定是否静默刷新。
  Future<void> _loadStudentReportCacheAndSettings() async {
    final generation = _credentialGeneration;
    final cachedResult = await _studentReportService
        .readLatestCachedSecondClassroomCredits();
    if (!mounted || generation != _credentialGeneration) return;
    if (cachedResult != null) {
      _setAcademicState(() => _studentReportResult = cachedResult);
    }
    await _loadStudentReportAutoRefreshSettings();
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
    _setAcademicState(() {
      _studentReportResult = result;
      _updateAcademicSourceFailure('第二课堂', failed: !result.isSuccess);
    });
  }

  void _updateAcademicSourceFailure(String source, {required bool failed}) {
    final updatedSources = {..._failedAcademicSources};
    if (failed) {
      updatedSources.add(source);
    } else {
      updatedSources.remove(source);
    }
    _failedAcademicSources = updatedSources;
  }

  bool _academicSourceHasFallbackData(String source) {
    return switch (source) {
      '教务摘要' =>
        _academicEamsResult?.isSuccess == true &&
            _academicEamsResult?.snapshot != null,
      '考试' => _academicExamResult?.snapshot != null,
      '成绩' => _academicGradeResult?.snapshot != null,
      '体育考勤' => _sportsAttendanceResult?.isSuccess == true,
      '第二课堂' => _studentReportResult?.isSuccess == true,
      _ => false,
    };
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
      AcademicEamsQueryStatus.fetchDisabled => '已在设置中停止获取',
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
      SportsAttendanceQueryStatus.fetchDisabled => '已在设置中停止获取',
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
      StudentReportQueryStatus.fetchDisabled => '已在设置中停止获取',
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
}
