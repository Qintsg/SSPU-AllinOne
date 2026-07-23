/* 清源桌面关闭确认表面。 */

import '../design/qingyuan/qingyuan_ui.dart';

typedef AppCloseAction = Future<void> Function(bool rememberChoice);

/// 关闭应用时的最小化/退出选择，负责本地交互状态但不直接操作平台窗口。
class AppCloseConfirmationDialog extends StatefulWidget {
  const AppCloseConfirmationDialog({
    super.key,
    required this.onMinimize,
    required this.onExit,
  });

  final AppCloseAction onMinimize;
  final AppCloseAction onExit;

  @override
  State<AppCloseConfirmationDialog> createState() =>
      _AppCloseConfirmationDialogState();
}

class _AppCloseConfirmationDialogState
    extends State<AppCloseConfirmationDialog> {
  bool _rememberChoice = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhDialog(
      title: '关闭应用',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(YhIcons.close, color: theme.color.brandStrong),
              SizedBox(width: theme.spacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '请选择点击窗口关闭按钮时的处理方式。',
                      style: theme.typography.body.copyWith(
                        color: theme.color.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: theme.spacing.xs),
                    const Text('不确定时请选择最小化到托盘，应用可从托盘再次打开。'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.m),
          YhCheckbox(
            label: '以后都使用此选项',
            value: _rememberChoice,
            onChanged: (value) =>
                setState(() => _rememberChoice = value ?? false),
          ),
        ],
      ),
      actions: [
        YhButton(
          label: '最小化到托盘',
          leadingIcon: YhIcons.minimize,
          variant: YhButtonVariant.secondary,
          autofocus: true,
          onTap: () => widget.onMinimize(_rememberChoice),
        ),
        YhButton(
          label: '退出应用',
          leadingIcon: YhIcons.power,
          variant: YhButtonVariant.danger,
          onTap: () => widget.onExit(_rememberChoice),
        ),
      ],
    );
  }
}
