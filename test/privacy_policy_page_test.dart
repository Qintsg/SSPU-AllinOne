/*
 * 法律与隐私说明测试 — 校验合并协议正文、关于页入口与首启确认弹窗
 * @Project : SSPU-AllinOne
 * @File : privacy_policy_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-15
 */

import 'dart:async';

import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart' as qingyuan;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sspu_allinone/app.dart';
import 'package:sspu_allinone/pages/about_page.dart';
import 'package:sspu_allinone/pages/agreement_page.dart';
import 'package:sspu_allinone/pages/legal_notice_page.dart';
import 'package:sspu_allinone/pages/privacy_policy_page.dart';
import 'package:sspu_allinone/pages/settings_page.dart';
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

  Widget zhYhApp({required Widget home}) {
    return qingyuan.YhApp(
      locale: const Locale('zh'),
      supportedLocales: const [Locale('zh'), Locale('en')],
      home: home,
    );
  }

  String selectableTextBody(WidgetTester tester) {
    return tester
        .widgetList<qingyuan.YhSelectableText>(
          find.byType(qingyuan.YhSelectableText),
        )
        .map((widget) => widget.data)
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

  testWidgets('隐私说明页面展示所有协议段落', (tester) async {
    await tester.pumpWidget(zhYhApp(home: const PrivacyPolicyPage()));

    expect(find.text('隐私说明'), findsOneWidget);
    expect(find.text('法律与隐私'), findsOneWidget);
    expect(find.text('管理本地数据'), findsOneWidget);
    final body = await pumpUntilSelectableText(tester, containsText: '免责声明');
    expect(body, contains('免责声明'));
    expect(body, contains('用户协议'));
    expect(body, contains('隐私协议'));
    expect(body, contains('开源许可证与第三方协议说明'));
    expect(body, contains('用户主动使用学校邮箱 SMTP 发信时'));
    expect(body, contains('收件人、抄送、密送、主题和正文会提交给学校邮箱服务端处理'));
    expect(body, contains('Apache License 2.0'));
    expect(body, isNot(contains('采用 MIT')));
  });

  testWidgets('结构化法律页展示来源、章节并执行主要行动', (tester) async {
    var actionInvoked = false;

    await tester.pumpWidget(
      zhYhApp(
        home: LegalNoticePage(
          title: '隐私说明',
          kicker: '法律与隐私',
          summary: '按数据类型说明收集目的、存储位置、联网时机和删除方式。',
          source: '随应用发布的文本',
          primaryActionLabel: '管理本地数据',
          onPrimaryAction: () => actionInvoked = true,
          sections: const [
            LegalNoticeSection(
              title: '账户凭据',
              body: '1. 本节说明账户凭据的使用边界和用户可执行的管理方式。',
            ),
            LegalNoticeSection(
              title: '校园数据缓存',
              body: '2. 本节说明校园数据缓存的保存位置和删除方式。',
            ),
            LegalNoticeSection(title: '诊断信息', body: '3. 本节说明诊断信息的处理范围。'),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('法律与隐私'), findsOneWidget);
    expect(find.text('隐私说明'), findsOneWidget);
    expect(find.text('按数据类型说明收集目的、存储位置、联网时机和删除方式。'), findsOneWidget);
    expect(find.text('随应用发布的文本'), findsWidgets);
    expect(find.text('账户凭据'), findsOneWidget);
    expect(find.text('校园数据缓存'), findsOneWidget);
    expect(find.text('诊断信息'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    expect(find.text('文档信息'), findsOneWidget);
    expect(find.text('来源'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('管理本地数据'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(actionInvoked, isTrue);
  });

  testWidgets('宽屏短法律正文收束为左锚定阅读列', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => resetView(tester));

    await tester.pumpWidget(
      zhYhApp(
        home: const LegalNoticePage(
          sections: [
            LegalNoticeSection(title: '账户凭据', body: '仅用于已明确发起的校园服务请求。'),
            LegalNoticeSection(title: '校园数据缓存', body: '可在设置中查看并按需清除。'),
            LegalNoticeSection(title: '诊断信息', body: '仅用于解释应用当前状态。'),
          ],
        ),
      ),
    );
    await tester.pump();

    final pageSize = tester.getSize(find.byType(qingyuan.YhPageScaffold));
    final card = find.byKey(const Key('legal-sections-card'));
    expect(card, findsOneWidget);
    expect(tester.getSize(card).width, lessThan(pageSize.width * 0.7));
    expect(tester.getSize(card).height, lessThan(pageSize.height * 0.5));
  });

  testWidgets('隐私说明主要行动进入本地数据管理', (tester) async {
    await tester.pumpWidget(zhYhApp(home: const PrivacyPolicyPage()));
    await pumpUntilSelectableText(tester, containsText: '免责声明');

    await tester.tap(find.text('管理本地数据'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(PrivacyPolicyPage), findsNothing);
  });

  testWidgets('法律正文加载失败后可在原页重试', (tester) async {
    var loadCount = 0;

    await tester.pumpWidget(
      zhYhApp(
        home: LegalNoticePage(
          loadLegalNotice: (_) async {
            loadCount += 1;
            if (loadCount == 1) throw StateError('missing asset');
            return '一、免责声明\n\n重新加载后的完整正文。';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('无法加载协议正文'), findsOneWidget);
    expect(find.bySemanticsLabel('返回'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);

    await tester.tap(find.text('重新加载'));
    await tester.pumpAndSettle();

    expect(loadCount, 2);
    expect(find.text('无法加载协议正文'), findsNothing);
    expect(find.text('一、免责声明'), findsOneWidget);
    expect(selectableTextBody(tester), contains('重新加载后的完整正文。'));
  });

  testWidgets('旧使用协议入口展示同一篇完整法律说明', (tester) async {
    await tester.pumpWidget(zhYhApp(home: const AgreementPage()));

    expect(find.text('用户协议'), findsOneWidget);
    expect(find.text('法律与协议'), findsOneWidget);
    expect(find.text('返回'), findsWidgets);
    expect(find.byType(LegalNoticePage), findsOneWidget);
  });

  testWidgets('关于页提供合并协议入口并可进入详情', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(zhYhApp(home: const AboutPage()));
    await pumpPageAnimations(tester);

    expect(find.text('法律与隐私说明'), findsOneWidget);
    expect(find.text('查看免责声明、用户协议、隐私协议和第三方协议'), findsOneWidget);
    expect(find.text('隐私协议'), findsNothing);

    await tester.tap(find.text('法律与隐私说明').first);
    await tester.pumpAndSettle();

    expect(find.byType(LegalNoticePage), findsOneWidget);
    expect(find.text('法律声明'), findsOneWidget);
    expect(find.text('返回设置'), findsOneWidget);
    expect(find.bySemanticsLabel('返回'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();

    expect(find.byType(LegalNoticePage), findsNothing);
    expect(find.text('关于'), findsOneWidget);
  });

  testWidgets('设置内法律详情保留生产导航壳', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      zhYhApp(
        home: const AppShell(
          initialDestinationIndex: 6,
          destinationOverrides: {'设置': AboutPage()},
        ),
      ),
    );
    await pumpPageAnimations(tester);
    await tester.ensureVisible(find.text('法律与隐私说明'));
    await tester.tap(find.text('法律与隐私说明'));
    await tester.pumpAndSettle();

    expect(find.byType(LegalNoticePage), findsOneWidget);
    expect(find.byType(qingyuan.YhNavRail), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('关于页展示当前项目许可证和主要第三方组件', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(zhYhApp(home: const AboutPage()));
    await pumpPageAnimations(tester);

    expect(find.text('许可证：'), findsOneWidget);
    expect(find.text('Apache License 2.0'), findsOneWidget);
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
      zhYhApp(
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
      zhYhApp(
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
      zhYhApp(
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

    final acceptButton = tester.widget<qingyuan.YhButton>(
      find.byKey(const Key('legal-consent-accept')),
    );
    expect(acceptButton.onTap, isNull);

    await tester.tap(
      find.byKey(const Key('legal-consent-accept')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(accepted, isFalse);
    expect(declined, isFalse);
  });

  testWidgets('协议选择保存期间互斥，失败后保留正文并可重试', (tester) async {
    final firstAttempt = Completer<void>();
    var acceptAttempts = 0;
    var declined = false;

    await tester.pumpWidget(
      zhYhApp(
        home: LegalConsentDialog(
          onAccept: () {
            acceptAttempts++;
            if (acceptAttempts == 1) return firstAttempt.future;
            return Future<void>.value();
          },
          onDecline: () => declined = true,
          loadLegalNotice: (_) async => '法律与隐私说明正文',
        ),
      ),
    );
    await pumpPageAnimations(tester);

    await tester.tap(find.byKey(const Key('legal-consent-accept')));
    await tester.pump();

    expect(acceptAttempts, 1);
    expect(find.text('正在保存…'), findsOneWidget);
    expect(find.textContaining('正在将协议选择安全保存到本机'), findsOneWidget);
    expect(
      tester
          .widget<qingyuan.YhButton>(
            find.byKey(const Key('legal-consent-decline')),
          )
          .onTap,
      isNull,
    );
    await tester.tap(
      find.byKey(const Key('legal-consent-decline')),
      warnIfMissed: false,
    );
    expect(declined, isFalse);

    firstAttempt.completeError(StateError('storage unavailable'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('未能保存协议选择'), findsOneWidget);
    expect(find.text('法律与隐私说明正文'), findsOneWidget);
    expect(find.text('重试保存并继续'), findsOneWidget);
    expect(
      tester
          .widget<qingyuan.YhButton>(
            find.byKey(const Key('legal-consent-decline')),
          )
          .onTap,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('legal-consent-accept')));
    await tester.pump();
    expect(acceptAttempts, 2);
    expect(find.textContaining('未能保存协议选择'), findsNothing);
  });

  testWidgets('协议正文加载失败后可在原弹窗重试', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      zhYhApp(
        home: LegalConsentDialog(
          onAccept: () {},
          onDecline: () {},
          loadLegalNotice: (_) async {
            attempts++;
            if (attempts == 1) throw StateError('asset unavailable');
            return '重新加载后的协议正文';
          },
        ),
      ),
    );
    await pumpPageAnimations(tester);

    expect(find.text('无法加载协议正文'), findsOneWidget);
    await tester.tap(find.text('重试加载协议'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('重新加载后的协议正文'), findsOneWidget);
    expect(
      tester
          .widget<qingyuan.YhButton>(
            find.byKey(const Key('legal-consent-accept')),
          )
          .onTap,
      isNotNull,
    );
  });
}
