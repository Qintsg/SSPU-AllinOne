/*
 * 设置页应用更新组件 — 在常规设置中检查 GitHub Release 更新
 * @Project : SSPU-AllinOne
 * @File : settings_update_section.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'dart:async';

import '../design/qingyuan/qingyuan_ui.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_update_service.dart';
import '../services/http_service.dart';
import 'settings_widgets.dart';

part 'settings_update_task_ledger.dart';
part 'settings_update_operations.dart';

enum _UpdateErrorKind { check, releaseOpen }

/// 常规设置中的应用更新摘要，完整操作统一进入独立任务页。
class SettingsUpdateSummary extends StatelessWidget {
  const SettingsUpdateSummary({super.key, this.onOpenDetails});

  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('更新与版本', style: theme.typography.h3),
          SizedBox(height: theme.spacing.s),
          Text(
            '手动检查 GitHub Releases，下载后必须通过 SHA-256 校验才能打开安装入口。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          if (onOpenDetails != null) ...[
            SizedBox(height: theme.spacing.m),
            YhButton(
              label: '打开应用更新',
              variant: YhButtonVariant.secondary,
              onTap: onOpenDetails,
            ),
          ],
        ],
      ),
    );
  }
}

/// 设置页应用更新检查卡片。
class SettingsUpdateSection extends StatefulWidget {
  /// 更新服务，测试中可注入 fake。
  final AppUpdateService updateService;

  /// 打开外部链接回调，测试中可替换。
  final Future<bool> Function(Uri uri)? launchUrlOverride;

  /// 是否使用独立清源任务页框架。
  final bool taskPage;

  SettingsUpdateSection({
    super.key,
    AppUpdateService? updateService,
    this.launchUrlOverride,
    this.taskPage = false,
  }) : updateService = updateService ?? AppUpdateService.instance;

  @override
  State<SettingsUpdateSection> createState() => _SettingsUpdateSectionState();
}

class _SettingsUpdateSectionState extends State<SettingsUpdateSection> {
  AppUpdateChannel _channel = AppUpdateChannel.stable;
  AppUpdateCheckResult? _result;
  AppUpdateDownloadProgress? _downloadProgress;
  AppUpdateDownloadResult? _downloadResult;
  AppUpdateOpenResult? _openResult;
  CancelToken? _downloadCancelToken;
  bool _isChecking = false;
  bool _isDownloading = false;
  bool _isOpening = false;
  bool _isOpeningExternal = false;
  String? _errorMessage;
  _UpdateErrorKind? _errorKind;
  String? _currentVersion;
  String? _versionError;
  int _operationGeneration = 0;
  int _externalOpenGeneration = 0;

  bool get _isBusy =>
      _isChecking || _isDownloading || _isOpening || _isOpeningExternal;

  @override
  void initState() {
    super.initState();
    if (widget.taskPage) unawaited(_loadCurrentVersion());
  }

  @override
  void didUpdateWidget(SettingsUpdateSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final serviceChanged = !identical(
      oldWidget.updateService,
      widget.updateService,
    );
    final launcherChanged = !identical(
      oldWidget.launchUrlOverride,
      widget.launchUrlOverride,
    );
    if (serviceChanged) {
      _operationGeneration++;
      _externalOpenGeneration++;
      _downloadCancelToken?.cancel('更新服务已变化');
      _isChecking = false;
      _isDownloading = false;
      _isOpening = false;
      _isOpeningExternal = false;
      _result = null;
      _errorMessage = null;
      _errorKind = null;
      _currentVersion = null;
      _versionError = null;
      _resetDownloadState();
    } else if (launcherChanged) {
      _externalOpenGeneration++;
      _isOpeningExternal = false;
      if (_errorKind == _UpdateErrorKind.releaseOpen) {
        _errorMessage = null;
        _errorKind = null;
      }
    }
    if (widget.taskPage && (!oldWidget.taskPage || serviceChanged)) {
      unawaited(_loadCurrentVersion());
    }
  }

  @override
  void dispose() {
    _operationGeneration++;
    _externalOpenGeneration++;
    _downloadCancelToken?.cancel('设置页已关闭');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.taskPage) return _buildTaskPage(context);
    final theme = context.yhTheme;

    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('应用更新', style: theme.typography.h3),
          ),
          SizedBox(height: theme.spacing.m),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.download,
            title: Text(
              '检查更新',
              style: theme.typography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '从 GitHub Release 查询正式版或测试版更新，不会在启动时自动联网',
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
            trailing: Wrap(
              spacing: theme.spacing.s,
              runSpacing: theme.spacing.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: theme.spacing.xs,
                  runSpacing: theme.spacing.xs,
                  children: [
                    _buildChannelOption(AppUpdateChannel.stable, '正式版'),
                    _buildChannelOption(AppUpdateChannel.preview, '测试版'),
                  ],
                ),
                YhButton(
                  label: _isChecking ? '检查中' : '检查更新',
                  onTap: _isBusy ? null : _checkForUpdates,
                  disabled: _isBusy,
                  leadingIcon: _isChecking ? null : YhIcons.refresh,
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            SizedBox(height: theme.spacing.m),
            _buildErrorMessage(context, _errorMessage!),
          ],
          if (_result != null) ...[
            SizedBox(height: theme.spacing.m),
            _buildResult(context, _result!),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelOption(AppUpdateChannel channel, String label) {
    final selected = _channel == channel;
    final disabled = _isBusy;
    final onPressed = disabled
        ? null
        : () => setState(() {
            _channel = channel;
            _resetDownloadState();
          });
    return YhButton(
      label: label,
      onTap: onPressed,
      disabled: disabled,
      variant: selected ? YhButtonVariant.primary : YhButtonVariant.secondary,
    );
  }

  Widget _buildErrorMessage(BuildContext context, String message) {
    return YhBanner(text: message, kind: YhBannerKind.danger);
  }

  Widget _buildTaskPage(BuildContext context) {
    return YhTaskPage(
      title: '应用更新',
      kicker: '设置',
      summary: '检查、可用版本和失败降级分开表达，不把网络失败误报为已是最新。',
      source: 'GitHub Releases',
      sourceSymbol: '设',
      primaryActionLabel: _isChecking ? '检查中' : '检查更新',
      onPrimaryAction: _isBusy ? null : _checkForUpdates,
      width: YhTaskPageWidth.fluid,
      bodyFit: YhTaskPageBodyFit.content,
      body: _buildTaskLedger(context),
    );
  }

  Widget _buildTaskLedger(BuildContext context) {
    final theme = context.yhTheme;
    final checkError = _errorKind == _UpdateErrorKind.check;
    const checkingAction = _UpdateLedgerAction(label: '处理中');
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_versionError != null) ...[
            YhBanner(text: _versionError!, kind: YhBannerKind.warn),
          ],
          if (_isChecking) ...[
            const _UpdateStateBanner(
              text: '正在从 GitHub Releases 恢复数据；已有页面框架与输入保持可用。',
            ),
          ],
          if (_errorMessage != null) ...[
            _UpdateStateBanner(
              text: checkError
                  ? '无法从 GitHub Releases 完成本次检查；'
                        '当前版本 ${_currentVersion ?? '未知'} 保持原有状态。'
                        '可检查网络条件后重试。'
                  : _errorMessage!,
              danger: true,
            ),
          ],
          _UpdateTaskRow(
            title:
                '${checkError ? '已完成：' : ''}当前版本 ${_currentVersion ?? '读取中'}',
            status: _isChecking
                ? '保留当前设置'
                : checkError
                ? '结果已保留'
                : _versionError == null
                ? '当前设置'
                : '版本状态暂不可用',
            action: _isChecking
                ? checkingAction
                : !checkError
                ? null
                : _UpdateLedgerAction(
                    label: '查看',
                    onPressed: _showCurrentVersion,
                  ),
          ),
          _UpdateTaskRow(
            title: '${checkError ? '未完成：' : ''}更新通道 ${_channel.name}',
            status: _isChecking
                ? '保留当前设置'
                : checkError
                ? '可安全重试'
                : '只在手动检查时联网',
            action: _isChecking
                ? checkingAction
                : _UpdateLedgerAction(
                    label: checkError ? '重试' : '切换',
                    onPressed: _isBusy
                        ? null
                        : checkError
                        ? _checkForUpdates
                        : _toggleChannel,
                  ),
          ),
          _UpdateTaskRow(
            title: '自动检查已关闭',
            status: _isChecking ? '保留当前设置' : '启动时不自动访问 GitHub',
            action: _isChecking ? checkingAction : null,
          ),
          if (_result != null) ...[
            SizedBox(height: theme.spacing.m),
            _buildResult(context, _result!),
          ],
        ],
      ),
    );
  }

  /// 在更新页面状态类内部统一提交拆分操作模块的状态更新。
  ///
  /// :param update: 需要在一次 rebuild 中应用的状态变更。
  void _setUpdateState(void Function() update) {
    if (!mounted) return;
    setState(update);
  }
}
