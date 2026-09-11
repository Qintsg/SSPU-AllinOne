/*
 * 教务页面本专科数据源 — 缓存、自动刷新与结果换代
 * @Project : SSPU-AllinOne
 * @File : academic_page_eams_sources.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_page.dart';

/// 管理本专科教务的缓存、刷新和来源结果，不承担页面布局职责。
extension _AcademicPageEamsSources on _AcademicPageState {
  /// 读取本专科教务自动刷新设置；未启用时不主动访问教务系统。
  ///
  /// :returns: 自动刷新策略配置完成时结束。
  Future<void> _loadAcademicEamsAutoRefreshSettings() async {
    final generation = _credentialGeneration;
    final service = widget.academicEamsService is AcademicEamsService
        ? widget.academicEamsService as AcademicEamsService
        : AcademicEamsService.instance;
    final enabled =
        widget.academicEamsAutoRefreshEnabledOverride ??
        await service.isAutoRefreshEnabled();
    final interval =
        widget.academicEamsAutoRefreshIntervalOverride ??
        await service.getAutoRefreshIntervalMinutes();
    final fetchEnabled =
        widget.academicEamsFetchEnabledOverride ??
        await DataModulePreferences.instance.isFetchEnabled(
          CampusDataModule.academicEams,
        );
    final credentials = await _loadCredentialsStatus();
    final credentialsReady =
        credentials.oaAccount.trim().isNotEmpty && credentials.hasOaPassword;
    if (!mounted || generation != _credentialGeneration) return;
    _academicEamsRefreshController.configureAutoRefresh(
      enabled: enabled && credentialsReady && fetchEnabled,
      intervalMinutes: interval,
    );
  }

  /// 先显示本地本专科教务缓存，再按间隔决定是否静默刷新。
  ///
  /// :returns: 缓存与自动刷新策略均读取完成时结束。
  Future<void> _loadAcademicEamsCacheAndSettings() async {
    final generation = _credentialGeneration;
    final cachedResult = await _academicEamsService.readLatestCachedOverview();
    if (!mounted || generation != _credentialGeneration) return;
    if (cachedResult != null) {
      _setAcademicState(() => _academicEamsResult = cachedResult);
    }
    await Future.wait<void>([
      _loadAcademicExamCacheAndDefaultTerm(),
      _loadAcademicGradeCache(),
    ]);
    if (!mounted || generation != _credentialGeneration) return;
    await _loadAcademicEamsAutoRefreshSettings();
  }

  /// 读取成绩缓存以便先展示本地数据，再按刷新策略决定是否联网。
  ///
  /// :returns: 可展示缓存写入后结束。
  Future<void> _loadAcademicGradeCache() async {
    final generation = _credentialGeneration;
    final cachedResult = await _academicEamsService.readLatestCachedGrades();
    if (!mounted ||
        generation != _credentialGeneration ||
        cachedResult == null) {
      return;
    }
    _setAcademicState(() => _academicGradeResult = cachedResult);
  }

  /// 读取考试缓存，并让卡片学期与全局查询学期保持一致。
  ///
  /// :returns: 学期匹配缓存及默认学期准备完成时结束。
  Future<void> _loadAcademicExamCacheAndDefaultTerm() async {
    final generation = _credentialGeneration;
    final cachedResult = await _academicEamsService
        .readLatestCachedExamSchedule();
    final termContext = await _academicTermService.getEffectiveContext(
      now: widget.academicTermNow,
    );
    final defaultTerm = termContext.effectiveQueryTerm;
    final cachedExams = cachedResult?.snapshot?.exams;
    final displayableCache = displayableExamCacheForTerm(
      cachedResult,
      defaultTerm,
    );
    if (!mounted || generation != _credentialGeneration) return;
    _setAcademicState(() {
      _writeAcademicExamTermSelection(defaultTerm);
      _academicExamResult = displayableCache;
      _writeAcademicExamSemesterSelection(
        displayableCache?.snapshot?.exams?.selectedSemester ??
            _findAcademicExamSemesterForTerm(
              cachedExams?.semesterOptions ?? const [],
              defaultTerm,
            ),
      );
    });
  }

  /// 读取摘要，并在非协同刷新时级联更新考试和成绩快照。
  ///
  /// :param silent: 是否使用校园网络约束的静默读取。
  /// :returns: 摘要请求结果；页面换代时不再更新页面状态。
  Future<AcademicEamsQueryResult> _fetchAcademicEamsForController({
    required bool silent,
  }) async {
    final generation = _credentialGeneration;
    _academicEamsLastRefreshHadExamFailure = false;
    final result = await _academicEamsService.fetchOverview(
      requireCampusNetwork: silent,
    );
    if (!mounted || generation != _credentialGeneration) return result;
    if (!_isCoordinatedRefresh && (result.isSuccess || !silent)) {
      await _academicExamRefreshController.runRefresh(silent: silent);
      final examResult = _academicExamResult;
      _academicEamsLastRefreshHadExamFailure =
          !silent && examResult != null && !examResult.isSuccess;
      await _academicGradeRefreshController.runRefresh(silent: silent);
    }
    return result;
  }

  /// 判断摘要结果能否作为自动刷新成功信号。
  ///
  /// :param result: 当前摘要读取结果。
  /// :returns: 摘要成功且关联考试读取未失败时返回 true。
  bool _isAcademicEamsRefreshSuccess(AcademicEamsQueryResult result) {
    return result.isSuccess && !_academicEamsLastRefreshHadExamFailure;
  }

  /// 应用摘要查询结果并更新来源失败归因。
  ///
  /// :param result: 当前换代的摘要查询结果。
  void _applyAcademicEamsResult(AcademicEamsQueryResult result) {
    _setAcademicState(() {
      _academicEamsResult = result;
      _updateAcademicSourceFailure('教务摘要', failed: !result.isSuccess);
    });
  }

  /// 读取当前学期的考试安排。
  ///
  /// :param silent: 是否使用校园网络约束的静默读取。
  /// :returns: 考试读取结果。
  Future<AcademicEamsQueryResult> _fetchAcademicExamForController({
    required bool silent,
  }) {
    return _academicEamsService.fetchExamSchedule(
      term: _readAcademicExamTermSelection(),
      semester: _readAcademicExamSemesterSelection(),
      requireCampusNetwork: silent,
    );
  }

  /// 应用考试读取结果，必要时回写服务器确定的学期。
  ///
  /// :param result: 当前换代的考试读取结果。
  void _applyAcademicExamResult(AcademicEamsQueryResult result) {
    final previousSnapshot = _academicExamResult?.snapshot;
    final visibleResult =
        !result.isSuccess && result.snapshot == null && previousSnapshot != null
        ? AcademicEamsQueryResult(
            status: result.status,
            message: result.message,
            detail: result.detail,
            checkedAt: result.checkedAt,
            entranceUri: result.entranceUri,
            finalUri: result.finalUri,
            campusNetworkStatus: result.campusNetworkStatus,
            snapshot: previousSnapshot,
          )
        : result;
    final selectedSemester = result.snapshot?.exams?.selectedSemester;
    _setAcademicState(() {
      _academicExamResult = visibleResult;
      _updateAcademicSourceFailure('考试', failed: !result.isSuccess);
      if (selectedSemester != null) {
        _writeAcademicExamSemesterSelection(selectedSemester);
        _writeAcademicExamTermSelection(
          selectedSemester.termChoice ?? _readAcademicExamTermSelection(),
        );
      }
    });
  }

  /// 读取课程成绩快照。
  ///
  /// :param silent: 是否使用校园网络约束的静默读取。
  /// :returns: 成绩读取结果。
  Future<AcademicEamsQueryResult> _fetchAcademicGradeForController({
    required bool silent,
  }) {
    return _academicEamsService.fetchGrades(requireCampusNetwork: silent);
  }

  /// 应用成绩读取结果并更新来源失败归因。
  ///
  /// :param result: 当前换代的成绩读取结果。
  void _applyAcademicGradeResult(AcademicEamsQueryResult result) {
    final previousSnapshot = _academicGradeResult?.snapshot;
    final visibleResult =
        !result.isSuccess && result.snapshot == null && previousSnapshot != null
        ? AcademicEamsQueryResult(
            status: result.status,
            message: result.message,
            detail: result.detail,
            checkedAt: result.checkedAt,
            entranceUri: result.entranceUri,
            finalUri: result.finalUri,
            campusNetworkStatus: result.campusNetworkStatus,
            snapshot: previousSnapshot,
          )
        : result;
    _setAcademicState(() {
      _academicGradeResult = visibleResult;
      _updateAcademicSourceFailure('成绩', failed: !result.isSuccess);
    });
  }
}
