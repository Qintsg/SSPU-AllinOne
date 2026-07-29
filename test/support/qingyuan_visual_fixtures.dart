/* 清源视觉验收脱敏 fixture — 固定时钟与确定性业务状态。 */

import 'dart:async';

import 'package:sspu_allinone/models/academic_calendar.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/models/campus_card.dart';
import 'package:sspu_allinone/models/email_mailbox.dart';
import 'package:sspu_allinone/models/message_item.dart';
import 'package:sspu_allinone/models/sports_attendance.dart';
import 'package:sspu_allinone/models/student_report.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
import 'package:sspu_allinone/services/academic_calendar_service.dart';
import 'package:sspu_allinone/services/academic_term_service.dart';
import 'package:sspu_allinone/services/campus_card_service.dart';
import 'package:sspu_allinone/services/email_service.dart';
import 'package:sspu_allinone/services/sports_attendance_service.dart';
import 'package:sspu_allinone/services/student_report_service.dart';

/// 视觉矩阵的固定本地时钟。
final DateTime qingyuanVisualNow = DateTime(2026, 7, 18, 9, 30);

/// 教务证据页的冻结来源时间，与对应 HTML 参考稿保持一致。
final DateTime qingyuanAcademicEvidenceTime = DateTime(2026, 7, 18, 8, 42);

/// 完全离线的学期解析模块，视觉采集不得访问真实教务处校历。
AcademicTermService buildQingyuanVisualAcademicTermService() {
  return AcademicTermService(
    calendarService: const QingyuanVisualAcademicCalendarClient(),
  );
}

class QingyuanVisualAcademicCalendarClient implements AcademicCalendarClient {
  const QingyuanVisualAcademicCalendarClient({
    this.cachedEntries = const [],
    this.viewerResult = const AcademicCalendarSyncResult(
      entries: [],
      loadedFromCache: false,
      refreshed: false,
    ),
    this.pendingViewer,
  });

  final List<AcademicCalendarCacheEntry> cachedEntries;
  final AcademicCalendarSyncResult viewerResult;
  final Completer<AcademicCalendarSyncResult>? pendingViewer;

  @override
  Future<AcademicCalendarSyncResult> ensureCalendarsForDate({
    DateTime? now,
  }) async => viewerResult;

  @override
  Future<AcademicCalendarSyncResult> ensureCalendarsForViewer({
    DateTime? now,
  }) => pendingViewer?.future ?? Future.value(viewerResult);

  @override
  Future<List<AcademicCalendarCacheEntry>> readCachedCalendars() async =>
      cachedEntries;

  @override
  Future<AcademicCalendarCacheEntry?> readCachedCalendar(int schoolYear) async {
    for (final entry in cachedEntries) {
      if (entry.schoolYearStart == schoolYear) return entry;
    }
    return null;
  }

  @override
  Future<List<AcademicTermDefinition>> readCachedTermDefinitions() async =>
      AcademicCalendarService.termDefinitionsFromEntries(cachedEntries);

  @override
  Future<List<AcademicCalendarCacheEntry>> refreshCalendars({
    List<int>? targetYears,
  }) async => viewerResult.entries;
}

final List<AcademicCalendarCacheEntry> qingyuanAcademicCalendarEntries = [
  AcademicCalendarCacheEntry(
    schoolYearStart: 2025,
    title: '2025-2026 学年校历',
    detailUrl: 'https://calendar.example.invalid/2025-2026',
    publishDate: '2025-04-24',
    pdfUrl: 'https://calendar.example.invalid/2025-2026.pdf',
    imageUrls: const [],
    sourceType: AcademicCalendarSourceType.pdf,
    fetchedAt: DateTime(2026, 7, 18, 8, 42),
    parseVersion: AcademicCalendarService.parseVersion,
    pdfFilePath: null,
    rawTextFilePath: null,
    rawExtractedText: null,
    schedule: null,
    warnings: const [],
    errorMessage: null,
  ),
  AcademicCalendarCacheEntry(
    schoolYearStart: 2024,
    title: '2024-2025 学年校历',
    detailUrl: 'https://calendar.example.invalid/2024-2025',
    publishDate: '2024-04-26',
    pdfUrl: 'https://calendar.example.invalid/2024-2025.pdf',
    imageUrls: const [],
    sourceType: AcademicCalendarSourceType.pdf,
    fetchedAt: DateTime(2026, 7, 18, 8, 42),
    parseVersion: AcademicCalendarService.parseVersion,
    pdfFilePath: null,
    rawTextFilePath: null,
    rawExtractedText: null,
    schedule: null,
    warnings: const [],
    errorMessage: null,
  ),
];

final AcademicCalendarSyncResult qingyuanAcademicCalendarContentResult =
    AcademicCalendarSyncResult(
      entries: qingyuanAcademicCalendarEntries,
      loadedFromCache: true,
      refreshed: false,
    );

const AcademicCalendarSyncResult qingyuanAcademicCalendarEmptyResult =
    AcademicCalendarSyncResult(
      entries: [],
      loadedFromCache: false,
      refreshed: true,
    );

final AcademicCalendarSyncResult qingyuanAcademicCalendarStaleResult =
    AcademicCalendarSyncResult(
      entries: qingyuanAcademicCalendarEntries,
      loadedFromCache: true,
      refreshed: false,
      errorMessage: '正在显示本地校历缓存；网络恢复后可刷新。',
    );

const AcademicCalendarSyncResult qingyuanAcademicCalendarErrorResult =
    AcademicCalendarSyncResult(
      entries: [],
      loadedFromCache: false,
      refreshed: false,
      errorMessage: '暂时无法读取校历，请检查网络后重试。',
    );

/// 首页时间轨的固定脱敏待办。
final List<MessageItem> qingyuanHomeMessages = [
  MessageItem(
    id: 'visual-home-task',
    title: '大学英语作业截止',
    date: '2026-07-18',
    url: 'https://academic.example.invalid/assignment',
    sourceType: MessageSourceType.schoolWebsite,
    sourceName: MessageSourceName.jwc,
    category: MessageCategory.jwcStudent,
    timestamp: DateTime(2026, 7, 18, 16).millisecondsSinceEpoch,
  ),
];

final Uri _campusCardEntranceUri = Uri.parse(
  'https://oa.example.invalid/interface/Entrance.jsp?id=campus-card',
);
final Uri _campusCardSourceUri = Uri.parse(
  'https://card.example.invalid/epay/consume/query',
);

/// 校园卡页面的固定脱敏交易记录。
const List<CampusCardTransactionRecord> qingyuanCampusCardTransactions = [
  CampusCardTransactionRecord(
    occurredAt: '2026-07-18 08:12',
    amount: -18.5,
    title: '一食堂 · POS 消费',
    counterparty: '一食堂',
    paymentMethod: '校园卡',
    status: '成功',
    direction: 'expense',
    rawCells: ['2026-07-18 08:12', '一食堂 · POS 消费', '-18.50'],
  ),
  CampusCardTransactionRecord(
    occurredAt: '2026-07-17 16:42',
    amount: 100,
    title: '校园卡充值',
    counterparty: '在线充值',
    paymentMethod: '在线充值',
    status: '成功',
    direction: 'income',
    rawCells: ['2026-07-17 16:42', '校园卡充值', '+100.00'],
  ),
  CampusCardTransactionRecord(
    occurredAt: '2026-07-16 12:06',
    amount: -18.5,
    title: '图书馆咖啡吧',
    counterparty: '图书馆咖啡吧',
    paymentMethod: '校园卡',
    status: '成功',
    direction: 'expense',
    rawCells: ['2026-07-16 12:06', '图书馆咖啡吧', '-18.50'],
  ),
];

/// 校园卡正常内容 fixture。
final CampusCardQueryResult qingyuanCampusCardContentResult = _campusCardResult(
  checkedAt: qingyuanVisualNow,
  balance: 128.5,
  records: qingyuanCampusCardTransactions,
);

/// 校园卡空内容 fixture，余额与交易均尚未读取。
final CampusCardQueryResult qingyuanCampusCardEmptyResult = _campusCardResult(
  checkedAt: qingyuanVisualNow,
  balance: null,
  records: const [],
);

/// 校园卡昨日缓存 fixture。
final CampusCardQueryResult qingyuanCampusCardStaleResult = _campusCardResult(
  checkedAt: DateTime(2026, 7, 17, 18),
  balance: 128.5,
  records: qingyuanCampusCardTransactions,
  message: '已显示本地校园卡缓存',
);

/// 校园卡查询失败 fixture。
final CampusCardQueryResult qingyuanCampusCardErrorResult =
    CampusCardQueryResult(
      status: CampusCardQueryStatus.networkError,
      message: '校园卡暂不可用',
      detail: '请检查 OA 登录与校园网络。',
      checkedAt: qingyuanVisualNow,
      entranceUri: _campusCardEntranceUri,
    );

CampusCardQueryResult _campusCardResult({
  required DateTime checkedAt,
  required double? balance,
  required List<CampusCardTransactionRecord> records,
  String message = '校园卡已同步',
}) {
  return CampusCardQueryResult(
    status: CampusCardQueryStatus.success,
    message: message,
    detail: '已读取脱敏校园卡余额与交易记录。',
    checkedAt: checkedAt,
    entranceUri: _campusCardEntranceUri,
    finalUri: _campusCardSourceUri,
    snapshot: CampusCardSnapshot(
      balance: balance,
      status: '正常',
      records: records,
      fetchedAt: checkedAt,
      sourceUri: _campusCardSourceUri,
      transactionPageCount: 1,
    ),
  );
}

/// 视觉测试使用的无网络校园卡客户端。
class QingyuanVisualCampusCardClient implements CampusCardBalanceClient {
  QingyuanVisualCampusCardClient({required this.result, this.cachedResult});

  final CampusCardQueryResult result;
  final CampusCardQueryResult? cachedResult;

  @override
  Future<CampusCardQueryResult?> readLatestCachedCampusCard() async =>
      cachedResult;

  @override
  Future<CampusCardQueryResult> fetchCampusCard({
    DateTime? startDate,
    DateTime? endDate,
    bool requireCampusNetwork = true,
    bool queryTransactions = false,
    bool syncAllTransactions = false,
  }) async => result;
}

/// 资讯页面的固定脱敏内容，不访问学校官网或公众号平台。
final List<MessageItem> qingyuanInfoMessages = [
  MessageItem(
    id: 'visual-info-001',
    title: '关于 2025–2026 学年夏季学期考试安排的通知',
    summary: '请同学们在教务系统中核对考试时间和地点，如有冲突及时联系学院教务老师。',
    date: '2026-07-18',
    url: 'https://academic.example.invalid/exam-notice',
    sourceType: MessageSourceType.schoolWebsite,
    sourceName: MessageSourceName.jwc,
    category: MessageCategory.jwcStudent,
    timestamp: DateTime(2026, 7, 18, 8, 30).millisecondsSinceEpoch,
  ),
  MessageItem(
    id: 'visual-info-002',
    title: '图书馆暑期开放时间调整',
    summary: '暑期开放区域与服务时间有所调整，入馆前请查看最新安排。',
    date: '2026-07-17',
    url: 'https://library.example.invalid/summer-hours',
    sourceType: MessageSourceType.schoolWebsite,
    sourceName: MessageSourceName.libCenter,
    category: MessageCategory.libCenterNotice,
    timestamp: DateTime(2026, 7, 17, 17, 20).millisecondsSinceEpoch,
  ),
  MessageItem(
    id: 'visual-info-003',
    title: '校园夏日服务指南',
    summary: '集中查看餐饮、班车、场馆与值班服务信息。',
    date: '2026-07-16',
    url: 'https://wechat.example.invalid/summer-guide',
    sourceType: MessageSourceType.wechatPublic,
    sourceName: MessageSourceName.wechatPublicPlaceholder,
    category: MessageCategory.wechatArticle,
    mpBookId: 'visual-wechat-account',
    mpName: '工大校园服务',
    timestamp: DateTime(2026, 7, 16, 9).millisecondsSinceEpoch,
  ),
  for (var index = 0; index < 4; index++)
    MessageItem(
      id: 'visual-info-school-$index',
      title: '学校官网脱敏资讯 ${index + 1}',
      date: '2026-07-15',
      url: 'https://www.example.invalid/news/$index',
      sourceType: MessageSourceType.schoolWebsite,
      sourceName: MessageSourceName.sspuOfficial,
      category: MessageCategory.sspuNews,
      timestamp: DateTime(2026, 7, 15, 12, index).millisecondsSinceEpoch,
    ),
  for (var index = 0; index < 3; index++)
    MessageItem(
      id: 'visual-info-academic-$index',
      title: '教务处脱敏通知 ${index + 1}',
      date: '2026-07-14',
      url: 'https://academic.example.invalid/news/$index',
      sourceType: MessageSourceType.schoolWebsite,
      sourceName: MessageSourceName.jwc,
      category: MessageCategory.jwcTeaching,
      timestamp: DateTime(2026, 7, 14, 12, index).millisecondsSinceEpoch,
    ),
  for (var index = 0; index < 2; index++)
    MessageItem(
      id: 'visual-info-wechat-$index',
      title: '微信公众号脱敏推文 ${index + 1}',
      date: '2026-07-13',
      url: 'https://wechat.example.invalid/article/$index',
      sourceType: MessageSourceType.wechatPublic,
      sourceName: MessageSourceName.wechatPublicPlaceholder,
      category: MessageCategory.wechatArticle,
      mpBookId: 'visual-wechat-account',
      mpName: '工大校园服务',
      timestamp: DateTime(2026, 7, 13, 12, index).millisecondsSinceEpoch,
    ),
];

final Uri _entranceUri = Uri.parse(
  'https://oa.example.invalid/interface/Entrance.jsp?id=academic',
);
final Uri _sourceUri = Uri.parse(
  'https://academic.example.invalid/course-table',
);

/// 课表正常内容 fixture。
final AcademicEamsQueryResult qingyuanScheduleContentResult = _scheduleResult(
  checkedAt: qingyuanVisualNow,
  entries: const [
    AcademicCourseTableEntry(
      courseName: '数据结构',
      weekday: 1,
      startUnit: 1,
      endUnit: 2,
      timeText: '周一 第1-2节',
      teacher: '陈老师',
      location: '计算机楼 301',
      weekDescription: '1-16周',
      rawText: '数据结构 陈老师 计算机楼 301 1-16周',
    ),
    AcademicCourseTableEntry(
      courseName: '人机交互设计',
      weekday: 3,
      startUnit: 5,
      endUnit: 6,
      timeText: '周三 第5-6节',
      teacher: '林老师',
      location: '艺术楼 B204',
      weekDescription: '2-15周',
      rawText: '人机交互设计 林老师 艺术楼 B204 2-15周',
    ),
    AcademicCourseTableEntry(
      courseName: '软件工程实践',
      weekday: 6,
      startUnit: 3,
      endUnit: 4,
      timeText: '周六 第3-4节',
      teacher: '周老师',
      location: '实训中心 405',
      weekDescription: '1-8周',
      rawText: '软件工程实践 周老师 实训中心 405 1-8周',
    ),
  ],
);

/// 首页学程与培养进度 fixture。
final AcademicEamsQueryResult qingyuanHomeAcademicResult = _scheduleResult(
  checkedAt: DateTime(2026, 7, 18, 8, 42),
  entries: const [
    AcademicCourseTableEntry(
      courseName: '高等数学',
      weekday: 6,
      startUnit: 1,
      endUnit: 2,
      timeText: '周六 第1-2节',
      teacher: '周老师',
      location: '教学楼 3 号楼 · 401',
      weekDescription: '1-16周',
      rawText: '高等数学 周老师 教学楼 3 号楼 401',
    ),
    AcademicCourseTableEntry(
      courseName: '数据结构',
      weekday: 6,
      startUnit: 3,
      endUnit: 4,
      timeText: '周六 第3-4节',
      teacher: '陈老师',
      location: '教学楼 2 号楼 · 302',
      weekDescription: '1-16周',
      rawText: '数据结构 陈老师 教学楼 2 号楼 302',
    ),
  ],
  programCompletion: const AcademicProgramCompletionSnapshot(
    completedCourseCount: 42,
    pendingCourseCount: 28,
    completedCredits: 86,
    pendingCredits: 64,
    moduleProgress: [],
  ),
);

final AcademicEamsQueryResult qingyuanAcademicOverviewEmptyResult =
    _academicDetailResult(message: '尚未读取可展示的教务数据');

final AcademicEamsQueryResult qingyuanAcademicOverviewStaleResult =
    AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.partialSuccess,
      message: '正在显示昨日教务缓存',
      detail: '网络恢复后可手动刷新；本地数据不会被删除。',
      checkedAt: DateTime(2026, 7, 17, 18),
      entranceUri: _academicVisualEntranceUri,
      finalUri: _academicVisualSourceUri,
      snapshot: qingyuanHomeAcademicResult.snapshot,
    );

/// 课表空数据 fixture。
final AcademicEamsQueryResult qingyuanScheduleEmptyResult = _scheduleResult(
  checkedAt: qingyuanVisualNow,
  entries: const [],
);

/// 课表过期缓存 fixture。
final AcademicEamsQueryResult qingyuanScheduleStaleResult = _scheduleResult(
  checkedAt: DateTime(2026, 7, 17, 18, 0),
  entries: qingyuanScheduleContentResult.snapshot!.courseTable!.entries,
  status: AcademicEamsQueryStatus.partialSuccess,
  warnings: const ['当前展示为昨日缓存，实时刷新暂不可用'],
);

/// 课表失败 fixture。
final AcademicEamsQueryResult qingyuanScheduleErrorResult =
    AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.networkError,
      message: '暂时无法读取课表',
      detail: '请检查校园网络或 VPN 后重试，已保留本地数据。',
      checkedAt: qingyuanVisualNow,
      entranceUri: _entranceUri,
    );

AcademicEamsQueryResult _scheduleResult({
  required DateTime checkedAt,
  required List<AcademicCourseTableEntry> entries,
  AcademicEamsQueryStatus status = AcademicEamsQueryStatus.success,
  List<String> warnings = const [],
  AcademicProgramCompletionSnapshot? programCompletion,
}) {
  return AcademicEamsQueryResult(
    status: status,
    message: status == AcademicEamsQueryStatus.success ? '课表已同步' : '正在显示缓存课表',
    detail: '已读取当前学期课表。',
    checkedAt: checkedAt,
    entranceUri: _entranceUri,
    snapshot: AcademicEamsSnapshot(
      fetchedAt: checkedAt,
      sourceUri: _sourceUri,
      warnings: warnings,
      hasCourseOfferingEntry: true,
      hasFreeClassroomEntry: true,
      profile: const AcademicEamsProfile(
        name: '清源同学',
        studentId: '20260001',
        department: '计算机与信息工程学院',
        major: '软件工程',
        className: '软件 241',
        gender: '不展示',
        studyLength: '4 年',
        educationLevel: '本科',
        rawFields: {},
      ),
      courseTable: AcademicCourseTableSnapshot(
        termName: '2025-2026 第2学期',
        entries: entries,
        fetchedAt: checkedAt,
        sourceUri: _sourceUri,
      ),
      programCompletion: programCompletion,
    ),
  );
}

/// 视觉测试使用的无网络 EAMS 客户端。
class QingyuanVisualAcademicEamsClient implements AcademicEamsClient {
  QingyuanVisualAcademicEamsClient({
    required this.result,
    this.cachedResult,
    this.cachedOverviewResult,
    this.cachedExamResult,
    this.cachedGradeResult,
    this.cachedGradeProcessResult,
    this.pendingCourseTable,
    this.pendingOverview,
    this.pendingExam,
    this.pendingGrades,
    this.pendingGradeProcess,
    this.examResult,
    this.gradeResult,
    this.gradeProcessResult,
  });

  final AcademicEamsQueryResult result;
  final AcademicEamsQueryResult? cachedResult;
  final AcademicEamsQueryResult? cachedOverviewResult;
  final AcademicEamsQueryResult? cachedExamResult;
  final AcademicEamsQueryResult? cachedGradeResult;
  final AcademicEamsQueryResult? cachedGradeProcessResult;
  final Completer<AcademicEamsQueryResult>? pendingCourseTable;
  final Completer<AcademicEamsQueryResult>? pendingOverview;
  final Completer<AcademicEamsQueryResult>? pendingExam;
  final Completer<AcademicEamsQueryResult>? pendingGrades;
  final Completer<AcademicEamsQueryResult>? pendingGradeProcess;
  final AcademicEamsQueryResult? examResult;
  final AcademicEamsQueryResult? gradeResult;
  final AcademicEamsQueryResult? gradeProcessResult;

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedCourseTable() async {
    return cachedResult;
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedOverview() async =>
      cachedOverviewResult;

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedExamSchedule() async =>
      cachedExamResult;

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedGrades() async =>
      cachedGradeResult;

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedGradeProcess() async =>
      cachedGradeProcessResult;

  @override
  Future<AcademicEamsProfile?> readCachedStudentProfile() async => null;

  @override
  Future<AcademicEamsProfile?> refreshStudentProfileIfIncomplete({
    bool forceRefresh = false,
  }) async => result.snapshot?.profile;

  @override
  Future<AcademicEamsQueryResult> fetchCourseTable({
    bool requireCampusNetwork = true,
  }) {
    return pendingCourseTable?.future ?? Future.value(result);
  }

  @override
  Future<AcademicEamsQueryResult> fetchOverview({
    bool requireCampusNetwork = true,
  }) => pendingOverview?.future ?? Future.value(result);

  @override
  Future<AcademicEamsQueryResult> fetchExamSchedule({
    AcademicTermChoice? term,
    AcademicEamsSemesterOption? semester,
    String? examTypeId,
    bool requireCampusNetwork = true,
  }) => pendingExam?.future ?? Future.value(examResult ?? result);

  @override
  Future<AcademicEamsQueryResult> fetchGrades({
    bool requireCampusNetwork = true,
  }) => pendingGrades?.future ?? Future.value(gradeResult ?? result);

  @override
  Future<AcademicEamsQueryResult> fetchGradeProcess({
    AcademicTermChoice? term,
    AcademicEamsSemesterOption? semester,
    bool requireCampusNetwork = true,
  }) =>
      pendingGradeProcess?.future ?? Future.value(gradeProcessResult ?? result);
}

final Uri _academicVisualEntranceUri = Uri.parse(
  'https://oa.example.invalid/interface/Entrance.jsp?id=academic',
);
final Uri _academicVisualSourceUri = Uri.parse(
  'https://academic.example.invalid/eams/read-only',
);
final AcademicEamsSemesterOption qingyuanAcademicSemester =
    AcademicEamsSemesterOption.fromEamsFields(
      id: 'visual-1042',
      schoolYear: '2025-2026',
      termCode: '2',
    );

final AcademicEamsQueryResult qingyuanAcademicGradeContentResult =
    _academicDetailResult(
      message: '成绩读取成功',
      grades: AcademicGradeSnapshot(
        currentTermRecords: const [
          AcademicGradeRecord(
            courseCode: 'CS201',
            courseName: '数据结构',
            termName: '2025-2026-2',
            scoreText: '92',
            totalScoreText: '92',
            credit: 4,
            gradePoint: 4.2,
            rawCells: ['CS201', '数据结构', '4', '92'],
          ),
          AcademicGradeRecord(
            courseCode: 'SE202',
            courseName: '软件工程实践',
            termName: '2025-2026-2',
            scoreText: '优秀',
            totalScoreText: '优秀',
            credit: 2,
            gradePoint: 4.5,
            rawCells: ['SE202', '软件工程实践', '2', '优秀'],
          ),
        ],
        historyRecords: const [
          AcademicGradeRecord(
            courseCode: 'MATH101',
            courseName: '高等数学',
            termName: '2025-2026-1',
            scoreText: '88',
            totalScoreText: '88',
            credit: 5,
            gradePoint: 3.8,
            rawCells: ['MATH101', '高等数学', '5', '88'],
          ),
        ],
        fetchedAt: qingyuanVisualNow,
        sourceUri: _academicVisualSourceUri,
      ),
    );

final AcademicEamsQueryResult qingyuanAcademicGradeEmptyResult =
    _academicDetailResult(
      message: '当前范围暂无成绩',
      grades: AcademicGradeSnapshot(
        currentTermRecords: const [],
        historyRecords: const [],
        fetchedAt: qingyuanVisualNow,
        sourceUri: _academicVisualSourceUri,
      ),
    );

final AcademicEamsQueryResult qingyuanAcademicGradeStaleResult =
    _academicDetailResult(
      status: AcademicEamsQueryStatus.partialSuccess,
      message: '正在显示昨日成绩缓存',
      detail: '网络恢复后可手动刷新。',
      checkedAt: DateTime(2026, 7, 17, 18),
      grades: qingyuanAcademicGradeContentResult.snapshot!.grades,
    );

final AcademicEamsQueryResult qingyuanAcademicExamContentResult =
    _academicDetailResult(
      message: '考试安排读取成功',
      exams: AcademicExamSnapshot(
        selectedSemester: qingyuanAcademicSemester,
        semesterOptions: [qingyuanAcademicSemester],
        selectedExamType: '1',
        examTypeOptions: const {'1': '期末考试', '2': '期中考试'},
        records: const [
          AcademicExamRecord(
            examType: '期末考试',
            courseSequence: 'CS201',
            courseName: '数据结构',
            examDate: '2026-07-22',
            examArrange: '09:00–10:30',
            examLocation: '教学楼 2 号楼 · 302',
            examSituation: '正常',
            rawCells: ['期末考试', 'CS201', '数据结构', '2026-07-22'],
          ),
          AcademicExamRecord(
            examType: '期末考试',
            courseSequence: 'SE202',
            courseName: '软件工程实践',
            examDate: '[考试情况尚未发布]',
            otherExplanation: '课程设计答辩安排另行通知',
            rawCells: ['期末考试', 'SE202', '软件工程实践', '[考试情况尚未发布]'],
          ),
        ],
        fetchedAt: qingyuanVisualNow,
        sourceUri: _academicVisualSourceUri,
      ),
    );

final AcademicEamsQueryResult qingyuanAcademicOverviewExamContentResult =
    _academicDetailResult(
      message: '考试安排读取成功',
      exams: AcademicExamSnapshot(
        selectedSemester: AcademicEamsSemesterOption.fromEamsFields(
          id: 'visual-summer',
          schoolYear: '2025-2026',
          termCode: '3',
        ),
        records: const [
          AcademicExamRecord(
            examType: '期末考试',
            courseSequence: 'MA302',
            courseName: '离散数学',
            examDate: '2026-07-22',
            examArrange: '09:00',
            examLocation: '教一 201',
            examSituation: '正常',
            rawCells: ['期末考试', 'MA302', '离散数学', '2026-07-22'],
          ),
        ],
        fetchedAt: qingyuanVisualNow,
        sourceUri: _academicVisualSourceUri,
      ),
    );

final AcademicEamsQueryResult qingyuanAcademicExamEmptyResult =
    _academicDetailResult(
      message: '当前学期暂无考试安排',
      exams: AcademicExamSnapshot(
        selectedSemester: qingyuanAcademicSemester,
        semesterOptions: [qingyuanAcademicSemester],
        selectedExamType: '1',
        examTypeOptions: const {'1': '期末考试'},
        records: const [],
        fetchedAt: qingyuanVisualNow,
        sourceUri: _academicVisualSourceUri,
      ),
    );

final AcademicEamsQueryResult qingyuanAcademicExamStaleResult =
    _academicDetailResult(
      status: AcademicEamsQueryStatus.partialSuccess,
      message: '正在显示昨日考试安排缓存',
      detail: '网络恢复后可手动刷新。',
      checkedAt: DateTime(2026, 7, 17, 18),
      exams: qingyuanAcademicExamContentResult.snapshot!.exams,
    );

final AcademicEamsQueryResult qingyuanAcademicGradeProcessContentResult =
    _academicDetailResult(
      message: '过程化成绩读取成功',
      gradeProcess: AcademicGradeProcessSnapshot(
        selectedSemester: qingyuanAcademicSemester,
        semesterOptions: [qingyuanAcademicSemester],
        records: const [
          AcademicGradeProcessRecord(
            courseCode: 'CS201',
            courseName: '数据结构',
            termName: '2025-2026-2',
            category: '专业基础课',
            credit: 4,
            items: [
              AcademicGradeProcessItem(label: '课堂表现', value: '95 / 10%'),
              AcademicGradeProcessItem(label: '课程作业', value: '90 / 30%'),
              AcademicGradeProcessItem(label: '期中测验', value: '88 / 20%'),
            ],
            rawCells: ['CS201', '数据结构', '课堂表现 95', '课程作业 90'],
          ),
        ],
        fetchedAt: qingyuanVisualNow,
        sourceUri: _academicVisualSourceUri,
      ),
    );

final AcademicEamsQueryResult qingyuanAcademicGradeProcessEmptyResult =
    _academicDetailResult(
      message: '当前学期暂无过程化成绩',
      gradeProcess: AcademicGradeProcessSnapshot(
        selectedSemester: qingyuanAcademicSemester,
        semesterOptions: [qingyuanAcademicSemester],
        records: const [],
        fetchedAt: qingyuanVisualNow,
        sourceUri: _academicVisualSourceUri,
      ),
    );

final AcademicEamsQueryResult qingyuanAcademicDetailErrorResult =
    AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.networkError,
      message: '暂时无法读取教务数据',
      detail: '请检查校园网络或 VPN 后重试；已有本地数据不会被删除。',
      checkedAt: qingyuanVisualNow,
      entranceUri: _academicVisualEntranceUri,
    );

AcademicEamsQueryResult _academicDetailResult({
  required String message,
  AcademicEamsQueryStatus status = AcademicEamsQueryStatus.success,
  String detail = '已读取固定脱敏教务数据。',
  DateTime? checkedAt,
  AcademicGradeSnapshot? grades,
  AcademicExamSnapshot? exams,
  AcademicGradeProcessSnapshot? gradeProcess,
}) {
  return AcademicEamsQueryResult(
    status: status,
    message: message,
    detail: detail,
    checkedAt: checkedAt ?? qingyuanVisualNow,
    entranceUri: _academicVisualEntranceUri,
    finalUri: _academicVisualSourceUri,
    snapshot: AcademicEamsSnapshot(
      fetchedAt: qingyuanVisualNow,
      sourceUri: _academicVisualSourceUri,
      warnings: const [],
      hasCourseOfferingEntry: true,
      hasFreeClassroomEntry: true,
      grades: grades,
      exams: exams,
      gradeProcess: gradeProcess,
    ),
  );
}

final SportsAttendanceSummary qingyuanAcademicSportsContentSummary =
    SportsAttendanceSummary(
      morningExerciseCount: 6,
      extracurricularActivityCount: 6,
      countAdjustmentCount: 0,
      sportsCorridorCount: 0,
      records: const [
        SportsAttendanceRecord(
          category: SportsAttendanceCategory.morningExercise,
          count: 1,
          occurredAt: '2026-07-15 06:45',
          project: '晨跑',
          location: '学校操场',
          remark: '有效',
          cells: ['2026-07-15 06:45', '晨跑', '学校操场', '有效'],
        ),
        SportsAttendanceRecord(
          category: SportsAttendanceCategory.extracurricularActivity,
          count: 1,
          occurredAt: '2026-07-17 18:30',
          project: '羽毛球活动',
          location: '体育馆 2 号场',
          remark: '已签到',
          cells: ['2026-07-17 18:30', '羽毛球活动', '体育馆 2 号场', '已签到'],
        ),
      ],
      fetchedAt: DateTime(2026, 7, 18, 8, 42),
      sourceUri: Uri.parse('https://sports.example.invalid/attendance'),
    );

final SportsAttendanceQueryResult qingyuanHomeSportsResult =
    SportsAttendanceQueryResult(
      status: SportsAttendanceQueryStatus.success,
      message: '体育考勤已同步',
      detail: '已读取脱敏体育考勤汇总。',
      checkedAt: DateTime(2026, 7, 18, 8, 42),
      entranceUri: Uri.parse('https://sports.example.invalid/login'),
      summary: qingyuanAcademicSportsContentSummary,
    );

final SportsAttendanceQueryResult qingyuanAcademicSportsEmptyResult =
    SportsAttendanceQueryResult(
      status: SportsAttendanceQueryStatus.success,
      message: '当前范围暂无体育考勤',
      detail: '已读取固定脱敏体育考勤数据。',
      checkedAt: qingyuanAcademicEvidenceTime,
      entranceUri: Uri.parse('https://sports.example.invalid/login'),
      summary: SportsAttendanceSummary(
        morningExerciseCount: 0,
        extracurricularActivityCount: 0,
        countAdjustmentCount: 0,
        sportsCorridorCount: 0,
        records: const [],
        fetchedAt: qingyuanAcademicEvidenceTime,
        sourceUri: Uri.parse('https://sports.example.invalid/attendance'),
      ),
    );

final SportsAttendanceQueryResult qingyuanAcademicSportsStaleResult =
    SportsAttendanceQueryResult(
      status: SportsAttendanceQueryStatus.success,
      message: '正在显示昨日体育考勤缓存',
      detail: '网络恢复后可手动刷新。',
      checkedAt: DateTime(2026, 7, 17, 18),
      entranceUri: Uri.parse('https://sports.example.invalid/login'),
      summary: qingyuanAcademicSportsContentSummary,
    );

final SportsAttendanceQueryResult qingyuanAcademicSportsErrorResult =
    SportsAttendanceQueryResult(
      status: SportsAttendanceQueryStatus.networkError,
      message: '暂时无法读取体育考勤',
      detail: '请检查校园网络或 VPN 后重试。',
      checkedAt: qingyuanAcademicEvidenceTime,
      entranceUri: Uri.parse('https://sports.example.invalid/login'),
    );

final SecondClassroomCreditSummary qingyuanAcademicStudentReportContentSummary =
    SecondClassroomCreditSummary(
      records: const [
        SecondClassroomCreditRecord(
          category: '社会实践',
          itemName: '社区数字助老志愿服务',
          credit: 2,
          semester: '2025-2026-2',
          occurredAt: '2026-06-14',
          status: '已认定',
          rawCells: ['社会实践', '社区数字助老志愿服务', '2.0', '已认定'],
        ),
        SecondClassroomCreditRecord(
          category: '创新创业',
          itemName: '校园应用创新训练',
          credit: 1.5,
          semester: '2025-2026-2',
          occurredAt: '2026-07-02',
          status: '通过',
          rawCells: ['创新创业', '校园应用创新训练', '1.5', '通过'],
        ),
      ],
      rules: const [
        SecondClassroomCreditRuleRow(
          category: '社会实践',
          item: '志愿服务',
          level: '校级',
          participation: '累计 20 小时',
          credit: 2,
          earnedCredit: 2,
          requiredCredit: 2,
          passStatus: '已通过',
        ),
        SecondClassroomCreditRuleRow(
          category: '创新创业',
          item: '创新训练项目',
          level: '校级',
          participation: '结项',
          credit: 1.5,
          earnedCredit: 1.5,
          requiredCredit: 1,
          passStatus: '已通过',
        ),
        SecondClassroomCreditRuleRow(
          category: '报告讲座',
          item: '通识讲座',
          level: '校级',
          participation: '3 场',
          credit: 1,
          earnedCredit: 0.5,
          requiredCredit: 1,
          passStatus: '进行中',
        ),
      ],
      totals: const SecondClassroomCreditTotals(
        totalCredit: 10,
        totalEarnedCredit: 8.5,
        totalRequiredCredit: 10,
        passStatus: '进行中',
      ),
      detailRecords: const [
        SecondClassroomCreditDetailRecord(
          name: '社区数字助老志愿服务',
          category: '社会实践',
          item: '志愿服务',
          level: '校级',
          participation: '累计 20 小时',
          earnedCredit: 2,
        ),
        SecondClassroomCreditDetailRecord(
          name: '校园应用创新训练',
          category: '创新创业',
          item: '创新训练项目',
          level: '校级',
          participation: '结项',
          earnedCredit: 1.5,
        ),
      ],
      fetchedAt: DateTime(2026, 7, 18, 8, 42),
      sourceUri: Uri.parse('https://student.example.invalid/report'),
    );

/// 首页第二课堂辅助坞的固定脱敏学分汇总。
final StudentReportQueryResult qingyuanHomeStudentReportResult =
    StudentReportQueryResult(
      status: StudentReportQueryStatus.success,
      message: '第二课堂学分已同步',
      detail: '已读取脱敏第二课堂学分汇总。',
      checkedAt: DateTime(2026, 7, 18, 8, 42),
      entranceUri: Uri.parse('https://oa.example.invalid/student-report'),
      summary: qingyuanAcademicStudentReportContentSummary,
    );

final StudentReportQueryResult qingyuanAcademicStudentReportEmptyResult =
    StudentReportQueryResult(
      status: StudentReportQueryStatus.success,
      message: '当前范围暂无第二课堂记录',
      detail: '已读取固定脱敏第二课堂数据。',
      checkedAt: qingyuanAcademicEvidenceTime,
      entranceUri: Uri.parse('https://oa.example.invalid/student-report'),
      summary: SecondClassroomCreditSummary(
        records: const [],
        totals: const SecondClassroomCreditTotals(
          totalEarnedCredit: 0,
          totalRequiredCredit: 0,
        ),
        fetchedAt: qingyuanAcademicEvidenceTime,
        sourceUri: Uri.parse('https://student.example.invalid/report'),
      ),
    );

final StudentReportQueryResult qingyuanAcademicStudentReportStaleResult =
    StudentReportQueryResult(
      status: StudentReportQueryStatus.success,
      message: '正在显示昨日第二课堂缓存',
      detail: '网络恢复后可手动刷新。',
      checkedAt: DateTime(2026, 7, 17, 18),
      entranceUri: Uri.parse('https://oa.example.invalid/student-report'),
      summary: qingyuanAcademicStudentReportContentSummary,
    );

final StudentReportQueryResult qingyuanAcademicStudentReportErrorResult =
    StudentReportQueryResult(
      status: StudentReportQueryStatus.networkError,
      message: '暂时无法读取第二课堂学分',
      detail: '请检查 OA 登录与校园网络后重试。',
      checkedAt: qingyuanAcademicEvidenceTime,
      entranceUri: Uri.parse('https://oa.example.invalid/student-report'),
    );

class QingyuanVisualSportsAttendanceClient implements SportsAttendanceClient {
  const QingyuanVisualSportsAttendanceClient(
    this.result, {
    this.cacheEnabled = true,
    this.pendingFetch,
  });

  final SportsAttendanceQueryResult result;
  final bool cacheEnabled;
  final Completer<SportsAttendanceQueryResult>? pendingFetch;

  @override
  Future<SportsAttendanceQueryResult?>
  readLatestCachedAttendanceSummary() async => cacheEnabled ? result : null;

  @override
  Future<SportsAttendanceQueryResult> fetchAttendanceSummary({
    bool requireCampusNetwork = true,
  }) => pendingFetch?.future ?? Future.value(result);
}

class QingyuanVisualStudentReportClient implements StudentReportClient {
  const QingyuanVisualStudentReportClient(
    this.result, {
    this.cacheEnabled = true,
    this.pendingFetch,
  });

  final StudentReportQueryResult result;
  final bool cacheEnabled;
  final Completer<StudentReportQueryResult>? pendingFetch;

  @override
  Future<StudentReportQueryResult?>
  readLatestCachedSecondClassroomCredits() async =>
      cacheEnabled ? result : null;

  @override
  Future<StudentReportQueryResult> validateLoginStatus() {
    throw UnsupportedError('视觉 fixture 不执行学工登录校验');
  }

  @override
  Future<StudentReportQueryResult> fetchSecondClassroomCredits({
    bool requireCampusNetwork = true,
  }) => pendingFetch?.future ?? Future.value(result);
}

const EmailServerEndpoint qingyuanEmailImapEndpoint = EmailServerEndpoint(
  host: 'imap.example.invalid',
  port: 993,
  isSecure: true,
);

const EmailServerEndpoint qingyuanEmailSmtpEndpoint = EmailServerEndpoint(
  host: 'smtp.example.invalid',
  port: 465,
  isSecure: true,
);

final List<EmailMessageSnapshot> qingyuanEmailMessages = [
  EmailMessageSnapshot(
    id: 'visual:001',
    subject: '选课结果确认通知',
    senderName: '教务处',
    senderAddress: 'academic@example.invalid',
    preview: '本学期选课结果已生效，请核对个人课表。',
    body: '清源同学：\n\n本学期选课结果已生效，请在课程表中核对上课时间与地点。\n\n此邮件为脱敏视觉测试数据。',
    receivedAt: DateTime(2026, 7, 18, 8, 12),
  ),
  EmailMessageSnapshot(
    id: 'visual:002',
    subject: '图书馆借阅到期提醒',
    senderName: '图书馆',
    senderAddress: 'library@example.invalid',
    preview: '您有 2 本图书即将到期，可在线办理续借。',
    body: '您有 2 本图书即将到期，请按时归还或在线续借。',
    receivedAt: DateTime(2026, 7, 17, 16, 42),
  ),
  EmailMessageSnapshot(
    id: 'visual:003',
    subject: '校园网络维护公告',
    senderName: '信息化办公室',
    senderAddress: 'it@example.invalid',
    preview: '周日凌晨将进行短时网络维护。',
    body: '周日 00:30-01:30 校园网络将进行例行维护。',
    receivedAt: DateTime(2026, 7, 16, 9),
  ),
];

final EmailMailboxQueryResult qingyuanEmailContentResult = _emailMailboxResult(
  checkedAt: qingyuanVisualNow,
  messages: qingyuanEmailMessages,
);

final EmailMailboxQueryResult qingyuanHomeEmailResult = _emailMailboxResult(
  checkedAt: DateTime(2026, 7, 18, 8, 42),
  messages: qingyuanEmailMessages.take(2).toList(growable: false),
);

final EmailMailboxQueryResult qingyuanEmailEmptyResult = _emailMailboxResult(
  checkedAt: qingyuanVisualNow,
  messages: const [],
);

final EmailMailboxQueryResult qingyuanEmailStaleResult = _emailMailboxResult(
  checkedAt: DateTime(2026, 7, 17, 9, 30),
  messages: qingyuanEmailMessages,
  message: '已显示本地邮件缓存',
);

final EmailMailboxQueryResult qingyuanEmailErrorResult =
    EmailMailboxQueryResult(
      status: EmailQueryStatus.networkError,
      protocol: EmailProtocol.imap,
      message: '无法读取学校邮箱',
      detail: '请检查邮箱账户、校园网或 VPN；已有本地缓存不会被删除。',
      checkedAt: qingyuanVisualNow,
      endpoint: qingyuanEmailImapEndpoint,
    );

final EmailSendResult qingyuanEmailSendErrorResult = EmailSendResult(
  status: EmailQueryStatus.networkError,
  message: '邮件未发送',
  detail: 'SMTP 服务器连接超时，请保留内容并稍后重试。',
  checkedAt: qingyuanVisualNow,
  endpoint: qingyuanEmailSmtpEndpoint,
  recipientsCount: 1,
);

EmailMailboxQueryResult _emailMailboxResult({
  required DateTime checkedAt,
  required List<EmailMessageSnapshot> messages,
  String message = '邮箱已同步',
}) {
  return EmailMailboxQueryResult(
    status: EmailQueryStatus.success,
    protocol: EmailProtocol.imap,
    message: message,
    detail: '已读取最近邮件。',
    checkedAt: checkedAt,
    endpoint: qingyuanEmailImapEndpoint,
    snapshot: EmailMailboxSnapshot(
      protocol: EmailProtocol.imap,
      account: 'student@example.invalid',
      messages: messages,
      fetchedAt: checkedAt,
      endpoint: qingyuanEmailImapEndpoint,
    ),
  );
}

class QingyuanVisualEmailClient implements EmailMailboxClient {
  QingyuanVisualEmailClient({
    this.cachedResult,
    EmailMailboxQueryResult? fetchResult,
    this.pendingFetch,
    this.pendingSend,
    EmailSendResult? sendResult,
  }) : fetchResult = fetchResult ?? qingyuanEmailContentResult,
       sendResult =
           sendResult ??
           EmailSendResult(
             status: EmailQueryStatus.success,
             message: '邮件已提交发送',
             detail: '已通过 SMTP 提交脱敏测试邮件。',
             checkedAt: qingyuanVisualNow,
             endpoint: qingyuanEmailSmtpEndpoint,
             recipientsCount: 1,
           );

  final EmailMailboxQueryResult? cachedResult;
  final EmailMailboxQueryResult fetchResult;
  final Completer<EmailMailboxQueryResult>? pendingFetch;
  final Completer<EmailSendResult>? pendingSend;
  final EmailSendResult sendResult;

  @override
  Future<EmailMailboxQueryResult?> readLatestCachedMessages(
    EmailProtocol protocol,
  ) async => cachedResult;

  @override
  Future<EmailMailboxQueryResult> fetchMessages({
    required EmailProtocol protocol,
    int messageCount = 10,
  }) {
    return pendingFetch?.future ?? Future.value(fetchResult);
  }

  @override
  Future<EmailLoginValidationResult> validateLogin(
    EmailProtocol protocol,
  ) async {
    return EmailLoginValidationResult(
      status: EmailQueryStatus.success,
      protocol: protocol,
      message: '${protocol.label} 登录校验通过',
      detail: '已完成连通性校验，未修改任何邮件状态。',
      checkedAt: qingyuanVisualNow,
      endpoint: protocol == EmailProtocol.smtp
          ? qingyuanEmailSmtpEndpoint
          : qingyuanEmailImapEndpoint,
    );
  }

  @override
  Future<EmailSendResult> sendMessage(EmailComposeRequest request) {
    return pendingSend?.future ?? Future.value(sendResult);
  }
}
