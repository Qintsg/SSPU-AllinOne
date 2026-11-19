/*
 * 新版教务响应到应用教务模型的转换
 * @Project : SSPU-AllinOne
 * @File : academic_portal_parsers.dart
 * @Author : Codex
 * @Date : 2026-11-19
 */

import 'dart:convert';

import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;

import '../models/academic_eams.dart';
import '../models/academic_term.dart';

/// 解码新版教务接口的 JSON 对象。
Map<String, dynamic> decodeAcademicPortalJson(String body) =>
    _object(jsonDecode(body));

/// 读取课表主页提供的可查询学期。
List<AcademicEamsSemesterOption> readPortalCourseSemesters(String body) {
  final select = html_parser.parse(body).querySelector('#allSemesters');
  if (select == null) throw const FormatException('课表页缺少学期列表');
  return [
    for (final option in select.querySelectorAll('option'))
      if (RegExp(r'^\d+$').hasMatch(option.attributes['value'] ?? ''))
        _semester(option.attributes['value']!, option.text),
  ];
}

/// 将课表打印接口返回的活动转换为日期、节次和周次记录。
AcademicCourseTableSnapshot parsePortalCourseTable(
  Map<String, dynamic> data, {
  required String account,
  required AcademicEamsSemesterOption semester,
  required Uri sourceUri,
  required DateTime fetchedAt,
}) {
  final tables = _objects(data['studentTableVms']);
  final owned = tables.where((table) => _text(table['code']) == account);
  if (tables.isNotEmpty && owned.isEmpty) {
    throw const FormatException('课表所属账号不一致');
  }
  final entries = <AcademicCourseTableEntry>[];
  for (final table in owned) {
    for (final activity in _objects(table['activities'])) {
      final weekday = _int(activity['weekday']);
      final start = _int(activity['startUnit']);
      final end = _int(activity['endUnit']);
      final name = _text(activity['courseName']);
      if (name.isEmpty ||
          weekday == null ||
          weekday < 1 ||
          weekday > 7 ||
          start == null ||
          end == null ||
          start < 1 ||
          end < start) {
        throw const FormatException('课表活动缺少课程、星期或节次');
      }
      final weeks =
          (activity['weekIndexes'] as List<dynamic>?)
              ?.map(_int)
              .whereType<int>()
              .toSet()
              .toList() ??
          [];
      weeks.sort();
      final places = [
        for (final key in ['campus', 'building', 'room'])
          if (_text(activity[key]).isNotEmpty) _text(activity[key]),
      ];
      final teachers = (activity['teachers'] as List<dynamic>?)
          ?.map(_text)
          .where((text) => text.isNotEmpty)
          .join('、');
      entries.add(
        AcademicCourseTableEntry(
          courseName: name,
          weekday: weekday,
          startUnit: start,
          endUnit: end,
          timeText: start == end ? '第$start节' : '第$start-$end节',
          rawText: name,
          teacher: teachers,
          location: places.isEmpty ? null : places.toSet().join(' '),
          weekDescription: weeks.isEmpty
              ? _text(activity['weeksStr'])
              : '第${weeks.join(',')}周',
        ),
      );
    }
  }
  entries.sort((a, b) {
    final dayOrder = a.weekday.compareTo(b.weekday);
    return dayOrder == 0 ? a.startUnit.compareTo(b.startUnit) : dayOrder;
  });
  return AcademicCourseTableSnapshot(
    entries: List.unmodifiable(entries),
    fetchedAt: fetchedAt,
    sourceUri: sourceUri,
    termName: semester.label,
    termChoice: semester.termChoice,
  );
}

/// 解码成绩单及随成绩返回的分项成绩。
({AcademicGradeSnapshot grades, AcademicGradeProcessSnapshot process})
parsePortalGrades(
  Map<String, dynamic> data, {
  required String studentId,
  required Uri sourceUri,
  required DateTime fetchedAt,
  AcademicTermChoice? term,
  String? semesterId,
}) {
  if (_text(data['currentStudentId']) != studentId) {
    throw const FormatException('成绩单所属账号不一致');
  }
  final terms = <String, AcademicEamsSemesterOption>{};
  String? currentId;
  for (final item in _objects(data['semesters'])) {
    final id = _requiredText(item['id']);
    terms[id] = _semester(id, _requiredText(item['nameZh']));
    final start = DateTime.tryParse(_text(item['startDate']));
    final end = DateTime.tryParse(_text(item['endDate']));
    if (start != null &&
        end != null &&
        !fetchedAt.isBefore(start) &&
        fetchedAt.isBefore(end.add(const Duration(days: 1)))) {
      currentId = id;
    }
  }
  final selected =
      terms[semesterId] ??
      (term == null
          ? null
          : terms.values.where((item) => item.matchesTerm(term)).firstOrNull);
  final current = <AcademicGradeRecord>[];
  final history = <AcademicGradeRecord>[];
  final process = <AcademicGradeProcessRecord>[];
  final rowsByTerm = _object(data['semesterId2studentGrades']);
  for (final batch in rowsByTerm.entries) {
    final portalTerm = terms[batch.key];
    for (final row in _objects(batch.value)) {
      if (_text(row['studentId']) != studentId) {
        throw const FormatException('成绩记录所属账号不一致');
      }
      final name = _requiredText(row['courseName']);
      final score = _text(row['gaGrade']);
      if (score.isEmpty || row['published'] == false) continue;
      final termName = portalTerm?.label ?? _text(row['semesterName']);
      final courseCode = _text(row['courseCode']);
      final credit = _number(row['credits']);
      final items = _gradeItems(_text(row['gradeDetail']));
      final grade = AcademicGradeRecord(
        courseName: name,
        courseCode: courseCode,
        termName: termName,
        credit: credit,
        gradePoint: _number(row['gp']),
        passed: row['passed'] as bool?,
        scoreText: score,
        totalScoreText: score,
        processScoreText: items.isEmpty
            ? null
            : items.map((item) => '${item.label} ${item.value}').join('，'),
        rawCells: [name, score],
      );
      (batch.key == currentId ? current : history).add(grade);
      if (items.isNotEmpty &&
          (term == null && semesterId == null || selected?.id == batch.key)) {
        process.add(
          AcademicGradeProcessRecord(
            courseName: name,
            courseCode: courseCode,
            courseSequence: _text(row['lessonCode']),
            category: _text(row['courseType']),
            termName: termName,
            credit: credit,
            items: items,
            rawCells: [name, score],
          ),
        );
      }
    }
  }
  return (
    grades: AcademicGradeSnapshot(
      currentTermRecords: List.unmodifiable(current),
      historyRecords: List.unmodifiable(history),
      fetchedAt: fetchedAt,
      sourceUri: sourceUri,
    ),
    process: AcademicGradeProcessSnapshot(
      records: List.unmodifiable(process),
      selectedSemester: selected,
      semesterOptions: List.unmodifiable(terms.values),
      fetchedAt: fetchedAt,
      sourceUri: sourceUri,
    ),
  );
}

/// 读取新版考试页的未结束考试列表，识别明确的空状态。
AcademicExamSnapshot parsePortalExams(
  String body,
  Uri sourceUri,
  DateTime fetchedAt,
) {
  final document = html_parser.parse(body);
  final table = document.querySelector('table.exam-table');
  if (table == null) throw const FormatException('考试页缺少考试列表');
  final rows = table.querySelectorAll('tr');
  final records = <AcademicExamRecord>[];
  var timeColumn = -1;
  var courseColumn = -1;
  var validEmpty = false;
  for (final row in rows) {
    final cells = row.children
        .where((cell) => cell.localName == 'td' || cell.localName == 'th')
        .toList();
    final values = cells.map((cell) => cell.text.trim()).toList();
    final timeHeader = values.indexWhere(
      (text) => text.replaceAll(RegExp(r'\s+'), '') == '时间地点',
    );
    final courseHeader = values.indexWhere(
      (text) => text.replaceAll(RegExp(r'\s+'), '') == '课程名称',
    );
    if (timeHeader >= 0 && courseHeader >= 0) {
      timeColumn = timeHeader;
      courseColumn = courseHeader;
      continue;
    }
    if (values.length == 1 && RegExp(r'暂无.*考试安排').hasMatch(values.single)) {
      validEmpty = true;
      continue;
    }
    if (timeColumn < 0 ||
        courseColumn < 0 ||
        timeColumn >= cells.length ||
        courseColumn >= cells.length) {
      continue;
    }
    final course = _cellLines(cells[courseColumn]);
    final timePlace = _cellLines(cells[timeColumn]);
    if (course.isEmpty || timePlace.isEmpty) continue;
    final when = timePlace.first;
    final dateMatch = RegExp(
      r'(\d{4})[-/.年](\d{1,2})[-/.月](\d{1,2})',
    ).firstMatch(when);
    final examDate = dateMatch == null
        ? null
        : '${dateMatch[1]}-${dateMatch[2]!.padLeft(2, '0')}-${dateMatch[3]!.padLeft(2, '0')}';
    final times = RegExp(
      r'\d{1,2}:\d{2}',
    ).allMatches(when).map((match) => match[0]!).toList();
    records.add(
      AcademicExamRecord(
        courseName: course.first,
        examType: course.length > 1 ? course.skip(1).join(' ') : null,
        examDate: examDate,
        examArrange: times.isNotEmpty ? times.join('-') : when,
        examLocation: timePlace.length > 1 ? timePlace.skip(1).join(' ') : null,
        rawCells: values,
      ),
    );
  }
  if (records.isEmpty && !validEmpty) {
    throw const FormatException('无法识别考试记录或空状态');
  }
  return AcademicExamSnapshot(
    records: List.unmodifiable(records),
    fetchedAt: fetchedAt,
    sourceUri: sourceUri,
    onlyUpcoming: true,
  );
}

/// 读取培养方案的模块树，按实际模块展开课程。
AcademicProgramPlanSnapshot parsePortalProgram(
  Map<String, dynamic> root, {
  required String? planName,
  required Uri sourceUri,
  required DateTime fetchedAt,
}) {
  final claimed = <String>{};
  final courses = <AcademicProgramPlanCourse>[];
  void visit(Map<String, dynamic> node, String? parent) {
    final type = node['type'];
    final label = _text(node['nameZh']);
    final category = type is Map<String, dynamic> ? _text(type['nameZh']) : '';
    final module = label.isNotEmpty
        ? label
        : category.isNotEmpty
        ? category
        : parent;
    for (final child in _objects(node['children'])) {
      visit(child, module);
    }
    for (final row in _objects(node['planCourses'])) {
      if (!claimed.add(_requiredText(row['id']))) continue;
      final course = _object(row['course']);
      final name = _requiredText(course['nameZh']);
      final term = _text(row['suggestTermsText']);
      courses.add(
        AcademicProgramPlanCourse(
          courseName: name,
          courseCode: _text(course['code']),
          credit: _number(course['credits']),
          moduleName: module,
          category: switch (row['compulsory']) {
            true => '必修',
            false => '选修',
            _ => null,
          },
          suggestedTerm: term.isEmpty ? _text(row['termsText']) : term,
          rawCells: [name],
        ),
      );
    }
  }

  visit(root, null);
  return AcademicProgramPlanSnapshot(
    courses: List.unmodifiable(courses),
    fetchedAt: fetchedAt,
    sourceUri: sourceUri,
    planName: planName,
  );
}

/// 从教务标签提取结构化学期，同时保留界面原始名称。
AcademicEamsSemesterOption _semester(String id, String name) {
  final label = name.trim();
  final year = RegExp(r'^(\d{4})\s*[-–—]\s*\d{4}').firstMatch(label);
  final academicYear = int.tryParse(year?.group(1) ?? '');
  final season = label.contains('秋')
      ? AcademicTermSeason.fall
      : label.contains('春')
      ? AcademicTermSeason.spring
      : label.contains('夏')
      ? AcademicTermSeason.summer
      : null;
  return AcademicEamsSemesterOption(
    id: id,
    label: label,
    schoolYear: year?.group(0),
    academicYear: academicYear,
    termCode: season?.label,
    termChoice: academicYear == null || season == null
        ? null
        : AcademicTermChoice(academicYear: academicYear, season: season),
  );
}

/// 通过 HTML 解析成绩明细内容，保留教务公布的分项及占比。
List<AcademicGradeProcessItem> _gradeItems(String markup) {
  final nodes = html_parser
      .parseFragment(markup)
      .querySelectorAll('.subGradeProcess');
  final items = <AcademicGradeProcessItem>[];
  for (final node in nodes) {
    final text = node.text.trim();
    final separator = text.indexOf(RegExp('[:：]'));
    if (separator < 1) continue;
    final label = text.substring(0, separator).trim();
    final value = text.substring(separator + 1).trim();
    if (value.isNotEmpty) {
      items.add(AcademicGradeProcessItem(label: label, value: value));
    }
  }
  return List.unmodifiable(items);
}

/// 按单元格块元素和换行元素提取考试的行文本。
List<String> _cellLines(html.Element cell) {
  const blocks = {'div', 'p', 'br', 'li'};
  final buffer = StringBuffer();
  void append(html.Node node) {
    if (node is html.Text) buffer.write(node.text);
    if (node is! html.Element) return;
    final breaks = blocks.contains(node.localName);
    if (breaks) buffer.writeln();
    for (final child in node.nodes) {
      append(child);
    }
    if (breaks) buffer.writeln();
  }

  append(cell);
  return buffer
      .toString()
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

Map<String, dynamic> _object(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('教务接口返回的 JSON 对象无效');
}

Iterable<Map<String, dynamic>> _objects(Object? value) {
  if (value is! List<dynamic>) throw const FormatException('教务接口返回的列表无效');
  return value.map(_object);
}

String _text(Object? value) =>
    value is String || value is num ? '$value'.trim() : '';

String _requiredText(Object? value) {
  final text = _text(value);
  if (text.isEmpty) throw const FormatException('教务接口缺少必填字段');
  return text;
}

int? _int(Object? value) => int.tryParse(_text(value));

double? _number(Object? value) => double.tryParse(_text(value));
