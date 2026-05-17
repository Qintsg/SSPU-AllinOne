/*
 * 应用入口 — 初始化 MaterialApp 并处理协议确认、密码保护、窗口关闭与托盘逻辑
 * @Project : SSPU-AllinOne
 * @File : main.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'dart:async';
import 'dart:io';
import 'widgets/material_compat.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'app.dart';
import 'pages/lock_page.dart';
import 'pages/agreement_page.dart';
import 'pages/privacy_policy_page.dart';
import 'services/app_exit_service.dart';
import 'services/app_data_directory_service.dart';
import 'services/password_service.dart';
import 'services/storage_service.dart';
import 'services/tray_service.dart';
import 'services/notification_service.dart';
import 'services/auto_refresh_service.dart';
import 'utils/webview_env.dart';

/// 全局字体族名称
import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';

/// 字体族常量（已迁移至 AppTheme.fontFamily，保留兼容引用）
const String kFontFamily = AppTheme.fontFamily;

/// 桌面窗口插件仅在 Flutter 桌面平台注册。
bool get _supportsDesktopShell =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// WebView2 和本地通知当前只面向 Windows 发行包启用。
bool get _supportsWindowsServices => !kIsWeb && Platform.isWindows;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows 平台：在 runApp() 前初始化 WebView2 环境
  // 必须在任何 WebView 实例创建前完成，否则会触发 RPC_E_DISCONNECTED (-2147417848)
  if (_supportsWindowsServices) {
    final availableVersion = await WebViewEnvironment.getAvailableVersion();
    if (availableVersion != null) {
      // WebView2 运行态同样放入统一应用数据目录，便于用户定位和清理。
      final webViewDataFolder =
          await AppDataDirectoryService.ensureDirectoryPath('webview2');
      globalWebViewEnvironment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(userDataFolder: webViewDataFolder),
      );
    }
  }

  if (_supportsDesktopShell) {
    // 桌面端拦截关闭事件并提供系统托盘入口。
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    await TrayService.instance.init();
  }

  runApp(const SSPUApp());
}

/// 应用根 Widget
/// 配置 Fluent 主题、暗色模式支持、国际化代理
/// 同时监听窗口关闭事件和系统托盘交互
class SSPUApp extends StatefulWidget {
  const SSPUApp({super.key});

  @override
  State<SSPUApp> createState() => _SSPUAppState();
}

class _SSPUAppState extends State<SSPUApp> with WindowListener, TrayListener {
  /// 是否已通过密码验证（或无需密码）
  bool _isUnlocked = false;

  /// 初始化检查是否已完成
  bool _isInitialized = false;

  /// 是否已接受使用协议与隐私协议。
  bool _agreementsAccepted = false;

  /// 防止协议弹窗重复弹出。
  bool _agreementDialogShowing = false;

  /// 防止关闭确认弹窗重复弹出
  bool _closeDialogShowing = false;

  /// 启动初始化失败时显示明确错误，避免长期停留在加载状态。
  String? _startupErrorMessage;

  /// MaterialApp 内部导航器 key，用于在 WindowListener 回调中弹出对话框
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    if (_supportsDesktopShell) {
      windowManager.addListener(this);
      trayManager.addListener(this);
    }
    _initApp();
  }

  @override
  void dispose() {
    if (_supportsDesktopShell) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  /// 初始化应用状态：先检查协议确认状态，再检查密码。
  Future<void> _initApp() async {
    try {
      await StorageService.init();
      final agreementsOk = await StorageService.areCurrentAgreementsAccepted();
      final hasPassword = await PasswordService.isPasswordSet();
      if (!mounted) return;
      setState(() {
        _agreementsAccepted = agreementsOk;
        _isUnlocked = !hasPassword;
        _isInitialized = true;
      });
      unawaited(_initBackgroundServices());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _startupErrorMessage = '启动初始化失败：$error';
        _isInitialized = true;
      });
    }
  }

  /// 初始化后台能力，不阻塞首屏渲染和用户进入主页。
  Future<void> _initBackgroundServices() async {
    try {
      await NotificationService.instance.init();
      await AutoRefreshService.instance.init();
    } catch (_) {
      // 后台刷新或通知初始化失败不应阻断 Android 启动主流程。
    }
  }

  /// 手动上锁，从设置页触发
  void _lockApp() {
    setState(() => _isUnlocked = false);
  }

  // ==================== 窗口关闭拦截 ====================

  /// 窗口关闭事件回调
  /// 根据用户偏好执行：最小化到托盘 / 直接退出 / 弹窗询问
  @override
  void onWindowClose() async {
    if (!_supportsDesktopShell) return;

    final isPreventClose = await windowManager.isPreventClose();
    if (!isPreventClose) return;

    final behavior = await StorageService.getCloseBehavior();
    switch (behavior) {
      case 'minimize':
        // 隐藏窗口，保留托盘图标后台运行
        await windowManager.hide();
        return;
      case 'exit':
        // 直接退出应用并回收托盘 / 定时器资源
        await AppExitService.instance.exit();
        return;
      default:
        // 每次询问用户
        _showCloseConfirmDialog();
    }
  }

  /// 显示关闭确认对话框，提供最小化/退出两个选项
  /// 勾选"以后都使用此选项"可持久化用户选择
  void _showCloseConfirmDialog() {
    if (!_supportsDesktopShell || _closeDialogShowing) return;

    final ctx = _navigatorKey.currentContext;
    // 若导航器上下文不可用（极端情况），直接退出
    if (ctx == null) {
      AppExitService.instance.exit();
      return;
    }

    _closeDialogShowing = true;
    bool rememberChoice = false;

    showDialog(
      context: ctx,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('关闭应用'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('选择点击关闭按钮时的操作：'),
                  const SizedBox(height: AppSpacing.md),
                  CheckboxListTile(
                    value: rememberChoice,
                    onChanged: (value) {
                      setDialogState(() => rememberChoice = value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                    title: const Text('以后都使用此选项'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('最小化到托盘'),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    if (rememberChoice) {
                      await StorageService.setCloseBehavior('minimize');
                    }
                    await windowManager.hide();
                  },
                ),
                FilledButton(
                  child: const Text('退出应用'),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    if (rememberChoice) {
                      await StorageService.setCloseBehavior('exit');
                    }
                    await AppExitService.instance.exit();
                  },
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      _closeDialogShowing = false;
    });
  }

  // ==================== 系统托盘交互 ====================

  /// 左键单击托盘图标：显示并聚焦主窗口
  @override
  void onTrayIconMouseDown() {
    if (!_supportsDesktopShell) return;

    windowManager.show();
    windowManager.focus();
  }

  /// 右键单击托盘图标：弹出右键菜单
  @override
  void onTrayIconRightMouseDown() {
    if (!_supportsDesktopShell) return;

    trayManager.popUpContextMenu();
  }

  /// 托盘右键菜单项点击回调
  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (!_supportsDesktopShell) return;

    switch (menuItem.key) {
      case 'show_window':
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'exit_app':
        await AppExitService.instance.exit();
        break;
    }
  }

  // ==================== 协议弹窗 ====================

  /// 显示首次启动的协议弹窗（仅弹出一次）。
  void _showAgreementDialog(BuildContext context) {
    if (_agreementDialogShowing) return;
    _agreementDialogShowing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('使用协议与隐私协议'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 420),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      kAgreementText.trim(),
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    SelectableText(
                      kPrivacyPolicyText.trim(),
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('不同意'),
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                  // 不同意协议时按平台能力关闭应用入口。
                  _closeApplication();
                },
              ),
              FilledButton(
                child: const Text('同意'),
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
              ),
            ],
          );
        },
      ).then((accepted) async {
        _agreementDialogShowing = false;
        if (accepted == true) {
          await StorageService.acceptCurrentAgreements();
          if (mounted) {
            setState(() => _agreementsAccepted = true);
          }
        }
      });
    });
  }

  // ==================== 构建 ====================

  /// 按当前平台关闭应用，避免移动端调用未注册的桌面插件通道。
  Future<void> _closeApplication() async {
    await AppExitService.instance.exit();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'SSPU-AllinOne',
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: _buildHome(),
    );
  }

  /// 根据初始化、协议确认和密码验证状态构建首屏
  Widget _buildHome() {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_startupErrorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: AppSpacing.regularPagePadding,
            child: Text(_startupErrorMessage!),
          ),
        ),
      );
    }

    // 未接受协议时显示空白页并弹出协议对话框。
    if (!_agreementsAccepted) {
      return Builder(
        builder: (context) {
          _showAgreementDialog(context);
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      );
    }

    // 需要密码验证时显示锁定页
    if (!_isUnlocked) {
      return LockPage(
        onUnlocked: () {
          setState(() => _isUnlocked = true);
        },
      );
    }

    // 已解锁，进入主界面
    return AppShell(onLock: _lockApp);
  }
}
