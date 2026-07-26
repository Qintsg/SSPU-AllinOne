/* 清源微信公众号认证摘要与任务账本。 */

import '../design/qingyuan/qingyuan_ui.dart';

enum SettingsWechatAuthDisplayState { initial, loading, content, error }

/// 微信推文主分区中的只读摘要，完整操作统一进入独立任务页。
class SettingsWechatAuthSummary extends StatelessWidget {
  const SettingsWechatAuthSummary({
    super.key,
    required this.state,
    required this.statusMessage,
    this.onOpenDetails,
  });

  final SettingsWechatAuthDisplayState state;
  final String statusMessage;
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(YhIcons.connect, color: theme.color.brandStrong),
              SizedBox(width: theme.spacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('微信公众号连接', style: theme.typography.h3),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      statusMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.small.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: theme.spacing.s),
              YhStatusPill(
                label: switch (state) {
                  SettingsWechatAuthDisplayState.initial => '未连接',
                  SettingsWechatAuthDisplayState.loading => '读取中',
                  SettingsWechatAuthDisplayState.content => '已连接',
                  SettingsWechatAuthDisplayState.error => '需处理',
                },
                kind: switch (state) {
                  SettingsWechatAuthDisplayState.initial =>
                    YhStatusKind.warning,
                  SettingsWechatAuthDisplayState.loading => YhStatusKind.info,
                  SettingsWechatAuthDisplayState.content =>
                    YhStatusKind.success,
                  SettingsWechatAuthDisplayState.error => YhStatusKind.danger,
                },
              ),
            ],
          ),
          if (onOpenDetails != null) ...[
            SizedBox(height: theme.spacing.m),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: YhButton(
                label: '管理微信公众号认证',
                variant: YhButtonVariant.secondary,
                onTap: onOpenDetails,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 微信认证任务页的确定性四态账本，供生产页与视觉矩阵复用。
class SettingsWechatAuthStatusCard extends StatelessWidget {
  const SettingsWechatAuthStatusCard({
    super.key,
    required this.state,
    required this.statusMessage,
    required this.onLogin,
    required this.onValidate,
    this.showStatusBanner = false,
    this.errorCompletedStepCount = 1,
  });

  final SettingsWechatAuthDisplayState state;
  final String statusMessage;
  final VoidCallback onLogin;
  final VoidCallback onValidate;
  final bool showStatusBanner;
  final int errorCompletedStepCount;

  bool get _busy => state == SettingsWechatAuthDisplayState.loading;

  @override
  Widget build(BuildContext context) {
    return YhCard(
      child: state == SettingsWechatAuthDisplayState.initial
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showStatusBanner) ...[
                  _WechatAuthStateBanner(text: statusMessage),
                  SizedBox(height: context.yhTheme.spacing.m),
                ],
                _buildInitial(context),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_busy)
                  _WechatAuthStateBanner(text: statusMessage)
                else if (state == SettingsWechatAuthDisplayState.error)
                  _WechatAuthStateBanner(text: statusMessage, danger: true)
                else if (showStatusBanner)
                  _WechatAuthStateBanner(text: statusMessage),
                _WechatAuthTaskRow(
                  title: _taskTitle('生成登录二维码', index: 0),
                  status: _taskStatus(index: 0),
                  actionLabel: _taskAction(index: 0),
                  onTap: _busy ? null : onLogin,
                ),
                _WechatAuthTaskRow(
                  title: _taskTitle('等待手机确认', index: 1),
                  status: _taskStatus(index: 1),
                  actionLabel: _taskAction(index: 1),
                  onTap: _busy ? null : onLogin,
                ),
                _WechatAuthTaskRow(
                  title: _taskTitle('连接后只读取授权信息', index: 2),
                  status: _taskStatus(index: 2),
                  actionLabel: _taskAction(index: 2),
                  onTap: _busy ? null : onValidate,
                ),
              ],
            ),
    );
  }

  Widget _buildInitial(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.color.brandTint,
            borderRadius: BorderRadius.circular(theme.radius.input),
          ),
          child: SizedBox.square(
            dimension: theme.control.minimumTarget + theme.spacing.l,
            child: Icon(
              YhIcons.connect,
              color: theme.color.brandInk,
              size: theme.spacing.xl,
            ),
          ),
        ),
        SizedBox(height: theme.spacing.l),
        const YhStatusPill(label: '尚未开始', kind: YhStatusKind.info),
        SizedBox(height: theme.spacing.s),
        Text(
          '尚未读取微信公众号认证',
          textAlign: TextAlign.center,
          style: theme.typography.h2.copyWith(
            fontWeight: theme.typography.h1.fontWeight,
          ),
        ),
        SizedBox(height: theme.spacing.s),
        Text(
          '先确认微信公众号连接的访问范围，再由你决定是否开始。',
          textAlign: TextAlign.center,
          style: theme.typography.body.copyWith(color: theme.color.muted),
        ),
        SizedBox(height: theme.spacing.m),
        Wrap(
          spacing: theme.spacing.s,
          runSpacing: theme.spacing.s,
          alignment: WrapAlignment.center,
          children: const [
            _WechatAuthScopePill(label: '生成登录二维码'),
            _WechatAuthScopePill(label: '等待手机确认'),
            _WechatAuthScopePill(label: '连接后只读取授权信息'),
          ],
        ),
        SizedBox(height: theme.spacing.l),
        YhButton(
          label: '开始认证',
          variant: YhButtonVariant.secondary,
          onTap: onLogin,
        ),
      ],
    );
  }

  String _taskTitle(String title, {required int index}) {
    if (state == SettingsWechatAuthDisplayState.error) {
      return '${index < errorCompletedStepCount ? '已完成' : '未完成'}：$title';
    }
    return title;
  }

  String _taskStatus({required int index}) => switch (state) {
    SettingsWechatAuthDisplayState.loading => '保留当前设置',
    SettingsWechatAuthDisplayState.content => index == 0 ? '当前设置' : '保存在本机',
    SettingsWechatAuthDisplayState.error =>
      index < errorCompletedStepCount ? '结果已保留' : '可安全重试',
    SettingsWechatAuthDisplayState.initial => '尚未开始',
  };

  String _taskAction({required int index}) => switch (state) {
    SettingsWechatAuthDisplayState.loading => '处理中',
    SettingsWechatAuthDisplayState.content => index == 2 ? '重新校验' : '重新认证',
    SettingsWechatAuthDisplayState.error => index == 2 ? '重新校验' : '重新认证',
    SettingsWechatAuthDisplayState.initial => '打开',
  };
}

class _WechatAuthScopePill extends StatelessWidget {
  const _WechatAuthScopePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.sunken,
        borderRadius: BorderRadius.circular(theme.radius.full),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.s,
          vertical: theme.spacing.xs,
        ),
        child: Text(
          label,
          style: theme.typography.caption.copyWith(color: theme.color.muted),
        ),
      ),
    );
  }
}

class _WechatAuthStateBanner extends StatelessWidget {
  const _WechatAuthStateBanner({required this.text, this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
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
              color: danger ? theme.color.danger : theme.color.warning,
              fontWeight: theme.typography.h3.fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}

class _WechatAuthTaskRow extends StatelessWidget {
  const _WechatAuthTaskRow({
    required this.title,
    required this.status,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String status;
  final String actionLabel;
  final VoidCallback? onTap;

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
                  children: [
                    Text(
                      title,
                      style: theme.typography.body.copyWith(
                        fontWeight: theme.typography.h3.fontWeight,
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
              SizedBox(width: theme.spacing.m),
              YhButton(
                label: actionLabel,
                variant: YhButtonVariant.secondary,
                disabled: onTap == null,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
