/* 外部网页确认页 — 在离开应用前展示目标域名与认证边界。 */

import '../design/qingyuan/qingyuan_ui.dart';

class ExternalLinkConfirmationPage extends StatelessWidget {
  const ExternalLinkConfirmationPage({
    super.key,
    required this.displayName,
    required this.uri,
    required this.authenticationRequired,
    required this.authenticationReady,
    this.openInApp = false,
  });

  final String displayName;
  final Uri uri;
  final bool authenticationRequired;
  final bool authenticationReady;

  /// 普通网页或 OA 会话入口在应用内 WebView 打开时使用的展示模式。
  final bool openInApp;

  bool get _canOpen => !authenticationRequired || authenticationReady;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final pagePadding =
        MediaQuery.sizeOf(context).width < theme.breakpoint.medium
        ? theme.spacing.m
        : theme.spacing.xl;
    return YhPageScaffold(
      appBar: YhAppBar(
        title: '确认打开外部网站',
        leading: YhIconButton(
          icon: YhIcons.back,
          semanticLabel: '返回快捷入口',
          variant: YhIconButtonVariant.ghost,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: theme.layout.formContentWidth,
            ),
            child: YhCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        theme.color.serviceQuickLink.withValues(
                          alpha: theme.opacity.domainTint,
                        ),
                        theme.color.surface,
                      ),
                      borderRadius: BorderRadius.circular(theme.radius.input),
                    ),
                    child: SizedBox.square(
                      dimension: theme.control.regular - theme.spacing.xs,
                      child: Icon(
                        authenticationRequired ? YhIcons.lock : YhIcons.globe,
                        size: theme.spacing.l,
                        color: theme.color.serviceQuickLink,
                      ),
                    ),
                  ),
                  SizedBox(height: theme.spacing.m + theme.spacing.xs),
                  Text(
                    '外部网页边界',
                    style: theme.typography.caption.copyWith(
                      color: theme.color.brandInk,
                      fontWeight: theme.typography.semibold,
                    ),
                  ),
                  SizedBox(height: theme.spacing.m),
                  Semantics(
                    header: true,
                    child: Text(displayName, style: theme.typography.h2),
                  ),
                  SizedBox(height: theme.spacing.s + theme.spacing.xs),
                  Text(
                    openInApp
                        ? '将在工大聚合内打开以下地址；网页内容由目标站点提供。'
                        : '即将离开工大聚合，并由系统浏览器打开以下地址。',
                    style: theme.typography.small.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                  SizedBox(height: theme.spacing.l),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.color.sunken,
                      borderRadius: BorderRadius.circular(theme.radius.m),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            theme.control.regular +
                            theme.spacing.l +
                            theme.spacing.xs,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(theme.spacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '目标域名',
                              style: theme.typography.caption.copyWith(
                                color: theme.color.muted,
                              ),
                            ),
                            SizedBox(height: theme.spacing.xs),
                            Semantics(
                              label: '目标域名 ${uri.host}',
                              child: Text(
                                uri.host,
                                style: theme.typography.body.copyWith(
                                  fontFamily: YhTypographyTokens.fontFamilyMono,
                                  fontWeight: theme.typography.h2.fontWeight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: theme.spacing.m),
                  YhBanner(
                    kind: _canOpen ? YhBannerKind.info : YhBannerKind.warn,
                    text: _canOpen
                        ? authenticationRequired
                              ? openInApp
                                    ? '本机存在可复用的 OA 登录会话；仅将目标 OA 域名的会话用于本次应用内打开。'
                                    : '本机存在可复用的 OA 登录会话；外部网站仍可能要求再次登录。'
                              : openInApp
                              ? '网页将在应用内打开；如需下载文件，可在页面工具栏交给系统应用处理。'
                              : '此链接将交给系统浏览器，浏览器中的登录与隐私设置由系统管理。'
                        : '当前没有可复用的 OA 登录会话。为避免无意义重定向，当前不会打开网站。',
                  ),
                  SizedBox(height: theme.spacing.l),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(
                      spacing: theme.spacing.s,
                      runSpacing: theme.spacing.s,
                      alignment: WrapAlignment.end,
                      children: _canOpen
                          ? [
                              YhButton(
                                label: '取消',
                                variant: YhButtonVariant.secondary,
                                onTap: () => Navigator.of(context).pop(false),
                              ),
                              YhButton(
                                label: openInApp ? '在应用内打开' : '打开外部网站',
                                onTap: () => Navigator.of(context).pop(true),
                              ),
                            ]
                          : [
                              YhButton(
                                label: '返回快捷入口',
                                onTap: () => Navigator.of(context).pop(false),
                              ),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
