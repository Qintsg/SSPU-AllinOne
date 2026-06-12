/*
 * 卡片自动刷新控制器 — 统一业务卡片缓存刷新、静默刷新与手动反馈
 * @Project : SSPU-AllinOne
 * @File : card_auto_refresh_controller.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../widgets/refresh_feedback_action.dart';

/// 卡片刷新任务。
typedef CardRefreshTask<T> = Future<T> Function({required bool silent});

/// 判断刷新结果是否成功。
typedef CardRefreshSuccessPredicate<T> = bool Function(T result);

/// 从失败刷新结果提取短原因。
typedef CardRefreshFailureReason<T> = String Function(T result);

/// 将刷新结果写回页面状态。
typedef CardRefreshResultApplier<T> = void Function(T result);

/// 读取当前卡片数据的刷新时间。
typedef CardRefreshCheckedAtReader = DateTime? Function();

/// 控制校园业务卡片的自动刷新、静默刷新和手动刷新短反馈。
class CardAutoRefreshController<T> extends ChangeNotifier {
  /// 构造卡片刷新控制器。
  CardAutoRefreshController({
    required CardRefreshTask<T> refreshTask,
    required CardRefreshSuccessPredicate<T> isSuccess,
    required CardRefreshResultApplier<T> applyResult,
    required CardRefreshCheckedAtReader checkedAt,
    required CardRefreshFailureReason<T> failureReason,
    DateTime Function()? now,
    Duration feedbackDuration = const Duration(seconds: 3),
  }) : _refreshTask = refreshTask,
       _isSuccess = isSuccess,
       _applyResult = applyResult,
       _checkedAt = checkedAt,
       _failureReason = failureReason,
       _now = now ?? DateTime.now,
       _feedbackDuration = feedbackDuration;

  final CardRefreshTask<T> _refreshTask;
  final CardRefreshSuccessPredicate<T> _isSuccess;
  final CardRefreshResultApplier<T> _applyResult;
  final CardRefreshCheckedAtReader _checkedAt;
  final CardRefreshFailureReason<T> _failureReason;
  final DateTime Function() _now;
  final Duration _feedbackDuration;

  Timer? _autoRefreshTimer;
  Timer? _feedbackTimer;

  bool _isLoading = false;
  bool _autoRefreshEnabled = false;
  int _autoRefreshIntervalMinutes = 0;
  RefreshActionFeedback? _feedback;
  bool _disposed = false;

  /// 当前是否正在刷新。
  bool get isLoading => _isLoading;

  /// 当前是否启用自动刷新。
  bool get autoRefreshEnabled => _autoRefreshEnabled;

  /// 自动刷新间隔，单位分钟。
  int get autoRefreshIntervalMinutes => _autoRefreshIntervalMinutes;

  /// 手动刷新结束后的短暂反馈。
  RefreshActionFeedback? get feedback => _feedback;

  /// 清除加载态、反馈和定时器，用于凭据切换等场景。
  void clearTransientState({bool stopAutoRefresh = false}) {
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
    if (stopAutoRefresh) {
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;
      _autoRefreshEnabled = false;
      _autoRefreshIntervalMinutes = 0;
    }
    _isLoading = false;
    _feedback = null;
    _notifyIfAlive();
  }

  /// 应用自动刷新设置，并在数据过期时触发一次静默刷新。
  void configureAutoRefresh({
    required bool enabled,
    required int intervalMinutes,
    bool refreshIfStale = true,
  }) {
    _autoRefreshEnabled = enabled;
    _autoRefreshIntervalMinutes = intervalMinutes;
    _restartAutoRefreshTimer();
    _notifyIfAlive();
    if (refreshIfStale &&
        enabled &&
        shouldAutoRefresh(_checkedAt(), intervalMinutes)) {
      unawaited(runRefresh(silent: true));
    }
  }

  /// 执行刷新；静默刷新失败不会覆盖旧缓存，也不会显示反馈。
  Future<void> runRefresh({bool silent = false}) async {
    if (_isLoading) return;
    if (!silent) {
      _feedbackTimer?.cancel();
      _feedback = null;
    }
    _isLoading = true;
    _notifyIfAlive();

    final result = await _refreshTask(silent: silent);
    if (_disposed) return;
    final success = _isSuccess(result);
    if (silent && !success) {
      _isLoading = false;
      _notifyIfAlive();
      return;
    }

    _applyResult(result);
    _isLoading = false;
    if (!silent) _showFeedback(result);
    _notifyIfAlive();
  }

  /// 判断给定刷新时间是否已超过刷新间隔。
  bool shouldAutoRefresh(DateTime? fetchedAt, int intervalMinutes) {
    if (intervalMinutes <= 0) return false;
    if (fetchedAt == null) return true;
    return _now().difference(fetchedAt) >= Duration(minutes: intervalMinutes);
  }

  void _restartAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    if (!_autoRefreshEnabled || _autoRefreshIntervalMinutes <= 0) return;
    _autoRefreshTimer = Timer.periodic(
      Duration(minutes: _autoRefreshIntervalMinutes),
      (_) {
        if (shouldAutoRefresh(_checkedAt(), _autoRefreshIntervalMinutes)) {
          unawaited(runRefresh(silent: true));
        }
      },
    );
  }

  void _showFeedback(T result) {
    _feedbackTimer?.cancel();
    _feedback = _isSuccess(result)
        ? const RefreshActionFeedback.success()
        : RefreshActionFeedback.failure(_failureReason(result));
    _feedbackTimer = Timer(_feedbackDuration, () {
      _feedback = null;
      _notifyIfAlive();
    });
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autoRefreshTimer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }
}
