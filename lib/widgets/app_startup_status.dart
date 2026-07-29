/* 清源应用启动状态表面。 */

import '../design/qingyuan/qingyuan_ui.dart';

/// 应用初始化阶段的确定性加载或错误表面。
class AppStartupStatus extends StatelessWidget {
  const AppStartupStatus({
    super.key,
    this.progressLabel,
    this.errorMessage,
    this.onRetry,
  }) : assert(progressLabel == null || errorMessage == null),
       assert((errorMessage == null) == (onRetry == null));

  final String? progressLabel;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final hasError = errorMessage != null;
    return YhPageScaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.m),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: theme.control.regular * 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.color.surface,
                border: Border.all(color: theme.color.border),
                borderRadius: BorderRadius.circular(theme.radius.l),
                boxShadow: theme.elevation.e2,
              ),
              child: Padding(
                padding: EdgeInsets.all(theme.spacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _StartupBrandMark(theme: theme),
                    ),
                    SizedBox(height: theme.spacing.m),
                    Text(
                      '应用启动',
                      style: theme.typography.caption.copyWith(
                        color: theme.color.brandStrong,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: theme.spacing.s),
                    Semantics(
                      header: true,
                      child: Text(
                        hasError ? '暂时无法启动' : '正在准备清源',
                        style: theme.typography.h1.copyWith(
                          color: theme.color.foreground,
                        ),
                      ),
                    ),
                    SizedBox(height: theme.spacing.s),
                    Text(
                      hasError
                          ? '本地设置或缓存还未就绪，没有访问校园服务。'
                          : '先恢复本地设置与安全状态，再决定是否访问校园服务。',
                      style: theme.typography.body.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                    SizedBox(height: theme.spacing.l),
                    if (hasError) ...[
                      YhBanner(
                        text: '$errorMessage请检查应用数据目录权限后重试。',
                        kind: YhBannerKind.danger,
                      ),
                      if (onRetry != null) ...[
                        SizedBox(height: theme.spacing.m),
                        Align(
                          alignment: Alignment.centerRight,
                          child: YhButton(
                            label: '重试启动',
                            leadingIcon: YhIcons.refresh,
                            autofocus: true,
                            onTap: onRetry,
                          ),
                        ),
                      ],
                    ] else ...[
                      YhProgress(
                        showPercent: false,
                        semanticLabel: progressLabel ?? '正在准备清源',
                      ),
                      SizedBox(height: theme.spacing.m),
                      _StartupStep(
                        label: progressLabel ?? '读取本地设置',
                        active: true,
                      ),
                      const _StartupStep(label: '恢复账户状态'),
                      const _StartupStep(label: '准备校园服务'),
                    ],
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

class _StartupBrandMark extends StatelessWidget {
  const _StartupBrandMark({required this.theme});

  final YhTheme theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.structural,
        borderRadius: BorderRadius.circular(theme.radius.l),
      ),
      child: SizedBox.square(
        dimension: theme.control.regular + theme.spacing.l,
        child: Center(
          child: Text(
            '源',
            style: theme.typography.h1.copyWith(
              color: theme.color.onStructural,
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupStep extends StatelessWidget {
  const _StartupStep({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Semantics(
      liveRegion: active,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? theme.color.brandTint : null,
          borderRadius: BorderRadius.circular(theme.radius.input),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: theme.control.minimumTarget),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? theme.color.brandStrong : null,
                    border: Border.all(
                      color: active
                          ? theme.color.brandStrong
                          : theme.color.muted,
                    ),
                  ),
                  child: SizedBox.square(dimension: theme.spacing.s),
                ),
                SizedBox(width: theme.spacing.s),
                Expanded(
                  child: Text(
                    label,
                    style: theme.typography.body.copyWith(
                      color: active ? theme.color.brandInk : theme.color.muted,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
