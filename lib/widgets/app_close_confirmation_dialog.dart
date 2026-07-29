/* 清源桌面关闭确认表面。 */

import '../design/qingyuan/qingyuan_ui.dart';

typedef AppCloseAction = Future<void> Function(bool rememberChoice);

enum AppCloseConfirmationDisplayState { content, operationLocked, error }

/// 关闭应用时的最小化/退出选择，负责本地交互状态但不直接操作平台窗口。
class AppCloseConfirmationDialog extends StatefulWidget {
  const AppCloseConfirmationDialog({
    super.key,
    required this.onMinimize,
    required this.onExit,
    this.onCancel,
    this.initialDisplayState = AppCloseConfirmationDisplayState.content,
  });

  final AppCloseAction onMinimize;
  final AppCloseAction onExit;
  final VoidCallback? onCancel;
  final AppCloseConfirmationDisplayState initialDisplayState;

  @override
  State<AppCloseConfirmationDialog> createState() =>
      _AppCloseConfirmationDialogState();
}

class _AppCloseConfirmationDialogState
    extends State<AppCloseConfirmationDialog> {
  bool _rememberChoice = false;
  late bool _isBusy;
  late String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isBusy =
        widget.initialDisplayState ==
        AppCloseConfirmationDisplayState.operationLocked;
    _errorMessage =
        widget.initialDisplayState == AppCloseConfirmationDisplayState.error
        ? '未能完成窗口操作；当前页面和选择仍已保留，可重试或取消。'
        : null;
  }

  Future<void> _runAction(AppCloseAction action) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      await action(_rememberChoice);
      if (mounted) setState(() => _isBusy = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = '未能完成窗口操作；当前页面和选择仍已保留，可重试或取消。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.m),
        child: YhDialog(
          eyebrow: '桌面窗口',
          title: '关闭工大聚合？',
          stackActionsOnCompact: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '最小化会保留当前页面与后台刷新；退出会停止本机任务。',
                style: theme.typography.body.copyWith(
                  color: theme.color.foreground,
                ),
              ),
              if (_isBusy) ...[
                SizedBox(height: theme.spacing.m),
                Semantics(
                  liveRegion: true,
                  child: const YhBanner(text: '正在保存关闭选择并处理窗口，完成前已锁定重复操作。'),
                ),
              ],
              if (_errorMessage != null) ...[
                SizedBox(height: theme.spacing.m),
                YhBanner(text: _errorMessage!, kind: YhBannerKind.danger),
              ],
              SizedBox(height: theme.spacing.m),
              YhCheckbox(
                label: '以后都使用本次选择',
                value: _rememberChoice,
                onChanged: _isBusy
                    ? null
                    : (value) =>
                          setState(() => _rememberChoice = value ?? false),
              ),
            ],
          ),
          actions: [
            YhButton(
              label: '取消',
              variant: YhButtonVariant.secondary,
              minWidth: compact ? theme.breakpoint.compact : null,
              autofocus: true,
              onTap: _isBusy ? null : widget.onCancel,
              disabled: _isBusy || widget.onCancel == null,
            ),
            YhButton(
              label: '最小化到托盘',
              leadingIcon: YhIcons.minimize,
              variant: YhButtonVariant.secondary,
              minWidth: compact ? theme.breakpoint.compact : null,
              onTap: _isBusy ? null : () => _runAction(widget.onMinimize),
              disabled: _isBusy,
            ),
            YhButton(
              label: _isBusy ? '正在处理…' : '退出应用',
              leadingIcon: YhIcons.power,
              variant: YhButtonVariant.danger,
              minWidth: compact ? theme.breakpoint.compact : null,
              onTap: _isBusy ? null : () => _runAction(widget.onExit),
              disabled: _isBusy,
            ),
          ],
        ),
      ),
    );
  }
}
