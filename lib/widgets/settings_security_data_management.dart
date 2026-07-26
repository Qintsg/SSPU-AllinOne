/*
 * 设置页安全分区数据管理 — 本地缓存、账户连接与隐私任务账本
 * @Project : SSPU-AllinOne
 * @File : settings_security_data_management.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

part of 'settings_security_section.dart';

enum SettingsDataPrivacyState { content, loading, error }

/// 旧安全分区中的只读摘要，完整操作统一进入独立任务页。
class SettingsDataPrivacySummary extends StatelessWidget {
  const SettingsDataPrivacySummary({super.key, this.onOpenDetails});

  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('数据与隐私', style: theme.typography.h2),
        SizedBox(height: theme.spacing.m),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.color.sunken,
            border: Border.all(color: theme.color.border),
            borderRadius: BorderRadius.circular(theme.radius.input),
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.m),
            child: Row(
              children: [
                Icon(YhIcons.database, color: theme.color.brandStrong),
                SizedBox(width: theme.spacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('本机数据与账户连接', style: theme.typography.body),
                      SizedBox(height: theme.spacing.xs),
                      Text(
                        '查看缓存范围、账户状态、清除后果与隐私说明。',
                        style: theme.typography.small.copyWith(
                          color: theme.color.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onOpenDetails != null) ...[
          SizedBox(height: theme.spacing.m),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: YhButton(
              label: '打开数据与隐私',
              variant: YhButtonVariant.secondary,
              onTap: onOpenDetails,
            ),
          ),
        ],
      ],
    );
  }
}

/// 本地数据与隐私任务列表；业务动作仍由设置页状态层提供。
class SettingsDataPrivacySection extends StatelessWidget {
  const SettingsDataPrivacySection({
    super.key,
    required this.onClearCampusCache,
    required this.onDisconnectAccounts,
    this.onOpenPrivacy,
    this.onViewCompleted,
    this.state = SettingsDataPrivacyState.content,
    this.errorMessage,
    this.operationError = true,
    this.loadingMessage = '正在从本机存储恢复数据；已有页面框架与输入保持可用。',
    this.clearedItems = const ['清除校园缓存'],
    this.cacheStatus = '当前设置',
    this.accountStatus = '保存在本机',
    this.privacyStatus = '保存在本机',
  });

  final VoidCallback onClearCampusCache;
  final VoidCallback onDisconnectAccounts;
  final VoidCallback? onOpenPrivacy;
  final VoidCallback? onViewCompleted;
  final SettingsDataPrivacyState state;
  final String? errorMessage;
  final bool operationError;
  final String loadingMessage;
  final List<String> clearedItems;
  final String cacheStatus;
  final String accountStatus;
  final String privacyStatus;

  @override
  Widget build(BuildContext context) {
    final tasks = _tasks;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state == SettingsDataPrivacyState.loading) ...[
            _DataPrivacyStatusBanner(text: loadingMessage),
          ],
          if (state == SettingsDataPrivacyState.error) ...[
            _DataPrivacyStatusBanner(
              text: errorMessage ?? '无法从本机存储完成本次操作；清除校园缓存仍保持原有状态，可检查条件后重试。',
              danger: true,
            ),
          ],
          for (var index = 0; index < tasks.length; index++)
            _DataPrivacyTaskRow(
              task: tasks[index],
              state: state,
              completed:
                  state == SettingsDataPrivacyState.error &&
                  operationError &&
                  clearedItems.contains(tasks[index].label),
              onViewCompleted: onViewCompleted,
              operationError: operationError,
            ),
        ],
      ),
    );
  }

  List<_DataPrivacyTask> get _tasks => [
    _DataPrivacyTask(
      label: '清除校园缓存',
      actionLabel: '清除',
      status: cacheStatus,
      onTap: onClearCampusCache,
      isOperation: true,
    ),
    _DataPrivacyTask(
      label: '断开账户连接',
      actionLabel: '断开',
      status: accountStatus,
      onTap: onDisconnectAccounts,
      isOperation: true,
    ),
    _DataPrivacyTask(
      label: '查看隐私说明',
      actionLabel: '查看',
      status: privacyStatus,
      onTap: onOpenPrivacy,
    ),
  ];
}

class _DataPrivacyStatusBanner extends StatelessWidget {
  const _DataPrivacyStatusBanner({required this.text, this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final foreground = danger ? theme.color.danger : theme.color.warning;
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: danger ? theme.color.dangerTint : theme.color.warningTint,
          borderRadius: BorderRadius.circular(theme.radius.s),
        ),
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.m),
          child: Text(
            text,
            style: theme.typography.body.copyWith(
              color: foreground,
              fontWeight: theme.typography.h3.fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}

class _DataPrivacyTask {
  const _DataPrivacyTask({
    required this.label,
    required this.actionLabel,
    required this.status,
    required this.onTap,
    this.isOperation = false,
  });

  final String label;
  final String actionLabel;
  final String status;
  final VoidCallback? onTap;
  final bool isOperation;
}

class _DataPrivacyTaskRow extends StatelessWidget {
  const _DataPrivacyTaskRow({
    required this.task,
    required this.state,
    required this.completed,
    required this.onViewCompleted,
    required this.operationError,
  });

  final _DataPrivacyTask task;
  final SettingsDataPrivacyState state;
  final bool completed;
  final VoidCallback? onViewCompleted;
  final bool operationError;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final error = state == SettingsDataPrivacyState.error && operationError;
    final title = error && task.isOperation
        ? '${completed ? '已完成' : '未完成'}：${task.label}'
        : task.label;
    final description = switch (state) {
      SettingsDataPrivacyState.content => task.status,
      SettingsDataPrivacyState.loading => '保留当前设置',
      SettingsDataPrivacyState.error =>
        !operationError || !task.isOperation
            ? task.status
            : completed
            ? '结果已保留'
            : '可安全重试',
    };
    final actionLabel = switch (state) {
      SettingsDataPrivacyState.content => task.actionLabel,
      SettingsDataPrivacyState.loading => '处理中',
      SettingsDataPrivacyState.error =>
        !operationError || !task.isOperation
            ? task.actionLabel
            : completed
            ? '查看'
            : '重试',
    };
    final actionEnabled =
        state != SettingsDataPrivacyState.loading &&
        (!completed || onViewCompleted != null);
    final onAction = completed ? onViewCompleted : task.onTap;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.color.border,
            width: theme.layout.divider,
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: theme.control.minimumTarget + theme.spacing.m,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: theme.spacing.s),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.typography.body.copyWith(
                        fontWeight: theme.typography.h3.fontWeight,
                      ),
                    ),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      description,
                      style: theme.typography.small.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: theme.spacing.m),
              _DataPrivacyTaskAction(
                label: actionLabel,
                semanticLabel: '$actionLabel：${task.label}',
                onPressed: actionEnabled ? onAction : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataPrivacyTaskAction extends StatelessWidget {
  const _DataPrivacyTaskAction({
    required this.label,
    required this.semanticLabel,
    this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      builder: (context, state, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: state.hovered ? theme.color.brandTint : theme.color.sunken,
          border: Border.all(
            color: state.focused ? theme.color.brandStrong : theme.color.border,
            width: theme.layout.controlBorder,
          ),
          borderRadius: BorderRadius.circular(theme.radius.full),
        ),
        child: child,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: theme.control.regular * 2,
          minHeight: theme.control.minimumTarget,
        ),
        child: Center(
          child: Text(
            label,
            style: theme.typography.body.copyWith(
              color: onPressed == null
                  ? theme.color.muted
                  : theme.color.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
