/* 清源微信公众平台认证状态卡。 */

import '../design/qingyuan/qingyuan_ui.dart';

enum SettingsWechatAuthDisplayState { initial, loading, content, error }

/// 微信认证的确定性四态表面，供设置页与视觉矩阵复用。
class SettingsWechatAuthStatusCard extends StatelessWidget {
  const SettingsWechatAuthStatusCard({
    super.key,
    required this.state,
    required this.configPath,
    required this.statusMessage,
    required this.onLogin,
    required this.onEdit,
    required this.onValidate,
    this.onClear,
  });

  final SettingsWechatAuthDisplayState state;
  final String configPath;
  final String statusMessage;
  final VoidCallback onLogin;
  final VoidCallback onEdit;
  final VoidCallback onValidate;
  final VoidCallback? onClear;

  bool get _authenticated => state == SettingsWechatAuthDisplayState.content;
  bool get _busy => state == SettingsWechatAuthDisplayState.loading;

  @override
  Widget build(BuildContext context) {
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
                label: _authenticated
                    ? '已认证'
                    : _busy
                    ? '认证中'
                    : '未认证',
                selected: _authenticated,
              ),
            ],
          ),
          SizedBox(height: theme.spacing.s),
          if (_busy) ...[
            const YhProgress(showPercent: false, semanticLabel: '正在校验公众号平台认证'),
            SizedBox(height: theme.spacing.s),
          ],
          if (state == SettingsWechatAuthDisplayState.error) ...[
            YhBanner(text: statusMessage, kind: YhBannerKind.danger),
            SizedBox(height: theme.spacing.s),
          ] else
            Text(
              statusMessage,
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
          SizedBox(height: theme.spacing.s),
          YhSelectableText(
            configPath.isEmpty ? '认证配置尚未生成' : '配置文件：$configPath',
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            children: [
              YhButton(
                label: '扫码登录',
                onTap: _busy ? null : onLogin,
                disabled: _busy,
                leadingIcon: YhIcons.qrCode,
              ),
              YhButton(
                label: '编辑配置文件',
                onTap: _busy ? null : onEdit,
                disabled: _busy,
                leadingIcon: YhIcons.edit,
                variant: YhButtonVariant.secondary,
              ),
              YhButton(
                label: _busy ? '校验中' : '重新加载配置并校验',
                onTap: _busy ? null : onValidate,
                disabled: _busy,
                leadingIcon: _busy ? null : YhIcons.sync,
                variant: YhButtonVariant.secondary,
              ),
              YhButton(
                label: '清除认证',
                onTap: _busy ? null : onClear,
                disabled: _busy || onClear == null,
                variant: YhButtonVariant.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
