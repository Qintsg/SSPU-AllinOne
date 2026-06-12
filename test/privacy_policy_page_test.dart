/*
 * 法律与隐私说明测试 — 校验合并协议正文、关于页入口与首启确认弹窗
 * @Project : SSPU-AllinOne
 * @File : privacy_policy_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-15
 */

import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sspu_allinone/pages/about_page.dart';
import 'package:sspu_allinone/pages/agreement_page.dart';
import 'package:sspu_allinone/pages/legal_notice_page.dart';
import 'package:sspu_allinone/pages/privacy_policy_page.dart';
import 'package:sspu_allinone/widgets/legal_consent_dialog.dart';

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

  Future<void> resetView(WidgetTester tester) async {
    tester.view.resetPadding();
    tester.view.resetViewPadding();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  }

  Future<void> pumpPageAnimations(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
  }

  Widget zhFluentApp({required Widget home}) {
    return FluentApp(
      locale: const Locale('zh'),
      supportedLocales: const [Locale('zh'), Locale('en')],
      home: home,
    );
  }

  String selectableTextBody(WidgetTester tester) {
    return tester
        .widgetList<SelectableText>(find.byType(SelectableText))
        .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
        .join('\n');
  }

  Future<String> pumpUntilSelectableText(
    WidgetTester tester, {
    required String containsText,
  }) async {
    for (var i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      final body = selectableTextBody(tester);
      if (body.contains(containsText)) {
        return body;
      }
    }

    return selectableTextBody(tester);
  }

  testWidgets('法律与隐私说明页面展示所有协议段落', (tester) async {
    await tester.pumpWidget(zhFluentApp(home: const PrivacyPolicyPage()));

    expect(find.text('法律与隐私说明'), findsOneWidget);
    final body = await pumpUntilSelectableText(tester, containsText: '免责声明');
    expect(body, contains('免责声明'));
    expect(body, contains('用户协议'));
    expect(body, contains('隐私协议'));
    expect(body, contains('开源许可证与第三方协议说明'));
    expect(body, contains('Artistic License 2.0'));
    expect(body, isNot(contains('采用 MIT')));
  });

  testWidgets('旧使用协议入口展示同一篇完整法律说明', (tester) async {
    await tester.pumpWidget(zhFluentApp(home: const AgreementPage()));

    expect(find.text('法律与隐私说明'), findsOneWidget);
    expect(find.byType(LegalNoticePage), findsOneWidget);
  });

  testWidgets('关于页提供合并协议入口并可进入详情', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(zhFluentApp(home: const AboutPage()));
    await pumpPageAnimations(tester);

    expect(find.text('法律与隐私说明'), findsOneWidget);
    expect(find.text('查看免责声明、用户协议、隐私协议和第三方协议'), findsOneWidget);
    expect(find.text('隐私协议'), findsNothing);

    await tester.tap(find.text('法律与隐私说明').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LegalNoticePage), findsOneWidget);
    expect(find.text('返回'), findsOneWidget);

    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();

    expect(find.byType(LegalNoticePage), findsNothing);
    expect(find.text('关于'), findsOneWidget);
  });

  testWidgets('关于页展示当前项目许可证和主要第三方组件', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(zhFluentApp(home: const AboutPage()));
    await pumpPageAnimations(tester);

    expect(find.text('许可证：'), findsOneWidget);
    expect(find.text('Artistic License 2.0'), findsOneWidget);
    expect(find.text('项目'), findsOneWidget);
    expect(find.text('使用场景'), findsOneWidget);
    expect(find.text('许可证说明'), findsOneWidget);
    expect(find.text('flutter_inappwebview'), findsOneWidget);
    expect(find.text('enough_mail'), findsOneWidget);
    expect(find.text('open_filex'), findsOneWidget);
    expect(find.textContaining('专利授权条款'), findsOneWidget);
    expect(find.textContaining('文件级弱 copyleft'), findsOneWidget);
  });

  testWidgets('桌面首次启动协议确认弹窗提供更大阅读面积', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => resetView(tester));

    await tester.pumpWidget(
      zhFluentApp(
        home: LegalConsentDialog(onAccept: () {}, onDecline: () {}),
      ),
    );
    await pumpPageAnimations(tester);

    final dialog = find.byKey(const Key('legal-consent-dialog'));
    final document = find.byKey(const Key('legal-consent-document'));
    expect(dialog, findsOneWidget);
    expect(document, findsOneWidget);
    expect(tester.getSize(dialog).width, greaterThanOrEqualTo(900));
    expect(tester.getSize(dialog).height, greaterThanOrEqualTo(700));
    expect(tester.getSize(document).height, greaterThanOrEqualTo(480));
    expect(
      find.byKey(const Key('legal-consent-actions-regular')),
      findsOneWidget,
    );
  });

  testWidgets('移动端首次启动协议确认弹窗适配安全区和纵向按钮', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 44, bottom: 34);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => resetView(tester));

    await tester.pumpWidget(
      zhFluentApp(
        home: LegalConsentDialog(onAccept: () {}, onDecline: () {}),
      ),
    );
    await pumpPageAnimations(tester);

    final dialog = find.byKey(const Key('legal-consent-dialog'));
    expect(dialog, findsOneWidget);
    expect(tester.getTopLeft(dialog).dy, greaterThanOrEqualTo(44));
    expect(tester.getBottomLeft(dialog).dy, lessThanOrEqualTo(810));
    expect(
      find.byKey(const Key('legal-consent-actions-compact')),
      findsOneWidget,
    );
    expect(find.text('同意全部协议并继续'), findsOneWidget);
    expect(find.text('不同意并退出'), findsOneWidget);
  });

  testWidgets('协议正文加载失败时不能同意协议', (tester) async {
    var accepted = false;
    var declined = false;

    await tester.pumpWidget(
      zhFluentApp(
        home: LegalConsentDialog(
          onAccept: () => accepted = true,
          onDecline: () => declined = true,
          loadLegalNotice: (_) => Future<String>.error(StateError('missing')),
        ),
      ),
    );
    await pumpPageAnimations(tester);

    expect(find.text('无法加载协议正文'), findsOneWidget);
    expect(find.text('协议正文加载完成后才可继续。'), findsOneWidget);

    final acceptButton = tester.widget<FluentButton>(
      find.byKey(const Key('legal-consent-accept')),
    );
    expect(acceptButton.onPressed, isNull);

    await tester.tap(
      find.byKey(const Key('legal-consent-accept')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(accepted, isFalse);
    expect(declined, isFalse);
  });
}
