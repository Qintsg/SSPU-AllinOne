/*
 * 课程周次解析器 — 支持区间、单双周、枚举和混合文本
 * @Project : SSPU-AllinOne
 * @File : course_week_parser.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

/// 课程周次解析结果。
class CourseWeekParseResult {
  const CourseWeekParseResult({
    required this.weeks,
    required this.showWhenUnknown,
  });

  /// 解析出的周次集合。
  final Set<int> weeks;

  /// 解析失败时是否保守显示。
  final bool showWhenUnknown;

  /// 是否能确定包含指定周次。
  bool contains(int week) {
    if (weeks.isEmpty) return showWhenUnknown;
    return weeks.contains(week);
  }
}

/// 课程周次解析器。
class CourseWeekParser {
  CourseWeekParser._();

  /// 解析周次描述。
  static CourseWeekParseResult parse(String? text) {
    final normalized = (text ?? '')
        .replaceAll('，', ',')
        .replaceAll('、', ',')
        .replaceAll('－', '-')
        .replaceAll('—', '-')
        .replaceAll('~', '-')
        .replaceAll('～', '-')
        .trim();
    if (normalized.isEmpty) {
      return const CourseWeekParseResult(weeks: {}, showWhenUnknown: true);
    }

    final oddOnly = normalized.contains('单周') || normalized.contains('单');
    final evenOnly = normalized.contains('双周') || normalized.contains('双');
    final weeks = <int>{};

    final rangePattern = RegExp(r'(\d{1,2})\s*-\s*(\d{1,2})\s*周?');
    for (final match in rangePattern.allMatches(normalized)) {
      final start = int.tryParse(match.group(1) ?? '');
      final end = int.tryParse(match.group(2) ?? '');
      if (start == null || end == null || start <= 0 || end < start) continue;
      for (var week = start; week <= end; week++) {
        if (_matchesParity(week, oddOnly: oddOnly, evenOnly: evenOnly)) {
          weeks.add(week);
        }
      }
    }

    final consumedRanges = normalized.replaceAll(rangePattern, ' ');
    final numberPattern = RegExp(r'(\d{1,2})\s*周?');
    for (final match in numberPattern.allMatches(consumedRanges)) {
      final week = int.tryParse(match.group(1) ?? '');
      if (week == null || week <= 0) continue;
      if (_matchesParity(week, oddOnly: oddOnly, evenOnly: evenOnly)) {
        weeks.add(week);
      }
    }

    if (weeks.isEmpty && (oddOnly || evenOnly)) {
      for (var week = 1; week <= 30; week++) {
        if (_matchesParity(week, oddOnly: oddOnly, evenOnly: evenOnly)) {
          weeks.add(week);
        }
      }
    }

    return CourseWeekParseResult(weeks: weeks, showWhenUnknown: weeks.isEmpty);
  }

  static bool _matchesParity(
    int week, {
    required bool oddOnly,
    required bool evenOnly,
  }) {
    if (oddOnly && week.isEven) return false;
    if (evenOnly && week.isOdd) return false;
    return true;
  }
}
