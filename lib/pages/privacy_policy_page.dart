/*
 * 隐私协议页面 — 兼容旧入口并展示完整法律与隐私说明
 * @Project : SSPU-AllinOne
 * @File : privacy_policy_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-15
 */

import '../design/qingyuan/qingyuan_ui.dart';

import 'legal_notice_page.dart';
import 'settings_page.dart';

/// 隐私协议页面。
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalNoticePage(
      title: '隐私说明',
      kicker: '法律与隐私',
      summary: '按数据类型说明收集目的、存储位置、联网时机和删除方式。',
      primaryActionLabel: '管理本地数据',
      onPrimaryAction: () => Navigator.of(context).pushReplacement(
        YhPageRoute<void>(
          builder: (_) => SettingsPage(
            landingRequest: SettingsLandingRequest(
              SettingsLandingSection.security,
            ),
          ),
        ),
      ),
    );
  }
}
