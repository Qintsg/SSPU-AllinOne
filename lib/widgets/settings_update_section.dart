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
    if (widget.taskPage &&
        (!oldWidget.taskPage ||
            oldWidget.updateService != widget.updateService)) {
      unawaited(_loadCurrentVersion());
    }
  }

  @override
  void dispose() {
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
      body: _buildTaskLedger(context),
    );
  }

  Widget _buildTaskLedger(BuildContext context) {
    final theme = context.yhTheme;
    final checkError = _errorKind == _UpdateErrorKind.check;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    if (compact &&
        !_isBusy &&
        _result == null &&
        _errorMessage == null &&
        _versionError == null) {
      return _buildCompactInitial(context);
    }
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

  Widget _buildCompactInitial(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: theme.control.regular * 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: theme.spacing.l),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.color.brandTint,
                borderRadius: BorderRadius.circular(theme.radius.input),
              ),
              child: SizedBox.square(
                dimension: theme.control.regular + theme.control.regular / 2,
                child: Icon(
                  YhIcons.open,
                  color: theme.color.brandStrong,
                  size: theme.spacing.xl2,
                ),
              ),
            ),
            SizedBox(height: theme.spacing.m),
            const YhStatusPill(label: '尚未开始'),
            SizedBox(height: theme.spacing.s),
            Text('尚未读取应用更新', style: theme.typography.h2),
            SizedBox(height: theme.spacing.s),
            Text(
              '先确认 GitHub Releases 的访问范围，再由你决定是否开始。',
              textAlign: TextAlign.center,
              style: theme.typography.body.copyWith(color: theme.color.muted),
            ),
            SizedBox(height: theme.spacing.m),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: theme.spacing.s,
              runSpacing: theme.spacing.xs,
              children: [
                YhStatusPill(label: '当前版本 ${_currentVersion ?? '读取中'}'),
                YhStatusPill(label: '更新通道 ${_channel.name}'),
                const YhStatusPill(label: '自动检查已关闭'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrentVersion() {
    YhBottomDrawer.show<void>(
      context,
      title: '当前版本',
      builder: (drawerContext) {
        final theme = drawerContext.yhTheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_currentVersion ?? '暂时无法读取'),
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

  void _toggleChannel() {
    if (_isBusy) return;
    setState(() {
      _channel = _channel == AppUpdateChannel.stable
          ? AppUpdateChannel.preview
          : AppUpdateChannel.stable;
      _result = null;
      _errorMessage = null;
      _errorKind = null;
      _resetDownloadState();
    });
  }

  Widget _buildResult(BuildContext context, AppUpdateCheckResult result) {
    final theme = context.yhTheme;
    final release = result.release;
    final resolvedAsset = result.recommendedAsset;
    final asset = resolvedAsset?.asset;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.sunken,
        borderRadius: BorderRadius.circular(theme.radius.input),
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _resultIcon(result.status),
                  color: theme.color.brandStrong,
                ),
                SizedBox(width: theme.spacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.message,
                        style: theme.typography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: theme.spacing.xs),
                      Text(
                        release == null
                            ? '当前版本：${result.currentVersion}'
                            : '当前版本：${result.currentVersion} · 最新版本：${release.version}',
                        style: theme.typography.small.copyWith(
                          color: theme.color.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (release != null) ...[
              SizedBox(height: theme.spacing.m),
              Wrap(
                spacing: theme.spacing.s,
                runSpacing: theme.spacing.s,
                children: [
                  YhButton(
                    label: _isOpeningExternal ? '打开中' : '打开 Release',
                    onTap: release.htmlUrl.isEmpty || _isOpeningExternal
                        ? null
                        : () => _openExternalUrl(release.htmlUrl),
                    disabled: release.htmlUrl.isEmpty || _isOpeningExternal,
                    leadingIcon: YhIcons.open,
                    variant: YhButtonVariant.secondary,
                  ),
                  if (resolvedAsset?.installSupport ==
                      AppUpdateInstallSupport.supported)
                    YhButton(
                      label: _isDownloading ? '下载中' : '下载并校验',
                      onTap: _canStartDownload(resolvedAsset!)
                          ? () => _startDownload(release, resolvedAsset)
                          : null,
                      disabled: !_canStartDownload(resolvedAsset),
                      leadingIcon: _isDownloading ? null : YhIcons.download,
                    ),
                  if (_isDownloading)
                    YhButton(
                      label: '取消',
                      onTap: _cancelDownload,
                      leadingIcon: YhIcons.close,
                      variant: YhButtonVariant.secondary,
                    ),
                  if (_downloadResult?.isVerified == true)
                    YhButton(
                      label: _isOpening
                          ? '打开中'
                          : resolvedAsset?.openActionLabel ?? '打开安装入口',
                      onTap: _isOpening ? null : _openInstaller,
                      disabled: _isOpening,
                      leadingIcon: _isOpening ? null : YhIcons.open,
                    ),
                ],
              ),
              if (asset != null) ...[
                SizedBox(height: theme.spacing.s),
                _buildAssetSummary(context, resolvedAsset!),
              ],
              if (resolvedAsset?.installSupport ==
                  AppUpdateInstallSupport.unsupported) ...[
                SizedBox(height: theme.spacing.s),
                _buildStatusMessage(
                  context,
                  '当前平台不支持在应用内打开本地安装入口，请使用 GitHub Release 页面下载。',
                  kind: YhBannerKind.warn,
                ),
              ],
              if (resolvedAsset != null && !resolvedAsset.hasChecksum) ...[
                SizedBox(height: theme.spacing.s),
                _buildStatusMessage(
                  context,
                  '未找到 SHA-256 校验值，应用会阻止打开安装入口。',
                  kind: YhBannerKind.warn,
                ),
              ],
              if (_downloadProgress != null || _isDownloading) ...[
                SizedBox(height: theme.spacing.m),
                _buildDownloadProgress(context),
              ],
              if (_downloadResult != null) ...[
                SizedBox(height: theme.spacing.s),
                _buildStatusMessage(
                  context,
                  _downloadResult!.message ??
                      _downloadStatusLabel(_downloadResult!.status),
                  kind: _downloadResult!.isVerified
                      ? YhBannerKind.success
                      : _downloadResult!.status ==
                            AppUpdateDownloadStatus.canceled
                      ? YhBannerKind.info
                      : YhBannerKind.danger,
                ),
              ],
              if (_openResult != null) ...[
                SizedBox(height: theme.spacing.s),
                _buildStatusMessage(
                  context,
                  _openResult!.message,
                  kind: _openResult!.isOpened
                      ? YhBannerKind.success
                      : YhBannerKind.warn,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  IconData _resultIcon(AppUpdateStatus status) {
    return switch (status) {
      AppUpdateStatus.available => YhIcons.download,
      AppUpdateStatus.upToDate => YhIcons.check,
      AppUpdateStatus.unavailable => YhIcons.info,
    };
  }

  Widget _buildAssetSummary(
    BuildContext context,
    AppUpdateResolvedAsset resolvedAsset,
  ) {
    final theme = context.yhTheme;
    final mutedStyle = theme.typography.small.copyWith(
      color: theme.color.muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '推荐资产：${resolvedAsset.asset.name}',
          style: mutedStyle,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        SizedBox(height: theme.spacing.xs),
        Wrap(
          spacing: theme.spacing.s,
          runSpacing: theme.spacing.xs,
          children: [
            Text(resolvedAsset.asset.displaySize, style: mutedStyle),
            Text(
              '${resolvedAsset.platform} / ${resolvedAsset.arch}',
              style: mutedStyle,
            ),
            Text(
              '校验来源：${resolvedAsset.checksumSourceLabel}',
              style: mutedStyle,
            ),
          ],
        ),
        if (resolvedAsset.isPortable) ...[
          SizedBox(height: theme.spacing.xs),
          Text('便携压缩包需要手动替换应用文件，应用不会自动解压或覆盖。', style: mutedStyle),
        ],
      ],
    );
  }

  Widget _buildDownloadProgress(BuildContext context) {
    final theme = context.yhTheme;
    final progress = _downloadProgress;
    final percent = progress?.percent;
    final percentText = percent == null
        ? '准备下载'
        : '${(percent * 100).toStringAsFixed(0)}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        YhProgress(value: percent, showPercent: false, semanticLabel: '更新下载进度'),
        SizedBox(height: theme.spacing.xs),
        Wrap(
          spacing: theme.spacing.s,
          runSpacing: theme.spacing.xs,
          children: [
            Text(percentText, style: theme.typography.small),
            Text(
              progress?.displayText ?? '等待网络响应',
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusMessage(
    BuildContext context,
    String message, {
    required YhBannerKind kind,
  }) {
    return YhBanner(text: message, kind: kind);
  }

  Future<void> _checkForUpdates() async {
    if (_isBusy) return;
    _downloadCancelToken?.cancel('重新检查更新');
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _errorKind = null;
      _result = null;
      _resetDownloadState();
    });

    try {
      final result = await widget.updateService.checkForUpdates(
        channel: _channel,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _currentVersion = result.currentVersion;
        _versionError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = HttpService.describeError(error);
        _errorKind = _UpdateErrorKind.check;
      });
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _openExternalUrl(String url) async {
    if (_isBusy) return;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Release 链接无效，无法打开。';
          _errorKind = _UpdateErrorKind.releaseOpen;
        });
      }
      return;
    }
    setState(() {
      _isOpeningExternal = true;
      _errorMessage = null;
      _errorKind = null;
    });
    try {
      final launcher = widget.launchUrlOverride;
      final opened = launcher != null
          ? await launcher(uri)
          : await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        setState(() {
          _errorMessage = '系统未能打开 Release 页面，可稍后重试。';
          _errorKind = _UpdateErrorKind.releaseOpen;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '打开 Release 页面失败：${HttpService.describeError(error)}';
        _errorKind = _UpdateErrorKind.releaseOpen;
      });
    } finally {
      if (mounted) setState(() => _isOpeningExternal = false);
    }
  }

  bool _canStartDownload(AppUpdateResolvedAsset asset) {
    return !_isChecking &&
        !_isDownloading &&
        !_isOpening &&
        !_isOpeningExternal &&
        asset.asset.downloadUrl.isNotEmpty &&
        asset.hasChecksum &&
        asset.installSupport == AppUpdateInstallSupport.supported;
  }

  Future<void> _startDownload(
    AppReleaseInfo release,
    AppUpdateResolvedAsset asset,
  ) async {
    if (_isBusy) return;
    final cancelToken = CancelToken();
    setState(() {
      _isDownloading = true;
      _downloadCancelToken = cancelToken;
      _downloadProgress = null;
      _downloadResult = null;
      _openResult = null;
      _errorMessage = null;
      _errorKind = null;
    });

    try {
      final result = await widget.updateService.downloadAndVerify(
        release,
        asset,
        cancelToken: cancelToken,
        onReceiveProgress: (progress) {
          if (!mounted) return;
          setState(() => _downloadProgress = progress);
        },
      );
      if (!mounted) return;
      setState(() => _downloadResult = result);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _downloadResult = AppUpdateDownloadResult(
          status: AppUpdateDownloadStatus.failed,
          asset: asset,
          filePath: null,
          message: HttpService.describeError(error),
          actualSha256: null,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          if (_downloadCancelToken == cancelToken) {
            _downloadCancelToken = null;
          }
        });
      }
    }
  }

  void _cancelDownload() {
    _downloadCancelToken?.cancel('用户取消下载');
  }

  Future<void> _openInstaller() async {
    final result = _downloadResult;
    if (result == null || _isBusy) return;
    setState(() {
      _isOpening = true;
      _openResult = null;
      _errorMessage = null;
      _errorKind = null;
    });
    try {
      final openResult = await widget.updateService.openVerifiedDownload(
        result,
      );
      if (!mounted) return;
      setState(() => _openResult = openResult);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _openResult = AppUpdateOpenResult(
          status: AppUpdateOpenStatus.failed,
          message: '打开安装入口失败：$error',
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  void _resetDownloadState() {
    _downloadProgress = null;
    _downloadResult = null;
    _openResult = null;
    _downloadCancelToken = null;
    _isDownloading = false;
    _isOpening = false;
  }

  String _downloadStatusLabel(AppUpdateDownloadStatus status) {
    return switch (status) {
      AppUpdateDownloadStatus.downloading => '正在下载。',
      AppUpdateDownloadStatus.verified => '安装包校验通过。',
      AppUpdateDownloadStatus.canceled => '下载已取消。',
      AppUpdateDownloadStatus.failed => '下载或校验失败。',
    };
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final version = await widget.updateService.loadCurrentVersion();
      if (!mounted) return;
      setState(() {
        _currentVersion = version;
        _versionError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _versionError = '无法读取当前应用版本；仍可手动检查 Release。');
    }
  }
}

class _UpdateStateBanner extends StatelessWidget {
  const _UpdateStateBanner({required this.text, this.danger = false});

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

class _UpdateTaskRow extends StatelessWidget {
  const _UpdateTaskRow({
    required this.title,
    required this.status,
    this.action,
  });

  final String title;
  final String status;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
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
                        fontWeight: theme.typography.h2.fontWeight,
                      ),
                    ),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      status,
                      style: theme.typography.small.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                SizedBox(width: theme.spacing.m),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateLedgerAction extends StatelessWidget {
  const _UpdateLedgerAction({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: label,
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
