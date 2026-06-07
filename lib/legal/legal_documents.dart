/*
 * 法律文档资源 — 统一管理协议版本、资产路径与本地化选择
 * @Project : SSPU-AllinOne
 * @File : legal_documents.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 当前需要用户确认的协议版本。
const String kLegalAgreementVersion = '20260607_artistic20_combined';

/// 中文完整法律与隐私说明资源。
const String kLegalNoticeZhAsset = 'assets/legal/legal_zh.txt';

/// 英文完整法律与隐私说明资源。
const String kLegalNoticeEnAsset = 'assets/legal/legal_en.txt';

/// 当前协议确认状态对应的持久化键名。
const String kLegalAgreementAcceptedKey =
    'agreement_${kLegalAgreementVersion}_accepted';

/// 根据语言环境选择完整法律说明资源。
String legalNoticeAssetForLocale(Locale? locale) {
  if (locale?.languageCode.toLowerCase() == 'zh') {
    return kLegalNoticeZhAsset;
  }

  return kLegalNoticeEnAsset;
}

/// 根据语言环境加载完整法律说明文本。
Future<String> loadLegalNoticeForLocale(Locale? locale) {
  return rootBundle.loadString(legalNoticeAssetForLocale(locale));
}

/// 根据上下文加载完整法律说明文本。
Future<String> loadLegalNoticeForContext(BuildContext context) {
  return loadLegalNoticeForLocale(Localizations.maybeLocaleOf(context));
}
