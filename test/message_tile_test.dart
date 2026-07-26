/*
 * 消息列表项组件测试 — 校验微信推文元信息展示
 * @Project : SSPU-AllinOne
 * @File : message_tile_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-25
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/models/message_item.dart';
import 'package:sspu_allinone/widgets/message_tile.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester,
    MessageItem message, {
    double width = 900,
  }) async {
    await tester.pumpWidget(
      YhApp(
        home: YhPageScaffold(
          body: SizedBox(
            width: width,
            child: MessageTile(
              message: message,
              isRead: false,
              onTap: () {},
              nowOverride: DateTime(2026, 4, 25, 12),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('微信推文只展示来源类型和公众号名称标签', (tester) async {
    const message = MessageItem(
      id: 'wechat-1',
      title: '微信测试标题',
      date: '2026-04-25',
      url: 'https://mp.weixin.qq.com/s/test',
      sourceType: MessageSourceType.wechatPublic,
      sourceName: MessageSourceName.wechatPublicPlaceholder,
      category: MessageCategory.wechatArticle,
      mpBookId: 'fakeid-1',
      mpName: '青春二工大',
      mpDisplayId: 'ssputw',
    );

    await pumpTile(tester, message);

    expect(find.textContaining('微信推文'), findsAtLeastNWidgets(1));
    expect(find.textContaining('青春二工大'), findsOneWidget);
    expect(find.text('微信号：ssputw'), findsNothing);
  });

  testWidgets('微信账号名缺失时展示明确 fallback', (tester) async {
    const message = MessageItem(
      id: 'wechat-2',
      title: '微信 fallback 测试',
      date: '2026-04-25',
      url: 'https://mp.weixin.qq.com/s/fallback',
      sourceType: MessageSourceType.wechatPublic,
      sourceName: MessageSourceName.wechatPublicPlaceholder,
      category: MessageCategory.wechatArticle,
    );

    await pumpTile(tester, message);

    expect(find.textContaining('微信推文'), findsAtLeastNWidgets(1));
    expect(find.textContaining('公众号名称未知'), findsOneWidget);
    expect(find.text('微信号未知'), findsNothing);
  });

  testWidgets('非微信消息仍展示所有不同来源和分类标签', (tester) async {
    const message = MessageItem(
      id: 'school-1',
      title: '官网测试标题',
      date: '2026-04-25',
      url: 'https://www.sspu.edu.cn/test',
      sourceType: MessageSourceType.schoolWebsite,
      sourceName: MessageSourceName.jwc,
      category: MessageCategory.jwcStudent,
    );

    await pumpTile(tester, message);

    expect(find.textContaining('学校官网'), findsOneWidget);
    expect(find.text('教务处'), findsOneWidget);
    expect(find.textContaining('学生专栏'), findsOneWidget);
  });

  testWidgets('资讯卡优先展示已提供摘要与语义来源药丸', (tester) async {
    const message = MessageItem(
      id: 'summary-1',
      title: '暑期开放时间调整',
      summary: '入馆前请查看最新安排。',
      date: '2026-04-25',
      url: 'https://library.example.invalid/notice',
      sourceType: MessageSourceType.schoolWebsite,
      sourceName: MessageSourceName.libCenter,
      category: MessageCategory.libCenterNotice,
    );

    await pumpTile(tester, message);

    expect(find.text('学校官网'), findsOneWidget);
    expect(find.text('入馆前请查看最新安排。'), findsOneWidget);
    expect(find.byType(YhStatusPill), findsOneWidget);
    final summary = tester.widget<Text>(find.text('入馆前请查看最新安排。'));
    final theme = tester.element(find.byType(MessageTile)).yhTheme;
    expect(summary.style?.height, theme.typography.supporting.height);
    final title = tester.widget<Text>(find.text('暑期开放时间调整'));
    expect(title.style?.height, theme.typography.feed.height);
  });

  testWidgets('窄屏消息卡片保持微信账号 fallback 与操作区可布局', (tester) async {
    const message = MessageItem(
      id: 'wechat-narrow',
      title: '这是一条用于覆盖窄屏布局的微信推文标题，标题较长但不应挤压右侧操作按钮',
      date: '2026-04-25',
      url: 'https://mp.weixin.qq.com/s/narrow',
      sourceType: MessageSourceType.wechatPublic,
      sourceName: MessageSourceName.wechatPublicPlaceholder,
      category: MessageCategory.wechatArticle,
      mpName: '青春二工大',
      mpDisplayId: 'sspu-super-long-wechat-display-id-for-responsive-layout',
    );

    await pumpTile(tester, message, width: 320);

    expect(find.textContaining('微信推文'), findsAtLeastNWidgets(1));
    expect(find.textContaining('青春二工大'), findsOneWidget);
    expect(find.bySemanticsLabel('打开消息：${message.title}'), findsOneWidget);
  });
}
