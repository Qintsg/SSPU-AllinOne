import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/ai_services_page.dart';
import 'package:sspu_allinone/services/mcp_server_controller.dart';
import 'package:sspu_allinone/services/storage_service.dart';

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
}
