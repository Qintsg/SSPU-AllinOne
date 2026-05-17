/*
 * 锁定页 — 应用启动时的密码验证界面
 * 设计参考 1Password 锁定页面风格
 * @Project : SSPU-AllinOne
 * @File : lock_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/password_service.dart';
import '../services/system_auth_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// 锁定页面。
/// 当用户设置密码保护后，应用启动时显示此页面。
/// 输入正确密码后解锁进入主界面。
class LockPage extends StatefulWidget {
  /// 解锁成功后的回调。
  final VoidCallback onUnlocked;

  const LockPage({super.key, required this.onUnlocked});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> with TickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// 错误提示文本。
  String? _errorMessage;

  /// 是否正在验证中。
  bool _isVerifying = false;

  /// 是否已启用且当前设备可用系统快速验证。
  bool _isSystemAuthEnabled = false;

  /// 是否正在请求系统认证。
  bool _isSystemAuthenticating = false;

  /// 防止系统认证与密码验证重复触发解锁回调。
  bool _hasCompletedUnlock = false;

  /// 抖动动画控制器，密码错误时触发。
  late AnimationController _shakeController;

  /// 抖动偏移动画。
  late Animation<double> _shakeAnimation;

  /// 解锁动画控制器（成功验证后播放）。
  late AnimationController _unlockController;

  /// 解锁缩放动画。
  late Animation<double> _unlockScale;

  /// 解锁透明度动画。
  late Animation<double> _unlockOpacity;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: AppMotion.long,
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _unlockController = AnimationController(
      duration: AppMotion.long,
      vsync: this,
    );
    _unlockScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _unlockController, curve: Curves.easeOutCubic),
    );
    _unlockOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _unlockController, curve: Curves.easeInCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });

    unawaited(_loadAndTrySystemAuth());
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _unlockController.dispose();
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 执行密码验证。
  Future<void> _handleUnlock() async {
    if (_hasCompletedUnlock) return;
    final inputPassword = _passwordController.text;

    if (inputPassword.isEmpty) {
      setState(() => _errorMessage = '请输入密码');
      _triggerShake();
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final isCorrect = await PasswordService.verifyPassword(inputPassword);

    if (!mounted) return;

    if (isCorrect) {
      _completeUnlock();
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = '密码错误，请重试';
      });
      _passwordController.clear();
      _triggerShake();
      _focusNode.requestFocus();
    }
  }

  /// 加载系统快速验证配置，并在可用时优先尝试系统认证。
  Future<void> _loadAndTrySystemAuth() async {
    final quickAuthEnabled = await PasswordService.isQuickAuthEnabled();
    if (!quickAuthEnabled) return;

    final systemAuthAvailable = await SystemAuthService.instance.isAvailable();
    if (!mounted || !systemAuthAvailable) return;

    setState(() => _isSystemAuthEnabled = true);
    await _handleSystemUnlock(autoTriggered: true);
  }

  /// 执行系统认证解锁。失败、取消、超时或不可用时保留手动密码路径。
  Future<void> _handleSystemUnlock({bool autoTriggered = false}) async {
    if (_hasCompletedUnlock || _isSystemAuthenticating) return;

    setState(() {
      _isSystemAuthenticating = true;
      if (!autoTriggered) _errorMessage = null;
    });

    final result = await SystemAuthService.instance.authenticate(
      localizedReason: '验证身份以解锁 SSPU-AllinOne',
    );

    if (!mounted || _hasCompletedUnlock) return;

    if (result == SystemAuthResult.success) {
      _completeUnlock();
      return;
    }

    setState(() {
      _isSystemAuthenticating = false;
      _errorMessage = '系统认证未完成，请输入密码解锁';
    });
    _focusNode.requestFocus();
  }

  /// 播放解锁动画并通知上层进入主界面。
  void _completeUnlock() {
    if (_hasCompletedUnlock) return;
    _hasCompletedUnlock = true;
    _unlockController.forward().then((_) {
      if (mounted) {
        widget.onUnlocked();
      }
    });
  }

  /// 触发密码输入框抖动效果。
  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_unlockScale, _unlockOpacity]),
      builder: (context, child) {
        return Opacity(
          opacity: _unlockOpacity.value,
          child: Transform.scale(scale: _unlockScale.value, child: child),
        );
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.regularPagePadding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo.png', width: 80, height: 80),
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      header: true,
                      child: Text('SSPU-AllinOne', style: textTheme.titleLarge),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '应用已锁定',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildPasswordForm(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建密码输入和解锁操作区。
  Widget _buildPasswordForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Column(
        children: [
          TextField(
            controller: _passwordController,
            focusNode: _focusNode,
            obscureText: true,
            decoration: InputDecoration(
              labelText: '密码',
              hintText: '输入密码以解锁',
              prefixIcon: const Icon(Icons.lock_outline),
              errorText: _errorMessage,
              errorMaxLines: 2,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleUnlock(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isVerifying ? null : _handleUnlock,
              child: _isVerifying
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('解锁'),
            ),
          ),
          if (_isSystemAuthEnabled) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSystemAuthenticating
                    ? null
                    : () => _handleSystemUnlock(),
                icon: _isSystemAuthenticating
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fingerprint),
                label: Text(_isSystemAuthenticating ? '等待系统认证' : '使用系统认证'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
