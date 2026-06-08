/*
 * 安全设置分区测试 — 校验教务凭据展示状态与密码回访隐藏行为
 * @Project : SSPU-AllinOne
 * @File : settings_security_section_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-24
 */

import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/academic_login_validation.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/academic_login_validation_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/widgets/settings_security_section.dart';

/// 等待目标组件出现，覆盖安全存储异步加载后的首帧。
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

void main() {
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
  }) async {
    await tester.pumpWidget(
      FluentApp(
        home: ScaffoldPage(
          content: SingleChildScrollView(
            child: SettingsSecuritySection(
              isPasswordEnabled: isPasswordEnabled,
              onPasswordProtectionChanged: (_) {},
              onChangePassword: () {},
              isQuickAuthEnabled: isQuickAuthEnabled,
              isQuickAuthAvailable: isQuickAuthAvailable,
              isQuickAuthBusy: isQuickAuthBusy,
              onQuickAuthChanged: (_) {},
              onLock: null,
              onClearMessageCache: () {},
              onClearAllData: () {},
              academicLoginValidationService: academicLoginValidationService,
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
    expect(find.text('数据均加密存储在本地，不会上传至云端；密码框留空时不修改已保存密码。'), findsOneWidget);
    expect(find.text('验证 OA 登录'), findsOneWidget);
    expect(find.text('20260001'), findsOneWidget);
    expect(find.text('学校邮箱账号：20260001@sspu.edu.cn'), findsOneWidget);
    expect(find.text('已填写'), findsNWidgets(3));
    expect(find.text('oa-pass'), findsNothing);
    expect(find.text('sports-pass'), findsNothing);
    expect(find.text('mail-pass'), findsNothing);
  });

  testWidgets('安全设置页可触发 OA 登录校验并展示缺少账号提示', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: false,
      isQuickAuthEnabled: false,
      isQuickAuthAvailable: false,
    );
    await pumpUntilFound(tester, find.text('验证 OA 登录'));

    await tester.ensureVisible(find.text('验证 OA 登录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('验证 OA 登录'));
    await tester.pumpAndSettle();

    expect(find.text('请先保存学工号（OA账号）'), findsOneWidget);
  });

  testWidgets('保存 OA 凭据后自动静默预热登录会话', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final validationService = _RecordingAcademicLoginValidationService();

    await pumpSecuritySection(
      tester,
      isPasswordEnabled: false,
      isQuickAuthEnabled: false,
      isQuickAuthAvailable: false,
      academicLoginValidationService: validationService,
    );
    await pumpUntilFound(tester, find.text('保存教务凭据'));

    await tester.enterText(find.byType(EditableText).at(0), '20260001');
    await tester.enterText(find.byType(EditableText).at(1), 'oa-pass');
    await tester.ensureVisible(find.text('保存教务凭据'));
    await tester.tap(find.text('保存教务凭据'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(validationService.forceRefreshValues, [true]);
    expect(validationService.requireCampusNetworkValues, [false]);
    expect(
      await AcademicCredentialsService.instance.readOaLoginSession(),
      isNull,
      reason: '设置页只负责触发预热，实际会话保存由登录校验服务完成。',
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
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

  testWidgets('窄屏安全设置堆叠 quick auth 与数据管理操作', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await configureNarrowView(tester);

    try {
      await pumpSecuritySection(
        tester,
        isPasswordEnabled: true,
        isQuickAuthEnabled: true,
        isQuickAuthAvailable: true,
        isQuickAuthBusy: true,
      );
      await pumpUntilFound(tester, find.text('系统快速验证'));

      expect(find.text('系统快速验证'), findsOneWidget);
      expect(find.text('立即上锁'), findsOneWidget);
      expect(find.text('清理信息中心缓存'), findsOneWidget);
      expect(find.text('清除所有数据'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetView(tester);
    }
  });
}

class _RecordingAcademicLoginValidationService
    extends AcademicLoginValidationService {
  _RecordingAcademicLoginValidationService()
    : super(gateway: _UnusedAcademicLoginGateway());

  final List<bool> forceRefreshValues = [];
  final List<bool> requireCampusNetworkValues = [];

  @override
  Future<AcademicLoginValidationResult> ensureSavedSession({
    bool forceRefresh = false,
    bool requireCampusNetwork = true,
  }) async {
    forceRefreshValues.add(forceRefresh);
    requireCampusNetworkValues.add(requireCampusNetwork);
    return _successResult();
  }

  @override
  Future<AcademicLoginValidationResult> validateSavedCredentials({
    bool requireCampusNetwork = true,
  }) async {
    return _successResult();
  }
}

class _UnusedAcademicLoginGateway implements AcademicLoginGateway {
  @override
  AcademicLoginSessionSnapshot currentSessionSnapshot({
    required Uri entranceUri,
    required Uri finalUri,
  }) => throw UnimplementedError();

  @override
  Future<String> fetchPublicKey(Duration timeout) => throw UnimplementedError();

  @override
  Future<AcademicLoginHttpSnapshot> openLoginPage(
    Uri entranceUri,
    Duration timeout,
  ) => throw UnimplementedError();

  @override
  Future<void> resetSession() async {}

  @override
  Future<AcademicLoginHttpSnapshot> submitLogin({
    required Uri loginUri,
    required Map<String, String> fields,
    required Duration timeout,
  }) => throw UnimplementedError();
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
