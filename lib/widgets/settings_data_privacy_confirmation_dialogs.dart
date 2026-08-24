/*
 * 数据与隐私危险确认 — 明确本机删除与保留边界
 * @Project : SSPU-AllinOne
 * @File : settings_data_privacy_confirmation_dialogs.dart
 * @Author : Qintsg
 * @Date : 2026-08-17
 */

import '../design/qingyuan/qingyuan_ui.dart';

/// 数据与隐私页面支持的危险确认任务。
enum SettingsDataPrivacyConfirmationKind {
  clearCampusCache,
  disconnectAccounts,
  clearAllData,
}

/// 显示数据与隐私危险确认，并返回用户是否显式确认。
///
/// :param context: 数据与隐私页面上下文。
/// :param kind: 需要确认的删除任务。
/// :returns: 仅显式点击危险主行动时返回 true；取消或系统返回均返回 false。
Future<bool> showSettingsDataPrivacyConfirmation(
  BuildContext context, {
  required SettingsDataPrivacyConfirmationKind kind,
}) async {
  final result = await YhDialog.show<bool>(
    context,
    barrierDismissible: false,
    barrierLabel: '数据删除确认不可通过遮罩关闭',
    builder: (dialogContext) => Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(dialogContext).pop(false);
              return null;
            },
          ),
        },
        child: _SettingsDataPrivacyConfirmationDialog(
          spec: _DataPrivacyConfirmationSpec.fromKind(kind),
        ),
      ),
    ),
  );
  return result ?? false;
}

class _SettingsDataPrivacyConfirmationDialog extends StatelessWidget {
  const _SettingsDataPrivacyConfirmationDialog({required this.spec});

  /// 当前危险任务的确定性文案与行动。
  final _DataPrivacyConfirmationSpec spec;

  /// 构建含数据边界账本和明确危险行动的确认模态。
  ///
  /// :param context: 当前清源主题与导航上下文。
  /// :returns: 可键盘取消的危险确认界面。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhDialog(
      eyebrow: '数据与隐私',
      title: spec.title,
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.breakpoint.compact),
        child: SingleChildScrollView(
          child: Column(
            key: const Key('settings-data-confirmation-content'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '请先确认本机数据边界；此操作不会修改校园服务器数据。',
                style: theme.typography.body.copyWith(
                  color: theme.color.foreground,
                ),
              ),
              SizedBox(height: theme.spacing.m),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: theme.color.border,
                      width: theme.layout.divider,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DataScopeRow(
                      key: const Key('settings-data-scope-delete'),
                      icon: YhIcons.delete,
                      label: '将删除',
                      description: spec.deleting,
                      foreground: theme.color.danger,
                      background: theme.color.dangerTint,
                    ),
                    SizedBox(
                      height: theme.layout.divider,
                      child: ColoredBox(color: theme.color.border),
                    ),
                    _DataScopeRow(
                      key: const Key('settings-data-scope-retained'),
                      icon: YhIcons.check,
                      label: spec.retainedLabel,
                      description: spec.retained,
                      foreground: theme.color.brandStrong,
                      background: theme.color.brandTint,
                    ),
                  ],
                ),
              ),
              SizedBox(height: theme.spacing.m),
              Text(
                spec.consequence,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        YhButton(
          label: '取消',
          variant: YhButtonVariant.secondary,
          autofocus: true,
          onTap: () => Navigator.of(context).pop(false),
        ),
        YhButton(
          label: spec.confirmLabel,
          variant: YhButtonVariant.danger,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class _DataScopeRow extends StatelessWidget {
  const _DataScopeRow({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.foreground,
    required this.background,
  });

  /// 范围语义图标。
  final IconData icon;

  /// 范围标题。
  final String label;

  /// 具体数据范围。
  final String description;

  /// 图标与标题前景色。
  final Color foreground;

  /// 图标底色。
  final Color background;

  /// 构建单条删除或保留范围说明。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 图标、范围标题与说明组成的紧凑行。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(theme.radius.full),
            ),
            child: SizedBox.square(
              dimension: theme.spacing.xl,
              child: Icon(icon, size: theme.spacing.m, color: foreground),
            ),
          ),
          SizedBox(width: theme.spacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.typography.body.copyWith(
                    color: theme.color.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  description,
                  style: theme.typography.small.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataPrivacyConfirmationSpec {
  const _DataPrivacyConfirmationSpec({
    required this.title,
    required this.deleting,
    required this.retainedLabel,
    required this.retained,
    required this.consequence,
    required this.confirmLabel,
  });

  /// 模态标题。
  final String title;

  /// 将从本机删除的数据范围。
  final String deleting;

  /// 保留范围标题。
  final String retainedLabel;

  /// 仍保留或不会删除的数据范围。
  final String retained;

  /// 操作完成后的明确后果。
  final String consequence;

  /// 危险主行动文案。
  final String confirmLabel;

  /// 从任务类型解析不可变的展示契约。
  ///
  /// :param kind: 数据危险任务。
  /// :returns: 对应任务的标题、范围与行动文案。
  factory _DataPrivacyConfirmationSpec.fromKind(
    SettingsDataPrivacyConfirmationKind kind,
  ) {
    return switch (kind) {
      SettingsDataPrivacyConfirmationKind.clearCampusCache =>
        const _DataPrivacyConfirmationSpec(
          title: '清除校园缓存？',
          deleting: '教务、课表、校园卡、体育、第二课堂、学校邮箱和信息中心的本地缓存。',
          retainedLabel: '仍会保留',
          retained: '账户凭据、主题、通知、首页设置和关注列表。',
          consequence: '只清理本机缓存；校园服务器上的数据不受影响。',
          confirmLabel: '清除校园缓存',
        ),
      SettingsDataPrivacyConfirmationKind.disconnectAccounts =>
        const _DataPrivacyConfirmationSpec(
          title: '断开账户连接？',
          deleting: 'OA、体育与邮箱凭据和登录会话、账户关联的校园缓存、微信公众号 Cookie 与 Token。',
          retainedLabel: '仍会保留',
          retained: '主题、通知、首页设置、关注列表和信息中心缓存。',
          consequence: '断开后可重新连接；不会删除校园或公众号平台账号。',
          confirmLabel: '断开连接',
        ),
      SettingsDataPrivacyConfirmationKind.clearAllData =>
        const _DataPrivacyConfirmationSpec(
          title: '清除全部本地数据？',
          deleting: '全部校园凭据、微信连接、校园与信息缓存，以及主题、通知、首页和关注设置。',
          retainedLabel: '不会删除',
          retained: '系统账户、设备生物识别信息和校园服务器上的数据。',
          consequence: '清除完成后应用会退出。',
          confirmLabel: '清除本地数据',
        ),
    };
  }
}
