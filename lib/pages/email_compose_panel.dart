/*
 * 邮箱撰写面板 — 提供 SMTP 普通文本邮件发送表单
 * @Project : SSPU-AllinOne
 * @File : email_compose_panel.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

part of 'email_page.dart';

/// 邮箱撰写面板。
class EmailComposePanel extends StatelessWidget {
  const EmailComposePanel({
    super.key,
    required this.toController,
    required this.ccController,
    required this.bccController,
    required this.subjectController,
    required this.bodyController,
    required this.isSending,
    required this.severityOf,
    required this.onSend,
    this.result,
    this.onCancel,
    this.showActions = true,
  });

  /// To 收件人输入控制器。
  final TextEditingController toController;

  /// Cc 抄送输入控制器。
  final TextEditingController ccController;

  /// Bcc 密送输入控制器。
  final TextEditingController bccController;

  /// 主题输入控制器。
  final TextEditingController subjectController;

  /// 正文输入控制器。
  final TextEditingController bodyController;

  /// 是否正在发送。
  final bool isSending;

  /// 最近一次发送结果。
  final EmailSendResult? result;

  /// 查询状态到信息等级的映射。
  final YhBannerKind Function(EmailQueryStatus status) severityOf;

  /// 点击发送。
  final VoidCallback onSend;

  /// 点击取消或关闭撰写面板。
  final VoidCallback? onCancel;

  /// 是否在表单末尾显示行动区；紧凑端由页面固定提交坞承载。
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      key: const Key('email-compose-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SMTP 主动发信',
            style: theme.typography.caption.copyWith(
              color: theme.color.brandInk,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            '仅在点击发送后提交普通文本；不保存草稿，不在后台重试。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns =
                  MediaQuery.sizeOf(context).width >
                  theme.breakpoint.compact + theme.breakpoint.compact / 2;
              if (!twoColumns) {
                return Column(
                  children: [
                    _buildAddressField(
                      label: '收件人',
                      controller: toController,
                      placeholder: 'name@example.com',
                    ),
                    SizedBox(height: theme.spacing.m),
                    _buildAddressField(
                      label: '抄送',
                      controller: ccController,
                      placeholder: '可选',
                    ),
                    SizedBox(height: theme.spacing.m),
                    _buildAddressField(
                      label: '密送',
                      controller: bccController,
                      placeholder: '可选',
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildAddressField(
                    label: '收件人',
                    controller: toController,
                    placeholder: 'name@example.com',
                  ),
                  SizedBox(height: theme.spacing.m),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAddressField(
                          label: '抄送',
                          controller: ccController,
                          placeholder: '可选',
                        ),
                      ),
                      SizedBox(width: theme.spacing.s),
                      Expanded(
                        child: _buildAddressField(
                          label: '密送',
                          controller: bccController,
                          placeholder: '可选',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          SizedBox(height: theme.spacing.m),
          YhTextField(
            controller: subjectController,
            label: '主题',
            hint: '邮件主题',
            enabled: !isSending,
            showDisabledAppearance: false,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: theme.spacing.m),
          YhTextField(
            controller: bodyController,
            label: '正文',
            hint: '输入邮件正文',
            enabled: !isSending,
            showDisabledAppearance: false,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
          ),
          if (result != null) ...[
            SizedBox(height: theme.spacing.m),
            Text(result!.message, style: theme.typography.h3),
            SizedBox(height: theme.spacing.s),
            YhBanner(text: result!.detail, kind: severityOf(result!.status)),
          ],
          if (showActions) ...[
            SizedBox(height: theme.spacing.m),
            Align(
              alignment: Alignment.centerRight,
              child: EmailComposeActions(
                isSending: isSending,
                onCancel: onCancel,
                onSend: onSend,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
  }) {
    return YhTextField(
      controller: controller,
      label: label,
      hint: placeholder,
      enabled: !isSending,
      showDisabledAppearance: false,
      textInputAction: TextInputAction.next,
    );
  }
}

/// 邮件撰写的取消与提交动作组。
class EmailComposeActions extends StatelessWidget {
  const EmailComposeActions({
    super.key,
    required this.isSending,
    required this.onSend,
    this.onCancel,
  });

  /// 是否正在提交 SMTP 请求。
  final bool isSending;

  /// 点击取消。
  final VoidCallback? onCancel;

  /// 点击发送。
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Wrap(
      spacing: theme.spacing.s,
      runSpacing: theme.spacing.xs,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (onCancel != null)
          YhButton(
            label: '取消',
            variant: YhButtonVariant.secondary,
            onTap: isSending ? null : onCancel,
          ),
        YhButton(
          label: isSending ? '正在发送' : '发送邮件',
          onTap: isSending ? null : onSend,
        ),
      ],
    );
  }
}

/// 紧凑端位于页面滚动区之外的邮件撰写提交坞。
class EmailComposeActionDock extends StatelessWidget {
  const EmailComposeActionDock({
    super.key,
    required this.isSending,
    required this.onSend,
    this.onCancel,
  });

  /// 是否正在提交 SMTP 请求。
  final bool isSending;

  /// 点击取消。
  final VoidCallback? onCancel;

  /// 点击发送。
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      key: const Key('email-compose-action-dock'),
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: Border(top: BorderSide(color: theme.color.border)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: theme.spacing.s,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: theme.layout.formContentWidth,
            ),
            child: EmailComposeActions(
              isSending: isSending,
              onCancel: onCancel,
              onSend: onSend,
            ),
          ),
        ),
      ),
    );
  }
}
