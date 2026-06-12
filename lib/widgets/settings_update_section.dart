/*
 * 设置页应用更新组件 — 在常规设置中检查 GitHub Release 更新
 * @Project : SSPU-AllinOne
 * @File : settings_update_section.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import '../design/fluent_ui.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_update_service.dart';
import '../services/http_service.dart';
import '../theme/app_spacing.dart';
import 'settings_widgets.dart';

/// 设置页应用更新检查卡片。
class SettingsUpdateSection extends StatefulWidget {
  /// 更新服务，测试中可注入 fake。
  final AppUpdateService updateService;

  /// 打开外部链接回调，测试中可替换。
  final Future<bool> Function(Uri uri)? launchUrlOverride;

  SettingsUpdateSection({
    super.key,
    AppUpdateService? updateService,
    this.launchUrlOverride,
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
  String? _errorMessage;

  @override
  void dispose() {
    _downloadCancelToken?.cancel('设置页已关闭');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = context.fluentType;

    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('应用更新', style: type.subtitle1)),
            const SizedBox(height: AppSpacing.md),
            buildResponsiveSettingsRow(
              context: context,
              icon: FluentIcons.download,
              title: Text('检查更新', style: type.body1Strong),
              subtitle: Text(
                '从 GitHub Release 查询正式版或测试版更新，不会在启动时自动联网',
                style: type.caption1,
              ),
              trailing: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _buildChannelOption(AppUpdateChannel.stable, '正式版'),
                      _buildChannelOption(AppUpdateChannel.preview, '测试版'),
                    ],
                  ),
                  FluentButton.primaryIcon(
                    onPressed: _isChecking ? null : _checkForUpdates,
                    icon: _isChecking
                        ? const SizedBox.square(
                            dimension: 16,
                            child: FluentProgressRing(strokeWidth: 2),
                          )
                        : const Icon(FluentIcons.refresh),
                    label: Text(_isChecking ? '检查中' : '检查更新'),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildErrorMessage(context, _errorMessage!),
            ],
            if (_result != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildResult(context, _result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChannelOption(AppUpdateChannel channel, String label) {
    final selected = _channel == channel;
    final disabled = _isChecking || _isDownloading;
    final onPressed = disabled
        ? null
        : () => setState(() {
            _channel = channel;
            _resetDownloadState();
          });
    if (selected) {
      return FluentButton.primary(onPressed: onPressed, child: Text(label));
    }
    return FluentButton.outline(onPressed: onPressed, child: Text(label));
  }

  Widget _buildErrorMessage(BuildContext context, String message) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.statusDangerBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: type.caption1.copyWith(color: colors.statusDangerForeground),
      ),
    );
  }

  Widget _buildResult(BuildContext context, AppUpdateCheckResult result) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final release = result.release;
    final resolvedAsset = result.recommendedAsset;
    final asset = resolvedAsset?.asset;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.neutralBackground2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_resultIcon(result.status), color: colors.brandForeground1),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.message, style: type.body1Strong),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      release == null
                          ? '当前版本：${result.currentVersion}'
                          : '当前版本：${result.currentVersion} · 最新版本：${release.version}',
                      style: type.caption1.copyWith(
                        color: colors.neutralForeground2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (release != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FluentButton.outlineIcon(
                  onPressed: release.htmlUrl.isEmpty
                      ? null
                      : () => _openExternalUrl(release.htmlUrl),
                  icon: const Icon(FluentIcons.openInNewWindow),
                  label: const Text('打开 Release'),
                ),
                if (resolvedAsset?.installSupport ==
                    AppUpdateInstallSupport.supported)
                  FluentButton.primaryIcon(
                    onPressed: _canStartDownload(resolvedAsset!)
                        ? () => _startDownload(release, resolvedAsset)
                        : null,
                    icon: _isDownloading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: FluentProgressRing(strokeWidth: 2),
                          )
                        : const Icon(FluentIcons.download),
                    label: Text(_isDownloading ? '下载中' : '下载并校验'),
                  ),
                if (_isDownloading)
                  FluentButton.outlineIcon(
                    onPressed: _cancelDownload,
                    icon: const Icon(FluentIcons.clear),
                    label: const Text('取消'),
                  ),
                if (_downloadResult?.isVerified == true)
                  FluentButton.primaryIcon(
                    onPressed: _isOpening ? null : _openInstaller,
                    icon: _isOpening
                        ? const SizedBox.square(
                            dimension: 16,
                            child: FluentProgressRing(strokeWidth: 2),
                          )
                        : const Icon(FluentIcons.openInNewWindow),
                    label: Text(resolvedAsset?.openActionLabel ?? '打开安装入口'),
                  ),
              ],
            ),
            if (asset != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildAssetSummary(context, resolvedAsset!),
            ],
            if (resolvedAsset?.installSupport ==
                AppUpdateInstallSupport.unsupported) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildStatusMessage(
                context,
                '当前平台不支持在应用内打开本地安装入口，请使用 GitHub Release 页面下载。',
                severity: FluentInfoSeverity.warning,
              ),
            ],
            if (resolvedAsset != null && !resolvedAsset.hasChecksum) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildStatusMessage(
                context,
                '未找到 SHA-256 校验值，应用会阻止打开安装入口。',
                severity: FluentInfoSeverity.warning,
              ),
            ],
            if (_downloadProgress != null || _isDownloading) ...[
              const SizedBox(height: AppSpacing.md),
              _buildDownloadProgress(context),
            ],
            if (_downloadResult != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildStatusMessage(
                context,
                _downloadResult!.message ??
                    _downloadStatusLabel(_downloadResult!.status),
                severity: _downloadResult!.isVerified
                    ? FluentInfoSeverity.success
                    : _downloadResult!.status ==
                          AppUpdateDownloadStatus.canceled
                    ? FluentInfoSeverity.info
                    : FluentInfoSeverity.error,
              ),
            ],
            if (_openResult != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildStatusMessage(
                context,
                _openResult!.message,
                severity: _openResult!.isOpened
                    ? FluentInfoSeverity.success
                    : FluentInfoSeverity.warning,
              ),
            ],
          ],
        ],
      ),
    );
  }

  IconData _resultIcon(AppUpdateStatus status) {
    return switch (status) {
      AppUpdateStatus.available => FluentIcons.download,
      AppUpdateStatus.upToDate => FluentIcons.checkMark,
      AppUpdateStatus.unavailable => FluentIcons.info,
    };
  }

  Widget _buildAssetSummary(
    BuildContext context,
    AppUpdateResolvedAsset resolvedAsset,
  ) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '推荐资产：${resolvedAsset.asset.name}',
          style: type.caption1.copyWith(color: colors.neutralForeground2),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              resolvedAsset.asset.displaySize,
              style: type.caption1.copyWith(color: colors.neutralForeground2),
            ),
            Text(
              '${resolvedAsset.platform} / ${resolvedAsset.arch}',
              style: type.caption1.copyWith(color: colors.neutralForeground2),
            ),
            Text(
              '校验来源：${resolvedAsset.checksumSourceLabel}',
              style: type.caption1.copyWith(color: colors.neutralForeground2),
            ),
          ],
        ),
        if (resolvedAsset.isPortable) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '便携压缩包需要手动替换应用文件，应用不会自动解压或覆盖。',
            style: type.caption1.copyWith(color: colors.neutralForeground2),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloadProgress(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final progress = _downloadProgress;
    final percent = progress?.percent;
    final percentText = percent == null
        ? '准备下载'
        : '${(percent * 100).toStringAsFixed(0)}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluentProgressBar(value: percent),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            Text(percentText, style: type.caption1),
            Text(
              progress?.displayText ?? '等待网络响应',
              style: type.caption1.copyWith(color: colors.neutralForeground2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusMessage(
    BuildContext context,
    String message, {
    required FluentInfoSeverity severity,
  }) {
    return FluentInfoBar(severity: severity, title: Text(message));
  }

  Future<void> _checkForUpdates() async {
    _downloadCancelToken?.cancel('重新检查更新');
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _result = null;
      _resetDownloadState();
    });

    try {
      final result = await widget.updateService.checkForUpdates(
        channel: _channel,
      );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = HttpService.describeError(error));
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launcher = widget.launchUrlOverride;
    if (launcher != null) {
      await launcher(uri);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool _canStartDownload(AppUpdateResolvedAsset asset) {
    return !_isChecking &&
        !_isDownloading &&
        asset.asset.downloadUrl.isNotEmpty &&
        asset.hasChecksum &&
        asset.installSupport == AppUpdateInstallSupport.supported;
  }

  Future<void> _startDownload(
    AppReleaseInfo release,
    AppUpdateResolvedAsset asset,
  ) async {
    final cancelToken = CancelToken();
    setState(() {
      _isDownloading = true;
      _downloadCancelToken = cancelToken;
      _downloadProgress = null;
      _downloadResult = null;
      _openResult = null;
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
    if (result == null) return;
    setState(() {
      _isOpening = true;
      _openResult = null;
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
}
