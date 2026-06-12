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
  final FluentInfoSeverity Function(EmailQueryStatus status) severityOf;

  /// 点击发送。
  final VoidCallback onSend;

  /// 点击取消或关闭撰写面板。
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return FluentSurface(
      key: const Key('email-compose-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluentSectionHeader(
            title: '撰写邮件',
            subtitle: '通过学校邮箱 SMTP 发送普通文本邮件',
            icon: FluentIcons.edit,
            action: Wrap(
              spacing: FluentSpacing.s,
              runSpacing: FluentSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FluentStatusChip(
                  label: 'SMTP 发信',
                  icon: FluentIcons.send,
                  tone: FluentStatusChipTone.brand,
                ),
                if (onCancel != null)
                  IconButton(
                    onPressed: isSending ? null : onCancel,
                    icon: const Icon(FluentIcons.clear),
                  ),
              ],
            ),
          ),
          const SizedBox(height: FluentSpacing.m),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 560;
              if (!twoColumns) {
                return Column(
                  children: [
                    _buildAddressField(
                      label: '收件人',
                      controller: toController,
                      placeholder: 'name@example.com',
                    ),
                    const SizedBox(height: FluentSpacing.s),
                    _buildAddressField(
                      label: '抄送',
                      controller: ccController,
                      placeholder: '可选',
                    ),
                    const SizedBox(height: FluentSpacing.s),
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
                  const SizedBox(height: FluentSpacing.s),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAddressField(
                          label: '抄送',
                          controller: ccController,
                          placeholder: '可选',
                        ),
                      ),
                      const SizedBox(width: FluentSpacing.s),
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
          const SizedBox(height: FluentSpacing.s),
          FluentTextField(
            controller: subjectController,
            label: '主题',
            placeholder: '邮件主题',
            enabled: !isSending,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: FluentSpacing.s),
          FluentTextField(
            controller: bodyController,
            label: '正文',
            placeholder: '输入邮件正文',
            enabled: !isSending,
            minLines: 8,
            maxLines: 12,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: FluentSpacing.s),
          Text(
            '支持用逗号、分号或换行分隔多个地址；暂不支持附件、草稿或后台重试。',
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: FluentSpacing.m),
            FluentInfoBar(
              title: Text(result!.message),
              content: Text(result!.detail),
              severity: severityOf(result!.status),
            ),
          ],
          const SizedBox(height: FluentSpacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: FluentSpacing.s,
              runSpacing: FluentSpacing.xs,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (onCancel != null)
                  FluentButton.outline(
                    onPressed: isSending ? null : onCancel,
                    child: const Text('取消'),
                  ),
                FluentButton.primary(
                  onPressed: isSending ? null : onSend,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSending) ...[
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: FluentProgressRing(strokeWidth: 2),
                        ),
                      ] else ...[
                        const Icon(FluentIcons.send, size: 14),
                      ],
                      const SizedBox(width: FluentSpacing.xs),
                      Text(isSending ? '正在发送' : '发送邮件'),
                    ],
                  ),
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
    return FluentTextField(
      controller: controller,
      label: label,
      placeholder: placeholder,
      enabled: !isSending,
      textInputAction: TextInputAction.next,
    );
  }
}
