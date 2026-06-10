/*
 * 学工报表服务测试支撑 — 提供 fake 网关与页面样例
 * @Project : SSPU-AllinOne
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
    Map<String, StudentReportHttpSnapshot>? detailPagesByPath,
    this.timeoutReportEntry = false,
    this.beforeCreditReturn,
  }) : entryPage = entryPage ?? _snapshot(_homeHtml),
       creditPage = creditPage ?? _snapshot(_creditHtml),
       reportEntryPage = reportEntryPage ?? _snapshot(_homeHtml),
       detailPagesByPath = detailPagesByPath ?? const {};

  final bool requireAuthFirst;
  final bool requireAuthReportEntryFirst;
  final bool requireAuthCreditFirst;
  final bool timeoutReportEntry;
  final StudentReportHttpSnapshot entryPage;
  final StudentReportHttpSnapshot creditPage;
  final StudentReportHttpSnapshot reportEntryPage;
  final Map<String, StudentReportHttpSnapshot> detailPagesByPath;
  final Future<void> Function()? beforeCreditReturn;
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
    final detailSnapshot = _findDetailSnapshot(pageUri);
    if (detailSnapshot != null) return detailSnapshot;
    if (pageUri.path.contains('/sharedc/sso/')) {
      _reportEntryFetchCount++;
      if (requireAuthReportEntryFirst && _reportEntryFetchCount == 1) {
        return _localLoginSnapshot;
      }
      if (timeoutReportEntry) throw TimeoutException('SSO timeout');
      return reportEntryPage;
    }
    if (pageUri.path.contains('detail.do')) {
      return StudentReportHttpSnapshot(
        finalUri: pageUri,
        statusCode: 404,
        body: 'not found',
      );
    }
    if (pageUri.path.contains('/studentxfform/') ||
        pageUri.path.contains('secondClassroom')) {
      _creditFetchCount++;
      if (requireAuthCreditFirst && _creditFetchCount == 1) {
        return _localLoginSnapshot;
      }
      await beforeCreditReturn?.call();
      return creditPage;
    }
    return StudentReportHttpSnapshot(
      finalUri: pageUri,
      statusCode: 404,
      body: 'not found',
    );
  }

  StudentReportHttpSnapshot? _findDetailSnapshot(Uri pageUri) {
    final pathWithQuery = pageUri.hasQuery
        ? '${pageUri.path}?${pageUri.query}'
        : pageUri.path;
    return detailPagesByPath[pageUri.toString()] ??
        detailPagesByPath[pathWithQuery] ??
        detailPagesByPath[pageUri.path];
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

SecondClassroomCreditSummary _cachedSummary(String itemName) {
  return SecondClassroomCreditSummary(
    fetchedAt: DateTime(2026, 5, 1),
    sourceUri: Uri.parse(
      'https://xgbb.sspu.edu.cn/sharedc/dc/studentxfform/index.do',
    ),
    records: [
      SecondClassroomCreditRecord(
        category: '思想成长',
        itemName: itemName,
        credit: 1,
        rawCells: ['思想成长', itemName, '1'],
      ),
    ],
    rules: [
      SecondClassroomCreditRuleRow(
        category: '思想成长',
        item: itemName,
        level: '校级',
        participation: '参与',
        credit: 1,
        earnedCredit: 1,
        requiredCredit: 1,
        passStatus: '通过',
      ),
    ],
    totals: const SecondClassroomCreditTotals(
      totalCredit: 1,
      totalEarnedCredit: 1,
      totalRequiredCredit: 1,
      passStatus: '通过',
    ),
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

const String _ruleMatrixCreditHtml = '''
<html>
  <body>
    <table>
      <tr>
        <th>类别</th><th>项目</th><th>等级</th><th>参与情况</th>
        <th>积分</th><th>已获分数</th><th>必修积分</th><th>通过情况</th>
      </tr>
      <tr>
        <td rowspan="2">思想成长</td><td>主题团日</td><td>校级</td><td>参与</td>
        <td>1.5</td>
        <td><a href="/sharedc/dc/studentxfform/detail.do?rule=1">1.5</a></td>
        <td>1</td><td>通过</td>
      </tr>
      <tr>
        <td>理论学习</td><td>院级</td><td>参与</td>
        <td>1</td><td>0</td><td>1</td><td>未通过</td>
      </tr>
      <tr>
        <td>社会实践</td><td>志愿服务</td><td>校级</td><td>参与</td>
        <td>2</td>
        <td><button data-url="/sharedc/dc/studentxfform/detail.do?rule=2">2</button></td>
        <td>1</td><td>通过</td>
      </tr>
      <tr>
        <td>报告与讲座</td><td>通识讲座</td><td>院级</td><td>1次</td>
        <td>0.5</td>
        <td>0.5<script>window.open('/sharedc/dc/studentxfform/detail.do?rule=3')</script></td>
        <td>1</td><td>未通过</td>
      </tr>
      <tr>
        <td colspan="4">总计</td><td>5</td><td>4</td><td>4</td><td>未通过</td>
      </tr>
    </table>
  </body>
</html>
''';

const String _detailCreditHtml = '''
<html>
  <body>
    <table>
      <tr>
        <th>名称</th><th>类别</th><th>项目</th><th>等级</th>
        <th>参与情况(h)</th><th>获得积分</th><th>签到时间</th>
      </tr>
      <tr>
        <td>主题团日</td><td>思想成长</td><td>主题教育</td><td>校级</td>
        <td>2</td><td>1.5</td><td>示例签到时间A</td>
      </tr>
      <tr>
        <td>志愿服务</td><td>社会实践</td><td>志愿公益</td><td>校级</td>
        <td>3</td><td>2</td><td>示例签到时间B</td>
      </tr>
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
