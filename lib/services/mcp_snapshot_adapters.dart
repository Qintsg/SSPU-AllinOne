import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/email_mailbox.dart';
import 'academic_eams_service.dart';
import 'campus_card_service.dart';
import 'email_service.dart';
import 'message_state_service.dart';
import 'student_report_service.dart';

class McpSnapshotEnvelope {
  const McpSnapshotEnvelope({
    required this.status,
    this.snapshotAt,
    this.data,
    this.page,
  });
  final String status;
  final DateTime? snapshotAt;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? page;

  Map<String, dynamic> toJson() => {
    'status': status,
    'snapshotAt': snapshotAt?.toUtc().toIso8601String(),
    'isStale': status == 'stale',
    'data': data,
    if (page != null) 'page': page,
  };
}

/// MCP 只读适配器：只能读取现有快照，不触发刷新和远端请求。
class McpSnapshotAdapters {
  McpSnapshotAdapters({
    AcademicEamsService? academic,
    StudentReportService? studentReport,
    CampusCardService? campusCard,
    MessageStateService? messages,
    EmailService? email,
  }) : academic = academic ?? AcademicEamsService.instance,
       studentReport = studentReport ?? StudentReportService.instance,
       _campusCardService = campusCard ?? CampusCardService.instance,
       _messageStateService = messages ?? MessageStateService.instance,
       _emailService = email ?? EmailService.instance;

  final AcademicEamsService academic;
  final StudentReportService studentReport;
  final CampusCardService _campusCardService;
  final MessageStateService _messageStateService;
  final EmailService _emailService;

  Future<McpSnapshotEnvelope> profile() async {
    final value = await academic.readCachedStudentProfile();
    if (value == null) return const McpSnapshotEnvelope(status: 'empty');
    return McpSnapshotEnvelope(
      status: value.savedAt != null && _stale(value.savedAt!) ? 'stale' : 'ok',
      snapshotAt: value.savedAt,
      data: {
        'displayName': value.name,
        'studentId': value.studentId,
        'department': value.department,
        'major': value.major,
        'className': value.className,
        'educationLevel': value.educationLevel,
        'studyLength': value.studyLength,
      },
    );
  }

  Future<McpSnapshotEnvelope> schedule() async {
    final result = await academic.readLatestCachedCourseTable();
    final snapshot = result?.snapshot?.courseTable;
    if (snapshot == null) return const McpSnapshotEnvelope(status: 'empty');
    final items = snapshot.entries.map((entry) {
      return <String, dynamic>{
        'courseName': entry.courseName,
        'teacherName': entry.teacher,
        'location': entry.location,
        'weekday': entry.weekday,
        'startPeriod': entry.startUnit,
        'endPeriod': entry.endUnit,
        'weekPattern': entry.weekDescription,
        'termName': snapshot.termName,
      };
    }).toList();
    return McpSnapshotEnvelope(
      status: _stale(snapshot.fetchedAt) ? 'stale' : 'ok',
      snapshotAt: snapshot.fetchedAt,
      data: {'items': items},
    );
  }

  Future<McpSnapshotEnvelope> grades() async {
    final result = await academic.readLatestCachedGrades();
    final snapshot = result?.snapshot?.grades;
    if (snapshot == null) return const McpSnapshotEnvelope(status: 'empty');
    final records = [
      ...snapshot.currentTermRecords,
      ...snapshot.historyRecords,
    ];
    return McpSnapshotEnvelope(
      status: _stale(snapshot.fetchedAt) ? 'stale' : 'ok',
      snapshotAt: snapshot.fetchedAt,
      data: {
        'items': records.map((record) {
          final json = record.toJson();
          return {
            'courseName': json['courseName'],
            'termName': json['termName'],
            'score': json['score'],
            'scoreText': json['scoreText'],
            'credits': json['credits'],
            'courseNature': json['courseNature'],
            'gradePoint': json['gradePoint'],
          };
        }).toList(),
      },
    );
  }

  Future<McpSnapshotEnvelope> exams() async {
    final result = await academic.readLatestCachedExamSchedule();
    final snapshot = result?.snapshot?.exams;
    if (snapshot == null) return const McpSnapshotEnvelope(status: 'empty');
    return McpSnapshotEnvelope(
      status: _stale(snapshot.fetchedAt) ? 'stale' : 'ok',
      snapshotAt: snapshot.fetchedAt,
      data: {
        'items': snapshot.records
            .where((record) => record.hasDisplayableExamInfo)
            .map(
              (record) => {
                'courseName': record.courseName,
                'examType': record.examType,
                'date': record.displayExamDate,
                'arrangement': record.displayExamArrange,
                'location': record.displayExamLocation,
                'status': record.displayExamSituation,
              },
            )
            .toList(),
      },
    );
  }

  Future<McpSnapshotEnvelope> program() async {
    final result = await academic.readLatestCachedOverview();
    final value = result?.snapshot?.programCompletion;
    if (value == null) return const McpSnapshotEnvelope(status: 'empty');
    final fetchedAt = result?.snapshot?.fetchedAt;
    return McpSnapshotEnvelope(
      status: fetchedAt != null && _stale(fetchedAt) ? 'stale' : 'ok',
      snapshotAt: fetchedAt,
      data: {
        'completedCourseCount': value.completedCourseCount,
        'pendingCourseCount': value.pendingCourseCount,
        'completedCredits': value.completedCredits,
        'pendingCredits': value.pendingCredits,
        'modules': value.moduleProgress
            .map(
              (module) => {
                'name': module.moduleName,
                'requiredCredits': module.totalCredits,
                'completedCredits': module.completedCredits,
                'pendingCredits': module.pendingCredits,
                'completedCourseCount': module.completedCourseCount,
                'pendingCourseCount': module.pendingCourseCount,
              },
            )
            .toList(),
      },
    );
  }

  Future<McpSnapshotEnvelope> secondClassroom() async {
    final result = await studentReport.readLatestCachedSecondClassroomCredits();
    final value = result?.summary;
    if (value == null) return const McpSnapshotEnvelope(status: 'empty');
    return McpSnapshotEnvelope(
      status: _stale(value.fetchedAt) ? 'stale' : 'ok',
      snapshotAt: value.fetchedAt,
      data: {
        'items': value.records
            .map(
              (record) => {
                'category': record.category,
                'itemName': record.itemName,
                'credit': record.credit,
                'semester': record.semester,
                'occurredAt': record.occurredAt,
                'status': record.status,
              },
            )
            .toList(),
        'totals': value.totals?.toJson(),
      },
    );
  }

  Future<McpSnapshotEnvelope> campusCard() async {
    final result = await _campusCardService.readLatestCachedCampusCard();
    final value = result?.snapshot;
    if (value == null) return const McpSnapshotEnvelope(status: 'empty');
    return McpSnapshotEnvelope(
      status: _stale(value.fetchedAt) ? 'stale' : 'ok',
      snapshotAt: value.fetchedAt,
      data: {
        'balance': value.balance,
        'currency': 'CNY',
        'cardStatus': value.status,
      },
    );
  }

  Future<McpSnapshotEnvelope> campusCardTransactions(
    Map<String, dynamic> args,
  ) async {
    final result = await _campusCardService.readLatestCachedCampusCard();
    final value = result?.snapshot;
    if (value == null) return const McpSnapshotEnvelope(status: 'empty');
    final from = _date(args['from']);
    final to = _date(args['to']);
    final direction = args['direction'] as String? ?? 'all';
    final records = value.records
        .where((record) {
          final occurred = _date(record.occurredAt);
          if (from != null && occurred != null && occurred.isBefore(from)) {
            return false;
          }
          if (to != null &&
              occurred != null &&
              occurred.isAfter(_endOfDay(to))) {
            return false;
          }
          final normalizedDirection = record.isIncome ? 'credit' : 'debit';
          return direction == 'all' || direction == normalizedDirection;
        })
        .map((record) {
          final normalizedDirection = record.isIncome ? 'credit' : 'debit';
          return <String, dynamic>{
            'occurredAt': record.occurredAt,
            'amount': record.amount.abs(),
            'currency': 'CNY',
            'direction': normalizedDirection,
            'merchant': record.merchant ?? record.title,
            'type': record.type,
            'balanceAfter': record.balanceAfter,
            'status': record.status,
          };
        })
        .toList();
    return McpSnapshotEnvelope(
      status: _stale(value.fetchedAt) ? 'stale' : 'ok',
      snapshotAt: value.fetchedAt,
      data: {'items': records},
    );
  }

  Future<McpSnapshotEnvelope> messages(Map<String, dynamic> args) async {
    final values = await _messageStateService.loadMessages();
    if (values.isEmpty) return const McpSnapshotEnvelope(status: 'empty');
    final query = (args['query'] as String?)?.trim().toLowerCase();
    final from = _date(args['from']);
    final to = _date(args['to']);
    final source = (args['source'] as String?)?.trim().toLowerCase();
    final filtered =
        values.where((message) {
          final published = _date(message.date);
          if (from != null && published != null && published.isBefore(from)) {
            return false;
          }
          if (to != null && published != null && published.isAfter(to)) {
            return false;
          }
          final sourceLabel = message.sourceName.label.toLowerCase();
          if (source != null &&
              source.isNotEmpty &&
              !sourceLabel.contains(source)) {
            return false;
          }
          if (query == null || query.isEmpty) return true;
          return message.title.toLowerCase().contains(query) ||
              (message.summary?.toLowerCase().contains(query) ?? false);
        }).toList()..sort((left, right) {
          final leftTime =
              left.timestamp ?? _date(left.date)?.millisecondsSinceEpoch ?? 0;
          final rightTime =
              right.timestamp ?? _date(right.date)?.millisecondsSinceEpoch ?? 0;
          return rightTime.compareTo(leftTime);
        });
    return McpSnapshotEnvelope(
      status: 'ok',
      data: {
        'items': filtered
            .map(
              (message) => {
                'title': message.title,
                'summary': _truncate(message.summary, 300),
                'publishedDate': message.date,
                'sourceName': message.sourceName.label,
                'category': message.category.label,
              },
            )
            .toList(),
      },
    );
  }

  Future<McpSnapshotEnvelope> email(Map<String, dynamic> args) async {
    // IMAP is the canonical inbox cache.  No network fetch, body read, or
    // attachment download is performed here.
    final result = await _emailService.readLatestCachedMessages(
      EmailProtocol.imap,
    );
    final snapshot = result?.snapshot;
    if (snapshot == null) return const McpSnapshotEnvelope(status: 'empty');
    final query = (args['query'] as String?)?.trim().toLowerCase();
    final from = _date(args['from']);
    final to = _date(args['to']);
    final filtered =
        snapshot.messages.where((message) {
          final received = message.receivedAt;
          if (from != null && received != null && received.isBefore(from)) {
            return false;
          }
          if (to != null &&
              received != null &&
              received.isAfter(_endOfDay(to))) {
            return false;
          }
          if (query == null || query.isEmpty) return true;
          return message.subject.toLowerCase().contains(query) ||
              message.senderName.toLowerCase().contains(query) ||
              message.senderAddress.toLowerCase().contains(query) ||
              message.preview.toLowerCase().contains(query);
        }).toList()..sort((left, right) {
          final leftTime = left.receivedAt?.millisecondsSinceEpoch ?? 0;
          final rightTime = right.receivedAt?.millisecondsSinceEpoch ?? 0;
          return rightTime.compareTo(leftTime);
        });
    return McpSnapshotEnvelope(
      status: _stale(snapshot.fetchedAt) ? 'stale' : 'ok',
      snapshotAt: snapshot.fetchedAt,
      data: {
        'items': filtered
            .map(
              (message) => {
                'messageId': base64UrlEncode(
                  sha256
                      .convert(utf8.encode(message.id))
                      .bytes
                      .take(12)
                      .toList(),
                ).replaceAll('=', ''),
                'subject': message.subject,
                'senderDisplayName': message.senderName,
                'senderAddress': message.senderAddress,
                'receivedAt': message.receivedAt?.toUtc().toIso8601String(),
                'preview': _truncate(message.preview, 300),
                'hasAttachments': message.attachments.isNotEmpty,
              },
            )
            .toList(),
      },
    );
  }

  DateTime? _date(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  DateTime _endOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

  String? _truncate(String? value, int limit) {
    if (value == null || value.isEmpty) return value;
    return value.length <= limit ? value : value.substring(0, limit);
  }

  bool _stale(DateTime at) =>
      DateTime.now().difference(at) > const Duration(hours: 24);
}
