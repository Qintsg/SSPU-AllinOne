/*
 * 本专科教务服务测试支撑 — 提供 fake 网关、会话快照与页面样例
 * @Project : SSPU-AllinOne
 * @File : academic_eams_service_test_support.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

import 'dart:async';

import 'package:sspu_allinone/models/academic_login_validation.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
import 'package:sspu_allinone/services/campus_network_status_service.dart';

AcademicEamsService buildAcademicEamsServiceForTest({
  required FakeAcademicEamsGateway gateway,
  required bool campusReachable,
  AcademicEamsOaLoginRefresher? refreshOaLogin,
}) {
  return AcademicEamsService(
    gateway: gateway,
    refreshOaLogin: refreshOaLogin,
    campusNetworkStatusService: CampusNetworkStatusService(
      probeUri: Uri.parse('https://jx.sspu.edu.cn/'),
      probe: (probeUri, timeout) async => CampusNetworkProbeResult(
        reachable: campusReachable,
        detail: campusReachable ? '校园网可达' : '校园网不可达',
        statusCode: campusReachable ? 200 : null,
      ),
    ),
  );
}

class FakeAcademicEamsGateway implements AcademicEamsGateway {
  FakeAcademicEamsGateway({
    this.requireAuthFirst = false,
    this.failFreeClassroomMenuOnce = false,
    this.studentProfileSnapshot,
    this.disableNumberedStudentProfileMenu = false,
    this.failSemesterCalendar = false,
    this.springOnlySemesterCalendar = false,
    this.chineseNamedSemesterCalendar = false,
    this.placeholderOnlyExamRow = false,
    this.includeUndatedExamRows = false,
    this.useShortExamCourseHeader = false,
  });

  final bool requireAuthFirst;
  final bool failFreeClassroomMenuOnce;
  final AcademicEamsHttpSnapshot? studentProfileSnapshot;
  final bool disableNumberedStudentProfileMenu;
  final bool failSemesterCalendar;
  final bool springOnlySemesterCalendar;
  final bool chineseNamedSemesterCalendar;
  final bool placeholderOnlyExamRow;
  final bool includeUndatedExamRows;
  final bool useShortExamCourseHeader;
  final List<Map<String, String>> resetCookieHeaders = [];
  final List<Uri> requestedPageUris = [];
  int openCount = 0;
  String? lastSubmittedMethod;
  Map<String, String>? lastSubmittedFields;
  final List<Map<String, String>> submittedFieldsHistory = [];
  bool _hasFailedFreeClassroomMenu = false;

  @override
  Future<void> resetSession(Map<String, String> cookieHeadersByHost) async {
    resetCookieHeaders.add(cookieHeadersByHost);
  }

  @override
  Future<AcademicEamsHttpSnapshot> openEntryPage(
    Uri entranceUri,
    Duration timeout,
  ) async {
    openCount++;
    if (requireAuthFirst && openCount == 1) return academicEamsCasSnapshot;
    return academicEamsHomeSnapshot;
  }

  @override
  Future<AcademicEamsHttpSnapshot> fetchPage(
    Uri pageUri,
    Duration timeout,
  ) async {
    requestedPageUris.add(pageUri);
    final path = pageUri.path;
    if (path.contains('home!submenus.action') &&
        (pageUri.queryParameters['menu.id'] == null ||
            pageUri.queryParameters['menu.id'] == '')) {
      return academicEamsRootSubmenuSnapshot;
    }
    if (path.contains('home!submenus.action') &&
        pageUri.queryParameters['menu.id'] == '5') {
      if (failFreeClassroomMenuOnce && !_hasFailedFreeClassroomMenu) {
        _hasFailedFreeClassroomMenu = true;
        throw TimeoutException('menu timeout');
      }
      if (disableNumberedStudentProfileMenu) {
        return academicEamsSubmenuWithoutStudentProfileSnapshot;
      }
      return academicEamsSubmenuSnapshot;
    }
    if (path.contains('home!submenus.action')) {
      return academicEamsEmptySubmenuSnapshot;
    }
    if (path.contains('home!index.action')) return academicEamsHomeSnapshot;
    if (path.contains('studentDetail.action') || path.contains('std.action')) {
      return studentProfileSnapshot ?? academicEamsStudentProfileSnapshot;
    }
    if (path.contains('courseTableForStd.action')) {
      return academicEamsCourseTableSnapshot;
    }
    if (path.contains('/teach/grade/course/person.action') &&
        !path.contains('historyCourseGrade')) {
      return academicEamsCurrentGradeSnapshot;
    }
    if (path.contains('historyCourseGrade')) {
      return academicEamsHistoryGradeSnapshot;
    }
    if (path.contains('/teach/program/student/myPlan.action')) {
      return academicEamsProgramPlanSnapshot;
    }
    if (path.contains('stdExamTable!examTable.action')) {
      final semesterId = pageUri.queryParameters['semester.id'] ?? '';
      final examTypeId = pageUri.queryParameters['examType.id'] ?? '';
      return academicEamsExamResultSnapshot(
        semesterId: semesterId,
        examTypeId: examTypeId,
        includeUndatedExamRows: includeUndatedExamRows,
        placeholderOnlyExamRow: placeholderOnlyExamRow,
        useShortCourseHeader: useShortExamCourseHeader,
      );
    }
    if (path.contains('stdExamTable.action')) {
      return academicEamsExamShellSnapshot;
    }
    if (path.contains('publicSearch.action')) {
      return academicEamsCourseOfferingEntrySnapshot;
    }
    if (path.contains('freeClassroom.action')) {
      return academicEamsFreeClassroomEntrySnapshot;
    }
    return AcademicEamsHttpSnapshot(
      finalUri: pageUri,
      statusCode: 404,
      body: 'not found',
    );
  }

  @override
  Future<AcademicEamsHttpSnapshot> submitForm({
    required Uri formUri,
    required String method,
    required Map<String, String> fields,
    required Duration timeout,
  }) async {
    lastSubmittedMethod = method;
    lastSubmittedFields = fields;
    submittedFieldsHistory.add(Map<String, String>.from(fields));
    if (formUri.path.contains('dataQuery.action') &&
        fields['dataType'] == 'semesterCalendar') {
      if (failSemesterCalendar) throw TimeoutException('semester timeout');
      if (chineseNamedSemesterCalendar) {
        return academicEamsChineseNamedSemesterCalendarSnapshot;
      }
      if (springOnlySemesterCalendar) {
        return academicEamsSpringOnlySemesterCalendarSnapshot;
      }
      return academicEamsSemesterCalendarSnapshot;
    }
    if (formUri.path.contains('publicSearch!search.action')) {
      return academicEamsCourseOfferingResultSnapshot;
    }
    if (formUri.path.contains('freeClassroom!search.action')) {
      return academicEamsFreeClassroomResultSnapshot;
    }
    return AcademicEamsHttpSnapshot(
      finalUri: formUri,
      statusCode: 404,
      body: 'not found',
    );
  }
}

final AcademicLoginSessionSnapshot academicEamsSessionSnapshot =
    AcademicLoginSessionSnapshot(
      cookieHeadersByHost: const {
        'oa.sspu.edu.cn': 'OA=fake-oa-session',
        'id.sspu.edu.cn': 'CASTGC=fake-cas-session',
      },
      authenticatedAt: DateTime(2026, 5, 2),
      entranceUri: academicEamsOaEntranceUri,
      finalUri: academicEamsOaEntranceUri,
    );

final Uri academicEamsOaEntranceUri = Uri.parse(
  'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
);

final AcademicEamsHttpSnapshot academicEamsCasSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse('https://id.sspu.edu.cn/cas/login'),
      statusCode: 200,
      body: '<html><title>统一身份认证</title></html>',
    );

final AcademicEamsHttpSnapshot academicEamsHomeSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: AcademicEamsService.defaultHomeUri,
      statusCode: 200,
      body: '''
<html>
  <head><title>EAMS 3.0.0</title></head>
  <body>
    <table>
      <tr><td>姓名</td><td>张三</td></tr>
      <tr><td>学号</td><td>20260001</td></tr>
      <tr><td>院系</td><td>计算机与信息工程学院</td></tr>
      <tr><td>专业</td><td>软件工程</td></tr>
      <tr><td>班级</td><td>软件 241</td></tr>
    </table>
  </body>
</html>
''',
    );

final AcademicEamsHttpSnapshot academicEamsEmptySubmenuSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse('https://jx.sspu.edu.cn/eams/home!submenus.action'),
      statusCode: 200,
      body: '<html><body></body></html>',
    );

final AcademicEamsHttpSnapshot academicEamsRootSubmenuSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/home!submenus.action?menu.id=',
      ),
      statusCode: 200,
      body: '''
<html>
  <body>
    <ul class="menu">
      <li class="expand">
        <a class="first_menu" href="#">学籍信息</a>
        <ul class="scroll_box">
          <li>
            <a class="p_1" href="/eams/studentDetail.action"
               onclick="return bg.Go(this,'main',true)">个人信息</a>
          </li>
        </ul>
      </li>
    </ul>
  </body>
</html>
''',
    );

final AcademicEamsHttpSnapshot academicEamsSubmenuSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/home!submenus.action?menu.id=5',
      ),
      statusCode: 200,
      body: '''
<html>
  <body>
    <a href="/eams/freeClassroom.action">空闲教室查询</a>
    <a href="/eams/std.action">学籍信息-个人信息</a>
  </body>
</html>
''',
    );

final AcademicEamsHttpSnapshot
academicEamsSubmenuWithoutStudentProfileSnapshot = AcademicEamsHttpSnapshot(
  finalUri: Uri.parse(
    'https://jx.sspu.edu.cn/eams/home!submenus.action?menu.id=5',
  ),
  statusCode: 200,
  body: '''
<html>
  <body>
    <a href="/eams/freeClassroom.action">空闲教室查询</a>
  </body>
</html>
''',
);

final AcademicEamsHttpSnapshot academicEamsStudentProfileSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse('https://jx.sspu.edu.cn/eams/studentDetail.action'),
      statusCode: 200,
      body: '''
<html>
  <body>
    <h2>学籍信息</h2>
    <table>
      <tr>
        <th>学号</th><th>姓名</th><th>性别</th><th>院系</th>
        <th>专业</th><th>行政班级</th><th>学制</th><th>学历层次</th>
      </tr>
      <tr>
        <td>20260001</td><td>张三</td><td>男</td><td>计算机与信息工程学院</td>
        <td>软件工程</td><td>软件 241</td><td>4 年</td><td>本科</td>
      </tr>
    </table>
  </body>
</html>
''',
    );

final AcademicEamsHttpSnapshot academicEamsCourseTableSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/courseTableForStd.action',
      ),
      statusCode: 200,
      body: '''
<html>
  <body>
    <div>2025-2026 第2学期</div>
    <table>
      <tr>
        <th>节次</th><th>周一</th><th>周二</th><th>周三</th>
        <th>周四</th><th>周五</th><th>周六</th><th>周日</th>
      </tr>
      <tr>
        <td>1</td>
        <td rowspan="2">高等数学<br/>张老师<br/>综合楼 A101<br/>1-16周</td>
        <td></td><td></td><td></td><td></td><td></td><td></td>
      </tr>
      <tr>
        <td>2</td>
        <td></td><td></td><td></td><td></td><td></td><td></td>
      </tr>
    </table>
  </body>
</html>
''',
    );

final AcademicEamsHttpSnapshot academicEamsCurrentGradeSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/teach/grade/course/person.action',
      ),
      statusCode: 200,
      body: '''
<html>
  <body>
    <table>
      <tr><th>课程名称</th><th>总评成绩</th><th>学分</th><th>学年学期</th></tr>
      <tr><td>高等数学</td><td>92</td><td>3</td><td>2025-2026-2</td></tr>
    </table>
  </body>
</html>
''',
    );

final AcademicEamsHttpSnapshot
academicEamsHistoryGradeSnapshot = AcademicEamsHttpSnapshot(
  finalUri: Uri.parse(
    'https://jx.sspu.edu.cn/eams/teach/grade/course/person!historyCourseGrade.action?projectType=MAJOR',
  ),
  statusCode: 200,
  body: '''
<html>
  <body>
    <table>
      <tr><th>课程名称</th><th>成绩</th><th>学分</th><th>学年学期</th></tr>
      <tr><td>程序设计基础</td><td>85</td><td>4</td><td>2025-2026-1</td></tr>
    </table>
  </body>
</html>
''',
);

final AcademicEamsHttpSnapshot academicEamsProgramPlanSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/teach/program/student/myPlan.action',
      ),
      statusCode: 200,
      body: '''
<html>
  <body>
    <h2>培养计划</h2>
    <table>
      <tr><th>模块</th><th>课程代码</th><th>课程名称</th><th>学分</th><th>建议学期</th></tr>
      <tr><td>公共基础</td><td>MATH101</td><td>高等数学</td><td>3</td><td>2025-2026-2</td></tr>
      <tr><td>专业基础</td><td>CS100</td><td>程序设计基础</td><td>4</td><td>2025-2026-1</td></tr>
    </table>
  </body>
</html>
''',
    );

final AcademicEamsHttpSnapshot academicEamsExamShellSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse('https://jx.sspu.edu.cn/eams/stdExamTable.action'),
      statusCode: 200,
      body: '''
<html>
  <body>
    <form name="semesterForm">
      <input type="hidden" id="semesterBar" name="semester.id" value="1042" />
      <select name="examType.id">
        <option value="1" selected>期末考试</option>
        <option value="2">期中考试</option>
        <option value="3">补考</option>
        <option value="4">缓考</option>
        <option value="5">平时考试</option>
      </select>
    </form>
    <script>
      var semesterBar = {tagId:"semesterBar", dataType:"semesterCalendar", value:"1042"};
      function getExams() {
        var actions = "stdExamTable!examTable.action?semester.id=1042&examType.id=1";
        bg.Go(actions, "examTableFrame");
      }
    </script>
  </body>
</html>
''',
    );

final AcademicEamsHttpSnapshot academicEamsSemesterCalendarSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse('https://jx.sspu.edu.cn/eams/dataQuery.action'),
      statusCode: 200,
      body: '''
({semesters:{y0:[
  {id:1041,schoolYear:"2025-2026",name:"1"},
  {id:1042,schoolYear:"2025-2026",name:"2"},
  {id:1043,schoolYear:"2025-2026",name:"3"}
]}})
''',
    );

final AcademicEamsHttpSnapshot academicEamsSpringOnlySemesterCalendarSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse('https://jx.sspu.edu.cn/eams/dataQuery.action'),
      statusCode: 200,
      body: '''
({semesters:{y0:[
  {id:1042,schoolYear:"2025-2026",name:"2"}
]}})
''',
    );

final AcademicEamsHttpSnapshot
academicEamsChineseNamedSemesterCalendarSnapshot = AcademicEamsHttpSnapshot(
  finalUri: Uri.parse('https://jx.sspu.edu.cn/eams/dataQuery.action'),
  statusCode: 200,
  body: '''
({semesters:{y0:[
  {id:1062,schoolYear:"2025-2026",name:"夏季"},
  {id:1042,schoolYear:"2025-2026",name:"春季"},
  {id:1022,schoolYear:"2025-2026",name:"秋季"},
  {id:1082,schoolYear:"2026-2027",name:"秋季"}
]}})
''',
);

AcademicEamsHttpSnapshot academicEamsExamResultSnapshot({
  required String semesterId,
  required String examTypeId,
  bool includeUndatedExamRows = false,
  bool placeholderOnlyExamRow = false,
  bool useShortCourseHeader = false,
}) {
  final row =
      placeholderOnlyExamRow && semesterId == '1042' && examTypeId == '5'
      ? '<tr><td>PLACEHOLDER</td><td>只含占位信息课程</td><td>-</td><td>-</td><td></td><td>-</td><td>暂无信息</td></tr>'
      : includeUndatedExamRows && semesterId == '1042' && examTypeId == '1'
      ? '''
<tr><td>2291</td><td>高等数学D2</td><td colspan="4">[考试情况尚未发布]</td><td>第17周期末考试</td></tr>
<tr><td>2564</td><td>大学生心理健康教育</td><td>2026-06-17</td><td>第16周 星期三 13:00-14:30</td><td>4201</td><td>正常</td><td>心理健康期末考试</td></tr>
<tr><td>2645</td><td>通用学术英语B</td><td colspan="4">[考试情况尚未发布]</td><td>第17周期末考试</td></tr>
'''
      : semesterId == '1041' && examTypeId == '1'
      ? '<tr><td>CS100</td><td>程序设计基础</td><td>2026-01-10</td><td>闭卷</td><td>综合楼 B101</td><td>正常</td><td></td></tr>'
      : semesterId == '1042' && examTypeId == '1'
      ? '<tr><td>MATH101</td><td>高等数学</td><td>2026-06-20</td><td>闭卷</td><td>综合楼 A201</td><td>正常</td><td>带学生证</td></tr>'
      : semesterId == '1042' && examTypeId == '2'
      ? '<tr><td>ENG201</td><td>大学英语</td><td></td><td>随堂</td><td>教学楼 C201</td><td>正常</td><td></td></tr>'
      : semesterId == '1042' && examTypeId == '5'
      ? '<tr><td>PSY101</td><td>大学生心理健康教育</td><td>-</td><td>课程论文</td><td></td><td>待发布</td><td>暂无信息</td></tr>'
      : '';
  final courseHeader = useShortCourseHeader ? '课程' : '课程名称';
  return AcademicEamsHttpSnapshot(
    finalUri: Uri.parse(
      'https://jx.sspu.edu.cn/eams/stdExamTable!examTable.action?semester.id=$semesterId&examType.id=$examTypeId',
    ),
    statusCode: 200,
    body:
        '''
<html>
  <body>
    <table>
      <tr>
        <th>课程序号</th><th>$courseHeader</th><th>考试日期</th><th>考试安排</th>
        <th>考试地点</th><th>考试情况</th><th>其它说明</th>
      </tr>
      $row
    </table>
  </body>
</html>
''',
  );
}

final AcademicEamsHttpSnapshot academicEamsExamSnapshot =
    academicEamsExamResultSnapshot(semesterId: '1042', examTypeId: '1');

final AcademicEamsHttpSnapshot academicEamsCourseOfferingEntrySnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse('https://jx.sspu.edu.cn/eams/publicSearch.action'),
      statusCode: 200,
      body: '''
<html>
  <body>
    <form action="publicSearch!search.action" method="get">
      <input type="hidden" name="pageNo" value="1" />
      <select name="semester">
        <option value="2025-2026-2">2025-2026-2</option>
        <option value="">全部学期</option>
      </select>
      <input type="text" name="courseName" value="" />
      <input type="text" name="teacherName" value="" />
      <input type="text" name="courseCode" value="" />
    </form>
    <table>
      <tr><th>课程名称</th><th>教师</th></tr>
      <tr><td>软件工程导论</td><td>王老师</td></tr>
    </table>
  </body>
</html>
''',
    );

final AcademicEamsHttpSnapshot academicEamsCourseOfferingResultSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/publicSearch!search.action',
      ),
      statusCode: 200,
      body: '''
<html>
  <body>
    <table>
      <tr><th>课程代码</th><th>课程名称</th><th>教师</th><th>学分</th><th>容量</th><th>地点</th><th>上课时间</th></tr>
      <tr><td>MATH101</td><td>高等数学</td><td>张老师</td><td>3</td><td>60</td><td>综合楼 A101</td><td>周一 1-2 节</td></tr>
    </table>
  </body>
</html>
''',
    );

final AcademicEamsHttpSnapshot academicEamsFreeClassroomEntrySnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse('https://jx.sspu.edu.cn/eams/freeClassroom.action'),
      statusCode: 200,
      body: '''
<html>
  <body>
    <form action="freeClassroom!search.action" method="post">
      <select name="campus">
        <option value="JH">金海</option>
        <option value="">全部校区</option>
      </select>
      <input type="text" name="building" value="" />
      <input type="text" name="date" value="" />
      <input type="text" name="startUnit" value="1" />
      <input type="text" name="endUnit" value="2" />
    </form>
  </body>
</html>
''',
    );

final AcademicEamsHttpSnapshot academicEamsFreeClassroomResultSnapshot =
    AcademicEamsHttpSnapshot(
      finalUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/freeClassroom!search.action',
      ),
      statusCode: 200,
      body: '''
<html>
  <body>
    <table>
      <tr><th>校区</th><th>楼宇</th><th>教室</th><th>容量</th><th>日期</th><th>节次</th></tr>
      <tr><td>金海</td><td>综合楼</td><td>综合楼 A301</td><td>80</td><td>2026-05-02</td><td>1-2</td></tr>
    </table>
  </body>
</html>
''',
    );
