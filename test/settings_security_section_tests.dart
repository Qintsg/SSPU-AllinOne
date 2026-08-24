/*
 * 安全设置分区行为测试 — 凭据、快速认证与恢复路径
 * @Project : SSPU-AllinOne
 * @File : settings_security_section_tests.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'settings_security_section_test.dart';

/// 注册安全设置分区行为测试。
///
/// :returns: 无返回值。
void _registerSecuritySectionTests() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> configureNarrowView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(320, 720));
  }

  Future<void> resetView(WidgetTester tester) async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  }

  Future<void> pumpSecuritySection(
    WidgetTester tester, {
    required bool isPasswordEnabled,
    required bool isQuickAuthEnabled,
    required bool isQuickAuthAvailable,
    bool isQuickAuthBusy = false,
    AcademicLoginValidationService? academicLoginValidationService,
    AcademicOaSessionPrewarmService? academicOaSessionPrewarmService,
    SportsAttendanceClient? sportsAttendanceService,
    EmailMailboxClient? emailMailboxService,
    VoidCallback? onOpenDataPrivacy,
    Future<AcademicCredentialsStatus> Function()? credentialsStatusLoader,
  }) async {
    await tester.pumpWidget(
      YhApp(
        home: YhPageScaffold(
          body: SingleChildScrollView(
            child: SettingsSecuritySection(
              isPasswordEnabled: isPasswordEnabled,
              onPasswordProtectionChanged: (_) {},
              onChangePassword: () {},
              isQuickAuthEnabled: isQuickAuthEnabled,
              isQuickAuthAvailable: isQuickAuthAvailable,
              isQuickAuthBusy: isQuickAuthBusy,
              onQuickAuthChanged: (_) {},
              onLock: null,
              onOpenDataPrivacy: onOpenDataPrivacy,
              academicLoginValidationService: academicLoginValidationService,
              academicOaSessionPrewarmService: academicOaSessionPrewarmService,
              sportsAttendanceService: sportsAttendanceService,
              emailMailboxService: emailMailboxService,
              credentialsStatusLoader: credentialsStatusLoader,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('安全设置页显示教务凭据状态但不回填密码', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
      sportsQueryPassword: 'sports-pass',
      emailPassword: 'mail-pass',
    );

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: false,
      isQuickAuthEnabled: false,
      isQuickAuthAvailable: false,
    );
    await pumpUntilFound(tester, find.text('学工号（OA账号）'));

    expect(find.text('教务凭据'), findsOneWidget);
    expect(find.text('数据均加密存储在本机，不会上传至云端；密码框留空时不修改已保存密码。'), findsOneWidget);
    expect(find.text('验证登录'), findsOneWidget);
    expect(find.text('20260001'), findsOneWidget);
    expect(find.text('学校邮箱账号：20260001@sspu.edu.cn'), findsOneWidget);
    expect(find.text('已填写'), findsNWidgets(3));
    expect(find.text('oa-pass'), findsNothing);
    expect(find.text('sports-pass'), findsNothing);
    expect(find.text('mail-pass'), findsNothing);
  });

  testWidgets('读取凭据状态失败会保留任务、输入和原位重试路径', (tester) async {
    var attempts = 0;
    final retryStatus = Completer<AcademicCredentialsStatus>();
    Future<AcademicCredentialsStatus> loadStatus() async {
      attempts += 1;
      if (attempts == 1) throw StateError('测试安全存储不可用');
      return retryStatus.future;
    }

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: true,
      isQuickAuthEnabled: true,
      isQuickAuthAvailable: true,
      onOpenDataPrivacy: () {},
      credentialsStatusLoader: loadStatus,
    );
    await pumpUntilFound(tester, find.text('重试'));

    expect(find.text('密码保护'), findsOneWidget);
    expect(find.text('系统快速验证'), findsOneWidget);
    expect(find.text('学工号（OA账号）'), findsOneWidget);
    expect(find.text('打开数据与隐私'), findsOneWidget);
    expect(find.textContaining('无法读取本机凭据状态'), findsOneWidget);

    final accountField = find.byType(EditableText).first;
    final passwordField = find.byType(EditableText).at(1);
    await tester.enterText(accountField, '20260001');
    await tester.enterText(passwordField, 'draft-password');
    final retry = find.widgetWithText(YhButton, '重试');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pump();

    expect(find.text('重试中'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('验证登录'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .every((field) => field.readOnly),
      isTrue,
    );

    retryStatus.complete(const AcademicCredentialsStatus.empty());
    await tester.pump();

    expect(attempts, 2);
    expect(find.textContaining('无法读取本机凭据状态'), findsNothing);
    expect(find.text('20260001'), findsOneWidget);
    expect(
      tester.widget<EditableText>(passwordField).controller.text,
      'draft-password',
    );
    expect(find.text('打开数据与隐私'), findsOneWidget);
  });

  testWidgets('凭据状态连续读取失败仍保留草稿和可触控重试动作', (tester) async {
    var attempts = 0;
    Future<AcademicCredentialsStatus> loadStatus() async {
      attempts += 1;
      throw StateError('测试安全存储持续不可用');
    }

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: true,
      isQuickAuthEnabled: true,
      isQuickAuthAvailable: true,
      credentialsStatusLoader: loadStatus,
    );
    await pumpUntilFound(tester, find.text('重试'));
    await tester.enterText(find.byType(EditableText).first, '20260001');

    final retry = find.widgetWithText(YhButton, '重试');
    expect(
      tester.getSize(retry).height,
      greaterThanOrEqualTo(YhTheme.light.control.minimumTarget),
    );
    expect(
      tester.getSize(retry).width,
      greaterThanOrEqualTo(YhTheme.light.control.minimumTarget),
    );
    await tester.tap(retry);
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.textContaining('无法读取本机凭据状态'), findsOneWidget);
    expect(find.text('20260001'), findsOneWidget);
    expect(find.widgetWithText(YhButton, '重试'), findsOneWidget);
  });

  testWidgets('安全设置页没有已保存密码时提示无可验证内容', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: false,
      isQuickAuthEnabled: false,
      isQuickAuthAvailable: false,
    );
    await pumpUntilFound(tester, find.text('验证登录'));

    await tester.ensureVisible(find.text('验证登录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('验证登录'));
    await tester.pumpAndSettle();

    expect(find.text('没有可验证的已保存密码'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('安全设置页验证所有已保存密码并显示逐项结果', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
      sportsQueryPassword: 'sports-pass',
      emailPassword: 'mail-pass',
    );
    final sportsService = _FakeSportsAttendanceClient(
      result: SportsAttendanceQueryResult(
        status: SportsAttendanceQueryStatus.credentialsRejected,
        message: '体育部账号或密码未通过校验',
        detail: '测试失败',
        checkedAt: DateTime(2026, 6, 11),
        entranceUri: Uri.parse('https://tygl.sspu.edu.cn/sportscore/'),
      ),
    );
    final emailService = _FakeEmailMailboxClient(
      result: EmailLoginValidationResult(
        status: EmailQueryStatus.success,
        protocol: EmailProtocol.smtp,
        message: 'SMTP 登录校验通过',
        detail: '测试成功',
        checkedAt: DateTime(2026, 6, 11),
        endpoint: EmailService.defaultSmtpEndpoint,
      ),
    );

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: false,
      isQuickAuthEnabled: false,
      isQuickAuthAvailable: false,
      academicLoginValidationService: AcademicLoginValidationService(
        gateway: _AlreadyLoggedInAcademicLoginGateway(),
      ),
      sportsAttendanceService: sportsService,
      emailMailboxService: emailService,
    );
    await pumpUntilFound(tester, find.text('验证登录'));

    await tester.tap(find.text('验证登录'));
    await pumpUntilFound(tester, find.text('验证未通过'));

    expect(find.text('验证通过'), findsNWidgets(2));
    expect(find.text('验证未通过'), findsOneWidget);
    expect(sportsService.requireCampusNetworkValues, [false]);
    expect(emailService.validatedProtocols, [EmailProtocol.smtp]);
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();
  });

  testWidgets('验证登录期间锁定整组凭据操作并在完成后保留草稿', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      sportsQueryPassword: 'sports-pass',
    );
    final sportsService = _DelayedSportsAttendanceClient();

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: false,
      isQuickAuthEnabled: false,
      isQuickAuthAvailable: false,
      sportsAttendanceService: sportsService,
    );
    await pumpUntilFound(tester, find.text('验证登录'));
    final fields = find.byType(EditableText, skipOffstage: false);
    await tester.enterText(fields.at(0), '20260002');

    await tester.tap(find.text('验证登录'));
    await tester.pump();

    expect(find.text('验证中'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('保存教务凭据'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      tester.widgetList<EditableText>(fields).every((field) => field.readOnly),
      isTrue,
    );
    expect(find.text('20260002'), findsOneWidget);

    sportsService.complete();
    await tester.pump();
    await tester.pump();

    expect(find.text('验证中'), findsNothing);
    expect(
      tester.widgetList<EditableText>(fields).every((field) => !field.readOnly),
      isTrue,
    );
    expect(find.text('20260002'), findsOneWidget);
  });

  testWidgets('验证服务换代后释放旧操作且旧结果不得回写', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      sportsQueryPassword: 'sports-pass',
    );
    final oldService = _DelayedSportsAttendanceClient();

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: false,
      isQuickAuthEnabled: false,
      isQuickAuthAvailable: false,
      sportsAttendanceService: oldService,
    );
    await pumpUntilFound(tester, find.text('验证登录'));
    await tester.tap(find.text('验证登录'));
    await tester.pump();
    expect(find.text('验证中'), findsOneWidget);

    final currentService = _FakeSportsAttendanceClient(
      result: SportsAttendanceQueryResult(
        status: SportsAttendanceQueryStatus.success,
        message: '当前服务验证通过',
        detail: '当前服务结果',
        checkedAt: DateTime(2026, 6, 11),
        entranceUri: Uri.parse('https://tygl.sspu.edu.cn/sportscore/'),
      ),
    );
    await pumpSecuritySection(
      tester,
      isPasswordEnabled: false,
      isQuickAuthEnabled: false,
      isQuickAuthAvailable: false,
      sportsAttendanceService: currentService,
    );
    await tester.pump();

    expect(find.text('验证中'), findsNothing);
    await tester.tap(find.text('验证登录'));
    await tester.pump();
    await tester.pump();
    expect(find.text('验证通过'), findsOneWidget);

    oldService.complete(isSuccess: false);
    await tester.pump();
    await tester.pump();

    expect(find.text('验证通过'), findsOneWidget);
    expect(find.text('验证未通过'), findsNothing);
  });

  testWidgets('保存 OA 凭据后自动静默预热登录会话', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final prewarmService = _RecordingAcademicOaSessionPrewarmService();

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: false,
      isQuickAuthEnabled: false,
      isQuickAuthAvailable: false,
      academicOaSessionPrewarmService: prewarmService,
    );
    await pumpUntilFound(tester, find.text('保存教务凭据'));

    await tester.enterText(find.byType(EditableText).at(0), '20260001');
    await tester.enterText(find.byType(EditableText).at(1), 'oa-pass');
    await tester.ensureVisible(find.text('保存教务凭据'));
    await tester.tap(find.text('保存教务凭据'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(prewarmService.forceRefreshValues, [true]);
    expect(prewarmService.requireCampusNetworkValues, [false]);
    expect(prewarmService.refreshStudentProfileValues, [true]);
    expect(
      await AcademicCredentialsService.instance.readOaLoginSession(),
      isNull,
      reason: '设置页只负责触发预热，实际会话保存由登录校验服务完成。',
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('iOS 保存教务凭据时反馈浮层不复用路由主滚动控制器', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    final sharedController = ScrollController();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await configureNarrowView(tester);

    try {
      await tester.pumpWidget(
        YhApp(
          home: PrimaryScrollController(
            controller: sharedController,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: SingleChildScrollView(
                    child: SizedBox(height: 1200, child: Text('同路由主滚动内容')),
                  ),
                ),
                Positioned.fill(
                  child: SingleChildScrollView(
                    primary: false,
                    child: SettingsSecuritySection(
                      isPasswordEnabled: false,
                      onPasswordProtectionChanged: (_) {},
                      onChangePassword: () {},
                      isQuickAuthEnabled: false,
                      isQuickAuthAvailable: false,
                      isQuickAuthBusy: false,
                      onQuickAuthChanged: (_) {},
                      onLock: null,
                      academicOaSessionPrewarmService:
                          _RecordingAcademicOaSessionPrewarmService(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await pumpUntilFound(tester, find.text('保存教务凭据'));
      expect(find.text('保存教务凭据'), findsOneWidget);

      expect(sharedController.positions, hasLength(1));

      final editableFields = find.byType(EditableText, skipOffstage: false);
      await tester.enterText(editableFields.at(0), '20260001');
      await tester.enterText(editableFields.at(1), 'oa-pass');
      await tester.ensureVisible(find.text('保存教务凭据'));
      await tester.tap(find.text('保存教务凭据'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.text('教务凭据已保存'), findsOneWidget);
      expect(sharedController.positions, hasLength(1));

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 100));
    } finally {
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetView(tester);
      sharedController.dispose();
    }
  });

  testWidgets('系统快速验证在可用时显示开关，不可用时显示密码兜底提示', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: false,
      isQuickAuthEnabled: false,
      isQuickAuthAvailable: true,
    );
    await pumpUntilFound(tester, find.text('学工号（OA账号）'));

    expect(find.text('系统快速验证'), findsNothing);

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: true,
      isQuickAuthEnabled: true,
      isQuickAuthAvailable: false,
    );
    await pumpUntilFound(tester, find.text('学工号（OA账号）'));

    expect(find.text('系统快速验证不可用'), findsOneWidget);
    expect(find.textContaining('仍可使用应用密码手动解锁'), findsOneWidget);

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: true,
      isQuickAuthEnabled: true,
      isQuickAuthAvailable: true,
    );
    await pumpUntilFound(tester, find.text('系统快速验证'));

    expect(find.text('系统快速验证'), findsOneWidget);
    expect(find.textContaining('仍可输入密码解锁'), findsOneWidget);
  });

  testWidgets('安全分区的数据与隐私摘要进入独立任务页', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(960, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var opened = false;

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: false,
      isQuickAuthEnabled: false,
      isQuickAuthAvailable: false,
      onOpenDataPrivacy: () => opened = true,
    );
    await pumpUntilFound(tester, find.text('打开数据与隐私'));
    await tester.ensureVisible(find.text('打开数据与隐私'));
    await tester.pumpAndSettle();

    expect(find.text('清理信息中心缓存'), findsNothing);
    expect(find.text('清除本地数据'), findsNothing);
    await tester.tap(find.text('打开数据与隐私'));
    await tester.pump();
    expect(opened, isTrue);
  });

  testWidgets('窄屏安全设置保留 quick auth 与数据隐私摘要', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await configureNarrowView(tester);

    try {
      await pumpSecuritySection(
        tester,
        isPasswordEnabled: true,
        isQuickAuthEnabled: true,
        isQuickAuthAvailable: true,
        isQuickAuthBusy: true,
        onOpenDataPrivacy: () {},
      );
      await pumpUntilFound(tester, find.text('系统快速验证'));

      expect(find.text('系统快速验证'), findsOneWidget);
      expect(find.text('立即上锁'), findsOneWidget);
      expect(find.text('打开数据与隐私'), findsOneWidget);
      expect(find.text('清理信息中心缓存'), findsNothing);
      expect(find.text('清除本地数据'), findsNothing);
      expect(
        (tester.getCenter(find.byType(YhSwitch).first).dy -
                tester.getCenter(find.text('密码保护')).dy)
            .abs(),
        lessThan(YhTheme.light.spacing.xl),
        reason: '简单开关应与说明同行，避免在窄屏额外占一整行。',
      );
      expect(
        find.byType(YhChip),
        findsNothing,
        reason: '凭据填写状态使用普通辅助文字，不重复套胶囊边框。',
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetView(tester);
    }
  });
}
