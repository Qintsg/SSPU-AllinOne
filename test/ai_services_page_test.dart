import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/ai_services_page.dart';
import 'package:sspu_allinone/services/mcp_server_controller.dart';
import 'package:sspu_allinone/services/storage_service.dart';

import 'support/responsive_test_sizes.dart';

void main() {
  testWidgets('AI services page exposes server and authorization controls', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    await tester.pumpWidget(const YhApp(home: AiServicesPage()));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('AI 服务'), findsOneWidget);
    expect(find.text('MCP 服务'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('授权外部应用访问'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('授权外部应用访问'), findsOneWidget);
    expect(find.text('个人信息'), findsOneWidget);
    expect(find.text('成绩'), findsOneWidget);
    expect(find.text('课表'), findsOneWidget);
    expect(find.text('培养计划'), findsOneWidget);
    expect(find.text('二课学分'), findsOneWidget);
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  testWidgets('unsupported mobile platform explains MCP is unavailable', (
    tester,
  ) async {
    try {
      SharedPreferences.setMockInitialValues({});
      StorageService.debugUseSharedPreferencesStorageForTesting(true);
      await tester.pumpWidget(
        YhApp(
          home: AiServicesPage(
            controller: McpServerController(platformSupported: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('当前平台不支持'), findsOneWidget);
      expect(
        find.textContaining('请使用 Windows、macOS 或 Linux 桌面版'),
        findsOneWidget,
      );
    } finally {
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
    }
  });

  testWidgets('AI 服务在宽屏使用窄宽等高双栏且端口操作同行', (tester) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    addTearDown(
      () => StorageService.debugUseSharedPreferencesStorageForTesting(null),
    );
    await setResponsiveTestViewport(tester, expandedTestViewport);
    addTearDown(() => resetResponsiveTestViewport(tester));
    await tester.pumpWidget(const YhApp(home: AiServicesPage()));
    await tester.pump(const Duration(milliseconds: 800));

    final authorization = find.byKey(const Key('mcp-authorization-card'));
    final audit = find.byKey(const Key('mcp-api-audit-card'));
    final portRow = find.byKey(const Key('mcp-port-action-row'));
    expect(find.byKey(const Key('ai-services-access-columns')), findsOneWidget);
    expect(tester.getSize(authorization).height, tester.getSize(audit).height);
    expect(
      tester.getSize(authorization).width,
      greaterThan(tester.getSize(audit).width),
    );
    expect(
      tester.getTopLeft(find.text('开启服务')).dy,
      greaterThanOrEqualTo(tester.getTopLeft(portRow).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI 服务在窄屏回落单栏且端口操作无溢出', (tester) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    addTearDown(
      () => StorageService.debugUseSharedPreferencesStorageForTesting(null),
    );
    await setResponsiveTestViewport(tester, compactTestViewport);
    addTearDown(() => resetResponsiveTestViewport(tester));
    await tester.pumpWidget(const YhApp(home: AiServicesPage()));
    await tester.pump(const Duration(milliseconds: 800));

    final authorization = find.byKey(const Key('mcp-authorization-card'));
    final audit = find.byKey(const Key('mcp-api-audit-card'));
    await tester.scrollUntilVisible(
      authorization,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('ai-services-access-stack')), findsOneWidget);
    expect(
      tester.getTopLeft(audit).dy,
      greaterThan(tester.getBottomLeft(authorization).dy),
    );
    expect(find.byKey(const Key('mcp-port-action-row')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
