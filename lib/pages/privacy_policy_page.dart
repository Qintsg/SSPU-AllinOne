/*
 * 隐私协议页面 — 兼容旧入口并展示完整法律与隐私说明
 * @Project : SSPU-AllinOne
 * @File : privacy_policy_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-15
 */

import '../design/fluent_ui.dart';

import 'legal_notice_page.dart';

/// 隐私协议页面。
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalNoticePage();
  }
}
