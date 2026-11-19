/*
 * 新版教务系统可直接打开的查询页面
 * @Project : SSPU-AllinOne
 * @File : academic_portal_links.dart
 * @Author : Codex
 * @Date : 2026-11-19
 */

import 'package:url_launcher/url_launcher.dart';

import '../design/qingyuan/qingyuan_ui.dart';

enum AcademicPortalPage {
  courseTable('课表', 'course-table'),
  exams('考试安排', 'exam-arrange'),
  grades('成绩查询', 'grade/sheet'),
  programPlan('培养方案', 'program/struct-document/info/index'),
  programCompletion('培养方案完成情况', 'program-completion-preview'),
  courseOfferings('全校开课查询', 'lesson-search');

  const AcademicPortalPage(this.label, this.path);

  final String label;
  final String path;

  /// 打开学校提供的查询页，浏览器自行处理统一身份认证。
  Future<void> open(BuildContext context) async {
    final opened = await launchUrl(
      Uri.https('jw.sspu.edu.cn', '/student/for-std/$path'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      showYhFeedback(
        context,
        message: '未能打开$label',
        severity: AppFeedbackSeverity.warning,
      );
    }
  }
}
