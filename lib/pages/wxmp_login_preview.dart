/*
 * 微信公众号扫码登录确定性预览模块 — 八态内容与外部区域
 * @Project : SSPU-AllinOne
 * @File : wxmp_login_preview.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

import '../design/qingyuan/qingyuan_ui.dart';

/// 公众号扫码登录的确定性视觉状态；仅供设计 fixture 和 Widget 测试注入。
enum WxmpLoginPreviewState {
  loading,
  initial,
  content,
  error,
  partialError,
  operationLocked,
  externalConfirmation,
  externalError,
}

/// 承载扫码登录生产与预览八态的深模块。
///
/// 页面只需提供状态、错误文案、当前结果文案、重试入口和平台正文；布局、认证
/// 接力条、加载遮罩与减少动态行为均在本模块内保持一致。
class WxmpLoginContentFrame extends StatelessWidget {
  /// 创建生产与 fixture 共用的扫码登录状态框架。
  ///
  /// :param state: 当前登录展示状态。
  /// :param errorMessage: 主页面失败时的恢复说明。
  /// :param documentBuilder: 平台 WebView 或确定性外部正文构建器。
  /// :param onRetry: 原位重新打开入口。
  /// :param resultMessage: 成功、部分失败或外部失败说明。
  const WxmpLoginContentFrame({
    super.key,
    required this.state,
    required this.errorMessage,
    required this.documentBuilder,
    required this.onRetry,
    this.resultMessage,
  });

  /// 当前冻结预览状态。
  final WxmpLoginPreviewState state;

  /// 主页面失败时的可恢复说明。
  final String errorMessage;

  /// 平台 WebView 或视觉 fixture 的正文构建器。
  final WidgetBuilder documentBuilder;

  /// 登录结果或外部打开失败说明。
  final String? resultMessage;

  /// 原位重新打开/刷新入口。
  final VoidCallback onRetry;

  /// 构建生产与预览共用的八态主体。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 与生产 WxmpLoginPage 内容区域一致的页面主体。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (state == WxmpLoginPreviewState.error) {
      return YhEmptyState(
        icon: YhIcons.warning,
        title: '无法打开微信登录页',
        message: errorMessage,
        action: YhButton(label: '重新打开登录页', onTap: onRetry),
      );
    }

    final loading = state == WxmpLoginPreviewState.loading;
    final message =
        resultMessage ??
        switch (state) {
          WxmpLoginPreviewState.operationLocked =>
            '正在保存并校验认证信息；完成前暂不能返回或再次开始登录。',
          _ => '请使用拥有公众号的微信账号扫码登录。连接信息只在校验通过后保存到本机。',
        };
    final bannerKind = switch (state) {
      WxmpLoginPreviewState.content => YhBannerKind.success,
      WxmpLoginPreviewState.partialError ||
      WxmpLoginPreviewState.externalError => YhBannerKind.danger,
      WxmpLoginPreviewState.operationLocked => YhBannerKind.warn,
      _ => YhBannerKind.info,
    };
    return Column(
      children: [
        if (!loading)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              theme.spacing.l,
              theme.spacing.s,
              theme.spacing.l,
              theme.spacing.xs,
            ),
            child: YhBanner(text: message, kind: bannerKind),
          ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: Builder(builder: documentBuilder)),
              if (loading)
                Positioned.fill(
                  child: ColoredBox(
                    color: theme.color.surface,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const YhProgress(
                            value: null,
                            showPercent: false,
                            semanticLabel: '正在打开微信登录页',
                          ),
                          SizedBox(height: theme.spacing.s),
                          Text(
                            '正在打开微信登录页',
                            style: theme.typography.body.copyWith(
                              color: theme.color.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 视觉 fixture 使用的外部网页占位；生产路径仍由 InAppWebView 绘制该区域。
class WxmpLoginPreviewDocument extends StatelessWidget {
  /// 创建公众号平台网页占位。
  ///
  /// :param key: 用于视觉 sidecar 定位的稳定 widget key。
  const WxmpLoginPreviewDocument({super.key});

  /// 构建填充剩余空间的外部内容替身。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 与生产 WebView 边界一致的确定性区域。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return ColoredBox(
      color: theme.color.sunken,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: theme.spacing.xl2 * 2,
              height: theme.spacing.xl2 * 2,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.color.foreground,
                  width: theme.layout.controlBorder * 2,
                ),
                borderRadius: BorderRadius.circular(theme.radius.s),
              ),
              child: Text(
                '码',
                style: theme.typography.h2.copyWith(
                  color: theme.color.foreground,
                ),
              ),
            ),
            SizedBox(height: theme.spacing.s),
            Text(
              '微信公众号平台',
              style: theme.typography.h3.copyWith(
                color: theme.color.foreground,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              '请使用微信扫码登录',
              style: theme.typography.body.copyWith(color: theme.color.muted),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              '此区域由对应平台 WebView 绘制',
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ],
        ),
      ),
    );
  }
}
