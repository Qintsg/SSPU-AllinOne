/* 教务详情刷新展示协调 — 单飞、旧内容保留与页面销毁隔离。 */

// Public named parameters initialize private strategy fields for a small seam.
// ignore_for_file: prefer_initializing_formals

part of 'academic_page.dart';

typedef AcademicDetailRefreshTask<T> = Future<T?> Function();

class AcademicDetailRefreshController<T> extends ChangeNotifier {
  AcademicDetailRefreshController({
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

  void updateExternalResult(T? result) {
    if (_disposed || identical(result, _result)) return;
    if (_isRefreshing) {
      _generation++;
      _isRefreshing = false;
      _activeRefresh = null;
    }
    _result = result;
    _retainedFailure = null;
    notifyListeners();
  }

  Future<void> refresh(AcademicDetailRefreshTask<T>? task) {
    if (task == null) return Future.value();
    final active = _activeRefresh;
    if (active != null) return active;
    final future = _performRefresh(task);
    _activeRefresh = future;
    return future.whenComplete(() {
      if (identical(_activeRefresh, future)) _activeRefresh = null;
    });
  }

  Future<void> _performRefresh(AcademicDetailRefreshTask<T> task) async {
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

class _AcademicDetailStateCard extends StatelessWidget {
  const _AcademicDetailStateCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    return YhCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // YhCard 已提供 24dp 上下内边距；这里约束内容区，使整卡
          // 分别达到紧凑端 7×48dp、宽屏 9×48dp 的设计高度。
          minHeight: theme.control.regular * (compact ? 6 : 8),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _AcademicDetailLoadingState extends StatelessWidget {
  const _AcademicDetailLoadingState({
    required this.title,
    required this.source,
  });

  final String title;
  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: title,
          value: '加载中',
          child: SizedBox.square(
            dimension: theme.control.minimumTarget,
            child: CustomPaint(
              painter: _AcademicDetailSpinnerPainter(
                trackColor: theme.color.border,
                activeColor: theme.color.brandStrong,
              ),
            ),
          ),
        ),
        SizedBox(height: theme.spacing.l),
        Text(title, textAlign: TextAlign.center, style: theme.typography.h2),
        SizedBox(height: theme.spacing.s),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.control.regular * 11),
          child: Text(
            '正在从$source恢复数据；页面来源和返回路径保持可用。',
            textAlign: TextAlign.center,
            style: theme.typography.body.copyWith(color: theme.color.muted),
          ),
        ),
      ],
    );
  }
}

class _AcademicDetailMessageState extends StatelessWidget {
  const _AcademicDetailMessageState({
    required this.symbol,
    required this.title,
    required this.message,
    required this.accent,
    required this.actionLabel,
    required this.onAction,
  });

  final String symbol;
  final String title;
  final String message;
  final Color accent;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: theme.layout.bottomNavigationHeight,
          height: theme.layout.bottomNavigationHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(theme.radius.l),
          ),
          child: Text(
            symbol,
            style: theme.typography.display.copyWith(
              color: accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: theme.spacing.l),
        Text(title, textAlign: TextAlign.center, style: theme.typography.h2),
        SizedBox(height: theme.spacing.s),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.control.regular * 11),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.typography.body.copyWith(color: theme.color.muted),
          ),
        ),
        SizedBox(height: theme.spacing.l),
        YhButton(
          label: actionLabel,
          variant: YhButtonVariant.secondary,
          onTap: onAction,
        ),
      ],
    );
  }
}

class _AcademicDetailSpinnerPainter extends CustomPainter {
  const _AcademicDetailSpinnerPainter({
    required this.trackColor,
    required this.activeColor,
  });

  final Color trackColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide / 12;
    final bounds = Offset.zero & size;
    final arcBounds = bounds.deflate(strokeWidth / 2);
    canvas.drawCircle(
      bounds.center,
      (size.shortestSide - strokeWidth) / 2,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawArc(
      arcBounds,
      -math.pi / 2,
      math.pi * 0.72,
      false,
      Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _AcademicDetailSpinnerPainter oldDelegate) {
    return trackColor != oldDelegate.trackColor ||
        activeColor != oldDelegate.activeColor;
  }
}

Future<void> _showAcademicDetailFailure(
  BuildContext context, {
  required String title,
  required String message,
  required String detail,
}) {
  return YhDialog.show<void>(
    context,
    builder: (dialogContext) => YhDialog(
      eyebrow: '最近一次读取',
      title: title,
      content: Text('$message：$detail'),
      actions: [
        YhButton(
          label: '关闭',
          variant: YhButtonVariant.secondary,
          onTap: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}
