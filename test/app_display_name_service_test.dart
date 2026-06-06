/*
 * 应用显示名服务测试 — 校验中英文语言环境下的显示名解析
 * @Project : SSPU-AllinOne
 * @File : app_display_name_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-06
 */

import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/services/app_display_name_service.dart';

void main() {
  test('中文语言环境返回工大聚合', () {
    expect(AppDisplayName.forLocale(const Locale('zh')), '工大聚合');
    expect(AppDisplayName.forLocale(const Locale('zh', 'CN')), '工大聚合');
    expect(
      AppDisplayName.forLocale(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ),
      '工大聚合',
    );
    expect(
      AppDisplayName.forLocale(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ),
      '工大聚合',
    );
  });

  test('非中文语言环境返回英文显示名', () {
    expect(AppDisplayName.forLocale(const Locale('en')), 'SSPU-AllinOne');
    expect(AppDisplayName.forLocale(const Locale('en', 'US')), 'SSPU-AllinOne');
    expect(AppDisplayName.forLocale(const Locale('ja')), 'SSPU-AllinOne');
    expect(AppDisplayName.forLocale(null), 'SSPU-AllinOne');
  });

  testWidgets('BuildContext 优先使用 Flutter Localizations locale', (tester) async {
    await tester.pumpWidget(
      FluentApp(
        locale: const Locale('zh'),
        supportedLocales: const [Locale('zh'), Locale('en')],
        home: Builder(builder: (context) => Text(AppDisplayName.of(context))),
      ),
    );

    expect(find.text('工大聚合'), findsOneWidget);
    expect(find.text('SSPU-AllinOne'), findsNothing);
  });
}
