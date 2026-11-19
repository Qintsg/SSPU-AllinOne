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

  /// 打开考试详情并同步详情页选中的学期。
  void _openExamSchedule() {
    if (_isCoordinatedRefresh) return;
    final generation = _credentialGeneration;
    Navigator.of(context).push(
      YhPageRoute(
        builder: (_) => AcademicEamsExamDetailPage(
          academicEamsService: _academicEamsService,
          academicTermService: _academicTermService,
          academicTermNow: widget.academicTermNow,
          initialResult: _academicExamResult,
          initialSelectedTerm: _readAcademicExamTermSelection(),
          initialSelectedSemester: _readAcademicExamSemesterSelection(),
          onResultChanged: (result, term, semester) {
            if (generation != _credentialGeneration) return;
            _setAcademicState(() {
              _academicExamResult = result;
              _writeAcademicExamTermSelection(term);
              _writeAcademicExamSemesterSelection(semester);
            });
          },
        ),
      ),
    );
  }

  /// 打开成绩详情并保留可展示的更新结果。
  void _openGrades() {
    if (_isCoordinatedRefresh) return;
    final generation = _credentialGeneration;
    Navigator.of(context).push(
      YhPageRoute(
        builder: (_) => AcademicEamsGradeDetailPage(
          academicEamsService: _academicEamsService,
          initialResult: _academicGradeResult,
          onResultChanged: (result) {
            if (generation != _credentialGeneration) return;
            _setAcademicState(() => _academicGradeResult = result);
          },
        ),
      ),
    );
  }

  /// 打开培养方案详情。
  void _openProgramPlan() {
    if (_isCoordinatedRefresh) return;
    Navigator.of(context).push(
      YhPageRoute(
        builder: (_) => AcademicProgramPlanPage(
          client: widget.programPlanService ?? AcademicEamsService.instance,
          initialResult: _academicEamsResult,
        ),
      ),
    );
  }

  /// 打开可用的空闲教室查询。
  void _openFreeClassrooms() {
    if (_isCoordinatedRefresh) return;
    Navigator.of(context).push(
      YhPageRoute(
        builder: (_) => AcademicFreeClassroomPage(
          client: widget.freeClassroomService ?? AcademicEamsService.instance,
        ),
      ),
    );
  }

  /// 用默认浏览器打开新版教务的全校开课查询。
  void _openCourseOfferings() {
    if (!_isCoordinatedRefresh) {
      unawaited(AcademicPortalPage.courseOfferings.open(context));
    }
  }
}
