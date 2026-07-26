/* 清源数据与隐私任务页。 */

import 'dart:async';

import '../design/qingyuan/qingyuan_ui.dart';
import '../widgets/settings_security_section.dart';

class SettingsDataPrivacySnapshot {
  const SettingsDataPrivacySnapshot({
    this.cacheStatus = '当前设置',
    this.accountStatus = '保存在本机',
    this.privacyStatus = '保存在本机',
  });

  final String cacheStatus;
  final String accountStatus;
  final String privacyStatus;
}

class SettingsDataPrivacyOperationException implements Exception {
  const SettingsDataPrivacyOperationException({
    required this.completedItems,
    required this.remainingItems,
  });

  final List<String> completedItems;
  final List<String> remainingItems;
}

class SettingsDataPrivacyPage extends StatefulWidget {
  const SettingsDataPrivacyPage({
    super.key,
    required this.onClearCampusCache,
    required this.onDisconnectAccounts,
    required this.onOpenPrivacy,
    this.onClearAllData,
    this.state = SettingsDataPrivacyState.content,
    this.errorMessage,
    this.sourceTimestamp,
    this.loadSnapshot,
    this.snapshot = const SettingsDataPrivacySnapshot(),
  });

  final Future<bool> Function() onClearCampusCache;
  final Future<bool> Function() onDisconnectAccounts;
  final VoidCallback onOpenPrivacy;
  final Future<bool> Function()? onClearAllData;
  final SettingsDataPrivacyState state;
  final String? errorMessage;
  final String? sourceTimestamp;
  final Future<SettingsDataPrivacySnapshot> Function()? loadSnapshot;
  final SettingsDataPrivacySnapshot snapshot;

  @override
  State<SettingsDataPrivacyPage> createState() =>
      _SettingsDataPrivacyPageState();
}

class _SettingsDataPrivacyPageState extends State<SettingsDataPrivacyPage> {
  late SettingsDataPrivacyState _state;
  late List<String> _completedItems;
  late SettingsDataPrivacySnapshot _snapshot;
  String? _errorMessage;
  bool _isExecuting = false;
  bool _operationError = false;

  @override
  void initState() {
    super.initState();
    _state = widget.loadSnapshot == null
        ? widget.state
        : SettingsDataPrivacyState.loading;
    _snapshot = widget.snapshot;
    _errorMessage = widget.errorMessage;
    _operationError = widget.state == SettingsDataPrivacyState.error;
    _completedItems = widget.state == SettingsDataPrivacyState.error
        ? <String>['清除校园缓存']
        : <String>[];
    if (widget.loadSnapshot != null) unawaited(_reloadSnapshot());
  }

  @override
  void didUpdateWidget(SettingsDataPrivacyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadSnapshot != widget.loadSnapshot) {
      _snapshot = widget.snapshot;
      _completedItems = <String>[];
      _operationError = false;
      if (widget.loadSnapshot != null) unawaited(_reloadSnapshot());
    } else if (oldWidget.state != widget.state ||
        oldWidget.errorMessage != widget.errorMessage) {
      _state = widget.state;
      _errorMessage = widget.errorMessage;
      _operationError = widget.state == SettingsDataPrivacyState.error;
      _completedItems = widget.state == SettingsDataPrivacyState.error
          ? <String>['清除校园缓存']
          : <String>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return YhTaskPage(
      title: '数据与隐私',
      kicker: '设置',
      summary: '清楚列出本地缓存、账户数据和清除后果，危险行动需要二次确认。',
      source: '本机存储',
      sourceSymbol: '设',
      sourceTimestamp: widget.sourceTimestamp,
      width: YhTaskPageWidth.fluid,
      primaryActionLabel: '管理本地数据',
      onPrimaryAction: () => _showActions(context),
      body: SettingsDataPrivacySection(
        state: _state,
        errorMessage: _errorMessage,
        operationError: _operationError,
        loadingMessage: _isExecuting
            ? '正在执行本地数据操作；页面会保留已完成结果。'
            : widget.loadSnapshot == null
            ? '正在从本机存储恢复数据；已有页面框架与输入保持可用。'
            : '正在读取本机数据与账户状态。',
        clearedItems: _completedItems,
        cacheStatus: _snapshot.cacheStatus,
        accountStatus: _snapshot.accountStatus,
        privacyStatus: _snapshot.privacyStatus,
        onClearCampusCache: () =>
            _runAction(label: '清除校园缓存', action: widget.onClearCampusCache),
        onDisconnectAccounts: () =>
            _runAction(label: '断开账户连接', action: widget.onDisconnectAccounts),
        onOpenPrivacy: widget.onOpenPrivacy,
        onViewCompleted: () => _showCompletedItems(context),
      ),
    );
  }

  void _showActions(BuildContext context) {
    YhBottomDrawer.show<void>(
      context,
      title: '本地数据操作',
      builder: (drawerContext) {
        final theme = drawerContext.yhTheme;
        final busy = _state == SettingsDataPrivacyState.loading;
        void run(VoidCallback action) {
          Navigator.of(drawerContext).pop();
          action();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            YhButton(
              label: '清除校园缓存',
              variant: YhButtonVariant.danger,
              onTap: busy
                  ? null
                  : () => run(
                      () => _runAction(
                        label: '清除校园缓存',
                        action: widget.onClearCampusCache,
                      ),
                    ),
            ),
            SizedBox(height: theme.spacing.s),
            YhButton(
              label: '断开账户连接',
              variant: YhButtonVariant.danger,
              onTap: busy
                  ? null
                  : () => run(
                      () => _runAction(
                        label: '断开账户连接',
                        action: widget.onDisconnectAccounts,
                      ),
                    ),
            ),
            SizedBox(height: theme.spacing.s),
            YhButton(
              label: '查看隐私说明',
              variant: YhButtonVariant.secondary,
              onTap: busy ? null : () => run(widget.onOpenPrivacy),
            ),
            if (widget.onClearAllData != null) ...[
              SizedBox(height: theme.spacing.l),
              SizedBox(
                height: theme.layout.divider,
                child: ColoredBox(color: theme.color.border),
              ),
              SizedBox(height: theme.spacing.l),
              YhButton(
                label: '清除全部本地数据',
                variant: YhButtonVariant.danger,
                onTap: busy
                    ? null
                    : () => run(
                        () => _runAction(
                          label: '清除全部本地数据',
                          action: widget.onClearAllData!,
                        ),
                      ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showCompletedItems(BuildContext context) {
    YhBottomDrawer.show<void>(
      context,
      title: '已完成项目',
      builder: (drawerContext) {
        final theme = drawerContext.yhTheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _completedItems.isEmpty
                  ? '当前没有已完成项目。'
                  : _completedItems.join('、'),
              style: theme.typography.body.copyWith(color: theme.color.muted),
            ),
            SizedBox(height: theme.spacing.l),
            YhButton(
              label: '关闭',
              variant: YhButtonVariant.secondary,
              onTap: () => Navigator.of(drawerContext).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runAction({
    required String label,
    required Future<bool> Function() action,
  }) async {
    if (_state == SettingsDataPrivacyState.loading) return;
    setState(() {
      _state = SettingsDataPrivacyState.loading;
      _errorMessage = null;
      _isExecuting = true;
      _operationError = false;
    });
    try {
      final completed = await action();
      if (!mounted) return;
      if (!completed) {
        setState(() {
          _state = SettingsDataPrivacyState.content;
          _isExecuting = false;
        });
        return;
      }
      if (!_completedItems.contains(label)) _completedItems.add(label);
      var snapshot = _snapshot;
      if (widget.loadSnapshot != null) {
        try {
          snapshot = await widget.loadSnapshot!();
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _state = SettingsDataPrivacyState.error;
            _isExecuting = false;
            _operationError = true;
            _errorMessage = '操作已完成，但未能刷新本机状态。\n已完成：$label\n未完成：状态刷新';
          });
          return;
        }
        if (!mounted) return;
      }
      setState(() {
        _snapshot = snapshot;
        _state = SettingsDataPrivacyState.content;
        _isExecuting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = SettingsDataPrivacyState.error;
        _isExecuting = false;
        _operationError = true;
        if (error is SettingsDataPrivacyOperationException) {
          _errorMessage = _operationErrorMessage(error);
          _completedItems.addAll(
            error.completedItems.where(
              (item) => !_completedItems.contains(item),
            ),
          );
        } else {
          _errorMessage = '本次操作未完成。\n已完成：无\n未完成：$label';
        }
      });
    }
  }

  Future<void> _reloadSnapshot() async {
    final loader = widget.loadSnapshot;
    if (loader == null) return;
    if (mounted) {
      setState(() {
        _state = SettingsDataPrivacyState.loading;
        _isExecuting = false;
        _operationError = false;
        _errorMessage = null;
      });
    }
    try {
      final snapshot = await loader();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _state = SettingsDataPrivacyState.content;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = SettingsDataPrivacyState.error;
        _operationError = false;
        _snapshot = const SettingsDataPrivacySnapshot(
          cacheStatus: '状态暂不可用',
          accountStatus: '状态暂不可用',
          privacyStatus: '随应用提供，可离线查看',
        );
        _errorMessage = '无法读取本机数据与账户状态；可重试操作或稍后重新进入。';
      });
    }
  }

  String _operationErrorMessage(SettingsDataPrivacyOperationException error) {
    final completed = error.completedItems.isEmpty
        ? '无'
        : error.completedItems.join('、');
    final remaining = error.remainingItems.isEmpty
        ? '无'
        : error.remainingItems.join('、');
    return '本次操作未完成。\n已完成：$completed\n未完成：$remaining';
  }
}
