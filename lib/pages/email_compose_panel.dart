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

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      key: const Key('email-compose-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(YhIcons.edit, color: theme.color.serviceMail),
              SizedBox(width: theme.spacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('撰写邮件', style: theme.typography.h3),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      '通过学校邮箱 SMTP 发送普通文本邮件',
                      style: theme.typography.caption.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ],
                ),
              ),
              YhChip(label: 'SMTP 发信', selected: true),
              if (onCancel != null) ...[
                SizedBox(width: theme.spacing.s),
                YhIconButton(
                  icon: YhIcons.close,
                  semanticLabel: '关闭撰写邮件',
                  onTap: isSending ? null : onCancel,
                ),
              ],
            ],
          ),
          SizedBox(height: theme.spacing.m),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns =
                  constraints.maxWidth >=
                  theme.breakpoint.compact - theme.control.compact;
              if (!twoColumns) {
                return Column(
                  children: [
                    _buildAddressField(
                      label: '收件人',
                      controller: toController,
                      placeholder: 'name@example.com',
                    ),
                    SizedBox(height: theme.spacing.s),
                    _buildAddressField(
                      label: '抄送',
                      controller: ccController,
                      placeholder: '可选',
                    ),
                    SizedBox(height: theme.spacing.s),
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
                  SizedBox(height: theme.spacing.s),
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
          SizedBox(height: theme.spacing.s),
          YhTextField(
            controller: subjectController,
            label: '主题',
            hint: '邮件主题',
            enabled: !isSending,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: theme.spacing.s),
          YhTextField(
            controller: bodyController,
            label: '正文',
            hint: '输入邮件正文',
            enabled: !isSending,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            '支持用逗号、分号或换行分隔多个地址；暂不支持附件、草稿或后台重试。',
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
          if (result != null) ...[
            SizedBox(height: theme.spacing.m),
            Text(result!.message, style: theme.typography.h3),
            SizedBox(height: theme.spacing.s),
            YhBanner(text: result!.detail, kind: severityOf(result!.status)),
          ],
          SizedBox(height: theme.spacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
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
                  leadingIcon: isSending ? null : YhIcons.send,
                  onTap: isSending ? null : onSend,
                ),
              ],
            ),
          ),
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
      textInputAction: TextInputAction.next,
    );
  }
}
