/*
 * 新版教务统一会话与学生只读查询
 * @Project : SSPU-AllinOne
 * @File : academic_portal_queries.dart
 * @Author : Codex
 * @Date : 2026-11-19
 */

part of 'academic_eams_service.dart';

extension _AcademicPortalQueries on AcademicEamsService {
  /// 使用独立教务会话读取学生数据，遇到登录页时刷新会话一次。
  Future<AcademicEamsQueryResult> _fetchPortal(
    _AcademicFetchScope scope,
    CampusNetworkStatus? campusStatus, {
    required String account,
    AcademicTermChoice? term,
    String? semesterId,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final auth = await _refreshOaLogin(
        forceRefresh: attempt != 0,
        requireCampusNetwork: false,
      );
      final session = auth.sessionSnapshot;
      if (!auth.isSuccess || session == null || !session.hasCookies) {
        return _buildResult(
          AcademicEamsQueryStatus.oaLoginRequired,
          message: '新版教务登录未完成',
          detail: auth.message,
          finalUri: entranceUri,
          campusNetworkStatus: campusStatus,
        );
      }
      final gateway = _createPortalGateway();
      await gateway.resetSession(session.cookieHeadersByHost);
      try {
        final queries = _PortalStudentQueries(gateway, timeout, account);
        await queries.verifyAccount();
        return await _fetchPortalSnapshot(
          queries,
          scope,
          campusStatus,
          term: term,
          semesterId: semesterId,
        );
      } on _PortalLoginRequired {
        // 同一账号会话过期时，先重新认证，再从入口读取一次。
      } on _PortalQueryFailure catch (error) {
        return _buildResult(
          error.status,
          message: error.message,
          detail: error.message,
          finalUri: entranceUri,
          campusNetworkStatus: campusStatus,
        );
      } on FormatException {
        return _buildResult(
          AcademicEamsQueryStatus.parseFailed,
          message: '未能识别新版教务返回的数据',
          detail: '服务器响应缺少预期的教务字段。',
          finalUri: entranceUri,
          campusNetworkStatus: campusStatus,
        );
      }
    }
    return _buildResult(
      AcademicEamsQueryStatus.oaLoginRequired,
      message: '新版教务会话已失效',
      detail: '请核对账号连接或完成统一身份认证后重试。',
      finalUri: entranceUri,
      campusNetworkStatus: campusStatus,
    );
  }

  /// 读取指定业务，或为总览并行读取各项只读数据。
  Future<AcademicEamsQueryResult> _fetchPortalSnapshot(
    _PortalStudentQueries queries,
    _AcademicFetchScope scope,
    CampusNetworkStatus? campusStatus, {
    AcademicTermChoice? term,
    String? semesterId,
  }) async {
    AcademicEamsProfile? profile;
    AcademicCourseTableSnapshot? courseTable;
    AcademicGradeSnapshot? grades;
    AcademicGradeProcessSnapshot? process;
    AcademicExamSnapshot? exams;
    AcademicProgramPlanSnapshot? program;
    final warnings = <String>[];

    switch (scope) {
      case _AcademicFetchScope.studentProfileOnly:
        profile = await queries.profile();
      case _AcademicFetchScope.courseTableOnly:
        courseTable = await queries.courseTable();
      case _AcademicFetchScope.examScheduleOnly:
        exams = await queries.exams();
      case _AcademicFetchScope.gradesOnly:
        grades = (await queries.grades()).grades;
      case _AcademicFetchScope.gradeProcessOnly:
        process = (await queries.grades(
          term: term,
          semesterId: semesterId,
        )).process;
      case _AcademicFetchScope.overview:
        var expired = false;
        Future<T?> load<T>(String name, Future<T> Function() read) async {
          try {
            return await read();
          } on _PortalLoginRequired {
            expired = true;
          } on _PortalQueryFailure catch (error) {
            warnings.add('$name：${error.message}');
          } on FormatException {
            warnings.add('$name：响应结构无法识别');
          } on DioException {
            warnings.add('$name：网络请求失败');
          } on TimeoutException {
            warnings.add('$name：网络请求超时');
          }
          return null;
        }
        final (p, c, g, e, plan) = await (
          load('学籍', queries.profile),
          load('课表', () => queries.courseTable(useSelectedTerm: false)),
          load('成绩', () async => (await queries.grades()).grades),
          load('考试', queries.exams),
          load('培养方案', queries.program),
        ).wait;
        if (expired) throw const _PortalLoginRequired();
        profile = p;
        courseTable = c;
        grades = g;
        exams = e;
        program = plan;
        if (p == null && c == null && g == null && e == null && plan == null) {
          return _buildResult(
            AcademicEamsQueryStatus.parseFailed,
            message: '本次未能读取新版教务数据',
            detail: warnings.join('；'),
            finalUri: entranceUri,
            campusNetworkStatus: campusStatus,
          );
        }
    }

    final source =
        courseTable?.sourceUri ??
        exams?.sourceUri ??
        grades?.sourceUri ??
        process?.sourceUri ??
        program?.sourceUri ??
        entranceUri;
    final snapshot = AcademicEamsSnapshot(
      fetchedAt: queries.fetchedAt,
      sourceUri: source,
      warnings: List.unmodifiable(warnings),
      hasCourseOfferingEntry: true,
      hasFreeClassroomEntry: false,
      profile: profile,
      courseTable: courseTable,
      grades: grades,
      gradeProcess: process,
      exams: exams,
      programPlan: program,
      programCompletion: grades == null
          ? null
          : _deriveProgramCompletion(program, grades),
    );
    return _buildResult(
      warnings.isEmpty
          ? AcademicEamsQueryStatus.success
          : AcademicEamsQueryStatus.partialSuccess,
      message: warnings.isEmpty ? '新版教务数据已读取' : '新版教务部分数据已读取',
      detail: warnings.isEmpty ? '已完成只读查询。' : warnings.join('；'),
      finalUri: source,
      campusNetworkStatus: campusStatus,
      snapshot: snapshot,
    );
  }
}

class _PortalStudentQueries {
  _PortalStudentQueries(this._gateway, this._timeout, this._account);

  final AcademicEamsGateway _gateway;
  final Duration _timeout;
  final String _account;
  final DateTime fetchedAt = DateTime.now();
  late final String _studentId;

  /// 在进入动态路径前确认实际会话所属学生。
  Future<void> verifyAccount() async {
    final data = await _readJson(_uri('/student/for-std/ws/students-json'));
    final students = data['students'];
    if (students is! List<dynamic>) throw const FormatException('学生接口缺少列表');
    for (final item in students.whereType<Map<String, dynamic>>()) {
      final id = '${item['id']}';
      if (item['code'] == _account && RegExp(r'^\d+$').hasMatch(id)) {
        _studentId = id;
        return;
      }
    }
    throw const _PortalQueryFailure(
      AcademicEamsQueryStatus.readOnlyEntryUnavailable,
      '当前统一认证账号没有可查询的学生身份',
    );
  }

  /// 读取当前账号的学籍详情。
  Future<AcademicEamsProfile> profile() async {
    final body = await _read(AcademicEamsService._studentProfileUri);
    final result = parseAcademicStudentProfile(body);
    if (result == null || result.studentId != _account) {
      throw const FormatException('学籍页面缺少匹配的账号');
    }
    return result;
  }

  /// 读取学校的课表学期及该学期活动数据。
  Future<AcademicCourseTableSnapshot> courseTable({
    bool useSelectedTerm = true,
  }) async {
    final source = _uri('/student/for-std/course-table');
    final options = readPortalCourseSemesters(await _read(source));
    final selected = useSelectedTerm
        ? (await AcademicTermService.instance.loadSettings()).selectedTerm
        : null;
    final semester = selected == null
        ? options.firstOrNull
        : options.where((option) => option.matchesTerm(selected)).firstOrNull;
    if (semester == null) {
      throw const _PortalQueryFailure(
        AcademicEamsQueryStatus.readOnlyEntryUnavailable,
        '新版教务未提供所选学期的课表',
      );
    }
    final data = await _readJson(
      _uri('/student/for-std/course-table/semester/${semester.id}/print-data', {
        'semesterId': semester.id,
        'hasExperiment': 'true',
      }),
    );
    return parsePortalCourseTable(
      data,
      account: _account,
      semester: semester,
      sourceUri: source,
      fetchedAt: fetchedAt,
    );
  }

  /// 获取全部学期成绩，同一响应也包含平时成绩及占比。
  Future<({AcademicGradeSnapshot grades, AcademicGradeProcessSnapshot process})>
  grades({AcademicTermChoice? term, String? semesterId}) async {
    final source = _uri('/student/for-std/grade/sheet');
    final data = await _readJson(
      _uri('/student/for-std/grade/sheet/info/$_studentId', {
        'semester': '',
        'student': _studentId,
      }),
    );
    return parsePortalGrades(
      data,
      studentId: _studentId,
      sourceUri: source,
      fetchedAt: fetchedAt,
      term: term,
      semesterId: semesterId,
    );
  }

  /// 查询新版学生页公布的未结束考试。
  Future<AcademicExamSnapshot> exams() async {
    final source = _uri('/student/for-std/exam-arrange');
    return parsePortalExams(await _read(source), source, fetchedAt);
  }

  /// 查询学生培养方案及课程模块树。
  Future<AcademicProgramPlanSnapshot> program() async {
    final source = _uri('/student/for-std/program/struct-document/info/index');
    final info = await _readJson(
      _uri('/student/for-std/program/program-info-json', {
        'studentId': _studentId,
      }),
    );
    final programs = info['programInfos'];
    if (programs is! List<dynamic>) throw const FormatException('培养方案缺少方案列表');
    if (programs.isEmpty) {
      return AcademicProgramPlanSnapshot(
        courses: const [],
        fetchedAt: fetchedAt,
        sourceUri: source,
      );
    }
    final modules = await _readJson(
      _uri('/student/for-std/program/root-module-json/$_studentId', {
        'showReferenceCourse': '1',
      }),
    );
    final names = programs
        .whereType<Map<String, dynamic>>()
        .map((program) => program['nameZh'])
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .join(' / ');
    return parsePortalProgram(
      modules,
      planName: names.isEmpty ? null : names,
      sourceUri: source,
      fetchedAt: fetchedAt,
    );
  }

  Future<Map<String, dynamic>> _readJson(Uri uri) async =>
      decodeAcademicPortalJson(
        await _read(uri, accept: Headers.jsonContentType),
      );

  /// 允许同站只读请求，在解析前识别失效会话、权限和服务器错误。
  Future<String> _read(Uri uri, {String? accept}) async {
    var response = await _gateway.fetchPage(uri, _timeout, accept: accept);
    if (_isPortalHome(response, uri)) {
      response = await _gateway.fetchPage(uri, _timeout, accept: accept);
    }
    if (response.statusCode == 401 ||
        response.finalUri.host == 'id.sspu.edu.cn' &&
            response.finalUri.path == '/cas/login') {
      throw const _PortalLoginRequired();
    }
    if (response.statusCode == 403) {
      throw const _PortalQueryFailure(
        AcademicEamsQueryStatus.readOnlyEntryUnavailable,
        '当前学生账号没有此教务查询权限',
      );
    }
    if (response.finalUri.origin != uri.origin ||
        response.statusCode != 200 ||
        _isPortalHome(response, uri)) {
      throw const _PortalQueryFailure(
        AcademicEamsQueryStatus.systemUnavailable,
        '新版教务查询暂不可用',
      );
    }
    return response.body;
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.https('jw.sspu.edu.cn', path, query);

  /// CAS 成功回调可能先到达教务首页，再用建立的会话读取原查询。
  bool _isPortalHome(AcademicEamsHttpSnapshot response, Uri uri) =>
      response.finalUri.origin == uri.origin &&
      (response.finalUri.path == '/home/' || response.finalUri.path == '/home');
}

class _PortalLoginRequired implements Exception {
  const _PortalLoginRequired();
}

class _PortalQueryFailure implements Exception {
  const _PortalQueryFailure(this.status, this.message);

  final AcademicEamsQueryStatus status;
  final String message;
}
