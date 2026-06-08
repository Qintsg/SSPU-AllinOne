/*
 * 校园网状态徽标 — 展示校园网 / VPN 检测结果
 * @Project : SSPU-AllinOne
 * @File : campus_network_status_indicator.dart
 * @Author : Qintsg
 * @Date : 2026-04-27
 */

import 'dart:async';

import '../design/fluent_ui.dart';

import '../models/campus_network_status.dart';
import '../services/campus_network_status_service.dart';

/// 校园网 / VPN 状态徽标展示样式。
enum CampusNetworkStatusIndicatorVariant {
  /// 标准胶囊样式，用于侧边栏等常规区域。
  standard,

  /// 桌面自绘标题栏样式，固定宽度并显示语义图标。
  titleBar,

  /// 首页右上角小状态样式，使用状态灯和短文案。
  home,
}

/// 应用级校园网 / VPN 状态徽标。
class CampusNetworkStatusIndicator extends StatefulWidget {
  const CampusNetworkStatusIndicator({
    super.key,
    this.service,
    this.variant = CampusNetworkStatusIndicatorVariant.standard,
    this.indicatorKey = const Key('campus-network-status-indicator'),
  });

  /// 检测服务；测试或后续平台差异化检测可注入自定义实现。
  final CampusNetworkStatusService? service;

  /// 展示样式。
  final CampusNetworkStatusIndicatorVariant variant;

  /// 内部可点击区域 Key，便于不同入口分别测试。
  final Key? indicatorKey;

  @override
  State<CampusNetworkStatusIndicator> createState() =>
      _CampusNetworkStatusIndicatorState();
}

class _CampusNetworkStatusIndicatorState
    extends State<CampusNetworkStatusIndicator> {
  CampusNetworkStatusService get _service {
    return widget.service ?? CampusNetworkStatusService.instance;
  }

  CampusNetworkStatus get _status => _service.currentStatus;

  int get _detectionIntervalMinutes => _service.detectionIntervalMinutes;

  bool get _isChecking => _service.isChecking;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    unawaited(_service.startStatusMonitoring());
  }

  @override
  void didUpdateWidget(CampusNetworkStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      final oldService =
          oldWidget.service ?? CampusNetworkStatusService.instance;
      oldService.removeListener(_onServiceChanged);
      oldService.stopStatusMonitoring();
      _service.addListener(_onServiceChanged);
      unawaited(_service.startStatusMonitoring());
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _service.stopStatusMonitoring();
    super.dispose();
  }

  /// 服务状态变化时刷新当前徽标视图。
  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  /// 刷新校园网状态。
  Future<void> _refreshStatus() async {
    await _service.refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette(context);
    final config = _variantConfig;

    return Tooltip(
      message: _tooltipMessage,
      child: Semantics(
        button: true,
        label: '校园网状态，$_displayLabel，点击重新检测',
        child: FluentHoverButton(
          onPressed: _isChecking ? null : _refreshStatus,
          builder: (context, states) => _buildContent(
            context,
            palette: palette,
            config: config,
            hovered: states.isHovered,
            pressed: states.isPressed,
          ),
        ),
      ),
    );
  }

  /// 构建徽标主体。
  Widget _buildContent(
    BuildContext context, {
    required _StatusPalette palette,
    required _IndicatorVariantConfig config,
    required bool hovered,
    required bool pressed,
  }) {
    final colors = context.fluentColors;
    final spacing = context.fluentSpacing;
    final radii = context.fluentRadii;
    final motion = context.fluentMotion;
    final type = context.fluentType;
    if (widget.variant == CampusNetworkStatusIndicatorVariant.titleBar) {
      return _buildTitleBarContent(
        context,
        palette: palette,
        config: config,
        hovered: hovered,
        pressed: pressed,
      );
    }

    final background = pressed
        ? palette.backgroundPressed
        : hovered
        ? palette.backgroundHover
        : palette.background;
    final label = _isChecking
        ? '检测中'
        : config.useShortLabel
        ? _status.shortLabel
        : _status.label;

    return AnimatedContainer(
      key: widget.indicatorKey,
      duration: motion.durationFast,
      curve: motion.curveDecelerateMid,
      width: config.width,
      height: config.height,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: config.horizontalPadding,
        vertical: config.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(radii.circular),
        boxShadow: config.elevated
            ? [
                BoxShadow(
                  color: colors.neutralForeground1.withValues(alpha: 0.08),
                  offset: const Offset(0, 6),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          config.useStatusLight
              ? _buildStatusLight(palette.foreground)
              : _buildStatusIcon(palette.foreground, config.iconSize),
          SizedBox(width: spacing.s),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (config.compactText ? type.caption1 : type.body1).copyWith(
                color: palette.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建桌面标题栏状态入口。
  Widget _buildTitleBarContent(
    BuildContext context, {
    required _StatusPalette palette,
    required _IndicatorVariantConfig config,
    required bool hovered,
    required bool pressed,
  }) {
    final colors = context.fluentColors;
    final motion = context.fluentMotion;
    final type = context.fluentType;
    final foreground = hovered || pressed
        ? palette.foreground
        : palette.foreground.withValues(alpha: 0.88);

    return AnimatedContainer(
      key: widget.indicatorKey,
      duration: motion.durationFast,
      curve: motion.curveDecelerateMid,
      width: config.width,
      height: config.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: motion.durationFast,
            curve: motion.curveDecelerateMid,
            width: config.labelWidth,
            height: config.height,
            alignment: Alignment.center,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            child: Text(
              _titleBarLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.caption1Strong.copyWith(
                color: colors.neutralForeground1,
              ),
            ),
          ),
          SizedBox(width: config.segmentGap),
          AnimatedContainer(
            duration: motion.durationFast,
            curve: motion.curveDecelerateMid,
            width: config.iconBoxWidth,
            height: config.height,
            alignment: Alignment.center,
            child: _buildStaticStatusIcon(foreground, config.iconSize),
          ),
        ],
      ),
    );
  }

  /// 构建不会因检测中切换成进度点的标题栏图标。
  Widget _buildStaticStatusIcon(Color foregroundColor, double size) {
    if (_status.accessMode == CampusNetworkAccessMode.campus) {
      return _TitleBarWifiIcon(color: foregroundColor, size: size);
    }

    return Icon(_statusIcon, size: size, color: foregroundColor);
  }

  /// 构建当前状态图标。
  Widget _buildStatusIcon(Color foregroundColor, double size) {
    if (_isChecking) {
      return FluentProgressRing(
        size: size,
        strokeWidth: 2,
        activeColor: foregroundColor,
      );
    }

    return Icon(_statusIcon, size: size, color: foregroundColor);
  }

  /// 构建首页使用的状态灯。
  Widget _buildStatusLight(Color foregroundColor) {
    if (_isChecking) {
      return FluentProgressRing(
        size: 12,
        strokeWidth: 2,
        activeColor: foregroundColor,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: foregroundColor,
        boxShadow: [
          BoxShadow(
            color: foregroundColor.withValues(alpha: 0.36),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const SizedBox.square(dimension: 9),
    );
  }

  IconData get _statusIcon {
    return switch (_status.accessMode) {
      CampusNetworkAccessMode.campus => FluentIcons.networkWifi,
      CampusNetworkAccessMode.vpn => FluentIcons.networkVpn,
      CampusNetworkAccessMode.outsideCampus => FluentIcons.networkOff,
      CampusNetworkAccessMode.unknown => FluentIcons.networkUnknown,
    };
  }

  /// 当前样式应展示的状态文案。
  String get _displayLabel {
    return switch (widget.variant) {
      CampusNetworkStatusIndicatorVariant.titleBar => _titleBarLabel,
      CampusNetworkStatusIndicatorVariant.home => _status.shortLabel,
      CampusNetworkStatusIndicatorVariant.standard => _status.label,
    };
  }

  /// 桌面标题栏按 issue #155 约定展示的固定文案。
  String get _titleBarLabel {
    return switch (_status.accessMode) {
      CampusNetworkAccessMode.vpn => 'VPN网络环境',
      CampusNetworkAccessMode.campus => '校园网环境',
      CampusNetworkAccessMode.outsideCampus => '校外网络环境',
      CampusNetworkAccessMode.unknown => '未知网络环境',
    };
  }

  _StatusPalette _palette(BuildContext context) {
    final colors = context.fluentColors;
    return switch (_status.accessMode) {
      CampusNetworkAccessMode.campus ||
      CampusNetworkAccessMode.vpn => _StatusPalette(
        foreground: colors.statusSuccessForeground,
        background: colors.statusSuccessBackground,
        backgroundHover: colors.statusSuccessBackground.withValues(alpha: 0.86),
        backgroundPressed: colors.statusSuccessBackground.withValues(
          alpha: 0.72,
        ),
        border: colors.statusSuccessForeground.withValues(alpha: 0.22),
      ),
      CampusNetworkAccessMode.outsideCampus => _StatusPalette(
        foreground: _usesMutedStatusColor
            ? colors.neutralForeground3
            : colors.statusWarningForeground,
        background: _usesMutedStatusColor
            ? colors.neutralBackground3
            : colors.statusWarningBackground,
        backgroundHover: _usesMutedStatusColor
            ? colors.neutralBackground2
            : colors.statusWarningBackground.withValues(alpha: 0.86),
        backgroundPressed: _usesMutedStatusColor
            ? colors.neutralBackground1Pressed
            : colors.statusWarningBackground.withValues(alpha: 0.72),
        border: colors.neutralStroke2,
      ),
      CampusNetworkAccessMode.unknown => _StatusPalette(
        foreground: colors.neutralForeground3,
        background: colors.neutralBackground3,
        backgroundHover: colors.neutralBackground2,
        backgroundPressed: colors.neutralBackground1Pressed,
        border: colors.neutralStroke2,
      ),
    };
  }

  /// 首页和标题栏中的非校园状态按需求使用灰色弱化展示。
  bool get _usesMutedStatusColor {
    return widget.variant == CampusNetworkStatusIndicatorVariant.home ||
        widget.variant == CampusNetworkStatusIndicatorVariant.titleBar;
  }

  _IndicatorVariantConfig get _variantConfig {
    return switch (widget.variant) {
      CampusNetworkStatusIndicatorVariant.standard =>
        const _IndicatorVariantConfig(
          height: 44,
          horizontalPadding: 14,
          verticalPadding: 8,
          iconSize: 18,
        ),
      CampusNetworkStatusIndicatorVariant.titleBar =>
        const _IndicatorVariantConfig(
          width: 142,
          height: 30,
          horizontalPadding: 0,
          verticalPadding: 4,
          iconSize: 20,
          labelWidth: 106,
          iconBoxWidth: 32,
          segmentGap: 4,
          compactText: true,
        ),
      CampusNetworkStatusIndicatorVariant.home => const _IndicatorVariantConfig(
        height: 32,
        horizontalPadding: 12,
        verticalPadding: 5,
        iconSize: 14,
        compactText: true,
        useShortLabel: true,
        useStatusLight: true,
        elevated: true,
      ),
    };
  }

  String get _tooltipMessage {
    if (widget.variant == CampusNetworkStatusIndicatorVariant.titleBar) {
      return _titleBarTooltipMessage;
    }

    final checkedAt = _status.checkedAt;
    final checkedAtLabel = checkedAt == null
        ? '尚未完成检测'
        : '检测时间：${checkedAt.hour.toString().padLeft(2, '0')}'
              ':${checkedAt.minute.toString().padLeft(2, '0')}'
              ':${checkedAt.second.toString().padLeft(2, '0')}';

    final intervalLabel = _detectionIntervalMinutes <= 0
        ? '自动检测：已关闭'
        : '自动检测：每 $_detectionIntervalMinutes 分钟';

    return '${_status.description}\n${_status.detail}\n$checkedAtLabel\n$intervalLabel\n点击可重新检测';
  }

  /// 桌面标题栏按 issue #155 约定展示的悬停说明。
  String get _titleBarTooltipMessage {
    return switch (_status.accessMode) {
      CampusNetworkAccessMode.vpn => '当前处于VPN网络环境下，部分校园内部服务可能无法访问',
      CampusNetworkAccessMode.campus => '当前处于校园非VPN网络环境下',
      CampusNetworkAccessMode.outsideCampus =>
        '当前处于非校园网络环境，访问校内服务需要连接校园网或打开VPN',
      CampusNetworkAccessMode.unknown =>
        '当前网络环境未知，可能是由于当前设备没有连接到网络、校园网内部错误、设备内部错误或网络波动等问题',
    };
  }
}

class _StatusPalette {
  const _StatusPalette({
    required this.foreground,
    required this.background,
    required this.backgroundHover,
    required this.backgroundPressed,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color backgroundHover;
  final Color backgroundPressed;
  final Color border;
}

class _IndicatorVariantConfig {
  const _IndicatorVariantConfig({
    this.width,
    required this.height,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    this.labelWidth = 0,
    this.iconBoxWidth = 0,
    this.segmentGap = 0,
    this.compactText = false,
    this.useShortLabel = false,
    this.useStatusLight = false,
    this.elevated = false,
  });

  final double? width;
  final double height;
  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final double labelWidth;
  final double iconBoxWidth;
  final double segmentGap;
  final bool compactText;
  final bool useShortLabel;
  final bool useStatusLight;
  final bool elevated;
}

class _TitleBarWifiIcon extends StatelessWidget {
  const _TitleBarWifiIcon({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _TitleBarWifiIconPainter(color)),
    );
  }
}

class _TitleBarWifiIconPainter extends CustomPainter {
  const _TitleBarWifiIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = (size.shortestSide * 0.1).clamp(1.6, 2.2).toDouble();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Path arc(double left, double top, double right, double bottom) {
      final path = Path()..moveTo(size.width * left, size.height * bottom);
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * top,
        size.width * right,
        size.height * bottom,
      );
      return path;
    }

    canvas.drawPath(arc(0.18, 0.16, 0.82, 0.48), paint);
    canvas.drawPath(arc(0.32, 0.38, 0.68, 0.61), paint);
    canvas.drawPath(arc(0.43, 0.58, 0.57, 0.72), paint);

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.82),
      size.shortestSide * 0.075,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _TitleBarWifiIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
