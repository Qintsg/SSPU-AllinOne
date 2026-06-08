/*
 * 校园网状态模型 — 描述校园网 / VPN 前置检测结果
 * @Project : SSPU-AllinOne
 * @File : campus_network_status.dart
 * @Author : Qintsg
 * @Date : 2026-04-27
 */

/// 校园受限服务可访问模式。
///
/// 通过 VPN 入口与体育部站点双探针区分 VPN、校园网、校外网络与未知网络。
enum CampusNetworkAccessMode {
  /// 尚未完成检测或检测状态不可确定。
  unknown,

  /// 已识别为校园网直连。
  campus,

  /// 已识别为学校 VPN 连接。
  vpn,

  /// 已识别为非校园网环境，受限校园服务暂不可用。
  outsideCampus,
}

/// 校园网 / VPN 前置检测结果。
/// 供 UI 展示与后续教务、校园卡、学工报表等受限功能复用。
class CampusNetworkStatus {
  const CampusNetworkStatus({
    required this.accessMode,
    required this.probeUri,
    required this.detail,
    this.vpnProbeUri,
    this.checkedAt,
  });

  /// 构建初始未知状态，避免 UI 在首次检测前误报未连接。
  factory CampusNetworkStatus.unknown({
    required Uri probeUri,
    Uri? vpnProbeUri,
  }) {
    return CampusNetworkStatus(
      accessMode: CampusNetworkAccessMode.unknown,
      probeUri: probeUri,
      vpnProbeUri: vpnProbeUri,
      detail: '尚未检测校园网 / VPN 状态',
    );
  }

  /// 校园网 / VPN 访问模式。
  final CampusNetworkAccessMode accessMode;

  /// 本次检测使用的目标地址。
  ///
  /// 双探针检测中该地址表示校园受限站点探针。
  final Uri probeUri;

  /// 本次检测使用的 VPN 入口探针地址。
  final Uri? vpnProbeUri;

  /// 检测完成时间；未知状态下为空。
  final DateTime? checkedAt;

  /// 面向用户和调试的简短说明。
  final String detail;

  /// 受限校园查询入口是否可以继续访问。
  bool get canAccessRestrictedServices {
    return switch (accessMode) {
      CampusNetworkAccessMode.campus || CampusNetworkAccessMode.vpn => true,
      CampusNetworkAccessMode.unknown ||
      CampusNetworkAccessMode.outsideCampus => false,
    };
  }

  /// 顶栏徽标展示文案。
  String get label {
    return switch (accessMode) {
      CampusNetworkAccessMode.campus => '校园网',
      CampusNetworkAccessMode.vpn => 'VPN 环境',
      CampusNetworkAccessMode.outsideCampus => '非校园网',
      CampusNetworkAccessMode.unknown => '网络未知',
    };
  }

  /// 小尺寸状态指示使用的短文案。
  String get shortLabel {
    return switch (accessMode) {
      CampusNetworkAccessMode.campus => '校园网',
      CampusNetworkAccessMode.vpn => 'VPN',
      CampusNetworkAccessMode.outsideCampus => '校外',
      CampusNetworkAccessMode.unknown => '未知',
    };
  }

  /// 状态详情，用于 Tooltip 和后续入口拦截提示。
  String get description {
    return switch (accessMode) {
      CampusNetworkAccessMode.campus => '当前处于校园网环境，可访问受限查询服务。',
      CampusNetworkAccessMode.vpn => '当前已连接学校 VPN，可访问受限查询服务。',
      CampusNetworkAccessMode.outsideCampus =>
        '当前处于非校园网环境，教务等受限查询入口需要先连接校园网或学校 VPN。',
      CampusNetworkAccessMode.unknown => '暂无法确认当前网络环境，请检查网络后重新检测。',
    };
  }
}
