/*
 * Material 3 空状态视图 — 统一空数据、无结果与未配置提示
 * @Project : SSPU-AllinOne
 * @File : empty_state_view.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: AppSpacing.regularPagePadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
