/*
 * 桌面窗口框架 — 自绘标题栏并承载校园网状态入口
 * @Project : SSPU-AllinOne
 * @File : desktop_window_frame.dart
 * @Author : Qintsg
 * @Date : 2026-05-31
 */

import 'dart:async';
import 'package:window_manager/window_manager.dart';

import '../design/fluent_ui.dart';
import '../services/app_display_name_service.dart';
import '../services/campus_network_status_service.dart';
import 'campus_network_status_indicator.dart';

/// macOS 使用系统原生红绿灯窗口按钮。
bool get _usesNativeMacOSWindowControls =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// 桌面端自绘窗口框架。
///
/// 原生标题栏被隐藏后，使用该组件提供拖拽区域、窗口按钮和网络状态入口。
class DesktopWindowFrame extends StatefulWidget {
  const DesktopWindowFrame({
    super.key,
    required this.child,
    this.campusNetworkStatusService,
  });

  /// 主内容。
  final Widget child;

  /// 校园网 / VPN 状态检测服务；为空时不展示状态入口。
  final CampusNetworkStatusService? campusNetworkStatusService;

  @override
  State<DesktopWindowFrame> createState() => _DesktopWindowFrameState();
}

class _DesktopWindowFrameState extends State<DesktopWindowFrame>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(_loadWindowState());
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  /// 读取初始最大化状态，保证窗口按钮图标与真实窗口一致。
  Future<void> _loadWindowState() async {
    final isMaximized = await windowManager.isMaximized();
    if (!mounted) return;
    setState(() => _isMaximized = isMaximized);
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;

    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => VirtualWindowFrame(
            child: ColoredBox(
              color: colors.neutralBackground1,
              child: Column(
                children: [
                  _DesktopWindowTitleBar(
                    isMaximized: _isMaximized,
                    campusNetworkStatusService:
                        widget.campusNetworkStatusService,
                    onToggleMaximized: _toggleMaximized,
                  ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 切换最大化 / 还原。
  void _toggleMaximized() {
    unawaited(_setMaximized(!_isMaximized));
  }

  Future<void> _setMaximized(bool maximized) async {
    if (maximized) {
      await windowManager.maximize();
      return;
    }
    await windowManager.unmaximize();
  }
}

class _DesktopWindowTitleBar extends StatelessWidget {
  const _DesktopWindowTitleBar({
    required this.isMaximized,
    required this.campusNetworkStatusService,
    required this.onToggleMaximized,
  });

  final bool isMaximized;
  final CampusNetworkStatusService? campusNetworkStatusService;
  final VoidCallback onToggleMaximized;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final spacing = context.fluentSpacing;
    final type = context.fluentType;
    final brightness = FluentTheme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.neutralBackground2,
        border: Border(bottom: BorderSide(color: colors.neutralStrokeDivider)),
      ),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: DragToMoveArea(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: _usesNativeMacOSWindowControls ? 84 : spacing.l,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.home,
                        size: 16,
                        color: colors.brandForeground1,
                      ),
                      SizedBox(width: spacing.s),
                      Text(
                        AppDisplayName.of(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: type.caption1Strong.copyWith(
                          color: colors.neutralForeground1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (campusNetworkStatusService != null) ...[
              CampusNetworkStatusIndicator(
                service: campusNetworkStatusService,
                variant: CampusNetworkStatusIndicatorVariant.titleBar,
                indicatorKey: const Key('campus-network-status-titlebar'),
              ),
              SizedBox(width: spacing.xs),
            ],
            if (!_usesNativeMacOSWindowControls) ...[
              WindowCaptionButton.minimize(
                brightness: brightness,
                onPressed: () => unawaited(windowManager.minimize()),
              ),
              isMaximized
                  ? WindowCaptionButton.unmaximize(
                      brightness: brightness,
                      onPressed: onToggleMaximized,
                    )
                  : WindowCaptionButton.maximize(
                      brightness: brightness,
                      onPressed: onToggleMaximized,
                    ),
              WindowCaptionButton.close(
                brightness: brightness,
                onPressed: () => unawaited(windowManager.close()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
