/*
 * 校园网状态检测服务测试 — 校验可达、不可达与异常兜底语义
 * @Project : SSPU-AllinOne
 * @File : campus_network_status_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-27
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/campus_network_status.dart';
import 'package:sspu_allinone/services/campus_network_status_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  final campusProbeUri = Uri.parse('https://tygl.sspu.edu.cn/');
  final vpnProbeUri = Uri.parse('https://vpn.sspu.edu.cn/');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    SharedPreferences.setMockInitialValues({});
  });

  test('VPN 入口和校园站点均可达时返回 VPN 环境', () async {
    final service = _buildService(
      campusProbeUri: campusProbeUri,
      vpnProbeUri: vpnProbeUri,
      vpnReachable: true,
      campusReachable: true,
    );

    final status = await service.checkStatus();

    expect(status.accessMode, CampusNetworkAccessMode.vpn);
    expect(status.canAccessRestrictedServices, isTrue);
    expect(status.probeUri, campusProbeUri);
    expect(status.vpnProbeUri, vpnProbeUri);
    expect(status.checkedAt, isNotNull);
  });

  test('仅校园站点可达时返回校园网环境', () async {
    final service = _buildService(
      campusProbeUri: campusProbeUri,
      vpnProbeUri: vpnProbeUri,
      vpnReachable: false,
      campusReachable: true,
    );

    final status = await service.checkStatus();

    expect(status.accessMode, CampusNetworkAccessMode.campus);
    expect(status.canAccessRestrictedServices, isTrue);
  });

  test('仅 VPN 入口可达时返回非校园网环境', () async {
    final service = _buildService(
      campusProbeUri: campusProbeUri,
      vpnProbeUri: vpnProbeUri,
      vpnReachable: true,
      campusReachable: false,
    );

    final status = await service.checkStatus();

    expect(status.accessMode, CampusNetworkAccessMode.outsideCampus);
    expect(status.canAccessRestrictedServices, isFalse);
    expect(status.description, contains('连接校园网或学校 VPN'));
  });

  test('双探针均不可达时返回网络环境未知', () async {
    final service = _buildService(
      campusProbeUri: campusProbeUri,
      vpnProbeUri: vpnProbeUri,
      vpnReachable: false,
      campusReachable: false,
    );

    final status = await service.checkStatus();

    expect(status.accessMode, CampusNetworkAccessMode.unknown);
    expect(status.canAccessRestrictedServices, isFalse);
  });

  test('单个探针抛出异常时不影响另一个探针判定', () async {
    final service = CampusNetworkStatusService(
      probeUri: campusProbeUri,
      vpnProbeUri: vpnProbeUri,
      probe: (uri, timeout) async {
        if (uri.host == vpnProbeUri.host) throw StateError('probe failed');
        return CampusNetworkProbeResult(
          reachable: true,
          statusCode: 200,
          detail: '已访问 ${uri.host}，HTTP 200',
        );
      },
    );

    final status = await service.checkStatus();

    expect(status.accessMode, CampusNetworkAccessMode.campus);
    expect(status.detail, contains('probe failed'));
  });

  test('检测间隔默认 15 分钟并支持关闭自动检测', () async {
    final service = CampusNetworkStatusService(probeUri: campusProbeUri);

    expect(
      await service.getDetectionIntervalMinutes(),
      CampusNetworkStatusService.defaultDetectionIntervalMinutes,
    );

    await service.setDetectionIntervalMinutes(30);
    expect(await service.getDetectionIntervalMinutes(), 30);

    await service.setDetectionIntervalMinutes(-1);
    expect(await service.getDetectionIntervalMinutes(), 0);
  });

  test('共享刷新会合并同时触发的检测请求', () async {
    var probeCount = 0;
    final service = CampusNetworkStatusService(
      probeUri: campusProbeUri,
      vpnProbeUri: vpnProbeUri,
      probe: (uri, timeout) async {
        probeCount++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return CampusNetworkProbeResult(
          reachable: true,
          statusCode: 200,
          detail: '已访问 ${uri.host}，HTTP 200',
        );
      },
    );

    final firstRefresh = service.refreshStatus();
    final secondRefresh = service.refreshStatus();
    final statuses = await Future.wait([firstRefresh, secondRefresh]);

    expect(statuses.first.accessMode, CampusNetworkAccessMode.vpn);
    expect(statuses.last.accessMode, CampusNetworkAccessMode.vpn);
    expect(service.currentStatus.accessMode, CampusNetworkAccessMode.vpn);
    expect(service.isChecking, isFalse);
    expect(probeCount, 2);
  });
}

CampusNetworkStatusService _buildService({
  required Uri campusProbeUri,
  required Uri vpnProbeUri,
  required bool vpnReachable,
  required bool campusReachable,
}) {
  return CampusNetworkStatusService(
    probeUri: campusProbeUri,
    vpnProbeUri: vpnProbeUri,
    probe: (uri, timeout) async {
      final reachable = uri.host == vpnProbeUri.host
          ? vpnReachable
          : campusReachable;
      return CampusNetworkProbeResult(
        reachable: reachable,
        statusCode: reachable ? 200 : null,
        detail: reachable ? '已访问 ${uri.host}，HTTP 200' : '访问 ${uri.host} 超时',
      );
    },
  );
}
