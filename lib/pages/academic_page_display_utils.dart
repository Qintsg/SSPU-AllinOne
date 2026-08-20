/*
 * 教务页面展示工具 — 学期匹配缓存
 * @Project : SSPU-AllinOne
 * @File : academic_page_display_utils.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'academic_page.dart';

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
