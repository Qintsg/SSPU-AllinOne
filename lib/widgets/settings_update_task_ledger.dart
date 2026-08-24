/*
 * 应用更新任务账本 — 结果摘要、状态横幅与任务行动
 * @Project : SSPU-AllinOne
 * @File : settings_update_task_ledger.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

part of 'settings_update_section.dart';

extension _SettingsUpdateResultView on _SettingsUpdateSectionState {
  /// 构建版本检查结果与下载、校验和打开行动。
  ///
  /// :param context: 当前清源主题上下文。
  /// :param result: 已完成的版本检查结果。
  /// :returns: 保留恢复行动的结果摘要。
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

  /// 返回版本检查结果使用的语义图标。
  ///
  /// :param status: 版本检查状态。
  /// :returns: 对应的清源语义图标。
  IconData _resultIcon(AppUpdateStatus status) => switch (status) {
    AppUpdateStatus.available => YhIcons.download,
    AppUpdateStatus.upToDate => YhIcons.check,
    AppUpdateStatus.unavailable => YhIcons.info,
  };

  /// 构建推荐安装资产的只读摘要。
  ///
  /// :param context: 当前清源主题上下文。
  /// :param resolvedAsset: 已解析的平台安装资产。
  /// :returns: 资产名称、平台、架构与校验来源摘要。
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

  /// 构建可读的下载进度与字节摘要。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 下载进度与传输文本。
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

  /// 使用清源横幅展示下载与外部打开状态。
  ///
  /// :param context: 当前清源主题上下文。
  /// :param message: 状态说明文本。
  /// :param kind: 状态严重级别。
  /// :returns: 对应语义的清源横幅。
  Widget _buildStatusMessage(
    BuildContext context,
    String message, {
    required YhBannerKind kind,
  }) => YhBanner(text: message, kind: kind);
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
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.s + theme.spacing.xs,
            vertical: theme.spacing.s + theme.spacing.xs,
          ),
          child: Text(
            text,
            style: theme.typography.small.copyWith(
              color: foreground,
              fontWeight: theme.typography.body.fontWeight,
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
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
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
                        fontWeight: theme.typography.h1.fontWeight,
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
                SizedBox(width: compact ? theme.spacing.s : theme.spacing.m),
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
          color: state.hovered ? theme.color.brandTint : theme.color.surface,
          border: Border.all(
            color: state.focused
                ? theme.color.brandStrong
                : onPressed == null
                ? theme.color.border
                : theme.color.brand,
            width: theme.layout.controlBorder,
          ),
          borderRadius: BorderRadius.circular(theme.radius.m),
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
                  : theme.color.brandStrong,
            ),
          ),
        ),
      ),
    );
  }
}
