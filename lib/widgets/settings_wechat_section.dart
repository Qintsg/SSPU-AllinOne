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
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '公众号平台认证',
                style: theme.typography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              YhChip(
                label: _controller.wxmpAuthenticated ? '已认证' : '未认证',
                selected: _controller.wxmpAuthenticated,
              ),
            ],
          ),
          if (_controller.wxmpAuthStatus != null) ...[
            SizedBox(height: theme.spacing.xs),
            Text(
              _controller.wxmpAuthStatus!.message,
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
          ],
          SizedBox(height: theme.spacing.s),
          YhSelectableText(
            _controller.wxmpConfigPath.isEmpty
                ? '认证配置路径加载中...'
                : '配置文件：${_controller.wxmpConfigPath}',
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
          if (_controller.wxmpConfigMessage.isNotEmpty) ...[
            SizedBox(height: theme.spacing.xs),
            Text(
              _controller.wxmpConfigMessage,
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
          ],
          SizedBox(height: theme.spacing.m),
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            children: [
              YhButton(
                label: '扫码登录',
                onTap: _openWxmpLogin,
                leadingIcon: YhIcons.qrCode,
              ),
              YhButton(
                label: '编辑配置文件',
                onTap: _openConfigEditor,
                leadingIcon: YhIcons.edit,
                variant: YhButtonVariant.secondary,
              ),
              YhButton(
                label: _controller.wxmpValidating ? '校验中' : '重新加载配置并校验',
                onTap: _controller.wxmpValidating
                    ? null
                    : () async =>
                          _showFeedback(await _controller.reloadConfigFile()),
                disabled: _controller.wxmpValidating,
                leadingIcon: _controller.wxmpValidating ? null : YhIcons.sync,
                variant: YhButtonVariant.secondary,
              ),
              YhButton(
                label: '清除认证',
                onTap: _controller.wxmpAuthenticated
                    ? () async => _showFeedback(await _controller.clearAuth())
                    : null,
                disabled: !_controller.wxmpAuthenticated,
                variant: YhButtonVariant.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
