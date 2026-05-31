/*
 * 校园网状态徽标 — 在导航栏展示校园网 / VPN 检测结果
 * @Project : SSPU-AllinOne
 * @File : campus_network_status_indicator.dart
 * @Author : Qintsg
 * @Date : 2026-04-27
 */

import 'dart:async';

import '../design/fluent_ui.dart';

import '../models/campus_network_status.dart';
import '../services/campus_network_status_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// 应用级校园网 / VPN 状态徽标。
class CampusNetworkStatusIndicator extends StatefulWidget {
  const CampusNetworkStatusIndicator({super.key, this.service});

  /// 检测服务；测试或后续平台差异化检测可注入自定义实现。
  final CampusNetworkStatusService? service;

  @override
  State<CampusNetworkStatusIndicator> createState() =>
      _CampusNetworkStatusIndicatorState();
}

class _CampusNetworkStatusIndicatorState
    extends State<CampusNetworkStatusIndicator> {
  late CampusNetworkStatus _status;

  /// 当前自动检测间隔；0 表示只允许手动点击刷新。
  int _detectionIntervalMinutes =
      CampusNetworkStatusService.defaultDetectionIntervalMinutes;

  /// 自动检测定时器，按设置页配置重排。
  Timer? _refreshTimer;

  /// 防止用户连续点击刷新造成重复探测。
  bool _isChecking = false;

  CampusNetworkStatusService get _service {
    return widget.service ?? CampusNetworkStatusService.instance;
  }

  @override
  void initState() {
    super.initState();
    _status = CampusNetworkStatus.unknown(probeUri: _service.probeUri);
    _service.addListener(_onServiceSettingsChanged);
    unawaited(_loadIntervalAndRefresh());
  }

  @override
  void didUpdateWidget(CampusNetworkStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      final oldService = oldWidget.service ?? CampusNetworkStatusService.instance;
      oldService.removeListener(_onServiceSettingsChanged);
      _service.addListener(_onServiceSettingsChanged);
      _status = CampusNetworkStatus.unknown(probeUri: _service.probeUri);
      unawaited(_loadIntervalAndRefresh());
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _service.removeListener(_onServiceSettingsChanged);
    super.dispose();
  }

  /// 服务设置变化时重新加载检测间隔。
  void _onServiceSettingsChanged() {
    unawaited(_reloadDetectionInterval());
  }

  /// 加载检测间隔并立即刷新状态。
  Future<void> _loadIntervalAndRefresh() async {
    final interval = await _service.getDetectionIntervalMinutes();
    if (!mounted) return;
    setState(() => _detectionIntervalMinutes = interval);
    await _refreshStatus();
  }

  /// 重新加载自动检测间隔。
  Future<void> _reloadDetectionInterval() async {
    final interval = await _service.getDetectionIntervalMinutes();
    if (!mounted) return;
    setState(() => _detectionIntervalMinutes = interval);
    _scheduleNextRefresh();
  }

  /// 刷新校园网状态。
  Future<void> _refreshStatus() async {
    if (_isChecking) return;
    _refreshTimer?.cancel();
    setState(() => _isChecking = true);
    final nextStatus = await _service.checkStatus();
    if (!mounted) return;
    setState(() {
      _status = nextStatus;
      _isChecking = false;
    });
    _scheduleNextRefresh();
  }

  /// 安排下一次自动检测。
  void _scheduleNextRefresh() {
    _refreshTimer?.cancel();
    if (_detectionIntervalMinutes <= 0) return;

    _refreshTimer = Timer(Duration(minutes: _detectionIntervalMinutes), () {
      unawaited(_refreshStatus());
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = _foregroundColor(colorScheme);
    final fillColor = _containerColor(colorScheme);

    return Tooltip(
      message: _tooltipMessage,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showLabel = constraints.maxWidth >= 96;
          return Semantics(
            button: true,
            label: '校园网状态，${_status.label}，点击重新检测',
            child: GestureDetector(
              key: const Key('campus-network-status-indicator'),
              behavior: HitTestBehavior.opaque,
              onTap: _isChecking ? null : _refreshStatus,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: AnimatedContainer(
                  duration: AppMotion.short,
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: showLabel ? AppSpacing.md : AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: fillColor,
                    border: Border.all(color: foregroundColor.withValues(alpha: 0.28)),
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusIcon(foregroundColor),
                      if (showLabel) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            _isChecking ? '检测中' : _status.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: foregroundColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建当前状态图标。
  Widget _buildStatusIcon(Color foregroundColor) {
    if (_isChecking) {
      return SizedBox.square(
        dimension: 20,
        child: FluentProgressRing(
          strokeWidth: 2,
          activeColor: foregroundColor,
        ),
      );
    }

    return Icon(_statusIcon, size: 20, color: foregroundColor);
  }

  IconData get _statusIcon {
    return switch (_status.accessMode) {
      CampusNetworkAccessMode.campus ||
      CampusNetworkAccessMode.vpn ||
      CampusNetworkAccessMode.campusOrVpn => Icons.power,
      CampusNetworkAccessMode.unavailable => Icons.power_off,
      CampusNetworkAccessMode.unknown => Icons.sync,
    };
  }

  Color _foregroundColor(ColorScheme colorScheme) {
    return switch (_status.accessMode) {
      CampusNetworkAccessMode.campus ||
      CampusNetworkAccessMode.vpn ||
      CampusNetworkAccessMode.campusOrVpn => colorScheme.primary,
      CampusNetworkAccessMode.unavailable => colorScheme.error,
      CampusNetworkAccessMode.unknown => colorScheme.onSurfaceVariant,
    };
  }

  Color _containerColor(ColorScheme colorScheme) {
    return switch (_status.accessMode) {
      CampusNetworkAccessMode.campus ||
      CampusNetworkAccessMode.vpn ||
      CampusNetworkAccessMode.campusOrVpn => colorScheme.primaryContainer,
      CampusNetworkAccessMode.unavailable => colorScheme.errorContainer,
      CampusNetworkAccessMode.unknown => colorScheme.surfaceContainerHighest,
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
