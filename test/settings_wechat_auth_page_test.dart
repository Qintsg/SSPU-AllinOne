/* 清源微信公众号认证任务页行为测试。 */

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/controllers/settings_wechat_controller.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/models/app_feedback_severity.dart';
import 'package:sspu_allinone/pages/settings_wechat_auth_page.dart';
import 'package:sspu_allinone/services/wxmp_auth_service.dart';
import 'package:sspu_allinone/services/wxmp_config_service.dart';
import 'package:sspu_allinone/widgets/settings_wechat_auth_status_card.dart';

void main() {
  testWidgets('认证使用真实任务页并把完整操作从主分区摘要分离', (tester) async {
    final controller = _WechatAuthController();
    await tester.pumpWidget(
      YhApp(home: SettingsWechatAuthPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('微信公众号认证'), findsOneWidget);
    expect(find.text('微信公众号连接'), findsOneWidget);
    expect(find.text('生成登录二维码'), findsOneWidget);
    expect(find.text('等待手机确认'), findsOneWidget);
    expect(find.text('连接后只读取授权信息'), findsOneWidget);
    expect(controller.loadCalls, 1);
  });

  testWidgets('校验期间锁定登录、编辑、校验和清除操作', (tester) async {
    final pending = Completer<SettingsWechatFeedback>();
    final controller = _WechatAuthController(
      authenticated: true,
      validateResult: pending.future,
    );
    await tester.pumpWidget(
      YhApp(home: SettingsWechatAuthPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重新校验认证'));
    await tester.pump();

    expect(find.text('开始认证'), findsOneWidget);
    expect(
      tester.widget<YhButton>(find.widgetWithText(YhButton, '开始认证')).onTap,
      isNull,
    );
    expect(find.text('处理中'), findsNWidgets(3));

    pending.complete(
      const SettingsWechatFeedback(
        title: '认证有效',
        severity: AppFeedbackSeverity.success,
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.validateCalls, 1);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('清除确认取消后保留连接且不调用清除', (tester) async {
    final controller = _WechatAuthController(authenticated: true);
    await tester.pumpWidget(
      YhApp(
        home: SettingsWechatAuthPage(
          controller: controller,
          clearConfirmation: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清除认证'));
    await tester.pumpAndSettle();

    expect(controller.clearCalls, 0);
    expect(find.text('已取消清除，公众号连接保持不变。'), findsOneWidget);
    expect(find.text('生成登录二维码'), findsOneWidget);
  });

  testWidgets('清除失败不误报完成并提供可重试方向', (tester) async {
    final controller = _WechatAuthController(
      authenticated: true,
      clearError: StateError('storage denied'),
    );
    await tester.pumpWidget(
      YhApp(
        home: SettingsWechatAuthPage(
          controller: controller,
          clearConfirmation: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清除认证'));
    await tester.pumpAndSettle();

    expect(controller.clearCalls, 1);
    expect(find.textContaining('未能完整清除本机认证'), findsOneWidget);
    expect(controller.authenticated, isTrue);
  });

  testWidgets('取消扫码不会触发结果回写并说明原连接是否保留', (tester) async {
    final controller = _WechatAuthController(authenticated: true);
    await tester.pumpWidget(
      YhApp(
        home: SettingsWechatAuthPage(
          controller: controller,
          loginFlow: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('开始认证').first);
    await tester.pumpAndSettle();

    expect(controller.loginSuccessCalls, 0);
    expect(find.text('已取消重新认证，原有连接保持不变。'), findsOneWidget);
  });

  testWidgets('未连接时取消扫码仍显示取消结果和继续路径', (tester) async {
    final controller = _WechatAuthController();
    await tester.pumpWidget(
      YhApp(
        home: SettingsWechatAuthPage(
          controller: controller,
          loginFlow: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('开始认证').first);
    await tester.pumpAndSettle();

    expect(find.text('已取消扫码认证，没有保存新的认证信息。'), findsOneWidget);
    expect(find.text('开始认证'), findsWidgets);
  });

  testWidgets('远端重新校验失败显示真实原因而不回落成尚未开始', (tester) async {
    final controller = _WechatAuthController(
      authenticated: true,
      authenticatedAfterValidate: false,
      validateResult: Future.value(
        const SettingsWechatFeedback(
          title: '认证不可用',
          content: 'Cookie 已过期，请重新扫码。',
          severity: AppFeedbackSeverity.warning,
        ),
      ),
    );
    await tester.pumpWidget(
      YhApp(home: SettingsWechatAuthPage(controller: controller)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重新校验认证'));
    await tester.pumpAndSettle();

    expect(find.text('Cookie 已过期，请重新扫码。'), findsWidgets);
    expect(find.text('尚未读取微信公众号认证'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('认证成功但列表刷新失败时保留已连接并说明部分失败', (tester) async {
    final controller = _WechatAuthController(
      authenticated: true,
      loginFeedback: const SettingsWechatFeedback(
        title: '登录成功，但公众号列表刷新失败',
        content: '认证连接已保留；可稍后刷新，不需要重新扫码。',
        severity: AppFeedbackSeverity.warning,
      ),
    );
    await tester.pumpWidget(
      YhApp(
        home: SettingsWechatAuthPage(
          controller: controller,
          loginFlow: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始认证').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('认证连接已保留'), findsWidgets);
    expect(controller.authenticated, isTrue);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('登录返回成功但凭据缺失时显示错误而不误报已连接', (tester) async {
    final controller = _WechatAuthController();
    await tester.pumpWidget(
      YhApp(
        home: SettingsWechatAuthPage(
          controller: controller,
          loginFlow: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('开始认证').first);
    await tester.pumpAndSettle();

    expect(controller.loginSuccessCalls, 1);
    expect(find.textContaining('认证结果未能写回设置'), findsOneWidget);
    expect(find.text('已连接'), findsNothing);
  });

  testWidgets('状态读取失败仍保留开始认证的恢复路径', (tester) async {
    final controller = _WechatAuthController(loadError: StateError('io'));
    await tester.pumpWidget(
      YhApp(
        home: SettingsWechatAuthPage(
          controller: controller,
          loginFlow: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('无法读取本机微信认证状态'), findsOneWidget);
    expect(find.text('开始认证'), findsOneWidget);
    expect(find.text('未完成：生成登录二维码'), findsOneWidget);
    expect(find.text('已完成：生成登录二维码'), findsNothing);
  });

  testWidgets('主分区摘要只暴露统一管理入口', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      YhApp(
        home: SettingsWechatAuthSummary(
          state: SettingsWechatAuthDisplayState.content,
          statusMessage: '认证信息可用',
          onOpenDetails: () => opened = true,
        ),
      ),
    );

    expect(find.text('编辑认证配置'), findsNothing);
    expect(find.text('清除认证'), findsNothing);
    await tester.tap(find.text('管理微信公众号认证'));
    expect(opened, isTrue);
  });
}

class _WechatAuthController extends SettingsWechatController {
  _WechatAuthController({
    this.authenticated = false,
    this.loadError,
    this.clearError,
    this.validateResult,
    this.authenticatedAfterValidate,
    this.loginFeedback,
  });

  bool authenticated;
  final Object? loadError;
  final Object? clearError;
  final Future<SettingsWechatFeedback>? validateResult;
  final bool? authenticatedAfterValidate;
  final SettingsWechatFeedback? loginFeedback;
  int loadCalls = 0;
  int validateCalls = 0;
  int clearCalls = 0;
  int loginSuccessCalls = 0;

  @override
  bool get isLoading => false;

  @override
  bool get wxmpAuthenticated => authenticated;

  @override
  WxmpAuthStatus? get wxmpAuthStatus => WxmpAuthStatus(
    state: authenticated ? WxmpAuthState.ready : WxmpAuthState.missingCookie,
    lastUpdate: null,
  );

  @override
  String get wxmpConfigPath => '应用数据目录/wxmp_config.toml';

  @override
  String get wxmpConfigMessage => '配置文件已就绪';

  @override
  Future<void> load() async {
    loadCalls += 1;
    if (loadError != null) throw loadError!;
  }

  @override
  Future<SettingsWechatFeedback> reloadConfigFile() async {
    validateCalls += 1;
    final result = validateResult == null
        ? const SettingsWechatFeedback(
            title: '认证有效',
            severity: AppFeedbackSeverity.success,
          )
        : await validateResult!;
    if (authenticatedAfterValidate != null) {
      authenticated = authenticatedAfterValidate!;
    }
    return result;
  }

  @override
  Future<SettingsWechatFeedback> clearAuth() async {
    clearCalls += 1;
    if (clearError != null) throw clearError!;
    authenticated = false;
    return const SettingsWechatFeedback(
      title: '公众号平台认证已清除',
      severity: AppFeedbackSeverity.info,
    );
  }

  @override
  Future<SettingsWechatFeedback> handleLoginSuccess() async {
    loginSuccessCalls += 1;
    return loginFeedback ??
        SettingsWechatFeedback(
          title: authenticated ? '公众号平台登录成功' : '登录结果缺少认证信息',
          severity: authenticated
              ? AppFeedbackSeverity.success
              : AppFeedbackSeverity.warning,
        );
  }

  @override
  Future<WxmpConfig> loadConfig() async => WxmpConfig.defaults();
}
