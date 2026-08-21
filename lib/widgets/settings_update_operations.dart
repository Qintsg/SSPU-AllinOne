/*
 * 应用更新操作 — 检查、下载、校验与外部打开
 * @Project : SSPU-AllinOne
 * @File : settings_update_operations.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'settings_update_section.dart';

extension _SettingsUpdateOperations on _SettingsUpdateSectionState {
  /// 打开当前版本信息抽屉。
  ///
  /// :returns: 无返回值；抽屉关闭后结束。
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

  /// 在稳定版与预览版更新通道之间切换并清理旧结果。
  ///
  /// :returns: 无返回值。
  void _toggleChannel() {
    if (_isBusy) return;
    _setUpdateState(() {
      _channel = _channel == AppUpdateChannel.stable
          ? AppUpdateChannel.preview
          : AppUpdateChannel.stable;
      _result = null;
      _errorMessage = null;
      _errorKind = null;
      _resetDownloadState();
    });
  }

  /// 检查当前更新通道的 Release，并隔离旧代结果。
  ///
  /// :returns: 检查任务结束时完成。
  Future<void> _checkForUpdates() async {
    if (_isBusy) return;
    _downloadCancelToken?.cancel('重新检查更新');
    _setUpdateState(() {
      _isChecking = true;
      _errorMessage = null;
      _errorKind = null;
      _result = null;
      _resetDownloadState();
    });
    final generation = _operationGeneration;
    final service = widget.updateService;

    try {
      final result = await service.checkForUpdates(channel: _channel);
      if (!mounted || generation != _operationGeneration) return;
      _setUpdateState(() {
        _result = result;
        _currentVersion = result.currentVersion;
        _versionError = null;
      });
    } catch (error) {
      if (!mounted || generation != _operationGeneration) return;
      _setUpdateState(() {
        _errorMessage = HttpService.describeError(error);
        _errorKind = _UpdateErrorKind.check;
      });
    } finally {
      if (mounted && generation == _operationGeneration) {
        _setUpdateState(() => _isChecking = false);
      }
    }
  }

  /// 打开 Release 外部页面并隔离重复或迟到的结果。
  ///
  /// :param url: Release 页面地址。
  /// :returns: 外部打开任务结束时完成。
  Future<void> _openExternalUrl(String url) async {
    if (_isBusy) return;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        _setUpdateState(() {
          _errorMessage = 'Release 链接无效，无法打开。';
          _errorKind = _UpdateErrorKind.releaseOpen;
        });
      }
      return;
    }
    _setUpdateState(() {
      _isOpeningExternal = true;
      _errorMessage = null;
      _errorKind = null;
    });
    final generation = _externalOpenGeneration;
    final launcher = widget.launchUrlOverride;
    try {
      final opened = launcher != null
          ? await launcher(uri)
          : await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted && generation == _externalOpenGeneration) {
        _setUpdateState(() {
          _errorMessage = '系统未能打开 Release 页面，可稍后重试。';
          _errorKind = _UpdateErrorKind.releaseOpen;
        });
      }
    } catch (error) {
      if (!mounted || generation != _externalOpenGeneration) return;
      _setUpdateState(() {
        _errorMessage = '打开 Release 页面失败：${HttpService.describeError(error)}';
        _errorKind = _UpdateErrorKind.releaseOpen;
      });
    } finally {
      if (mounted && generation == _externalOpenGeneration) {
        _setUpdateState(() => _isOpeningExternal = false);
      }
    }
  }

  /// 判断下载行动是否满足平台安装与校验条件。
  ///
  /// :param asset: 当前 Release 的候选资产。
  /// :returns: 可以开始下载时返回 true。
  bool _canStartDownload(AppUpdateResolvedAsset asset) {
    return !_isChecking &&
        !_isDownloading &&
        !_isOpening &&
        !_isOpeningExternal &&
        asset.asset.downloadUrl.isNotEmpty &&
        asset.hasChecksum &&
        asset.installSupport == AppUpdateInstallSupport.supported;
  }

  /// 下载并校验候选安装资产，保留取消与旧代隔离语义。
  ///
  /// :param release: 当前 Release 信息。
  /// :param asset: 已解析的候选资产。
  /// :returns: 下载任务结束时完成。
  Future<void> _startDownload(
    AppReleaseInfo release,
    AppUpdateResolvedAsset asset,
  ) async {
    if (_isBusy) return;
    final cancelToken = CancelToken();
    _setUpdateState(() {
      _isDownloading = true;
      _downloadCancelToken = cancelToken;
      _downloadProgress = null;
      _downloadResult = null;
      _openResult = null;
      _errorMessage = null;
      _errorKind = null;
    });
    final generation = _operationGeneration;
    final service = widget.updateService;

    try {
      final result = await service.downloadAndVerify(
        release,
        asset,
        cancelToken: cancelToken,
        onReceiveProgress: (progress) {
          if (!mounted ||
              generation != _operationGeneration ||
              _downloadCancelToken != cancelToken) {
            return;
          }
          _setUpdateState(() => _downloadProgress = progress);
        },
      );
      if (!mounted ||
          generation != _operationGeneration ||
          _downloadCancelToken != cancelToken) {
        return;
      }
      _setUpdateState(() => _downloadResult = result);
    } catch (error) {
      if (!mounted ||
          generation != _operationGeneration ||
          _downloadCancelToken != cancelToken) {
        return;
      }
      _setUpdateState(
        () => _downloadResult = AppUpdateDownloadResult(
          status: AppUpdateDownloadStatus.failed,
          asset: asset,
          filePath: null,
          message: HttpService.describeError(error),
          actualSha256: null,
        ),
      );
    } finally {
      if (mounted && generation == _operationGeneration) {
        _setUpdateState(() {
          _isDownloading = false;
          if (_downloadCancelToken == cancelToken) {
            _downloadCancelToken = null;
          }
        });
      }
    }
  }

  /// 取消当前下载任务。
  ///
  /// :returns: 无返回值。
  void _cancelDownload() {
    _downloadCancelToken?.cancel('用户取消下载');
  }

  /// 打开已通过校验的本地安装入口。
  ///
  /// :returns: 打开任务结束时完成。
  Future<void> _openInstaller() async {
    final result = _downloadResult;
    if (result == null || _isBusy) return;
    _setUpdateState(() {
      _isOpening = true;
      _openResult = null;
      _errorMessage = null;
      _errorKind = null;
    });
    final generation = _operationGeneration;
    final service = widget.updateService;
    try {
      final openResult = await service.openVerifiedDownload(result);
      if (!mounted || generation != _operationGeneration) return;
      _setUpdateState(() => _openResult = openResult);
    } catch (error) {
      if (!mounted || generation != _operationGeneration) return;
      _setUpdateState(
        () => _openResult = AppUpdateOpenResult(
          status: AppUpdateOpenStatus.failed,
          message: '打开安装入口失败：$error',
        ),
      );
    } finally {
      if (mounted && generation == _operationGeneration) {
        _setUpdateState(() => _isOpening = false);
      }
    }
  }

  /// 清理下载、校验和安装入口结果。
  ///
  /// :returns: 无返回值。
  void _resetDownloadState() {
    _downloadProgress = null;
    _downloadResult = null;
    _openResult = null;
    _downloadCancelToken = null;
    _isDownloading = false;
    _isOpening = false;
  }

  /// 返回下载结果的用户可读状态。
  ///
  /// :param status: 下载状态。
  /// :returns: 状态说明文本。
  String _downloadStatusLabel(AppUpdateDownloadStatus status) {
    return switch (status) {
      AppUpdateDownloadStatus.downloading => '正在下载。',
      AppUpdateDownloadStatus.verified => '安装包校验通过。',
      AppUpdateDownloadStatus.canceled => '下载已取消。',
      AppUpdateDownloadStatus.failed => '下载或校验失败。',
    };
  }

  /// 异步读取当前应用版本，并隔离页面已换代的结果。
  ///
  /// :returns: 版本读取任务结束时完成。
  Future<void> _loadCurrentVersion() async {
    final generation = _operationGeneration;
    final service = widget.updateService;
    try {
      final version = await service.loadCurrentVersion();
      if (!mounted || generation != _operationGeneration) return;
      _setUpdateState(() {
        _currentVersion = version;
        _versionError = null;
      });
    } catch (_) {
      if (!mounted || generation != _operationGeneration) return;
      _setUpdateState(() => _versionError = '无法读取当前应用版本；仍可手动检查 Release。');
    }
  }
}
