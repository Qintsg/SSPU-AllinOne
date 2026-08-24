/*
 * 微信推文配置编辑对话框 — 字段式填写公众号平台配置
 * @Project : SSPU-AllinOne
 * @File : settings_wechat_config_dialog.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'dart:async';

import '../design/qingyuan/qingyuan_ui.dart';
import '../services/wxmp_config_service.dart';

/// 显示公众号平台字段式配置编辑器。
///
/// :param context: 微信认证设置页上下文。
/// :param initialConfig: 打开模态时的配置快照。
/// :returns: 已校验的新配置；取消时返回 null。
Future<WxmpConfig?> showSettingsWechatConfigDialog({
  required BuildContext context,
  required WxmpConfig initialConfig,
}) {
  return YhDialog.show<WxmpConfig>(
    context,
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
  final _perRequestCountFieldKey = GlobalKey();
  final _requestDelayFieldKey = GlobalKey();
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
    final theme = context.yhTheme;
    final mediaSize = MediaQuery.sizeOf(context);
    final compact = mediaSize.width < theme.breakpoint.compact;
    final maxDialogWidth = compact
        ? mediaSize.width - theme.spacing.m * 2
        : theme.breakpoint.medium + theme.spacing.xl2;
    final contentHeight = (mediaSize.height - theme.spacing.xl2 * 4).clamp(
      theme.spacing.xl2 * 4,
      560.0,
    );

    return YhDialog(
      constraints: BoxConstraints(maxWidth: maxDialogWidth),
      eyebrow: '高级认证配置',
      title: '编辑公众号平台配置',
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: contentHeight),
        child: SingleChildScrollView(
          child: SizedBox(
            key: const Key('wechat-config-dialog-content'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '只填写配置项内容。Cookie 和 Token 属于敏感信息，请勿分享。',
                  style: theme.typography.small.copyWith(
                    color: theme.color.muted,
                  ),
                ),
                SizedBox(height: theme.spacing.l),
                _ConfigFieldsLayout(
                  compact: compact,
                  children: [
                    _ConfigTextField(
                      label: 'Cookie',
                      controller: _cookieController,
                      maxLines: 1,
                      autofocus: !compact,
                    ),
                    _ConfigTextField(
                      label: 'Token',
                      controller: _tokenController,
                    ),
                    _ConfigTextField(
                      label: 'App ID',
                      controller: _appIdController,
                    ),
                    _ConfigTextField(
                      label: 'User-Agent',
                      controller: _userAgentController,
                    ),
                    _ConfigTextField(
                      key: _perRequestCountFieldKey,
                      label: '单次抓取数量',
                      controller: _perRequestCountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      errorText: _perRequestCountError,
                    ),
                    _ConfigTextField(
                      key: _requestDelayFieldKey,
                      label: '请求间隔（毫秒）',
                      controller: _requestDelayController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      errorText: _requestDelayError,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        YhButton(
          label: '取消',
          onTap: _cancel,
          variant: YhButtonVariant.secondary,
        ),
        YhButton(label: '保存配置', onTap: _submit),
      ],
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final targetContext = perRequestCount == null
            ? _perRequestCountFieldKey.currentContext
            : _requestDelayFieldKey.currentContext;
        if (targetContext == null) return;
        unawaited(
          Scrollable.ensureVisible(
            targetContext,
            duration: context.yhTheme.motion.base,
            curve: context.yhTheme.motion.curve,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          ),
        );
      });
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

class _ConfigFieldsLayout extends StatelessWidget {
  const _ConfigFieldsLayout({required this.compact, required this.children});

  /// 是否使用单列布局。
  final bool compact;

  /// 表单字段。
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleColumn =
            compact || constraints.maxWidth < theme.breakpoint.compact;
        final columns = singleColumn ? 1 : 2;
        if (columns == 1 && children.length >= 6) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ConfigFieldColumn(
                spacing: theme.spacing.s,
                children: children.take(4).toList(growable: false),
              ),
              SizedBox(height: theme.spacing.s),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children[4]),
                  SizedBox(width: theme.spacing.s),
                  Expanded(child: children[5]),
                ],
              ),
            ],
          );
        }
        if (columns == 1) {
          return _ConfigFieldColumn(
            spacing: theme.spacing.s,
            children: children,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index += 2) ...[
              if (index > 0) SizedBox(height: theme.spacing.m),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children[index]),
                  SizedBox(width: theme.spacing.l),
                  Expanded(
                    child: index + 1 < children.length
                        ? children[index + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ConfigFieldColumn extends StatelessWidget {
  const _ConfigFieldColumn({required this.children, required this.spacing});

  /// 字段列表。
  final List<Widget> children;

  /// 字段之间的响应式纵向间距。
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          children[i],
        ],
      ],
    );
  }
}

class _ConfigTextField extends StatelessWidget {
  const _ConfigTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.maxLines = 1,
    this.autofocus = false,
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

  /// 最大行数。
  final int maxLines;

  /// 是否在模态打开后获取初始焦点。
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return YhTextField(
      label: label,
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      errorText: errorText,
      maxLines: maxLines,
      autofocus: autofocus,
    );
  }
}
