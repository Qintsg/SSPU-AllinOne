/*
 * 学工报表服务测试支撑 — 提供 fake 网关与页面样例
 * @Project : SSPU-all-in-one
 * @File : student_report_service_test_support.dart
 * @Author : Qintsg
 * @Date : 2026-05-09
 */

part of 'student_report_service_test.dart';

StudentReportService _buildService({
  required _FakeStudentReportGateway gateway,
  required bool campusReachable,
  StudentReportOaLoginRefresher? refreshOaLogin,
}) {
  return StudentReportService(
    gateway: gateway,
    refreshOaLogin: refreshOaLogin,
    campusNetworkStatusService: CampusNetworkStatusService(
      probeUri: Uri.parse('https://xgbb.sspu.edu.cn/'),
      probe: (probeUri, timeout) async => CampusNetworkProbeResult(
        reachable: campusReachable,
        detail: campusReachable ? '校园网可达' : '校园网不可达',
        statusCode: campusReachable ? 200 : null,
      ),
    ),
  );
}

class _FakeStudentReportGateway implements StudentReportGateway {
  _FakeStudentReportGateway({
    this.requireAuthFirst = false,
    this.requireAuthReportEntryFirst = false,
    this.requireAuthCreditFirst = false,
    StudentReportHttpSnapshot? entryPage,
    StudentReportHttpSnapshot? creditPage,
    StudentReportHttpSnapshot? reportEntryPage,
    this.timeoutReportEntry = false,
  }) : entryPage = entryPage ?? _snapshot(_homeHtml),
       creditPage = creditPage ?? _snapshot(_creditHtml),
       reportEntryPage = reportEntryPage ?? _snapshot(_homeHtml);

  final bool requireAuthFirst;
  final bool requireAuthReportEntryFirst;
  final bool requireAuthCreditFirst;
  final bool timeoutReportEntry;
  final StudentReportHttpSnapshot entryPage;
  final StudentReportHttpSnapshot creditPage;
  final StudentReportHttpSnapshot reportEntryPage;
  final List<Map<String, String>> resetCookieHeaders = [];
  final List<Uri> fetchedUris = [];
  int openCount = 0;
  int fetchCount = 0;
  int _reportEntryFetchCount = 0;
  int _creditFetchCount = 0;

  @override
  Future<void> resetSession(Map<String, String> cookieHeadersByHost) async {
    resetCookieHeaders.add(cookieHeadersByHost);
  }

  @override
  Future<StudentReportHttpSnapshot> openEntryPage(
    Uri entranceUri,
    Duration timeout,
  ) async {
    openCount++;
    if (requireAuthFirst && openCount == 1) return _casSnapshot;
    return entryPage;
  }

  @override
  Future<StudentReportHttpSnapshot> fetchPage(
    Uri pageUri,
    Duration timeout,
  ) async {
    fetchCount++;
    fetchedUris.add(pageUri);
    if (pageUri.path.contains('/sharedc/sso/')) {
      _reportEntryFetchCount++;
      if (requireAuthReportEntryFirst && _reportEntryFetchCount == 1) {
        return _localLoginSnapshot;
      }
      if (timeoutReportEntry) throw TimeoutException('SSO timeout');
      return reportEntryPage;
    }
    if (pageUri.path.contains('/studentxfform/') ||
        pageUri.path.contains('secondClassroom')) {
      _creditFetchCount++;
      if (requireAuthCreditFirst && _creditFetchCount == 1) {
        return _localLoginSnapshot;
      }
      return creditPage;
    }
    return StudentReportHttpSnapshot(
      finalUri: pageUri,
      statusCode: 404,
      body: 'not found',
    );
  }
}

StudentReportHttpSnapshot _snapshot(String body) {
  return StudentReportHttpSnapshot(
    finalUri: Uri.parse('https://xgbb.sspu.edu.cn/sharedc/core/home/index.do'),
    statusCode: 200,
    body: body,
  );
}

final StudentReportHttpSnapshot _casSnapshot = StudentReportHttpSnapshot(
  finalUri: Uri.parse('https://id.sspu.edu.cn/cas/login'),
  statusCode: 200,
  body: '<html><title>登录 - 上海第二工业大学</title></html>',
);

final StudentReportHttpSnapshot _localLoginSnapshot = StudentReportHttpSnapshot(
  finalUri: Uri.parse(
    'https://xgbb.sspu.edu.cn/sharedc/core/login/index.do?protocol=https',
  ),
  statusCode: 200,
  body: '''
<html>
  <body>
    <form>
      <input name="userName">
      <input name="userPwd">
      <input name="verifycode">
    </form>
  </body>
</html>
''',
);

final StudentReportHttpSnapshot _oaPortalSnapshot = StudentReportHttpSnapshot(
  finalUri: Uri.parse('https://oa.sspu.edu.cn/interface/Entrance.jsp'),
  statusCode: 200,
  body: '''
<html>
  <body>
    <a href="https://xgbb.sspu.edu.cn/sharedc/sso/fore-login.do">学工报表</a>
  </body>
</html>
''',
);

final AcademicLoginSessionSnapshot _sessionSnapshot =
    AcademicLoginSessionSnapshot(
      cookieHeadersByHost: const {
        'oa.sspu.edu.cn': 'OA=fake-oa-session',
        'id.sspu.edu.cn': 'CASTGC=fake-cas-session',
      },
      authenticatedAt: DateTime(2026, 5, 1),
      entranceUri: _oaEntranceUri,
      finalUri: _oaEntranceUri,
    );

final Uri _oaEntranceUri = Uri.parse(
  'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=xgreport',
);

AcademicLoginValidationResult _loginSuccessResult() {
  return AcademicLoginValidationResult(
    status: AcademicLoginValidationStatus.success,
    message: 'OA 登录校验通过',
    detail: '已刷新 OA 会话',
    checkedAt: DateTime(2026, 5, 1),
    entranceUri: _oaEntranceUri,
    finalUri: _oaEntranceUri,
    sessionSnapshot: _sessionSnapshot,
  );
}

const String _homeHtml = '''
<html>
  <body>
    <a href="/sharedc/core/home/secondClassroom.do">第二课堂学分查询</a>
  </body>
</html>
''';

const String _creditHtml = '''
<html>
  <body>
    <table>
      <tr><th>类别</th><th>项目名称</th><th>认定时间</th><th>状态</th><th>学分</th></tr>
      <tr><td>思想成长</td><td>主题团日</td><td>2026-04-20</td><td>已认定</td><td>1.5</td></tr>
      <tr><td>创新创业</td><td>创新训练项目</td><td>2026-04-25</td><td>通过</td><td>2</td></tr>
    </table>
  </body>
</html>
''';

const String _scoreColumnCreditHtml = '''
<html>
  <body>
    <table>
      <tr><th>模块</th><th>活动名称</th><th>学年学期</th><th>获得分数</th><th>认定日期</th><th>审核状态</th></tr>
      <tr><td>社会实践</td><td>志愿服务</td><td>2025-2026-2</td><td>0.50分</td><td>2026-03-01</td><td>通过</td></tr>
      <tr><td></td><td>专题讲座</td><td>2025-2026-2</td><td>1</td><td>2026-04-01</td><td>已认定</td></tr>
    </table>
  </body>
</html>
''';

const String _semesterDetailCreditHtml = '''
<html>
  <body>
    <table>
      <tr><th>学期</th><th>课程状态</th><th>项目名称</th><th>获得分数</th></tr>
      <tr><td>2024-2025-1</td><td>活动</td><td>迎新志愿服务</td><td>1</td></tr>
    </table>
  </body>
</html>
''';

final StudentReportHttpSnapshot _clientErrorHome = _snapshot('''
<html>
  <head><title>学工报表</title></head>
  <body>
    <script>console.error('client fallback');</script>
    <a href="/sharedc/core/home/secondClassroom.do">第二课堂学分查询</a>
  </body>
</html>
''');

final StudentReportHttpSnapshot _onclickHome = _snapshot('''
<html>
  <body>
    <nav>第二课堂</nav>
    <a href="javascript:void(0)" onclick="toMainUrl('dc/studentxfform/index.do','',true)">
      <span>第二学堂学分查询</span>
    </a>
  </body>
</html>
''');
