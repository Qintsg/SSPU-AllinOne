/*
 * 清源空状态视图 — 统一空数据、无结果与未配置提示
 * @Project : SSPU-AllinOne
 * @File : empty_state_view.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import '../design/qingyuan/qingyuan_ui.dart';

/// 通用空状态视图。
class EmptyStateView extends StatelessWidget {
  /// 图标。
  final IconData icon;

  /// 标题。
  final String title;

  /// 说明文本。
  final String? message;

  /// 可选操作。
  final Widget? action;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return YhEmptyState(
      icon: icon,
      title: title,
      message: message,
      action: action,
    );
  }
}
