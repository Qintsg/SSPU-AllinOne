/*
 * 教务页面详情导航 — 成绩、考试与课表上下文传递
 * @Project : SSPU-AllinOne
 * @File : academic_page_navigation.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_page.dart';

/// 管理教务详情路由，不承担来源读取或页面布局职责。
extension _AcademicPageNavigation on _AcademicPageState {
  /// 打开课程成绩详情，并把当前已验证快照作为初始内容。
  void _openAcademicGradeDetail() {
    if (_isCoordinatedRefresh) return;
    Navigator.of(context).push(
      YhPageRoute(
        builder: (_) => AcademicEamsGradeDetailPage(
          academicEamsService: _academicEamsService,
          initialResult: _academicGradeResult,
          onResultChanged: _applyAcademicGradeResult,
        ),
      ),
    );
  }

  /// 打开考试安排详情，并保留当前选择的学期上下文。
  void _openAcademicExamDetail() {
    if (_isCoordinatedRefresh) return;
    Navigator.of(context).push(
      YhPageRoute(
        builder: (_) => AcademicEamsExamDetailPage(
          academicEamsService: _academicEamsService,
          academicTermService: _academicTermService,
          academicTermNow: widget.academicTermNow,
          initialResult: _academicExamResult,
          initialSelectedTerm: _readAcademicExamTermSelection(),
          initialSelectedSemester: _readAcademicExamSemesterSelection(),
          onResultChanged: _applyAcademicExamDetailResult,
        ),
      ),
    );
  }

  /// 接纳详情页同代结果，并回写服务器确认的考试学期。
  ///
  /// :param result: 详情页读取到的考试结果。
  /// :param selectedTerm: 用户在详情页保留的学期选择。
  /// :param selectedSemester: 用户在详情页保留的服务端学期选项。
  void _applyAcademicExamDetailResult(
    AcademicEamsQueryResult result,
    AcademicTermChoice? selectedTerm,
    AcademicEamsSemesterOption? selectedSemester,
  ) {
    final resultSemester = result.snapshot?.exams?.selectedSemester;
    _setAcademicState(() {
      _academicExamResult = result;
      _writeAcademicExamSemesterSelection(resultSemester ?? selectedSemester);
      _writeAcademicExamTermSelection(
        resultSemester?.termChoice ??
            selectedTerm ??
            _readAcademicExamTermSelection(),
      );
    });
  }

  /// 打开课程表，并把摘要的自动刷新设置传递给下一级页面。
  void _openCourseSchedule() {
    if (_isCoordinatedRefresh) return;
    Navigator.of(context).push(
      YhPageRoute(
        builder: (_) => CourseSchedulePage(
          academicEamsService: _academicEamsService,
          initialResult: _academicEamsResult,
          autoRefreshEnabledOverride:
              _academicEamsRefreshController.autoRefreshEnabled,
          autoRefreshIntervalOverride:
              _academicEamsRefreshController.autoRefreshIntervalMinutes,
        ),
      ),
    );
  }
}
