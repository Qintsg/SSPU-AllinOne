/*
 * 查询结果文案工具 — 提供通用失败原因兜底处理
 * @Project : SSPU-AllinOne
 * @File : query_result_messages.dart
 * @Author : Qintsg
 * @Date : 2026-06-10
 */

/// 返回第一个非空文本；均为空时返回 [fallback]。
String firstNonEmptyText(
  String? primary,
  String? secondary, {
  required String fallback,
}) {
  final primaryText = primary?.trim();
  if (primaryText != null && primaryText.isNotEmpty) return primaryText;
  final secondaryText = secondary?.trim();
  if (secondaryText != null && secondaryText.isNotEmpty) return secondaryText;
  return fallback;
}
