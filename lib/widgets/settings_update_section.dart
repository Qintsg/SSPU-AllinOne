/*
 * 设置页应用更新组件 — 在常规设置中检查 GitHub Release 更新
 * @Project : SSPU-AllinOne
 * @File : settings_update_section.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import '../design/fluent_ui.dart';
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
  bool _isChecking = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text('应用更新', style: textTheme.titleMedium),
            ),
            const SizedBox(height: AppSpacing.md),
            buildResponsiveSettingsRow(
              context: context,
              icon: Icons.system_update_alt_outlined,
              title: Text('检查更新', style: textTheme.titleSmall),
              subtitle: Text(
                '从 GitHub Release 查询正式版或测试版更新，不会在启动时自动联网',
                style: textTheme.bodySmall,
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
                        : const Icon(Icons.refresh),
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
    final onPressed = _isChecking
        ? null
        : () => setState(() => _channel = channel);
    if (selected) {
      return FluentButton.primary(onPressed: onPressed, child: Text(label));
    }
    return FluentButton.outline(onPressed: onPressed, child: Text(label));
  }

  Widget _buildErrorMessage(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.onErrorContainer),
      ),
    );
  }

  Widget _buildResult(BuildContext context, AppUpdateCheckResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final release = result.release;
    final asset = result.recommendedAsset;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_resultIcon(result.status), color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.message, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      release == null
                          ? '当前版本：${result.currentVersion}'
                          : '当前版本：${result.currentVersion} · 最新版本：${release.version}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('打开 Release'),
                ),
                if (asset != null)
                  FluentButton.primaryIcon(
                    onPressed: asset.downloadUrl.isEmpty
                        ? null
                        : () => _openExternalUrl(asset.downloadUrl),
                    icon: const Icon(Icons.download),
                    label: Text('下载 ${asset.displaySize}'),
                  ),
              ],
            ),
            if (asset != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '推荐资产：${asset.name}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  IconData _resultIcon(AppUpdateStatus status) {
    return switch (status) {
      AppUpdateStatus.available => Icons.system_update_alt,
      AppUpdateStatus.upToDate => Icons.check_circle_outline,
      AppUpdateStatus.unavailable => Icons.info_outline,
    };
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _result = null;
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
}
