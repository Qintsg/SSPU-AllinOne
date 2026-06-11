/*
 * 设置页微信分区组件 — 公众号平台认证、刷新设置与 SSPU 微信矩阵
 * @Project : SSPU-AllinOne
 * @File : settings_wechat_section.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import '../design/fluent_ui.dart';

import '../controllers/settings_wechat_controller.dart';
import '../services/wxmp_config_service.dart';
import '../theme/fluent_tokens.dart';
import '../utils/webview_env.dart';
import 'app_feedback.dart';
import 'settings_wechat_config_dialog.dart';
import 'settings_wechat_matrix_card.dart';
import 'settings_wechat_refresh_card.dart';
import '../pages/wxmp_login_page.dart';

/// 微信推文设置分区。
class SettingsWechatSection extends StatefulWidget {
  /// 测试可注入已加载控制器，避免 widget test 的 fake async 阻塞文件 I/O。
  @visibleForTesting
  final SettingsWechatController? controller;

  const SettingsWechatSection({super.key, this.controller});

  @override
  State<SettingsWechatSection> createState() => _SettingsWechatSectionState();
}

class _SettingsWechatSectionState extends State<SettingsWechatSection> {
  late final SettingsWechatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SettingsWechatController();
    _controller.load();
  }

  Future<void> _showFeedback(SettingsWechatFeedback feedback) async {
    if (!mounted) return;
    showFluentInfoBar(
      context,
      title: Text(feedback.title),
      content: feedback.content == null ? null : Text(feedback.content!),
      severity: feedback.severity,
      actionBuilder: (close) => FluentIconButton(
        icon: const Icon(FluentIcons.clear),
        onPressed: close,
      ),
    );
  }

  Future<void> _openWxmpLogin() async {
    final webViewEnvironment = await ensureGlobalWebViewEnvironment();
    if (!mounted) return;

    final success = await Navigator.of(context).push<bool>(
      FluentPageRoute(
        builder: (_) => WxmpLoginPage(webViewEnvironment: webViewEnvironment),
      ),
    );
    if (success == true) {
      await _showFeedback(await _controller.handleLoginSuccess());
    }
  }

  Future<void> _openConfigEditor() async {
    late final WxmpConfig initialConfig;
    try {
      initialConfig = await _controller.loadConfig();
    } catch (error) {
      await _showFeedback(
        SettingsWechatFeedback(
          title: '读取配置文件失败',
          content: '$error',
          severity: FluentInfoSeverity.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    final savedConfig = await showSettingsWechatConfigDialog(
      context: context,
      initialConfig: initialConfig,
    );

    if (savedConfig == null) return;
    await _showFeedback(await _controller.saveConfig(savedConfig));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Center(child: FluentProgressRing());
        }

        final theme = FluentTheme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('微信推文消息获取', style: theme.typography.subtitle),
            const SizedBox(height: FluentSpacing.l),
            SettingsWechatRefreshCard(
              manualFetchCount: _controller.wechatManualFetchCount,
              autoRefreshEnabled: _controller.wechatAutoRefreshEnabled,
              refreshInterval: _controller.wechatRefreshInterval,
              autoFetchCount: _controller.wechatAutoFetchCount,
              onManualFetchCountChanged: (value) =>
                  _controller.setManualFetchCount(value),
              onAutoRefreshChanged: (value) =>
                  _controller.setAutoRefreshEnabled(value),
              onRefreshIntervalChanged: (value) =>
                  _controller.setRefreshInterval(value),
              onAutoFetchCountChanged: (value) =>
                  _controller.setAutoFetchCount(value),
              onEnableAll: () async =>
                  _showFeedback(await _controller.setWechatPageEnabled(true)),
              onDisableAll: () async =>
                  _showFeedback(await _controller.setWechatPageEnabled(false)),
            ),
            const SizedBox(height: FluentSpacing.l),
            _buildAuthCard(theme),
            const SizedBox(height: FluentSpacing.l),
            SettingsWechatMatrixCard(
              authenticated: _controller.wxmpAuthenticated,
              batchFollowing: _controller.wxmpBatchFollowing,
              batchProgress: _controller.wxmpBatchProgress,
              mpNotificationEnabled: _controller.wxmpMpNotificationEnabled,
              followedMps: _controller.wxmpFollowedMps,
              followingAccountId: _controller.wxmpFollowingAccountId,
              onBatchFollow: () async =>
                  _showFeedback(await _controller.batchFollowSspuWxmp()),
              onToggleAccount: (account, enabled) async => _showFeedback(
                await _controller.toggleSspuAccount(account, enabled),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAuthCard(FluentThemeData theme) {
    final statusTone = _controller.wxmpAuthenticated
        ? FluentStatusChipTone.success
        : FluentStatusChipTone.warning;

    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: FluentSpacing.s,
              runSpacing: FluentSpacing.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('公众号平台认证', style: theme.typography.bodyStrong),
                FluentStatusChip(
                  label: _controller.wxmpAuthenticated ? '已认证' : '未认证',
                  tone: statusTone,
                  icon: _controller.wxmpAuthenticated
                      ? FluentIcons.checkMark
                      : FluentIcons.warning,
                ),
              ],
            ),
            if (_controller.wxmpAuthStatus != null) ...[
              const SizedBox(height: FluentSpacing.xs),
              Text(
                _controller.wxmpAuthStatus!.message,
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorSecondary,
                ),
              ),
            ],
            const SizedBox(height: FluentSpacing.s),
            SelectableText(
              _controller.wxmpConfigPath.isEmpty
                  ? '认证配置路径加载中...'
                  : '配置文件：${_controller.wxmpConfigPath}',
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
            if (_controller.wxmpConfigMessage.isNotEmpty) ...[
              const SizedBox(height: FluentSpacing.xxs),
              Text(
                _controller.wxmpConfigMessage,
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorSecondary,
                ),
              ),
            ],
            const SizedBox(height: FluentSpacing.m),
            Wrap(
              spacing: FluentSpacing.s,
              runSpacing: FluentSpacing.s,
              children: [
                FluentButton.primary(
                  onPressed: _openWxmpLogin,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.qrCode, size: 14),
                      SizedBox(width: FluentSpacing.xs + FluentSpacing.xxs),
                      Text('扫码登录'),
                    ],
                  ),
                ),
                FluentButton.outline(
                  onPressed: _openConfigEditor,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.edit, size: 14),
                      SizedBox(width: FluentSpacing.xs + FluentSpacing.xxs),
                      Text('编辑配置文件'),
                    ],
                  ),
                ),
                FluentButton.outline(
                  onPressed: _controller.wxmpValidating
                      ? null
                      : () async =>
                            _showFeedback(await _controller.reloadConfigFile()),
                  child: _controller.wxmpValidating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: FluentProgressRing(strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FluentIcons.sync, size: 14),
                            SizedBox(
                              width: FluentSpacing.xs + FluentSpacing.xxs,
                            ),
                            Text('重新加载配置并校验'),
                          ],
                        ),
                ),
                FluentButton.outline(
                  onPressed: _controller.wxmpAuthenticated
                      ? () async => _showFeedback(await _controller.clearAuth())
                      : null,
                  child: const Text('清除认证'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
