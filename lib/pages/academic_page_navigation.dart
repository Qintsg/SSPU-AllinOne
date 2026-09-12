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
}
