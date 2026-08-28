/*
 * 校园网状态检测服务 — 通过可替换探针检测校园网 / VPN 可达性
 * @Project : SSPU-AllinOne
 * @File : campus_network_status_service.dart
 * @Author : Qintsg
 * @Date : 2026-04-27
 */

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/campus_network_status.dart';
import 'http_service.dart';
import 'storage_service.dart';

/// 校园网检测探针签名。
typedef CampusNetworkProbe =
    Future<CampusNetworkProbeResult> Function(Uri probeUri, Duration timeout);

/// 单次探针访问结果。
class CampusNetworkProbeResult {
  const CampusNetworkProbeResult({
    required this.reachable,
    required this.detail,
    this.statusCode,
  });

  /// 目标校园站点是否成功返回可用 HTTP 响应。
  final bool reachable;

  /// 探针结果说明。
  final String detail;

  /// HTTP 状态码；连接失败或超时时为空。
  final int? statusCode;
}

/// 校园网 / VPN 前置检测服务。
class CampusNetworkStatusService extends ChangeNotifier {
  CampusNetworkStatusService({
    CampusNetworkProbe? probe,
    Uri? probeUri,
    Uri? vpnProbeUri,
    Duration? timeout,
  }) : _probe = probe ?? _defaultProbe,
       probeUri = probeUri ?? defaultProbeUri,
       vpnProbeUri = vpnProbeUri ?? defaultVpnProbeUri,
       timeout = timeout ?? const Duration(seconds: 5) {
    _currentStatus = CampusNetworkStatus.unknown(
      probeUri: this.probeUri,
      vpnProbeUri: this.vpnProbeUri,
    );
  }

  /// 全局单例，供应用顶栏与后续受限入口共用。
  static final CampusNetworkStatusService instance =
      CampusNetworkStatusService();

  /// 默认校园受限站点检测目标：体育部查询系统域名。
  static final Uri defaultProbeUri = defaultCampusProbeUri;

  /// 默认校园受限站点检测目标：体育部查询系统域名。
  static final Uri defaultCampusProbeUri = Uri.parse(
    'https://tygl.sspu.edu.cn/',
  );

  /// 默认 VPN 入口检测目标：学校 VPN 入口域名。
  static final Uri defaultVpnProbeUri = Uri.parse('https://vpn.sspu.edu.cn/');

  /// 默认检测间隔，兼顾状态新鲜度与校园站点访问频率。
  static const int defaultDetectionIntervalMinutes = 15;

  /// 实际校园受限站点检测目标地址。
  final Uri probeUri;

  /// 实际 VPN 入口检测目标地址。
  final Uri vpnProbeUri;

  /// 单次检测超时时间，避免启动后长期占用 UI 状态。
  final Duration timeout;

  final CampusNetworkProbe _probe;

  late CampusNetworkStatus _currentStatus;

  /// 当前缓存的校园网 / VPN 状态，供多个入口共享展示。
  CampusNetworkStatus get currentStatus => _currentStatus;

  /// 当前自动检测间隔；0 表示只允许手动刷新。
  int get detectionIntervalMinutes => _detectionIntervalMinutes;

  /// 当前是否已有检测任务在执行。
  bool get isChecking => _isChecking;

  int _detectionIntervalMinutes = defaultDetectionIntervalMinutes;
  int _activeStatusConsumerCount = 0;
  bool _isChecking = false;
  Timer? _refreshTimer;
  Future<CampusNetworkStatus>? _refreshFuture;

  /// 启动共享状态监听；首次有展示入口挂载时立即刷新一次。
  Future<void> startStatusMonitoring() async {
    _activeStatusConsumerCount++;
    if (_activeStatusConsumerCount > 1) return;

    await _loadDetectionIntervalFromStorage();
    if (_activeStatusConsumerCount <= 0) return;
    await refreshStatus();
  }

  /// 停止共享状态监听；最后一个展示入口卸载时取消自动刷新。
  void stopStatusMonitoring() {
    if (_activeStatusConsumerCount <= 0) return;

    _activeStatusConsumerCount--;
    if (_activeStatusConsumerCount > 0) return;

    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 刷新共享校园网 / VPN 状态，并合并同时触发的检测请求。
  Future<CampusNetworkStatus> refreshStatus() {
    final pendingRefresh = _refreshFuture;
    if (pendingRefresh != null) return pendingRefresh;

    _refreshTimer?.cancel();
    _refreshTimer = null;
    _isChecking = true;

    final refresh = _refreshAndStoreStatus();
    _refreshFuture = refresh;
    notifyListeners();
    return refresh;
  }

  /// 执行一次校园网 / VPN 状态检测。
  Future<CampusNetworkStatus> checkStatus() async {
    final results = await Future.wait([
      _safeProbe(vpnProbeUri),
      _safeProbe(probeUri),
    ]);
    final vpnResult = results.first;
    final campusResult = results.last;

    return CampusNetworkStatus(
      accessMode: _resolveAccessMode(
        vpnReachable: vpnResult.reachable,
        campusReachable: campusResult.reachable,
      ),
      probeUri: probeUri,
      vpnProbeUri: vpnProbeUri,
      checkedAt: DateTime.now(),
      detail: 'VPN 入口：${vpnResult.detail}\n校园站点：${campusResult.detail}',
    );
  }

  /// 读取校园网 / VPN 状态自动检测间隔。
  Future<int> getDetectionIntervalMinutes() async {
    final stored = await StorageService.getInt(
      StorageKeys.campusNetworkDetectionIntervalMinutes,
    );
    return _normalizeInterval(stored ?? defaultDetectionIntervalMinutes);
  }

  /// 保存校园网 / VPN 状态自动检测间隔并通知现有徽标立即重排定时器。
  Future<void> setDetectionIntervalMinutes(int minutes) async {
    final normalized = _normalizeInterval(minutes);
    await StorageService.setInt(
      StorageKeys.campusNetworkDetectionIntervalMinutes,
      normalized,
    );
    _detectionIntervalMinutes = normalized;
    _scheduleNextRefresh();
    notifyListeners();
  }

  Future<void> _loadDetectionIntervalFromStorage() async {
    _detectionIntervalMinutes = await getDetectionIntervalMinutes();
    _scheduleNextRefresh();
    notifyListeners();
  }

  Future<CampusNetworkStatus> _refreshAndStoreStatus() async {
    try {
      final nextStatus = await checkStatus();
      _currentStatus = nextStatus;
      return nextStatus;
    } finally {
      _isChecking = false;
      _refreshFuture = null;
      _scheduleNextRefresh();
      notifyListeners();
    }
  }

  void _scheduleNextRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (_activeStatusConsumerCount <= 0 || _detectionIntervalMinutes <= 0) {
      return;
    }

    _refreshTimer = Timer(Duration(minutes: _detectionIntervalMinutes), () {
      unawaited(refreshStatus());
    });
  }

  /// 间隔只接受非负分钟数；0 表示关闭自动检测但保留手动点击刷新。
  int _normalizeInterval(int minutes) {
    return minutes < 0 ? 0 : minutes;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// 执行单个探针并将异常收敛为不可达结果，避免一次失败中断整体判定。
  Future<CampusNetworkProbeResult> _safeProbe(Uri uri) async {
    try {
      return await _probe(uri, timeout);
    } catch (error) {
      return CampusNetworkProbeResult(
        reachable: false,
        detail: '访问 ${uri.host} 失败：$error',
      );
    }
  }

  /// 按双探针结果解析当前网络环境。
  CampusNetworkAccessMode _resolveAccessMode({
    required bool vpnReachable,
    required bool campusReachable,
  }) {
    if (vpnReachable && campusReachable) return CampusNetworkAccessMode.vpn;
    if (!vpnReachable && campusReachable) return CampusNetworkAccessMode.campus;
    if (vpnReachable && !campusReachable) {
      return CampusNetworkAccessMode.outsideCampus;
    }
    return CampusNetworkAccessMode.unknown;
  }

  /// 默认探针只发起只读 GET 请求；任何非 5xx HTTP 响应都表示内网域名可达。
  static Future<CampusNetworkProbeResult> _defaultProbe(
    Uri probeUri,
    Duration timeout,
  ) async {
    try {
      final response = await HttpService.instance.dio
          .getUri<Object>(
            probeUri,
            options: Options(
              followRedirects: false,
              receiveTimeout: timeout,
              responseType: ResponseType.plain,
              sendTimeout: timeout,
              validateStatus: (statusCode) => statusCode != null,
            ),
          )
          .timeout(timeout);
      final statusCode = response.statusCode;
      final reachable = statusCode != null && statusCode < 500;
      return CampusNetworkProbeResult(
        reachable: reachable,
        statusCode: statusCode,
        detail: reachable
            ? '已访问 ${probeUri.host}，HTTP $statusCode'
            : '${probeUri.host} 返回 HTTP $statusCode',
      );
    } on TimeoutException {
      return CampusNetworkProbeResult(
        reachable: false,
        detail: '访问 ${probeUri.host} 超时',
      );
    } on DioException catch (error) {
      return CampusNetworkProbeResult(
        reachable: false,
        statusCode: error.response?.statusCode,
        detail: HttpService.describeError(error),
      );
    }
  }
}
