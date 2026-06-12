/*
 * 教务中心页面测试支撑 — 提供 fake 服务与页面样例结果
 * @Project : SSPU-AllinOne
 * @File : academic_page_test_support.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

part of 'academic_page_test.dart';

class _FakeSportsAttendanceClient implements SportsAttendanceClient {
  _FakeSportsAttendanceClient({required this.result});

  final SportsAttendanceQueryResult result;
  int fetchCount = 0;
  final List<bool> requireCampusNetworkValues = [];

  @override
  Future<SportsAttendanceQueryResult?>
  readLatestCachedAttendanceSummary() async {
    return null;
  }

  @override
  Future<SportsAttendanceQueryResult> fetchAttendanceSummary({
    bool requireCampusNetwork = true,
  }) async {
    fetchCount++;
    requireCampusNetworkValues.add(requireCampusNetwork);
    return result;
  }
}

class _FakeStudentReportClient implements StudentReportClient {
  _FakeStudentReportClient({required this.result});

  final StudentReportQueryResult result;
  int fetchCount = 0;
  final List<bool> requireCampusNetworkValues = [];

  @override
  Future<StudentReportQueryResult?>
  readLatestCachedSecondClassroomCredits() async {
    return null;
  }

  @override
  Future<StudentReportQueryResult> fetchSecondClassroomCredits({
    bool requireCampusNetwork = true,
  }) async {
    fetchCount++;
    requireCampusNetworkValues.add(requireCampusNetwork);
    return result;
  }

  @override
  Future<StudentReportQueryResult> validateLoginStatus() async {
    return result;
  }
}

class _FakeAcademicEamsClient implements AcademicEamsClient {
  _FakeAcademicEamsClient({required this.result, this.examResultResolver});

  final AcademicEamsQueryResult result;
  final AcademicEamsQueryResult Function(
    AcademicTermChoice? term,
    AcademicEamsSemesterOption? semester,
  )?
  examResultResolver;
  int overviewFetchCount = 0;
  int courseTableFetchCount = 0;
  int examFetchCount = 0;
  final List<bool> overviewRequireCampusNetworkValues = [];
  final List<bool> courseTableRequireCampusNetworkValues = [];
  final List<AcademicTermChoice?> examTermValues = [];
  final List<AcademicEamsSemesterOption?> examSemesterValues = [];
  final List<String?> examTypeValues = [];

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedCourseTable() async {
    return null;
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedOverview() async {
    return null;
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedExamSchedule() async {
    return null;
  }

  @override
  Future<AcademicEamsProfile?> readCachedStudentProfile() async {
    return null;
  }

  @override
  Future<AcademicEamsProfile?> refreshStudentProfileIfIncomplete({
    bool forceRefresh = false,
  }) async {
    return result.snapshot?.profile;
  }

  @override
  Future<AcademicEamsQueryResult> fetchCourseTable({
    bool requireCampusNetwork = true,
  }) async {
    courseTableFetchCount++;
    courseTableRequireCampusNetworkValues.add(requireCampusNetwork);
    return result;
  }

  @override
  Future<AcademicEamsQueryResult> fetchOverview({
    bool requireCampusNetwork = true,
  }) async {
    overviewFetchCount++;
    overviewRequireCampusNetworkValues.add(requireCampusNetwork);
    return result;
  }

  @override
  Future<AcademicEamsQueryResult> fetchExamSchedule({
    AcademicTermChoice? term,
    AcademicEamsSemesterOption? semester,
    String? examTypeId,
    bool requireCampusNetwork = true,
  }) async {
    examFetchCount++;
    examTermValues.add(term);
    examSemesterValues.add(semester);
    examTypeValues.add(examTypeId);
    return examResultResolver?.call(term, semester) ?? result;
  }
}

final SportsAttendanceQueryResult _successResult = SportsAttendanceQueryResult(
  status: SportsAttendanceQueryStatus.success,
  message: '体育部考勤查询成功',
  detail: '已读取课外活动考勤总次数与明细记录。',
  checkedAt: DateTime(2026, 4, 30),
  entranceUri: Uri.parse('https://tygl.sspu.edu.cn/sportscore/'),
  finalUri: Uri.parse(
    'https://tygl.sspu.edu.cn/sportscore/stScore.aspx?item=1',
  ),
  summary: SportsAttendanceSummary(
    morningExerciseCount: 2,
    extracurricularActivityCount: 3,
    countAdjustmentCount: -1,
    sportsCorridorCount: 4,
    fetchedAt: DateTime(2026, 4, 30),
    sourceUri: Uri.parse(
      'https://tygl.sspu.edu.cn/sportscore/stScore.aspx?item=1',
    ),
    records: [
      const SportsAttendanceRecord(
        category: SportsAttendanceCategory.morningExercise,
        count: 1,
        occurredAt: '2026-04-01 06:50',
        project: '晨跑',
        location: '操场',
        cells: ['2026-04-01 06:50', '早操', '晨跑', '操场', '1次'],
      ),
      const SportsAttendanceRecord(
        category: SportsAttendanceCategory.sportsCorridor,
        count: 4,
        occurredAt: '2026-04-05',
        project: '长廊学习',
        location: '体育长廊',
        cells: ['2026-04-05', '体育长廊', '长廊学习', '体育长廊', '4次'],
      ),
    ],
  ),
);

final StudentReportQueryResult _creditResult = StudentReportQueryResult(
  status: StudentReportQueryStatus.success,
  message: '第二课堂学分查询成功',
  detail: '已读取第二课堂规则矩阵、总计和已获分数详情。',
  checkedAt: DateTime(2026, 5, 1),
  entranceUri: Uri.parse(
    'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=xgreport',
  ),
  finalUri: Uri.parse(
    'https://xgbb.sspu.edu.cn/sharedc/core/home/secondClassroom.do',
  ),
  summary: SecondClassroomCreditSummary(
    fetchedAt: DateTime(2026, 5, 1),
    sourceUri: Uri.parse(
      'https://xgbb.sspu.edu.cn/sharedc/core/home/secondClassroom.do',
    ),
    records: const [
      SecondClassroomCreditRecord(
        category: '社会实践',
        itemName: '志愿服务',
        credit: 4.65,
        occurredAt: '2026-04-20',
        status: '已认定',
        rawCells: ['社会实践', '志愿服务', '2026-04-20', '已认定', '4.65'],
      ),
      SecondClassroomCreditRecord(
        category: '报告与讲座',
        itemName: '通识讲座',
        credit: 1.5,
        occurredAt: '2026-04-25',
        status: '通过',
        rawCells: ['报告与讲座', '通识讲座', '2026-04-25', '通过', '1.5'],
      ),
      SecondClassroomCreditRecord(
        category: '创新创业活动',
        itemName: '创新训练项目',
        credit: 2,
        occurredAt: '2026-04-25',
        status: '通过',
        rawCells: ['创新创业活动', '创新训练项目', '2026-04-25', '通过', '2'],
      ),
    ],
    rules: const [
      SecondClassroomCreditRuleRow(
        category: '社会实践',
        item: '志愿服务',
        level: '院级',
        participation: '20小时',
        credit: 1,
        earnedCredit: 4.65,
        requiredCredit: 2,
        passStatus: '通过',
      ),
      SecondClassroomCreditRuleRow(
        category: '报告与讲座',
        item: '通识讲座',
        level: '',
        participation: '1次',
        credit: 0.25,
        earnedCredit: 1.5,
        requiredCredit: 2,
        passStatus: '未通过',
      ),
      SecondClassroomCreditRuleRow(
        category: '校园文化活动',
        item: '专业类竞赛',
        level: '省部级及以上',
        participation: '获奖',
        credit: 0.5,
        earnedCredit: 0.5,
        requiredCredit: 2,
        passStatus: '通过',
      ),
      SecondClassroomCreditRuleRow(
        category: '校园文化活动',
        item: '文化艺术、体育健身类社团',
        level: '校级',
        participation: '优秀社员',
        credit: 0.5,
        earnedCredit: 0.5,
        requiredCredit: 2,
        passStatus: '通过',
      ),
      SecondClassroomCreditRuleRow(
        category: '创新创业活动',
        item: '创新训练',
        level: '校级',
        participation: '立项',
        credit: 2,
        earnedCredit: 2,
        requiredCredit: 0,
        passStatus: '通过',
      ),
    ],
    totals: const SecondClassroomCreditTotals(
      totalCredit: 61.9,
      totalEarnedCredit: 10.55,
      totalRequiredCredit: 8,
      passStatus: '未通过',
    ),
    detailRecords: const [
      SecondClassroomCreditDetailRecord(
        name: '志愿服务',
        category: '社会实践',
        item: '志愿服务',
        level: '院级',
        participation: '20小时',
        earnedCredit: 4.65,
      ),
      SecondClassroomCreditDetailRecord(
        name: '通识讲座',
        category: '报告与讲座',
        item: '通识讲座',
        level: '',
        participation: '1次',
        earnedCredit: 1.5,
      ),
      SecondClassroomCreditDetailRecord(
        name: '专业类竞赛',
        category: '校园文化活动',
        item: '专业类竞赛',
        level: '省部级及以上',
        participation: '获奖',
        earnedCredit: 0.5,
      ),
      SecondClassroomCreditDetailRecord(
        name: '优秀社员',
        category: '校园文化活动',
        item: '文化艺术、体育健身类社团',
        level: '校级',
        participation: '优秀社员',
        earnedCredit: 0.5,
      ),
      SecondClassroomCreditDetailRecord(
        name: '创新训练项目',
        category: '创新创业活动',
        item: '创新训练',
        level: '校级',
        participation: '立项',
        earnedCredit: 2,
      ),
    ],
  ),
);

final AcademicEamsQueryResult _academicEamsResult = AcademicEamsQueryResult(
  status: AcademicEamsQueryStatus.success,
  message: '本专科教务只读查询成功',
  detail: '已读取课表、成绩、考试和培养计划。',
  checkedAt: DateTime(2026, 5, 2),
  entranceUri: Uri.parse(
    'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
  ),
  finalUri: Uri.parse('https://jx.sspu.edu.cn/eams/home!index.action'),
  snapshot: AcademicEamsSnapshot(
    fetchedAt: DateTime(2026, 5, 2),
    sourceUri: Uri.parse('https://jx.sspu.edu.cn/eams/home!index.action'),
    warnings: const [],
    hasCourseOfferingEntry: true,
    hasFreeClassroomEntry: true,
    profile: const AcademicEamsProfile(
      name: '张三',
      studentId: '20260001',
      department: '计算机与信息工程学院',
      major: '软件工程',
      className: '软件 241',
      gender: '男',
      studyLength: '4 年',
      educationLevel: '本科',
      rawFields: {'姓名': '张三', '学号': '20260001'},
    ),
    courseTable: AcademicCourseTableSnapshot(
      termName: '2025-2026 第2学期',
      entries: const [
        AcademicCourseTableEntry(
          courseName: '高等数学',
          weekday: 1,
          startUnit: 1,
          endUnit: 2,
          timeText: '周一 第1-2节',
          teacher: '张老师',
          location: '综合楼 A101',
          weekDescription: '1-16周',
          rawText: '高等数学 张老师 综合楼 A101 1-16周',
        ),
      ],
      fetchedAt: DateTime(2026, 5, 2),
      sourceUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/courseTableForStd.action',
      ),
    ),
    grades: AcademicGradeSnapshot(
      currentTermRecords: const [
        AcademicGradeRecord(
          courseName: '高等数学',
          scoreText: '92',
          rawCells: ['高等数学', '92', '3'],
          credit: 3,
        ),
      ],
      historyRecords: const [],
      fetchedAt: DateTime(2026, 5, 2),
      sourceUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/teach/grade/course/person.action',
      ),
    ),
    programPlan: AcademicProgramPlanSnapshot(
      courses: const [
        AcademicProgramPlanCourse(
          courseName: '高等数学',
          rawCells: ['公共基础', '高等数学', '3'],
          credit: 3,
          moduleName: '公共基础',
        ),
      ],
      fetchedAt: DateTime(2026, 5, 2),
      sourceUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/teach/program/student/myPlan.action',
      ),
    ),
    programCompletion: const AcademicProgramCompletionSnapshot(
      completedCourseCount: 1,
      pendingCourseCount: 0,
      completedCredits: 3,
      pendingCredits: 0,
      moduleProgress: [
        AcademicProgramModuleProgress(
          moduleName: '公共基础',
          totalCourseCount: 1,
          completedCourseCount: 1,
          pendingCourseCount: 0,
          totalCredits: 3,
          completedCredits: 3,
          pendingCredits: 0,
        ),
      ],
    ),
    exams: AcademicExamSnapshot(
      records: const [
        AcademicExamRecord(
          courseName: '高等数学',
          rawCells: ['高等数学', '2026-06-20 08:30', '综合楼 A201', '18'],
          examTime: '2026-06-20 08:30',
          location: '综合楼 A201',
          seatNumber: '18',
        ),
      ],
      fetchedAt: DateTime(2026, 5, 2),
      sourceUri: Uri.parse('https://jx.sspu.edu.cn/eams/stdExamTable.action'),
    ),
  ),
);

final AcademicEamsQueryResult _academicExamResult = AcademicEamsQueryResult(
  status: AcademicEamsQueryStatus.success,
  message: '考试安排读取成功',
  detail: '已读取所选学期考试安排。',
  checkedAt: DateTime(2026, 6, 11, 10, 0),
  entranceUri: Uri.parse(
    'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
  ),
  finalUri: Uri.parse(
    'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action?semester.id=1042&examType.id=1',
  ),
  snapshot: AcademicEamsSnapshot(
    fetchedAt: DateTime(2026, 6, 11, 10, 0),
    sourceUri: Uri.parse(
      'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action',
    ),
    warnings: const [],
    hasCourseOfferingEntry: true,
    hasFreeClassroomEntry: true,
    exams: AcademicExamSnapshot(
      selectedSemester: AcademicEamsSemesterOption.fromEamsFields(
        id: '1042',
        schoolYear: '2025-2026',
        termCode: '2',
      ),
      semesterOptions: [
        AcademicEamsSemesterOption.fromEamsFields(
          id: '1041',
          schoolYear: '2025-2026',
          termCode: '1',
        ),
        AcademicEamsSemesterOption.fromEamsFields(
          id: '1042',
          schoolYear: '2025-2026',
          termCode: '2',
        ),
        AcademicEamsSemesterOption.fromEamsFields(
          id: '1043',
          schoolYear: '2025-2026',
          termCode: '3',
        ),
      ],
      records: const [
        AcademicExamRecord(
          examType: '期末考试',
          courseSequence: '2291',
          courseName: '高等数学D2',
          examDate: '[考试情况尚未发布]',
          otherExplanation: '第17周期末考试',
          rawCells: [
            '期末考试',
            '2291',
            '高等数学D2',
            '[考试情况尚未发布]',
            '',
            '',
            '',
            '第17周期末考试',
          ],
        ),
        AcademicExamRecord(
          examType: '期末考试',
          courseSequence: '2564',
          courseName: '大学生心理健康教育',
          examDate: '2026-06-17',
          examArrange: '第16周 星期三 13:00-14:30',
          examLocation: '4201',
          examSituation: '正常',
          otherExplanation: '心理健康期末考试',
          rawCells: [
            '期末考试',
            '2564',
            '大学生心理健康教育',
            '2026-06-17',
            '第16周 星期三 13:00-14:30',
            '4201',
            '正常',
            '心理健康期末考试',
          ],
        ),
        AcademicExamRecord(
          examType: '期末考试',
          courseSequence: '2645',
          courseName: '通用学术英语B',
          examDate: '[考试情况尚未发布]',
          otherExplanation: '第17周期末考试',
          rawCells: [
            '期末考试',
            '2645',
            '通用学术英语B',
            '[考试情况尚未发布]',
            '',
            '',
            '',
            '第17周期末考试',
          ],
        ),
      ],
      fetchedAt: DateTime(2026, 6, 11, 10, 0),
      sourceUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action',
      ),
    ),
  ),
);

/// 明显过期的考试缓存（2020-2021 秋），用于校验缓存学期与全局默认学期不一致时不展示。
final AcademicEamsQueryResult _staleExamCacheResult = AcademicEamsQueryResult(
  status: AcademicEamsQueryStatus.success,
  message: '考试安排读取成功',
  detail: '已读取所选学期考试安排。',
  checkedAt: DateTime(2020, 9, 1, 10, 0),
  entranceUri: Uri.parse(
    'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
  ),
  finalUri: Uri.parse(
    'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action?semester.id=801&examType.id=1',
  ),
  snapshot: AcademicEamsSnapshot(
    fetchedAt: DateTime(2020, 9, 1, 10, 0),
    sourceUri: Uri.parse(
      'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action',
    ),
    warnings: const [],
    hasCourseOfferingEntry: true,
    hasFreeClassroomEntry: true,
    exams: AcademicExamSnapshot(
      selectedSemester: AcademicEamsSemesterOption.fromEamsFields(
        id: '801',
        schoolYear: '2020-2021',
        termCode: '1',
      ),
      semesterOptions: [
        AcademicEamsSemesterOption.fromEamsFields(
          id: '801',
          schoolYear: '2020-2021',
          termCode: '1',
        ),
      ],
      records: const [
        AcademicExamRecord(
          examType: '期末考试',
          courseSequence: 'OLD100',
          courseName: '陈旧学期课程',
          examDate: '2021-01-05',
          examArrange: '闭卷',
          examLocation: '老楼 101',
          examSituation: '正常',
          rawCells: [
            '期末考试',
            'OLD100',
            '陈旧学期课程',
            '2021-01-05',
            '闭卷',
            '老楼 101',
            '正常',
            '',
          ],
        ),
      ],
      fetchedAt: DateTime(2020, 9, 1, 10, 0),
      sourceUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action',
      ),
    ),
  ),
);

AcademicEamsQueryResult _academicExamResultForSeason(
  AcademicTermSeason season,
) {
  if (season == AcademicTermSeason.spring) return _academicExamResult;
  if (season == AcademicTermSeason.summer) {
    final summerSemester = AcademicEamsSemesterOption.fromEamsFields(
      id: '1043',
      schoolYear: '2025-2026',
      termCode: '3',
    );
    return AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.success,
      message: '当前学期暂无考试安排',
      detail: '已读取所选学期考试安排，未发现可展示的考试信息。',
      checkedAt: DateTime(2026, 6, 11, 10, 8),
      entranceUri: Uri.parse(
        'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
      ),
      finalUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action?semester.id=1043&examType.id=1',
      ),
      snapshot: AcademicEamsSnapshot(
        fetchedAt: DateTime(2026, 6, 11, 10, 8),
        sourceUri: Uri.parse(
          'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action',
        ),
        warnings: const [],
        hasCourseOfferingEntry: true,
        hasFreeClassroomEntry: true,
        exams: AcademicExamSnapshot(
          selectedSemester: summerSemester,
          semesterOptions: [summerSemester],
          records: const [],
          fetchedAt: DateTime(2026, 6, 11, 10, 8),
          sourceUri: Uri.parse(
            'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action',
          ),
        ),
      ),
    );
  }
  final fallSemester = AcademicEamsSemesterOption.fromEamsFields(
    id: '1041',
    schoolYear: '2025-2026',
    termCode: '1',
  );
  return AcademicEamsQueryResult(
    status: AcademicEamsQueryStatus.success,
    message: '考试安排读取成功',
    detail: '已读取所选学期考试安排。',
    checkedAt: DateTime(2026, 6, 11, 10, 5),
    entranceUri: Uri.parse(
      'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
    ),
    finalUri: Uri.parse(
      'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action?semester.id=1041&examType.id=1',
    ),
    snapshot: AcademicEamsSnapshot(
      fetchedAt: DateTime(2026, 6, 11, 10, 5),
      sourceUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action',
      ),
      warnings: const [],
      hasCourseOfferingEntry: true,
      hasFreeClassroomEntry: true,
      exams: AcademicExamSnapshot(
        selectedSemester: fallSemester,
        semesterOptions: [
          fallSemester,
          AcademicEamsSemesterOption.fromEamsFields(
            id: '1042',
            schoolYear: '2025-2026',
            termCode: '2',
          ),
        ],
        records: const [
          AcademicExamRecord(
            examType: '期末考试',
            courseSequence: 'CS100',
            courseName: '程序设计基础',
            examDate: '2026-01-10',
            examArrange: '闭卷',
            examLocation: '综合楼 B101',
            examSituation: '正常',
            rawCells: [
              '期末考试',
              'CS100',
              '程序设计基础',
              '2026-01-10',
              '闭卷',
              '综合楼 B101',
              '正常',
              '',
            ],
          ),
          AcademicExamRecord(
            examType: '平时考试',
            courseSequence: 'PHY100',
            courseName: '大学物理',
            examDate: '2026-01-12',
            examArrange: '开卷',
            examLocation: '综合楼 B102',
            examSituation: '正常',
            rawCells: [
              '平时考试',
              'PHY100',
              '大学物理',
              '2026-01-12',
              '开卷',
              '综合楼 B102',
              '正常',
              '',
            ],
          ),
        ],
        fetchedAt: DateTime(2026, 6, 11, 10, 5),
        sourceUri: Uri.parse(
          'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action',
        ),
      ),
    ),
  );
}
