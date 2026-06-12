/*
 * 应用入口 — 初始化 FluentApp 并处理协议确认、密码保护、窗口关闭与托盘逻辑
 * @Project : SSPU-AllinOne
 * @File : main.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'dart:async';
import 'dart:io';
import 'design/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'app.dart';
import 'pages/lock_page.dart';
import 'services/app_exit_service.dart';
import 'services/app_display_name_service.dart';
import 'services/app_user_agent_service.dart';
import 'services/password_service.dart';
import 'services/campus_network_status_service.dart';
import 'services/storage_service.dart';
import 'services/tray_service.dart';
import 'services/notification_service.dart';
import 'services/auto_refresh_service.dart';
import 'services/academic_oa_session_prewarm_service.dart';
import 'widgets/desktop_window_frame.dart';
import 'widgets/legal_consent_dialog.dart';

import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';

/// 字体族常量（已迁移至 AppTheme.fontFamily，保留兼容引用）
const String kFontFamily = AppTheme.fontFamily;

/// 桌面窗口插件仅在 Flutter 桌面平台注册。
bool get _supportsDesktopShell =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppUserAgentService.initialize();

  if (_supportsDesktopShell) {
    // 桌面端拦截关闭事件并提供系统托盘入口。
    await windowManager.ensureInitialized();
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setPreventClose(true);
    await windowManager.setTitle(AppDisplayName.currentPlatformName);
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

  /// 是否已接受当前完整法律与隐私说明。
  bool _agreementsAccepted = false;

  /// 防止协议弹窗重复弹出。
  bool _agreementDialogShowing = false;

  /// 防止关闭确认弹窗重复弹出
  bool _closeDialogShowing = false;

  /// 启动初始化失败时显示明确错误，避免长期停留在加载状态。
  String? _startupErrorMessage;

  /// FluentApp 内部导航器 key，用于在 WindowListener 回调中弹出对话框
  final _navigatorKey = GlobalKey<NavigatorState>();

  /// 主界面共享的校园网 / VPN 状态检测服务。
  final CampusNetworkStatusService _campusNetworkStatusService =
      CampusNetworkStatusService.instance;

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
    unawaited(
      AcademicOaSessionPrewarmService.instance.prewarm(
        forceRefresh: true,
        requireCampusNetwork: false,
      ),
    );
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

    showFluentDialog<void>(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return FluentDialog(
              title: const Text('关闭应用'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FluentDialogMessage(
                    icon: FluentIcons.clear,
                    message: '请选择点击窗口关闭按钮时的处理方式。',
                    details: '也可以点击弹窗外的空白区域取消本次操作，应用会继续保持打开。',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Checkbox(
                    checked: rememberChoice,
                    semanticLabel: '以后都使用此选项',
                    content: const Text('以后都使用此选项'),
                    onChanged: (value) {
                      setDialogState(() => rememberChoice = value ?? false);
                    },
                  ),
                ],
              ),
              actions: [
                FluentButton.outlineIcon(
                  icon: const Icon(FluentIcons.blocked),
                  label: const Text('最小化到托盘'),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    if (rememberChoice) {
                      await StorageService.setCloseBehavior('minimize');
                    }
                    await windowManager.hide();
                  },
                ),
                FluentButton.primaryIcon(
                  icon: const Icon(FluentIcons.power),
                  label: const Text('退出应用'),
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
      showLegalConsentDialog(context: context).then((accepted) async {
        _agreementDialogShowing = false;
        if (accepted == true) {
          await StorageService.acceptCurrentAgreements();
          if (mounted) {
            setState(() => _agreementsAccepted = true);
          }
        } else if (accepted == false) {
          // 不同意协议时按平台能力关闭应用入口。
          await _closeApplication();
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
    return FluentApp(
      navigatorKey: _navigatorKey,
      title: AppDisplayName.english,
      onGenerateTitle: AppDisplayName.of,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: _buildHome(),
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!_supportsDesktopShell) return content;

        return DesktopWindowFrame(
          campusNetworkStatusService: _shouldShowCampusNetworkStatus
              ? _campusNetworkStatusService
              : null,
          child: content,
        );
      },
    );
  }

  /// 是否允许展示并触发校园网状态检测。
  bool get _shouldShowCampusNetworkStatus {
    return _isInitialized &&
        _startupErrorMessage == null &&
        _agreementsAccepted &&
        _isUnlocked;
  }

  /// 根据初始化、协议确认和密码验证状态构建首屏
  Widget _buildHome() {
    if (!_isInitialized) {
      return const ScaffoldPage(content: Center(child: FluentProgressRing()));
    }

    if (_startupErrorMessage != null) {
      return ScaffoldPage(
        content: Center(
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
          return const ScaffoldPage(
            content: Center(child: FluentProgressRing()),
          );
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
    return AppShell(
      onLock: _lockApp,
      campusNetworkStatusService: _campusNetworkStatusService,
    );
  }
}
