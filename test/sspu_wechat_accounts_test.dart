/*
 * 微信矩阵账号测试 — 校验推荐公众号静态列表
 * @Project : SSPU-AllinOne
 * @File : sspu_wechat_accounts_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/models/sspu_wechat_accounts.dart';

void main() {
  test('微信矩阵包含补充政务和招考公众号', () {
    expect(
      sspuWechatAccounts,
      contains(
        isA<SspuWechatAccount>()
            .having((account) => account.name, 'name', '上海发布')
            .having(
              (account) => account.wxAccount,
              'wxAccount',
              'shanghaifabu',
            ),
      ),
    );
    expect(
      sspuWechatAccounts,
      contains(
        isA<SspuWechatAccount>()
            .having((account) => account.name, 'name', '上海市教育考试院')
            .having((account) => account.wxAccount, 'wxAccount', 'shmeea_fabu'),
      ),
    );
  });

  test('微信矩阵微信号保持唯一', () {
    final accounts = sspuWechatAccounts.map((account) => account.wxAccount);

    expect(accounts.toSet(), hasLength(sspuWechatAccounts.length));
  });
}
