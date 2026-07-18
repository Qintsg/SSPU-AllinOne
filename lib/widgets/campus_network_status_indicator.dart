/*
 * 校园网状态徽标 — 展示校园网 / VPN 检测结果
 * @Project : SSPU-AllinOne
 * @File : campus_network_status_indicator.dart
 * @Author : Qintsg
 * @Date : 2026-04-27
 */

import 'dart:async';

import '../design/qingyuan/qingyuan_ui.dart';
import '../models/campus_network_status.dart';
import '../services/campus_network_status_service.dart';

enum CampusNetworkStatusIndicatorVariant { standard, titleBar, home }

class CampusNetworkStatusIndicator extends StatefulWidget {
  const CampusNetworkStatusIndicator({
    super.key,
    this.service,
    this.variant = CampusNetworkStatusIndicatorVariant.standard,
    this.indicatorKey = const Key('campus-network-status-indicator'),
  });

  final CampusNetworkStatusService? service;
  final CampusNetworkStatusIndicatorVariant variant;
  final Key? indicatorKey;

  @override
  State<CampusNetworkStatusIndicator> createState() =>
      _CampusNetworkStatusIndicatorState();
}

class _CampusNetworkStatusIndicatorState
    extends State<CampusNetworkStatusIndicator> {
  CampusNetworkStatusService get _service =>
      widget.service ?? CampusNetworkStatusService.instance;

  CampusNetworkStatus get _status => _service.currentStatus;
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
    if (oldWidget.service == widget.service) return;
    final oldService = oldWidget.service ?? CampusNetworkStatusService.instance;
    oldService.removeListener(_onServiceChanged);
    oldService.stopStatusMonitoring();
    _service.addListener(_onServiceChanged);
    unawaited(_service.startStatusMonitoring());
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _service.stopStatusMonitoring();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final palette = _palette(theme);
    final config = _variantConfig(theme);
    return YhTooltip(
      message: _tooltipMessage,
      child: YhPressable(
        semanticLabel: '校园网状态，$_displayLabel，点击重新检测',
        onPressed: _isChecking
            ? null
            : () => unawaited(_service.refreshStatus()),
        builder: (context, state, child) => _buildContent(
          theme,
          palette: palette,
          config: config,
          state: state,
          child: child,
        ),
        child: _buildInnerContent(theme, palette, config),
      ),
    );
  }

  Widget _buildContent(
    YhTheme theme, {
    required _StatusPalette palette,
    required _IndicatorVariantConfig config,
    required YhPressableState state,
    required Widget child,
  }) {
    final mutedTitleBar =
        widget.variant == CampusNetworkStatusIndicatorVariant.titleBar;
    final background = mutedTitleBar
        ? state.pressed
              ? theme.color.brand.withValues(alpha: 0.14)
              : state.hovered
              ? theme.color.brandTint
              : theme.color.surface.withValues(alpha: 0)
        : state.pressed
        ? palette.backgroundPressed
        : state.hovered
        ? palette.backgroundHover
        : palette.background;
    return AnimatedContainer(
      key: widget.indicatorKey,
      duration: theme.motion.fast,
      curve: theme.motion.curve,
      width: config.width,
      height: config.height,
      padding: EdgeInsets.symmetric(
        horizontal: config.horizontalPadding,
        vertical: config.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: background,
        border: mutedTitleBar ? null : Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(theme.radius.full),
        boxShadow: config.elevated ? theme.elevation.e1 : const [],
      ),
      child: child,
    );
  }

  Widget _buildInnerContent(
    YhTheme theme,
    _StatusPalette palette,
    _IndicatorVariantConfig config,
  ) {
    if (widget.variant == CampusNetworkStatusIndicatorVariant.titleBar) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _titleBarLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.typography.small.copyWith(
                color: theme.color.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: theme.spacing.xs),
          SizedBox(
            width: theme.spacing.xl,
            child: Center(
              child: _buildStatusIcon(
                palette.foreground,
                theme.spacing.l - theme.spacing.xs,
              ),
            ),
          ),
        ],
      );
    }

    final label = _isChecking
        ? '检测中'
        : config.useShortLabel
        ? _status.shortLabel
        : _status.label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (config.useStatusLight)
          _StatusLight(color: palette.foreground, checking: _isChecking)
        else
          _buildStatusIcon(palette.foreground, config.iconSize),
        SizedBox(width: theme.spacing.s),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (config.compactText
                        ? theme.typography.small
                        : theme.typography.body)
                    .copyWith(
                      color: palette.foreground,
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(Color color, double size) {
    if (_status.accessMode == CampusNetworkAccessMode.campus) {
      return _TitleBarWifiIcon(color: color, size: size);
    }
    return Opacity(
      opacity: _isChecking ? 0.55 : 1,
      child: Icon(_statusIcon, size: size, color: color),
    );
  }

  IconData get _statusIcon => switch (_status.accessMode) {
    CampusNetworkAccessMode.campus => YhIcons.globe,
    CampusNetworkAccessMode.vpn => YhIcons.networkVpn,
    CampusNetworkAccessMode.outsideCampus => YhIcons.networkOff,
    CampusNetworkAccessMode.unknown => YhIcons.networkUnknown,
  };

  String get _displayLabel => switch (widget.variant) {
    CampusNetworkStatusIndicatorVariant.titleBar => _titleBarLabel,
    CampusNetworkStatusIndicatorVariant.home => _status.shortLabel,
    CampusNetworkStatusIndicatorVariant.standard => _status.label,
  };

  String get _titleBarLabel => switch (_status.accessMode) {
    CampusNetworkAccessMode.vpn => 'VPN网络环境',
    CampusNetworkAccessMode.campus => '校园网环境',
    CampusNetworkAccessMode.outsideCampus => '校外网络环境',
    CampusNetworkAccessMode.unknown => '未知网络环境',
  };

  _StatusPalette _palette(YhTheme theme) {
    final muted =
        widget.variant == CampusNetworkStatusIndicatorVariant.home ||
        widget.variant == CampusNetworkStatusIndicatorVariant.titleBar;
    return switch (_status.accessMode) {
      CampusNetworkAccessMode.campus ||
      CampusNetworkAccessMode.vpn => _StatusPalette(
        foreground: theme.color.success,
        background: theme.color.successTint,
        backgroundHover: theme.color.successTint.withValues(alpha: 0.82),
        backgroundPressed: theme.color.successTint.withValues(alpha: 0.64),
        border: theme.color.success.withValues(alpha: 0.28),
      ),
      CampusNetworkAccessMode.outsideCampus => _StatusPalette(
        foreground: muted ? theme.color.muted : theme.color.warning,
        background: muted ? theme.color.sunken : theme.color.warningTint,
        backgroundHover: theme.color.brandTint,
        backgroundPressed: theme.color.brand.withValues(alpha: 0.16),
        border: theme.color.border,
      ),
      CampusNetworkAccessMode.unknown => _StatusPalette(
        foreground: theme.color.muted,
        background: theme.color.sunken,
        backgroundHover: theme.color.brandTint,
        backgroundPressed: theme.color.brand.withValues(alpha: 0.16),
        border: theme.color.border,
      ),
    };
  }

  _IndicatorVariantConfig _variantConfig(YhTheme theme) =>
      switch (widget.variant) {
        CampusNetworkStatusIndicatorVariant.standard => _IndicatorVariantConfig(
          height: theme.control.regular,
          horizontalPadding: theme.spacing.m,
          verticalPadding: theme.spacing.s,
          iconSize: theme.spacing.l,
        ),
        CampusNetworkStatusIndicatorVariant.titleBar => _IndicatorVariantConfig(
          width: theme.spacing.xl2 * 3,
          height: theme.spacing.xl,
          horizontalPadding: theme.spacing.s,
          verticalPadding: 0,
          iconSize: theme.spacing.l - theme.spacing.xs,
          compactText: true,
        ),
        CampusNetworkStatusIndicatorVariant.home => _IndicatorVariantConfig(
          height: theme.spacing.xl,
          horizontalPadding: theme.spacing.m - theme.spacing.xs,
          verticalPadding: theme.spacing.xs,
          iconSize: theme.spacing.m,
          compactText: true,
          useShortLabel: true,
          useStatusLight: true,
          elevated: true,
        ),
      };

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
    final interval = _service.detectionIntervalMinutes;
    final intervalLabel = interval <= 0 ? '自动检测：已关闭' : '自动检测：每 $interval 分钟';
    return '${_status.description}\n${_status.detail}\n$checkedAtLabel\n$intervalLabel\n点击可重新检测';
  }

  String get _titleBarTooltipMessage => switch (_status.accessMode) {
    CampusNetworkAccessMode.vpn => '当前处于VPN网络环境下，部分校园内部服务可能无法访问',
    CampusNetworkAccessMode.campus => '当前处于校园非VPN网络环境下',
    CampusNetworkAccessMode.outsideCampus => '当前处于非校园网络环境，访问校内服务需要连接校园网或打开VPN',
    CampusNetworkAccessMode.unknown =>
      '当前网络环境未知，可能是由于当前设备没有连接到网络、校园网内部错误、设备内部错误或网络波动等问题',
  };
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
  final bool compactText;
  final bool useShortLabel;
  final bool useStatusLight;
  final bool elevated;
}

class _StatusLight extends StatelessWidget {
  const _StatusLight({required this.color, required this.checking});

  final Color color;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return AnimatedOpacity(
      opacity: checking ? 0.45 : 1,
      duration: theme.motion.fast,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.36),
              blurRadius: theme.spacing.s,
              spreadRadius: theme.spacing.xs / 4,
            ),
          ],
        ),
        child: SizedBox.square(dimension: theme.spacing.s),
      ),
    );
  }
}

class _TitleBarWifiIcon extends StatelessWidget {
  const _TitleBarWifiIcon({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _TitleBarWifiIconPainter(color)),
  );
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

    Path arc(double left, double top, double right, double bottom) => Path()
      ..moveTo(size.width * left, size.height * bottom)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * top,
        size.width * right,
        size.height * bottom,
      );

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
  bool shouldRepaint(covariant _TitleBarWifiIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
