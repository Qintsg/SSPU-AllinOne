/* 保留式刷新协调 — 单飞、有效内容保留与异步代次隔离。 */

// Public strategy parameters initialize private fields without leaking private
// names into the shared controller API.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

typedef RetainedRefreshTask<T> = Future<T?> Function();

/// 将远程刷新复杂性收敛在一个小接口后的深模块。
///
/// 调用方只提供成功、可保留内容和失败文案三项领域判断；模块负责：
/// - 重复刷新共享同一任务；
/// - 失败时保留仍有效的当前结果；
/// - 外部结果换代或销毁后丢弃旧任务完成；
/// - null 与异常使用稳定、可恢复的失败状态。
class RetainedRefreshController<T> extends ChangeNotifier {
  RetainedRefreshController({
    required T? initialResult,
    required bool Function(T result) isSuccess,
    required bool Function(T result) hasUsableContent,
    required String Function(T result) failureMessage,
  }) : _result = initialResult,
       _isSuccess = isSuccess,
       _hasUsableContent = hasUsableContent,
       _failureMessage = failureMessage;

  final bool Function(T result) _isSuccess;
  final bool Function(T result) _hasUsableContent;
  final String Function(T result) _failureMessage;

  T? _result;
  bool _isRefreshing = false;
  String? _retainedFailure;
  Future<void>? _activeRefresh;
  int _generation = 0;
  bool _disposed = false;

  T? get result => _result;
  bool get isRefreshing => _isRefreshing;
  String? get retainedFailure => _retainedFailure;

  /// 用宿主的新代结果整体替换当前状态，并使进行中的旧请求失效。
  void updateExternalResult(T? result) {
    if (_disposed) return;
    final resultChanged = !identical(result, _result);
    final invalidatedRefresh = _isRefreshing;
    if (invalidatedRefresh) {
      _generation++;
      _isRefreshing = false;
      _activeRefresh = null;
    }
    if (!resultChanged && !invalidatedRefresh) return;
    _result = result;
    _retainedFailure = null;
    notifyListeners();
  }

  Future<void> refresh(RetainedRefreshTask<T>? task) {
    if (task == null) return Future.value();
    final active = _activeRefresh;
    if (active != null) return active;
    final future = _performRefresh(task);
    _activeRefresh = future;
    return future.whenComplete(() {
      if (identical(_activeRefresh, future)) _activeRefresh = null;
    });
  }

  Future<void> _performRefresh(RetainedRefreshTask<T> task) async {
    final generation = _generation;
    _isRefreshing = true;
    _retainedFailure = null;
    notifyListeners();
    try {
      final next = await task();
      if (_disposed || generation != _generation) return;
      if (next == null) {
        _retainedFailure = '刷新未完成；当前内容已保留，可稍后重试。';
        return;
      }
      if (_isSuccess(next)) {
        _result = next;
        _retainedFailure = null;
      } else if (_result != null && _hasUsableContent(_result as T)) {
        _retainedFailure = _failureMessage(next);
      } else {
        _result = next;
      }
    } on Object catch (_) {
      if (_disposed || generation != _generation) return;
      _retainedFailure = '刷新未完成；当前内容已保留，可稍后重试。';
    } finally {
      if (!_disposed && generation == _generation) {
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
