/* 密码相关对话框 — 设置、移除、确认与修改密码。 */

import 'dart:async';

import '../design/qingyuan/qingyuan_ui.dart';
import '../services/password_service.dart';

Future<bool> showSetPasswordDialog(BuildContext context) {
  final password = TextEditingController();
  final confirm = TextEditingController();
  return _showPasswordFormDialog(
    context,
    title: '设置密码',
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
