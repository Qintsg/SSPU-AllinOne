/*
 * 卡片自动刷新控制器测试 — 校验静默刷新、手动反馈与过期判断
 * @Project : SSPU-AllinOne
 * @File : card_auto_refresh_controller_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/controllers/card_auto_refresh_controller.dart';

class _RefreshResult {
  const _RefreshResult({
    required this.success,
    required this.checkedAt,
    this.reason = '',
  });

  final bool success;
  final DateTime checkedAt;
  final String reason;
}

void main() {
  test('静默刷新失败时不覆盖旧结果且不显示反馈', () async {
    var appliedResult = _RefreshResult(
      success: true,
      checkedAt: DateTime(2026, 6, 11, 8),
    );
    var fetchCount = 0;
    final controller = CardAutoRefreshController<_RefreshResult>(
      refreshTask: ({required bool silent}) async {
        fetchCount++;
        return _RefreshResult(
          success: false,
          checkedAt: DateTime(2026, 6, 11, 9),
          reason: '网络不可用',
        );
      },
      isSuccess: (result) => result.success,
      applyResult: (result) => appliedResult = result,
      checkedAt: () => appliedResult.checkedAt,
      failureReason: (result) => result.reason,
      now: () => DateTime(2026, 6, 11, 10),
    );
    addTearDown(controller.dispose);

    final outcome = await controller.runRefresh(silent: true);

    expect(fetchCount, 1);
    expect(appliedResult.success, isTrue);
    expect(appliedResult.checkedAt, DateTime(2026, 6, 11, 8));
    expect(controller.isLoading, isFalse);
    expect(controller.feedback, isNull);
    expect(outcome?.result?.success, isFalse);
    expect(outcome?.success, isFalse);
    expect(outcome?.applied, isFalse);
  });

  test('刷新任务抛出异常后解除加载锁并返回失败结果', () async {
    final controller = CardAutoRefreshController<_RefreshResult>(
      refreshTask: ({required bool silent}) =>
          Future<_RefreshResult>.error(StateError('network exploded')),
      isSuccess: (result) => result.success,
      applyResult: (_) {},
      checkedAt: () => null,
      failureReason: (result) => result.reason,
    );
    addTearDown(controller.dispose);

    final outcome = await controller.runRefresh(silent: true);

    expect(outcome?.success, isFalse);
    expect(outcome?.applied, isFalse);
    expect(outcome?.error, isA<StateError>());
    expect(controller.isLoading, isFalse);
  });

  test('清除瞬态状态后旧代请求不得覆盖新代结果', () async {
    final first = Completer<_RefreshResult>();
    final second = Completer<_RefreshResult>();
    var callCount = 0;
    _RefreshResult? appliedResult;
    final controller = CardAutoRefreshController<_RefreshResult>(
      refreshTask: ({required bool silent}) {
        callCount++;
        return callCount == 1 ? first.future : second.future;
      },
      isSuccess: (result) => result.success,
      applyResult: (result) => appliedResult = result,
      checkedAt: () => appliedResult?.checkedAt,
      failureReason: (result) => result.reason,
    );
    addTearDown(controller.dispose);

    final oldRequest = controller.runRefresh(silent: true);
    controller.clearTransientState();
    final newRequest = controller.runRefresh(silent: true);
    final newResult = _RefreshResult(
      success: true,
      checkedAt: DateTime(2026, 7, 29, 10),
    );
    second.complete(newResult);
    expect((await newRequest)?.applied, isTrue);
    expect(appliedResult, same(newResult));

    first.complete(
      _RefreshResult(success: true, checkedAt: DateTime(2026, 7, 29, 9)),
    );
    expect((await oldRequest)?.applied, isFalse);
    expect(appliedResult, same(newResult));
    expect(controller.isLoading, isFalse);
  });

  testWidgets('手动刷新失败显示短反馈并在三秒后恢复', (tester) async {
    late _RefreshResult appliedResult;
    final controller = CardAutoRefreshController<_RefreshResult>(
      refreshTask: ({required bool silent}) async {
        return _RefreshResult(
          success: false,
          checkedAt: DateTime(2026, 6, 11, 9),
          reason: '校园网/VPN不可用',
        );
      },
      isSuccess: (result) => result.success,
      applyResult: (result) => appliedResult = result,
      checkedAt: () => DateTime(2026, 6, 11, 8),
      failureReason: (result) => result.reason,
    );
    addTearDown(controller.dispose);

    await controller.runRefresh();

    expect(appliedResult.success, isFalse);
    expect(controller.feedback?.label, '刷新失败:校园网/VPN不可用×');

    await tester.pump(const Duration(seconds: 3));

    expect(controller.feedback, isNull);
  });

  test('自动刷新过期判断使用配置间隔', () {
    final controller = CardAutoRefreshController<_RefreshResult>(
      refreshTask: ({required bool silent}) async {
        return _RefreshResult(
          success: true,
          checkedAt: DateTime(2026, 6, 11, 10),
        );
      },
      isSuccess: (result) => result.success,
      applyResult: (_) {},
      checkedAt: () => DateTime(2026, 6, 11, 8),
      failureReason: (result) => result.reason,
      now: () => DateTime(2026, 6, 11, 10),
    );
    addTearDown(controller.dispose);

    expect(controller.shouldAutoRefresh(null, 30), isTrue);
    expect(
      controller.shouldAutoRefresh(DateTime(2026, 6, 11, 9, 45), 30),
      isFalse,
    );
    expect(
      controller.shouldAutoRefresh(DateTime(2026, 6, 11, 9, 29), 30),
      isTrue,
    );
    expect(controller.shouldAutoRefresh(DateTime(2026, 6, 11, 8), 0), isFalse);
  });
}
