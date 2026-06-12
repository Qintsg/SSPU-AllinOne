/*
 * Fluent 底部抽屉 — 移动端低频入口与筛选面板容器
 * @Project : SSPU-AllinOne
 * @File : fluent_bottom_drawer.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

import '../fluent/fluent_context_ext.dart';

/// Fluent 底部抽屉容器。
class FluentBottomDrawer extends StatelessWidget {
  const FluentBottomDrawer({
    super.key,
    required this.child,
    this.title,
    this.maxHeightFactor = 0.82,
  });

  /// 标题。
  final Widget? title;

  /// 主体内容。
  final Widget child;

  /// 最大高度占屏幕比例。
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final type = context.fluentType;
    final media = MediaQuery.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: spacing.m,
          right: spacing.m,
          bottom: spacing.m + media.viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: media.size.height * maxHeightFactor,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.neutralBackground1,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(radii.xLarge),
                bottom: Radius.circular(radii.xLarge),
              ),
              border: Border.all(color: colors.neutralStroke2),
              boxShadow: context.fluentElevation.shadow28,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(spacing.l),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.neutralStroke1,
                          borderRadius: BorderRadius.circular(radii.circular),
                        ),
                      ),
                    ),
                    if (title != null) ...[
                      SizedBox(height: spacing.m),
                      DefaultTextStyle(
                        style: type.subtitle2.copyWith(
                          color: colors.neutralForeground1,
                        ),
                        child: title!,
                      ),
                    ],
                    SizedBox(height: spacing.m),
                    Flexible(
                      child: SingleChildScrollView(
                        primary: false,
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 打开 Fluent 底部抽屉。
Future<T?> showFluentBottomDrawer<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: '关闭底部抽屉',
    barrierColor: context.fluentColors.neutralForeground1.withValues(
      alpha: 0.32,
    ),
    transitionDuration: context.fluentMotion.durationSlow,
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final motion = context.fluentMotion;
      final curved = CurvedAnimation(
        parent: animation,
        curve: motion.curveDecelerateMid,
        reverseCurve: motion.curveAccelerateMid,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
