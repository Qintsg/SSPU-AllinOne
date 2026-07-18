/*
 * 设置页应用更新组件 — 在常规设置中检查 GitHub Release 更新
 * @Project : SSPU-AllinOne
 * @File : settings_update_section.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import '../design/qingyuan/qingyuan_ui.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_update_service.dart';
import '../services/http_service.dart';
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
                  onTap: _isChecking ? null : _checkForUpdates,
                  disabled: _isChecking,
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
    final disabled = _isChecking || _isDownloading;
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
                    label: '打开 Release',
                    onTap: release.htmlUrl.isEmpty
                        ? null
                        : () => _openExternalUrl(release.htmlUrl),
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
                      label: resolvedAsset?.openActionLabel ?? '打开安装入口',
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
