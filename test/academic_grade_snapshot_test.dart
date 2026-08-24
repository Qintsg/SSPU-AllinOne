/*
 * 成绩快照模型测试 — 校验跨当前/历史合并去重、学期分组与绩点加权
 * @Project : SSPU-AllinOne
 * @File : academic_grade_snapshot_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-14
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/models/academic_eams/grades.dart';

AcademicGradeRecord _record({
  required String courseName,
  String? courseCode,
  String? termName,
  String scoreText = '',
  double? credit,
  double? gradePoint,
  String? processScoreText,
}) {
  return AcademicGradeRecord(
    courseName: courseName,
    courseCode: courseCode,
    termName: termName,
    scoreText: scoreText,
    credit: credit,
    gradePoint: gradePoint,
    processScoreText: processScoreText,
    rawCells: const [],
  );
}

AcademicGradeSnapshot _snapshot({
  required List<AcademicGradeRecord> current,
  required List<AcademicGradeRecord> history,
}) {
  return AcademicGradeSnapshot(
    currentTermRecords: current,
    historyRecords: history,
    fetchedAt: DateTime(2026, 6, 14),
    sourceUri: Uri.parse('https://jx.sspu.edu.cn/eams/grade'),
  );
}

void main() {
  test('availableTerms 去重并按学年学期倒序', () {
    final snapshot = _snapshot(
      current: [
        _record(courseName: '高等数学', termName: '2025-2026-2', credit: 3),
      ],
      history: [
        _record(courseName: '程序设计基础', termName: '2025-2026-1', credit: 4),
        _record(courseName: '大学英语', termName: '2025-2026-1', credit: 2),
      ],
    );

    expect(snapshot.availableTerms, ['2025-2026-2', '2025-2026-1']);
    expect(snapshot.latestTermName, '2025-2026-2');
  });

  test('allRecords 按课程代码与学期跨当前/历史去重', () {
    final snapshot = _snapshot(
      current: [
        _record(
          courseName: '高等数学',
          courseCode: 'MATH101',
          termName: '2025-2026-2',
          credit: 3,
        ),
      ],
      history: [
        _record(
          courseName: '高等数学',
          courseCode: 'MATH101',
          termName: '2025-2026-2',
          credit: 3,
        ),
        _record(
          courseName: '程序设计基础',
          courseCode: 'CS100',
          termName: '2025-2026-1',
          credit: 4,
        ),
      ],
    );

    expect(snapshot.allRecords.length, 2);
    expect(snapshot.creditsForTerm(null), 7);
  });

  test('recordsForTerm 过滤指定学期，空参返回全部', () {
    final snapshot = _snapshot(
      current: [
        _record(courseName: '高等数学', termName: '2025-2026-2', credit: 3),
      ],
      history: [
        _record(courseName: '程序设计基础', termName: '2025-2026-1', credit: 4),
      ],
    );

    expect(snapshot.recordsForTerm('2025-2026-1').single.courseName, '程序设计基础');
    expect(snapshot.recordsForTerm(null).length, 2);
    expect(snapshot.recordsForTerm('').length, 2);
    expect(snapshot.recordsForTerm('2099-2100-1'), isEmpty);
  });

  test('weightedGpaForTerm 按学分加权且忽略缺绩点记录', () {
    final snapshot = _snapshot(
      current: [
        _record(
          courseName: '高等数学',
          termName: '2025-2026-2',
          credit: 3,
          gradePoint: 4.0,
        ),
        _record(
          courseName: '大学英语',
          termName: '2025-2026-2',
          credit: 1,
          gradePoint: 2.0,
        ),
        _record(
          courseName: '体育',
          termName: '2025-2026-2',
          credit: 2,
          gradePoint: null,
        ),
      ],
      history: const [],
    );

    // (3*4.0 + 1*2.0) / (3 + 1) = 3.5，缺绩点的体育不计入加权。
    expect(snapshot.weightedGpaForTerm('2025-2026-2'), closeTo(3.5, 1e-9));
    // 学分汇总仍计入缺绩点课程的学分。
    expect(snapshot.creditsForTerm('2025-2026-2'), 6);
  });

  test('recordsByTermDesc 按学期倒序且学期内保持原顺序', () {
    final snapshot = _snapshot(
      current: [_record(courseName: '高等数学', termName: '2025-2026-2')],
      history: [
        _record(courseName: '程序设计基础', termName: '2025-2026-1'),
        _record(courseName: '大学英语', termName: '2025-2026-1'),
        _record(courseName: '线性代数', termName: '2026-2027-1'),
      ],
    );

    expect(snapshot.recordsByTermDesc.map((r) => r.courseName).toList(), [
      '线性代数',
      '高等数学',
      '程序设计基础',
      '大学英语',
    ]);
  });

  test('无绩点数据时 weightedGpaForTerm 返回 null', () {
    final snapshot = _snapshot(
      current: [
        _record(courseName: '高等数学', termName: '2025-2026-2', credit: 3),
      ],
      history: const [],
    );

    expect(snapshot.weightedGpaForTerm(null), isNull);
  });
}
