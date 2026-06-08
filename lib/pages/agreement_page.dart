/*
 * 使用协议页面 — 兼容旧入口并展示完整法律与隐私说明
 * @Project : SSPU-AllinOne
 * @File : agreement_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import '../design/fluent_ui.dart';

import 'legal_notice_page.dart';

/// 使用协议页面。
class AgreementPage extends StatelessWidget {
  const AgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalNoticePage();
  }
}
