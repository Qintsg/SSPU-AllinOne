/*
 * Fluent 数据状态 — 页面与磁贴统一表达未配置、加载、就绪、降级和失败
 * @Project : SSPU-AllinOne
 * @File : fluent_data_state.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

/// 业务数据展示状态。
enum FluentDataState {
  /// 缺少账号、密码或必要设置。
  notConfigured,

  /// 正在加载，允许继续显示旧缓存。
  loading,

  /// 数据完整可用。
  ready,

  /// 使用缓存或部分数据降级展示。
  degraded,

  /// 当前无可用数据且刷新失败。
  failed,
}

/// 数据状态展示文案。
extension FluentDataStateLabel on FluentDataState {
  /// 用户可读名称。
  String get label {
    return switch (this) {
      FluentDataState.notConfigured => '未配置',
      FluentDataState.loading => '加载中',
      FluentDataState.ready => '就绪',
      FluentDataState.degraded => '降级',
      FluentDataState.failed => '失败',
    };
  }
}
