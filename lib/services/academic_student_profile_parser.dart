/*
 * 新版教务系统学籍详情解析
 * @Project : SSPU-AllinOne
 * @File : academic_student_profile_parser.dart
 * @Author : Codex
 * @Date : 2026-11-19
 */

import 'package:html/parser.dart' as html_parser;

import '../models/academic_eams/profile.dart';

/// 读取新版学籍详情中与应用个人信息模型对应的字段。
AcademicEamsProfile? parseAcademicStudentProfile(String html) {
  final document = html_parser.parse(html);
  final rawFields = <String, String>{};
  const profileLabels = {'姓名', '学号', '院系', '专业', '行政班', '性别', '学制', '学历层次'};
  for (final labelElement in document.querySelectorAll(
    '.content-item_content-item-label',
  )) {
    final label = labelElement.text.trim().replaceFirst(
      RegExp(r'\s*[:：]$'),
      '',
    );
    if (!profileLabels.contains(label)) continue;
    final valueElement = labelElement.nextElementSibling;
    if (valueElement == null ||
        !valueElement.classes.contains('content-item_content-item-value')) {
      continue;
    }
    final value = valueElement.text.trim();
    if (value.isNotEmpty) rawFields.putIfAbsent(label, () => value);
  }

  // 学号用于在保存前校验学籍信息的账号归属。
  final studentId = rawFields['学号'];
  if (studentId == null) return null;
  return AcademicEamsProfile(
    name: rawFields['姓名'],
    studentId: studentId,
    department: rawFields['院系'],
    major: rawFields['专业'],
    className: rawFields['行政班'],
    gender: rawFields['性别'],
    studyLength: rawFields['学制'],
    educationLevel: rawFields['学历层次'],
    rawFields: Map.unmodifiable(rawFields),
  );
}
