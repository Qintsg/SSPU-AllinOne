/*
 * 清源微信公众号认证任务页
 * @Project : SSPU-AllinOne
 * @File : settings_wechat_auth_page.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

import 'dart:async';

import '../controllers/settings_wechat_controller.dart';
import '../design/qingyuan/qingyuan_ui.dart';
import '../services/wxmp_config_service.dart';
import '../utils/webview_env.dart';
import '../widgets/settings_wechat_auth_status_card.dart';
import '../widgets/settings_wechat_config_dialog.dart';
import 'wxmp_login_page.dart';

typedef SettingsWechatLoginFlow = Future<bool?> Function(BuildContext context);
typedef SettingsWechatConfigEditor =
    Future<WxmpConfig?> Function(BuildContext context, WxmpConfig config);
typedef SettingsWechatClearConfirmation =
    Future<bool> Function(BuildContext context);

/// 微信公众号认证的独立任务页。
///
/// 控制器仍是认证状态的唯一业务真源；页面只维护当前交互、提示和错误等展示状态。
class SettingsWechatAuthPage extends StatefulWidget {
  const SettingsWechatAuthPage({
    super.key,
    this.controller,
    this.loginFlow,
    this.configEditor,
    this.clearConfirmation,
    this.sourceTimestamp,
    this.previewState,
    this.previewStatusMessage,
  });

  final SettingsWechatController? controller;
  final SettingsWechatLoginFlow? loginFlow;
  final SettingsWechatConfigEditor? configEditor;
  final SettingsWechatClearConfirmation? clearConfirmation;
  final String? sourceTimestamp;

  /// 视觉矩阵专用的确定性状态；设置后不会读取真实本机状态。
  @visibleForTesting
  final SettingsWechatAuthDisplayState? previewState;

  @visibleForTesting
  final String? previewStatusMessage;

  @override
  State<SettingsWechatAuthPage> createState() => _SettingsWechatAuthPageState();
}

enum _WechatAuthOperation { login, edit, validate, clear }

class _SettingsWechatAuthPageState extends State<SettingsWechatAuthPage> {
  late SettingsWechatController _controller;
  late bool _ownsController;
  _WechatAuthOperation? _operation;
  String? _noticeMessage;
  String? _errorMessage;
  bool _loadFailed = false;
  int _errorCompletedStepCount = 0;
  int _sourceGeneration = 0;

  bool get _preview => widget.previewState != null;
  bool get _busy => _operation != null;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? SettingsWechatController();
    if (!_preview) unawaited(_load());
  }

  @override
  void didUpdateWidget(SettingsWechatAuthPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = !identical(
      oldWidget.controller,
      widget.controller,
    );
    final operationSourceChanged =
        controllerChanged ||
        !identical(oldWidget.loginFlow, widget.loginFlow) ||
        !identical(oldWidget.configEditor, widget.configEditor) ||
        !identical(oldWidget.clearConfirmation, widget.clearConfirmation) ||
        oldWidget.previewState != widget.previewState;
    if (!operationSourceChanged) return;

    _sourceGeneration++;
    _operation = null;
    _noticeMessage = null;
    _errorMessage = null;
    _loadFailed = false;
    _errorCompletedStepCount = 0;
    if (controllerChanged) {
      if (_ownsController) _controller.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? SettingsWechatController();
    }
    if (!_preview &&
        (controllerChanged || oldWidget.previewState != widget.previewState)) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _sourceGeneration++;
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_preview) return _buildPage(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final state = _displayState;
    return YhTaskPage(
      title: '微信公众号认证',
      kicker: '账户连接',
      appBarEyebrow: '设置',
      summary: '扫码、等待、已连接和失败状态保持同一位置，过期二维码可明确刷新。',
      source: '微信公众号连接',
      sourceSymbol: '设',
      sourceTimestamp: widget.sourceTimestamp,
      width: YhTaskPageWidth.fluid,
      bodyFit: YhTaskPageBodyFit.content,
      primaryActionLabel: '开始认证',
      onPrimaryAction: _busy ? null : _startLogin,
      moreActions: [
        YhTaskPageAction(label: '编辑认证配置', onTap: _busy ? null : _editConfig),
        YhTaskPageAction(label: '重新校验认证', onTap: _busy ? null : _validate),
        if (_authenticated)
          YhTaskPageAction(
            label: '清除认证',
            variant: YhButtonVariant.danger,
            onTap: _busy ? null : _confirmAndClear,
          ),
      ],
      body: SettingsWechatAuthStatusCard(
        state: state,
        statusMessage: _statusMessage,
        showStatusBanner: _noticeMessage != null,
        errorCompletedStepCount: _preview ? 1 : _errorCompletedStepCount,
        onLogin: _startLogin,
        onValidate: _validate,
      ),
    );
  }

  SettingsWechatAuthDisplayState get _displayState {
    if (_preview) return widget.previewState!;
    if (_busy || (_controller.isLoading && !_loadFailed)) {
      return SettingsWechatAuthDisplayState.loading;
    }
    if (_errorMessage != null ||
        _loadFailed ||
        _controller.wxmpConfigMessage.contains('失败')) {
      return SettingsWechatAuthDisplayState.error;
    }
    return _controller.wxmpAuthenticated
        ? SettingsWechatAuthDisplayState.content
        : SettingsWechatAuthDisplayState.initial;
  }

  bool get _authenticated => _preview
      ? widget.previewState == SettingsWechatAuthDisplayState.content
      : _controller.wxmpAuthenticated;

  String get _statusMessage {
    if (widget.previewStatusMessage != null) {
      return widget.previewStatusMessage!;
    }
    if (_errorMessage != null) return _errorMessage!;
    if (_noticeMessage != null) return _noticeMessage!;
    if (_operation != null) {
      return switch (_operation!) {
        _WechatAuthOperation.login => '正在打开扫码登录；其他认证操作暂时不可用。',
        _WechatAuthOperation.edit => '正在读取并保存配置；其他认证操作暂时不可用。',
        _WechatAuthOperation.validate => '正在校验 Cookie 与 Token；当前连接状态会保留到结果返回。',
        _WechatAuthOperation.clear => '正在清除本机认证；不会影响公众号平台上的账号。',
      };
    }
    final messages = <String>[
      if (_controller.wxmpAuthStatus != null)
        _controller.wxmpAuthStatus!.message,
      if (_controller.wxmpConfigMessage.isNotEmpty)
        _controller.wxmpConfigMessage,
    ];
    return messages.isEmpty ? '尚未连接公众号平台账号。' : messages.join(' · ');
  }

  Future<void> _load() async {
    final generation = _sourceGeneration;
    final controller = _controller;
    try {
      await controller.load();
      if (!_isCurrent(generation)) return;
      setState(() => _loadFailed = false);
    } catch (_) {
      if (!_isCurrent(generation)) return;
      setState(() {
        _loadFailed = true;
        _errorCompletedStepCount = 0;
        _errorMessage = '无法读取本机微信认证状态；可重新进入或直接开始认证。';
      });
    }
  }

  Future<void> _startLogin() async {
    if (_busy || _preview) return;
    await _runOperation(_WechatAuthOperation.login, (generation) async {
      final controller = _controller;
      final loginFlow = widget.loginFlow ?? _defaultLoginFlow;
      final wasAuthenticated = controller.wxmpAuthenticated;
      final result = await loginFlow(context);
      if (!_isCurrent(generation)) return;
      if (result != true) {
        _noticeMessage = wasAuthenticated
            ? '已取消重新认证，原有连接保持不变。'
            : '已取消扫码认证，没有保存新的认证信息。';
        return;
      }
      _errorCompletedStepCount = 2;
      final feedback = await controller.handleLoginSuccess();
      if (!_isCurrent(generation)) return;
      if (!controller.wxmpAuthenticated) {
        throw StateError('登录结果未包含可用的 Cookie 与 Token');
      }
      _showFeedback(feedback, generation: generation);
      _noticeMessage = feedback.severity == AppFeedbackSeverity.success
          ? wasAuthenticated
                ? '新认证已通过校验并替换原连接。'
                : '认证已连接，可重新校验或清除本机凭据。'
          : feedback.content ?? feedback.title;
    }, failureMessage: '认证结果未能写回设置；原连接状态已重新读取，请重试。');
  }

  Future<bool?> _defaultLoginFlow(BuildContext context) async {
    final webViewEnvironment = await ensureGlobalWebViewEnvironment();
    if (!context.mounted) return false;
    return Navigator.of(context).push<bool>(
      YhPageRoute<bool>(
        builder: (_) => WxmpLoginPage(webViewEnvironment: webViewEnvironment),
      ),
    );
  }

  Future<void> _editConfig() async {
    if (_busy || _preview) return;
    await _runOperation(_WechatAuthOperation.edit, (generation) async {
      final controller = _controller;
      final configEditor = widget.configEditor ?? _defaultConfigEditor;
      final initialConfig = await controller.loadConfig();
      if (!_isCurrent(generation) || !mounted) return;
      final saved = await configEditor(context, initialConfig);
      if (!_isCurrent(generation)) return;
      if (saved == null) {
        _noticeMessage = '已取消编辑，认证配置没有变化。';
        return;
      }
      final feedback = await controller.saveConfig(saved);
      if (!_isCurrent(generation)) return;
      _showFeedback(feedback, generation: generation);
      _noticeMessage = feedback.title;
    }, failureMessage: '无法读取或保存认证配置；原配置保持不变，可检查文件权限后重试。');
  }

  Future<WxmpConfig?> _defaultConfigEditor(
    BuildContext context,
    WxmpConfig config,
  ) {
    return showSettingsWechatConfigDialog(
      context: context,
      initialConfig: config,
    );
  }

  Future<void> _validate() async {
    if (_busy || _preview) return;
    await _runOperation(_WechatAuthOperation.validate, (generation) async {
      final controller = _controller;
      final feedback = await controller.reloadConfigFile();
      if (!_isCurrent(generation)) return;
      _showFeedback(feedback, generation: generation);
      if (feedback.severity != AppFeedbackSeverity.success ||
          !controller.wxmpAuthenticated) {
        _errorCompletedStepCount = controller.wxmpAuthenticated ? 3 : 2;
        _errorMessage = feedback.content ?? feedback.title;
        return;
      }
      _noticeMessage = feedback.content ?? feedback.title;
    }, failureMessage: '本次校验未完成；现有认证配置与上一次有效结果保持不变。');
  }

  Future<void> _confirmAndClear() async {
    if (_busy || _preview || !_controller.wxmpAuthenticated) return;
    final generation = _sourceGeneration;
    final confirmation = widget.clearConfirmation ?? _defaultClearConfirmation;
    final confirmed = await confirmation(context);
    if (!_isCurrent(generation)) return;
    if (!confirmed) {
      setState(() => _noticeMessage = '已取消清除，公众号连接保持不变。');
      return;
    }
    await _runOperation(
      _WechatAuthOperation.clear,
      (operationGeneration) async {
        final controller = _controller;
        final feedback = await controller.clearAuth();
        if (!_isCurrent(operationGeneration)) return;
        _showFeedback(feedback, generation: operationGeneration);
        _noticeMessage = '本机 Cookie 与 Token 已清除；公众号平台账号未受影响。';
      },
      failureMessage: '未能完整清除本机认证；连接状态保持可见，请检查本机存储后重试。',
    );
  }

  Future<bool> _defaultClearConfirmation(BuildContext context) {
    return YhDialog.confirm(
      context,
      title: '清除微信公众号认证',
      message:
          '将移除本机保存的 Cookie 与 Token，并清空已读取的公众号列表。\n\n'
          '不会注销或删除公众号平台账号；之后可重新扫码连接。',
      confirmText: '清除认证',
      danger: true,
      barrierDismissible: false,
    );
  }

  Future<void> _runOperation(
    _WechatAuthOperation operation,
    Future<void> Function(int generation) action, {
    required String failureMessage,
  }) async {
    if (_busy) return;
    setState(() {
      _operation = operation;
      _errorMessage = null;
      _noticeMessage = null;
      _errorCompletedStepCount = switch (operation) {
        _WechatAuthOperation.login ||
        _WechatAuthOperation.edit => _controller.wxmpAuthenticated ? 3 : 0,
        _WechatAuthOperation.validate => _controller.wxmpAuthenticated ? 2 : 0,
        _WechatAuthOperation.clear => _controller.wxmpAuthenticated ? 3 : 0,
      };
    });
    final generation = _sourceGeneration;
    try {
      await action(generation);
    } catch (_) {
      if (_isCurrent(generation)) _errorMessage = failureMessage;
    } finally {
      if (_isCurrent(generation)) {
        setState(() => _operation = null);
      }
    }
  }

  bool _isCurrent(int generation) => mounted && generation == _sourceGeneration;

  void _showFeedback(
    SettingsWechatFeedback feedback, {
    required int generation,
  }) {
    if (!_isCurrent(generation)) return;
    showYhFeedback(
      context,
      message: feedback.title,
      details: feedback.content,
      severity: feedback.severity,
    );
  }
}
