/*
 * 课程节次模型 — 内置教务处作息时间表
 * @Project : SSPU-AllinOne
 * @File : course_period.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 *
 * 数据来源：https://jwc.sspu.edu.cn/zxsj/list.htm
 */

/// 单个课程节次。
class CoursePeriod {
  const CoursePeriod({
    required this.unit,
    required this.label,
    required this.startTime,
    required this.endTime,
    this.note,
  });

  /// 节次序号。
  final int unit;

  /// 中文节次名。
  final String label;

  /// 开始时间 HH:mm。
  final String startTime;

  /// 结束时间 HH:mm。
  final String endTime;

  /// 备注。
  final String? note;

  /// 展示时间段。
  String get timeRange => '$startTime-$endTime';
}

/// 课程节次表。
class CoursePeriodTable {
  const CoursePeriodTable({required this.periods});

  /// 节次列表。
  final List<CoursePeriod> periods;

  /// 按节次读取。
  CoursePeriod? periodOf(int unit) {
    for (final period in periods) {
      if (period.unit == unit) return period;
    }
    return null;
  }

  /// 指定节次范围的时间段。
  String rangeText(int startUnit, int endUnit) {
    final start = periodOf(startUnit);
    final end = periodOf(endUnit);
    if (start == null || end == null) return '第$startUnit-$endUnit节';
    return '${start.startTime}-${end.endTime}';
  }

  /// 上海第二工业大学教务处作息时间表。
  static const CoursePeriodTable standard = CoursePeriodTable(
    periods: [
      CoursePeriod(unit: 1, label: '第一节', startTime: '08:00', endTime: '08:45'),
      CoursePeriod(unit: 2, label: '第二节', startTime: '08:50', endTime: '09:35'),
      CoursePeriod(unit: 3, label: '第三节', startTime: '09:50', endTime: '10:35'),
      CoursePeriod(unit: 4, label: '第四节', startTime: '10:40', endTime: '11:25'),
      CoursePeriod(
        unit: 5,
        label: '第五节',
        startTime: '11:25',
        endTime: '12:10',
        note: '除三节连上课程外，一般不排课',
      ),
      CoursePeriod(unit: 6, label: '第六节', startTime: '13:00', endTime: '13:45'),
      CoursePeriod(unit: 7, label: '第七节', startTime: '13:50', endTime: '14:35'),
      CoursePeriod(unit: 8, label: '第八节', startTime: '14:50', endTime: '15:35'),
      CoursePeriod(unit: 9, label: '第九节', startTime: '15:40', endTime: '16:25'),
      CoursePeriod(
        unit: 10,
        label: '第十节',
        startTime: '16:30',
        endTime: '17:15',
      ),
      CoursePeriod(
        unit: 11,
        label: '第十一节',
        startTime: '18:00',
        endTime: '18:45',
      ),
      CoursePeriod(
        unit: 12,
        label: '第十二节',
        startTime: '18:50',
        endTime: '19:35',
      ),
      CoursePeriod(
        unit: 13,
        label: '第十三节',
        startTime: '19:40',
        endTime: '20:25',
      ),
    ],
  );
}
