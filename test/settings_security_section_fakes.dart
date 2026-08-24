/*
 * 安全设置分区测试适配器 — 服务结果与延迟行为
 * @Project : SSPU-AllinOne
 * @File : settings_security_section_fakes.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'settings_security_section_test.dart';

class _RecordingAcademicOaSessionPrewarmService
    extends AcademicOaSessionPrewarmService {
  _RecordingAcademicOaSessionPrewarmService()
    : super(
        ensureSession:
            ({
              bool forceRefresh = false,
              bool requireCampusNetwork = true,
            }) async => _successResult(),
        ensureStudentProfile: ({bool forceRefresh = false}) async =>
            const AcademicEamsProfile(
              name: '张三',
              studentId: '20260001',
              department: '计算机与信息工程学院',
              major: '软件工程',
              className: '软件 241',
              gender: '男',
              studyLength: '4 年',
              educationLevel: '本科',
              rawFields: {},
            ),
      );

  final List<bool> forceRefreshValues = [];
  final List<bool> requireCampusNetworkValues = [];
  final List<bool> refreshStudentProfileValues = [];

  @override
  Future<AcademicLoginValidationResult?> prewarm({
    bool forceRefresh = true,
    bool requireCampusNetwork = false,
    bool refreshStudentProfile = true,
  }) async {
    forceRefreshValues.add(forceRefresh);
    requireCampusNetworkValues.add(requireCampusNetwork);
    refreshStudentProfileValues.add(refreshStudentProfile);
    return _successResult();
  }
}

class _AlreadyLoggedInAcademicLoginGateway implements AcademicLoginGateway {
  @override
  Future<void> resetSession() async {}

  @override
  Future<AcademicLoginHttpSnapshot> openLoginPage(
    Uri entranceUri,
    Duration timeout,
  ) async {
    return AcademicLoginHttpSnapshot(
      finalUri: Uri.parse('https://oa.sspu.edu.cn/home'),
      statusCode: 200,
      body: '<html>OA</html>',
    );
  }

  @override
  Future<String> fetchPublicKey(Duration timeout) async => '';

  @override
  Future<AcademicLoginHttpSnapshot> submitLogin({
    required Uri loginUri,
    required Map<String, String> fields,
    required Duration timeout,
  }) async {
    return AcademicLoginHttpSnapshot(
      finalUri: Uri.parse('https://oa.sspu.edu.cn/home'),
      statusCode: 200,
      body: '<html>OA</html>',
    );
  }

  @override
  AcademicLoginSessionSnapshot currentSessionSnapshot({
    required Uri entranceUri,
    required Uri finalUri,
  }) {
    return AcademicLoginSessionSnapshot(
      cookieHeadersByHost: const {'oa.sspu.edu.cn': 'SESSION=test'},
      authenticatedAt: DateTime(2026, 6, 11),
      entranceUri: entranceUri,
      finalUri: finalUri,
    );
  }
}

class _FakeSportsAttendanceClient implements SportsAttendanceClient {
  _FakeSportsAttendanceClient({required this.result});

  final SportsAttendanceQueryResult result;
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
    requireCampusNetworkValues.add(requireCampusNetwork);
    return result;
  }
}

class _DelayedSportsAttendanceClient implements SportsAttendanceClient {
  final Completer<SportsAttendanceQueryResult> _completer = Completer();

  void complete({bool isSuccess = true}) {
    _completer.complete(
      SportsAttendanceQueryResult(
        status: isSuccess
            ? SportsAttendanceQueryStatus.success
            : SportsAttendanceQueryStatus.credentialsRejected,
        message: isSuccess ? '体育部登录校验通过' : '旧服务验证未通过',
        detail: isSuccess ? '测试成功' : '旧服务结果',
        checkedAt: DateTime(2026, 6, 11),
        entranceUri: Uri.parse('https://tygl.sspu.edu.cn/sportscore/'),
      ),
    );
  }

  @override
  Future<SportsAttendanceQueryResult?>
  readLatestCachedAttendanceSummary() async => null;

  @override
  Future<SportsAttendanceQueryResult> fetchAttendanceSummary({
    bool requireCampusNetwork = true,
  }) => _completer.future;
}

class _FakeEmailMailboxClient implements EmailMailboxClient {
  _FakeEmailMailboxClient({required this.result});

  final EmailLoginValidationResult result;
  final List<EmailProtocol> validatedProtocols = [];

  @override
  Future<EmailMailboxQueryResult?> readLatestCachedMessages(
    EmailProtocol protocol,
  ) async {
    return null;
  }

  @override
  Future<EmailMailboxQueryResult> fetchMessages({
    required EmailProtocol protocol,
    int messageCount = 10,
  }) async {
    return EmailMailboxQueryResult(
      status: EmailQueryStatus.unexpectedError,
      protocol: protocol,
      message: '测试不读取邮件',
      detail: '测试不读取邮件',
      checkedAt: DateTime(2026, 6, 11),
      endpoint: EmailService.defaultImapEndpoint,
    );
  }

  @override
  Future<EmailLoginValidationResult> validateLogin(
    EmailProtocol protocol,
  ) async {
    validatedProtocols.add(protocol);
    return result;
  }

  @override
  Future<EmailSendResult> sendMessage(EmailComposeRequest request) async {
    return EmailSendResult(
      status: EmailQueryStatus.unexpectedError,
      message: '测试不发送邮件',
      detail: '测试不发送邮件',
      checkedAt: DateTime(2026, 6, 11),
      endpoint: EmailService.defaultSmtpEndpoint,
    );
  }
}

AcademicLoginValidationResult _successResult() {
  return AcademicLoginValidationResult(
    status: AcademicLoginValidationStatus.success,
    message: 'OA 登录会话已就绪',
    detail: '测试会话',
    checkedAt: DateTime(2026, 6, 4),
    entranceUri: Uri.parse(
      'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
    ),
  );
}
