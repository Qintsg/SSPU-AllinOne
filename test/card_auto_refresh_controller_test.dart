/*
 * 卡片自动刷新控制器测试 — 校验静默刷新、手动反馈与过期判断
 * @Project : SSPU-AllinOne
 * @File : card_auto_refresh_controller_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

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

    await controller.runRefresh(silent: true);

    expect(fetchCount, 1);
    expect(appliedResult.success, isTrue);
    expect(appliedResult.checkedAt, DateTime(2026, 6, 11, 8));
    expect(controller.isLoading, isFalse);
    expect(controller.feedback, isNull);
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
