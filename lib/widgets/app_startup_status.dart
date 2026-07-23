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
    return YhPageScaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.l),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: theme.breakpoint.compact - theme.spacing.xl2 * 2,
            ),
            child: errorMessage != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      YhBanner(
                        text: '$errorMessage 应用尚未进入主界面。请重试；若问题持续，请检查本地存储权限。',
                        kind: YhBannerKind.danger,
                      ),
                      if (onRetry != null) ...[
                        SizedBox(height: theme.spacing.m),
                        Align(
                          alignment: Alignment.centerRight,
                          child: YhButton(
                            label: '重试初始化',
                            leadingIcon: YhIcons.refresh,
                            autofocus: true,
                            onTap: onRetry,
                          ),
                        ),
                      ],
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      YhProgress(
                        showPercent: false,
                        semanticLabel: progressLabel,
                      ),
                      SizedBox(height: theme.spacing.m),
                      Text(
                        progressLabel ?? '正在启动',
                        textAlign: TextAlign.center,
                        style: theme.typography.small.copyWith(
                          color: theme.color.muted,
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
