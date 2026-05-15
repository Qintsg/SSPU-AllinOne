/*
 * 隐私协议页面测试 — 校验协议内容与关于页入口
 * @Project : SSPU-AllinOne
 * @File : privacy_policy_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-15
 */

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sspu_allinone/pages/about_page.dart';
import 'package:sspu_allinone/pages/privacy_policy_page.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'SSPU-AllinOne',
      packageName: 'cn.qintsg.sspuallinone',
      version: '0.2.5-alpha',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('隐私协议页面展示本地数据和系统安全存储说明', (tester) async {
    await tester.pumpWidget(const FluentApp(home: PrivacyPolicyPage()));

    expect(find.text('隐私协议'), findsOneWidget);
    expect(find.textContaining('开发者不会主动收集、上传'), findsOneWidget);
    expect(find.textContaining('~/.sspu-all-in-one/'), findsOneWidget);
    expect(find.textContaining('系统安全存储'), findsOneWidget);
    expect(find.textContaining('WebView2'), findsOneWidget);
  });

  testWidgets('关于页提供隐私协议入口并可进入协议详情', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const FluentApp(home: AboutPage()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('隐私协议'), findsOneWidget);
    expect(find.text('查看本地数据、凭据和网络访问说明'), findsOneWidget);

    await tester.tap(find.text('隐私协议').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('SSPU-AllinOne 隐私协议'), findsOneWidget);
    expect(find.textContaining('清除所有本地数据'), findsOneWidget);
  });
}
