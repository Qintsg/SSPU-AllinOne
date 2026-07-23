/*
 * 设置页微信分区组件 — 公众号平台认证、刷新设置与 SSPU 微信矩阵
 * @Project : SSPU-AllinOne
 * @File : settings_wechat_section.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import '../design/qingyuan/qingyuan_ui.dart';

import '../controllers/settings_wechat_controller.dart';
import '../services/wxmp_config_service.dart';
import '../utils/webview_env.dart';
import 'app_feedback.dart';
import 'settings_wechat_config_dialog.dart';
import 'settings_wechat_matrix_card.dart';
import 'settings_wechat_refresh_card.dart';
import 'settings_wechat_auth_status_card.dart';
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
    showAppFeedback(
      context,
      message: feedback.title,
      details: feedback.content,
      severity: feedback.severity,
    );
  }

  Future<void> _openWxmpLogin() async {
    final webViewEnvironment = await ensureGlobalWebViewEnvironment();
    if (!mounted) return;

    final success = await Navigator.of(context).push<bool>(
      YhPageRoute<bool>(
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
          severity: AppFeedbackSeverity.error,
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
          return Center(
            child: SizedBox(
              width: context.yhTheme.layout.statusProgressWidth,
              child: const YhProgress(showPercent: false),
            ),
          );
        }

        final theme = context.yhTheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('微信推文消息获取', style: theme.typography.h2),
            SizedBox(height: theme.spacing.l),
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
            ),
            SizedBox(height: theme.spacing.l),
            _buildAuthCard(context),
            SizedBox(height: theme.spacing.l),
            SettingsWechatMatrixCard(
              authenticated: _controller.wxmpAuthenticated,
              batchFollowing: _controller.wxmpBatchFollowing,
              batchProgress: _controller.wxmpBatchProgress,
              mpNotificationEnabled: _controller.wxmpMpNotificationEnabled,
              followedMps: _controller.wxmpFollowedMps,
              followingAccountId: _controller.wxmpFollowingAccountId,
              onBatchFollow: () async =>
                  _showFeedback(await _controller.batchFollowSspuWxmp()),
              onEnableAll: () async =>
                  _showFeedback(await _controller.setWechatMatrixEnabled(true)),
              onDisableAll: () async => _showFeedback(
                await _controller.setWechatMatrixEnabled(false),
              ),
              onToggleAccount: _controller.toggleSspuAccount,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    final message = [
      if (_controller.wxmpAuthStatus != null)
        _controller.wxmpAuthStatus!.message,
      if (_controller.wxmpConfigMessage.isNotEmpty)
        _controller.wxmpConfigMessage,
    ].join(' · ');
    return SettingsWechatAuthStatusCard(
      state: _controller.wxmpValidating
          ? SettingsWechatAuthDisplayState.loading
          : _controller.wxmpConfigMessage.contains('失败')
          ? SettingsWechatAuthDisplayState.error
          : _controller.wxmpAuthenticated
          ? SettingsWechatAuthDisplayState.content
          : SettingsWechatAuthDisplayState.initial,
      configPath: _controller.wxmpConfigPath,
      statusMessage: message.isEmpty ? '尚未连接公众号平台账号。' : message,
      onLogin: _openWxmpLogin,
      onEdit: _openConfigEditor,
      onValidate: () async =>
          _showFeedback(await _controller.reloadConfigFile()),
      onClear: _controller.wxmpAuthenticated
          ? () async => _showFeedback(await _controller.clearAuth())
          : null,
    );
  }
}
