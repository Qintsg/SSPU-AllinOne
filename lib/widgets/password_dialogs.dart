/*
 * 密码相关对话框 — 设置、移除、确认与修改本地密码
 * @Project : SSPU-AllinOne
 * @File : password_dialogs.dart
 * @Author : Qintsg
 * @Date : 2026-08-17
 */

import 'dart:async';

import '../design/qingyuan/qingyuan_ui.dart';
import '../services/password_service.dart';

/// 显示设置本地密码对话框。
///
/// :param context: 设置页上下文。
/// :returns: 密码是否成功保存。
Future<bool> showSetPasswordDialog(BuildContext context) {
  final password = TextEditingController();
  final confirm = TextEditingController();
  return _showPasswordFormDialog(
    context,
    title: '设置本地密码',
    message: '设置密码后，每次重新打开应用时需要输入密码才能进入。',
    fields: [
      _PasswordFieldSpec(password, '输入密码', '请输入密码'),
      _PasswordFieldSpec(confirm, '确认密码', '请再次输入密码'),
    ],
    confirmLabel: '设置密码',
    validate: () {
      if (password.text.isEmpty) return '密码不能为空';
      if (password.text != confirm.text) return '两次输入的密码不一致';
      return null;
    },
    onAccepted: () => PasswordService.setPassword(password.text),
  );
}

/// 显示移除本地密码的危险确认对话框。
///
/// :param context: 设置页上下文。
/// :returns: 密码保护是否成功移除。
Future<bool> showRemovePasswordDialog(BuildContext context) {
  final password = TextEditingController();
  return _showPasswordFormDialog(
    context,
    title: '移除密码',
    message: '请输入当前密码以确认移除密码保护。',
    fields: [_PasswordFieldSpec(password, '当前密码', '请输入当前密码')],
    confirmLabel: '确认移除',
    danger: true,
    validate: () async =>
        await PasswordService.verifyPassword(password.text) ? null : '密码错误',
    onAccepted: PasswordService.removePassword,
  );
}

/// 验证当前本地密码后允许调用方继续敏感操作。
///
/// :param context: 当前页面上下文。
/// :param title: 对话框标题。
/// :param message: 验证原因。
/// :param confirmLabel: 主行动文案。
/// :returns: 当前密码是否验证通过。
Future<bool> showConfirmCurrentPasswordDialog(
  BuildContext context, {
  String title = '确认当前密码',
  String message = '请输入当前密码以继续。',
  String confirmLabel = '确认',
}) {
  final password = TextEditingController();
  return _showPasswordFormDialog(
    context,
    title: title,
    message: message,
    fields: [_PasswordFieldSpec(password, '当前密码', '请输入当前密码')],
    confirmLabel: confirmLabel,
    validate: () async =>
        await PasswordService.verifyPassword(password.text) ? null : '密码错误',
  );
}

/// 显示修改本地密码对话框。
///
/// :param context: 设置页上下文。
/// :returns: 新密码是否成功保存。
Future<bool> showChangePasswordDialog(BuildContext context) {
  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirm = TextEditingController();
  return _showPasswordFormDialog(
    context,
    title: '修改密码',
    message: '先验证当前密码，再设置新的本地解锁密码。',
    fields: [
      _PasswordFieldSpec(oldPassword, '当前密码', '请输入当前密码'),
      _PasswordFieldSpec(newPassword, '新密码', '请输入新密码'),
      _PasswordFieldSpec(confirm, '确认新密码', '请再次输入新密码'),
    ],
    confirmLabel: '确认修改',
    validate: () async {
      if (!await PasswordService.verifyPassword(oldPassword.text)) {
        return '当前密码错误';
      }
      if (newPassword.text.isEmpty) return '新密码不能为空';
      if (newPassword.text != confirm.text) return '两次输入的新密码不一致';
      return null;
    },
    onAccepted: () => PasswordService.setPassword(newPassword.text),
  );
}

class _PasswordFieldSpec {
  const _PasswordFieldSpec(this.controller, this.label, this.hint);

  final TextEditingController controller;
  final String label;
  final String hint;
}

/// 执行共享密码表单、异步校验和可选保存操作。
///
/// :param context: 当前页面上下文。
/// :param title: 模态标题。
/// :param message: 操作边界说明。
/// :param fields: 需要按顺序填写的密码字段。
/// :param confirmLabel: 主行动文案。
/// :param validate: 表单与当前密码校验器。
/// :param onAccepted: 校验通过后的保存操作。
/// :param danger: 是否禁止点击遮罩取消。
/// :returns: 操作是否完成。
Future<bool> _showPasswordFormDialog(
  BuildContext context, {
  required String title,
  required String message,
  required List<_PasswordFieldSpec> fields,
  required String confirmLabel,
  required FutureOr<String?> Function() validate,
  FutureOr<void> Function()? onAccepted,
  bool danger = false,
}) async {
  try {
    final result = await YhDialog.show<bool>(
      context,
      barrierDismissible: !danger,
      builder: (dialogContext) {
        String? errorMessage;
        var busy = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => YhDialog(
            eyebrow: '本机安全',
            title: title,
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.yhTheme.breakpoint.compact,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    SizedBox(height: context.yhTheme.spacing.m),
                    for (var index = 0; index < fields.length; index++) ...[
                      YhTextField(
                        controller: fields[index].controller,
                        label: fields[index].label,
                        hint: fields[index].hint,
                        prefixIcon: YhIcons.lock,
                        obscure: true,
                        enabled: !busy,
                        autofocus: index == 0,
                        textInputAction: index == fields.length - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                      ),
                      if (index < fields.length - 1)
                        SizedBox(height: context.yhTheme.spacing.s),
                    ],
                    if (errorMessage != null) ...[
                      SizedBox(height: context.yhTheme.spacing.s),
                      YhBanner(text: errorMessage!, kind: YhBannerKind.danger),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              YhButton(
                label: '取消',
                variant: YhButtonVariant.secondary,
                onTap: busy
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                disabled: busy,
              ),
              YhButton(
                label: busy ? '正在验证…' : confirmLabel,
                variant: danger
                    ? YhButtonVariant.danger
                    : YhButtonVariant.primary,
                disabled: busy,
                onTap: busy
                    ? null
                    : () async {
                        setDialogState(() {
                          busy = true;
                          errorMessage = null;
                        });
                        final validationError = await validate();
                        if (!dialogContext.mounted) return;
                        if (validationError != null) {
                          setDialogState(() {
                            busy = false;
                            errorMessage = validationError;
                          });
                          return;
                        }
                        Navigator.of(dialogContext).pop(true);
                      },
              ),
            ],
          ),
        );
      },
    );
    if (result != true) return false;
    await onAccepted?.call();
    return true;
  } finally {
    for (final field in fields) {
      field.controller.dispose();
    }
  }
}
