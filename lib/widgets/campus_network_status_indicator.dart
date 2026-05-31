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
        label: '校园网状态，${_status.label}，点击重新检测',
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
      CampusNetworkAccessMode.campus => FluentIcons.plugConnected,
      CampusNetworkAccessMode.vpn => FluentIcons.shield,
      CampusNetworkAccessMode.outsideCampus => FluentIcons.globe,
      CampusNetworkAccessMode.unknown => FluentIcons.syncStatus,
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
        foreground: widget.variant == CampusNetworkStatusIndicatorVariant.home
            ? colors.neutralForeground3
            : colors.statusWarningForeground,
        background: widget.variant == CampusNetworkStatusIndicatorVariant.home
            ? colors.neutralBackground3
            : colors.statusWarningBackground,
        backgroundHover:
            widget.variant == CampusNetworkStatusIndicatorVariant.home
            ? colors.neutralBackground2
            : colors.statusWarningBackground.withValues(alpha: 0.86),
        backgroundPressed:
            widget.variant == CampusNetworkStatusIndicatorVariant.home
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
          width: 152,
          height: 30,
          horizontalPadding: 12,
          verticalPadding: 4,
          iconSize: 16,
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
