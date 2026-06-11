/*
 * 微信推文配置编辑对话框 — 字段式填写公众号平台配置
 * @Project : SSPU-AllinOne
 * @File : settings_wechat_config_dialog.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:flutter/services.dart';

import '../design/fluent_ui.dart';
import '../services/wxmp_config_service.dart';
import '../theme/app_breakpoints.dart';

/// 显示公众号平台字段式配置编辑器。
Future<WxmpConfig?> showSettingsWechatConfigDialog({
  required BuildContext context,
  required WxmpConfig initialConfig,
}) {
  return showDialog<WxmpConfig>(
    context: context,
    builder: (dialogContext) =>
        _SettingsWechatConfigDialog(initialConfig: initialConfig),
  );
}

class _SettingsWechatConfigDialog extends StatefulWidget {
  const _SettingsWechatConfigDialog({required this.initialConfig});

  /// 初始配置。
  final WxmpConfig initialConfig;

  @override
  State<_SettingsWechatConfigDialog> createState() =>
      _SettingsWechatConfigDialogState();
}

class _SettingsWechatConfigDialogState
    extends State<_SettingsWechatConfigDialog> {
  late final TextEditingController _cookieController;
  late final TextEditingController _tokenController;
  late final TextEditingController _appIdController;
  late final TextEditingController _userAgentController;
  late final TextEditingController _perRequestCountController;
  late final TextEditingController _requestDelayController;

  String? _perRequestCountError;
  String? _requestDelayError;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    _cookieController = TextEditingController(text: config.cookie);
    _tokenController = TextEditingController(text: config.token);
    _appIdController = TextEditingController(text: config.appId);
    _userAgentController = TextEditingController(text: config.userAgent);
    _perRequestCountController = TextEditingController(
      text: config.perRequestArticleCount.toString(),
    );
    _requestDelayController = TextEditingController(
      text: config.requestDelayMs.toString(),
    );
  }

  @override
  void dispose() {
    _cookieController.dispose();
    _tokenController.dispose();
    _appIdController.dispose();
    _userAgentController.dispose();
    _perRequestCountController.dispose();
    _requestDelayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.fluentSpacing;
    final type = context.fluentType;
    final colors = context.fluentColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final compact = availableWidth < AppBreakpoints.compactMax;
        final availableDialogWidth = (availableWidth - spacing.xxxl).clamp(
          0,
          double.infinity,
        );
        final minDialogWidth = availableDialogWidth < 320
            ? availableDialogWidth
            : 320;
        final maxDialogWidth = AppBreakpoints.mediumMax + spacing.xxxl * 2;
        final dialogWidth = availableDialogWidth.clamp(
          minDialogWidth,
          maxDialogWidth,
        );
        final dialogHeight = availableHeight - spacing.xxxl;

        return FluentDialog(
          constraints: BoxConstraints(
            minWidth: dialogWidth.toDouble(),
            maxWidth: dialogWidth.toDouble(),
            maxHeight: dialogHeight.clamp(360, 720),
          ),
          title: const Text('编辑公众号平台配置'),
          content: SizedBox(
            key: const Key('wechat-config-dialog-content'),
            width: dialogWidth.toDouble(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '只填写配置项内容。Cookie 和 Token 属于敏感信息，请勿分享。',
                  style: type.caption1.copyWith(
                    color: colors.neutralForeground2,
                  ),
                ),
                SizedBox(height: spacing.l),
                _ConfigFieldsLayout(
                  compact: compact,
                  children: [
                    _ConfigTextField(
                      label: 'cookie',
                      controller: _cookieController,
                      minLines: compact ? 3 : 4,
                      maxLines: compact ? 5 : 6,
                    ),
                    _ConfigTextField(
                      label: 'token',
                      controller: _tokenController,
                    ),
                    _ConfigTextField(
                      label: 'app_id',
                      controller: _appIdController,
                    ),
                    _ConfigTextField(
                      label: 'user_agent',
                      controller: _userAgentController,
                      maxLines: 2,
                    ),
                    _ConfigTextField(
                      label: 'per_request_article_count',
                      controller: _perRequestCountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      errorText: _perRequestCountError,
                    ),
                    _ConfigTextField(
                      label: 'request_delay_ms',
                      controller: _requestDelayController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      errorText: _requestDelayError,
                    ),
                  ],
                ),
                SizedBox(height: spacing.xl),
                _ConfigDialogActions(onCancel: _cancel, onSubmit: _submit),
              ],
            ),
          ),
        );
      },
    );
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _submit() {
    final perRequestCount = _readInt(
      controller: _perRequestCountController,
      min: 1,
      max: 20,
      emptyMessage: '请输入 1-20 的整数',
      outOfRangeMessage: '范围为 1-20',
      onError: (value) => _perRequestCountError = value,
    );
    final requestDelay = _readInt(
      controller: _requestDelayController,
      min: 0,
      max: 60000,
      emptyMessage: '请输入 0-60000 的整数',
      outOfRangeMessage: '范围为 0-60000',
      onError: (value) => _requestDelayError = value,
    );

    if (perRequestCount == null || requestDelay == null) {
      setState(() {});
      return;
    }

    Navigator.of(context).pop(
      WxmpConfig(
        cookie: _cookieController.text.trim(),
        token: _tokenController.text.trim(),
        appId: _appIdController.text.trim(),
        userAgent: _userAgentController.text.trim(),
        perRequestArticleCount: perRequestCount,
        requestDelayMs: requestDelay,
      ),
    );
  }

  int? _readInt({
    required TextEditingController controller,
    required int min,
    required int max,
    required String emptyMessage,
    required String outOfRangeMessage,
    required ValueChanged<String?> onError,
  }) {
    final text = controller.text.trim();
    final value = int.tryParse(text);
    if (value == null) {
      onError(emptyMessage);
      return null;
    }
    if (value < min || value > max) {
      onError(outOfRangeMessage);
      return null;
    }
    onError(null);
    return value;
  }
}

class _ConfigDialogActions extends StatelessWidget {
  const _ConfigDialogActions({required this.onCancel, required this.onSubmit});

  /// 取消编辑。
  final VoidCallback onCancel;

  /// 提交配置。
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final spacing = context.fluentSpacing;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Wrap(
        spacing: spacing.m,
        runSpacing: spacing.s,
        alignment: WrapAlignment.end,
        children: [
          FluentButton.outline(onPressed: onCancel, child: const Text('取消')),
          FluentButton.primary(onPressed: onSubmit, child: const Text('保存')),
        ],
      ),
    );
  }
}

class _ConfigFieldsLayout extends StatelessWidget {
  const _ConfigFieldsLayout({required this.compact, required this.children});

  /// 是否使用单列布局。
  final bool compact;

  /// 表单字段。
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.fluentSpacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            compact || constraints.maxWidth < AppBreakpoints.compactMax ? 1 : 2;
        if (columns == 1) {
          return _ConfigFieldColumn(children: children);
        }

        final leftColumn = <Widget>[];
        final rightColumn = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          if (i.isEven) {
            leftColumn.add(children[i]);
          } else {
            rightColumn.add(children[i]);
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ConfigFieldColumn(children: leftColumn)),
            SizedBox(width: spacing.l),
            Expanded(child: _ConfigFieldColumn(children: rightColumn)),
          ],
        );
      },
    );
  }
}

class _ConfigFieldColumn extends StatelessWidget {
  const _ConfigFieldColumn({required this.children});

  /// 字段列表。
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.fluentSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: spacing.m),
          children[i],
        ],
      ],
    );
  }
}

class _ConfigTextField extends StatelessWidget {
  const _ConfigTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  /// 配置键名。
  final String label;

  /// 文本控制器。
  final TextEditingController controller;

  /// 键盘类型。
  final TextInputType? keyboardType;

  /// 输入过滤器。
  final List<TextInputFormatter>? inputFormatters;

  /// 错误文本。
  final String? errorText;

  /// 最小行数。
  final int minLines;

  /// 最大行数。
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final spacing = context.fluentSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.fluentType.caption1Strong),
        SizedBox(height: spacing.xs),
        FluentTextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          errorText: errorText,
          minLines: minLines,
          maxLines: maxLines,
        ),
      ],
    );
  }
}
