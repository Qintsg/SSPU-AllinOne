/*
 * 应用退出服务 — 统一处理桌面端安全退出流程
 * @Project : SSPU-AllinOne
 * @File : app_exit_service.dart
 * @Author : Qintsg
 * @Date : 2026-04-21
 */

import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'auto_refresh_service.dart';
import 'tray_service.dart';
import '../utils/webview_env.dart';

/// 仅桌面平台具备窗口与托盘资源，移动端 / Web 走系统退出。
bool get _supportsDesktopShell =>
    !kIsWeb &&
    (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS);

/// 统一应用退出入口。
///
/// 桌面端在真正销毁窗口前，需要先解除关闭拦截并释放托盘与后台定时器；
/// 否则可能出现窗口想关但进程仍挂着不退出的状态。
class AppExitService {
  AppExitService._();

  static final AppExitService instance = AppExitService._();

  bool _isExiting = false;

  static const Duration _desktopExitStepTimeout = Duration(milliseconds: 200);

  /// 可见窗口优先隐藏的超时；窗口消失优先级高于完整释放资源。
  static const Duration _visibleWindowCloseTimeout = Duration(
    milliseconds: 120,
  );

  /// 桌面端后台收尾总超时，避免无前端窗口时进程长期挂起。
  static const Duration _desktopExitTotalTimeout = Duration(milliseconds: 1500);

  /// 当前是否处于退出流程中，用于避免重复触发。
  bool get isExiting => _isExiting;

  /// 执行桌面端退出步骤，超时或异常都继续后续销毁流程。
  Future<void> _runDesktopExitStep(Future<void> Function() step) async {
    try {
      await step().timeout(_desktopExitStepTimeout, onTimeout: () {});
    } catch (_) {
      // 退出路径不应因为单个平台资源释放失败而阻塞进程关闭。
    }
  }

  /// 先隐藏用户可见窗口，让后续 native 资源释放在后台完成。
  Future<void> _hideVisibleWindowBeforeExit() async {
    try {
      await windowManager.hide().timeout(
        _visibleWindowCloseTimeout,
        onTimeout: () {},
      );
    } catch (_) {
      // 隐藏窗口失败时仍继续退出，避免窗口通道异常阻断进程关闭。
    }
  }

  /// 执行桌面端后台收尾，并用总超时兜底防止资源释放长期挂起。
  Future<void> _finishDesktopExitInBackground() async {
    try {
      await _finishDesktopExitSteps().timeout(
        _desktopExitTotalTimeout,
        onTimeout: () {},
      );
    } finally {
      io.exit(0);
    }
  }

  /// 释放桌面端退出相关资源。
  Future<void> _finishDesktopExitSteps() async {
    var isPreventClose = true;
    try {
      isPreventClose = await windowManager.isPreventClose().timeout(
        _desktopExitStepTimeout,
        onTimeout: () => true,
      );
    } catch (_) {
      isPreventClose = true;
    }
    if (isPreventClose) {
      await _runDesktopExitStep(() => windowManager.setPreventClose(false));
    }

    AutoRefreshService.instance.dispose();
    await _runDesktopExitStep(disposeGlobalWebViewEnvironment);
    await _runDesktopExitStep(() => TrayService.instance.destroy());
    await _runDesktopExitStep(() => windowManager.destroy());
  }

  /// 按平台执行安全退出。
  Future<void> exit() async {
    if (_isExiting) return;
    _isExiting = true;

    try {
      if (_supportsDesktopShell) {
        await _hideVisibleWindowBeforeExit();
        await _finishDesktopExitInBackground();
      }

      await SystemNavigator.pop();
    } finally {
      _isExiting = false;
    }
  }
}
