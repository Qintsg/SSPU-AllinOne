/*
 * 法律与隐私说明页面 — 展示合并后的免责声明、用户协议、隐私协议和第三方协议
 * @Project : SSPU-AllinOne
 * @File : legal_notice_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import '../design/qingyuan/qingyuan_ui.dart';

import '../legal/legal_documents.dart';

/// 完整法律与隐私说明页面。
class LegalNoticePage extends StatefulWidget {
  const LegalNoticePage({super.key, this.title = '法律与隐私说明'});

  /// 页面标题。
  final String title;

  @override
  State<LegalNoticePage> createState() => _LegalNoticePageState();
}

class _LegalNoticePageState extends State<LegalNoticePage> {
  late Future<String> _legalNoticeFuture;
  String? _legalNoticeAsset;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.maybeLocaleOf(context);
    final asset = legalNoticeAssetForLocale(locale);
    if (_legalNoticeAsset != asset) {
      _legalNoticeAsset = asset;
      _legalNoticeFuture = loadLegalNoticeForLocale(locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPageScaffold(
      appBar: YhAppBar(
        title: widget.title,
        leading: YhIconButton(
          icon: YhIcons.back,
          semanticLabel: '返回',
          variant: YhIconButtonVariant.ghost,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.spacing.m),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: theme.breakpoint.medium),
            child: FutureBuilder<String>(
              future: _legalNoticeFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Semantics(
                    liveRegion: true,
                    child: YhCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '无法加载协议正文',
                            style: theme.typography.h3.copyWith(
                              color: theme.color.danger,
                            ),
                          ),
                          SizedBox(height: theme.spacing.s),
                          Text('${snapshot.error}'),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return Semantics(
                    liveRegion: true,
                    label: '正在加载协议正文',
                    child: YhCard(
                      child: Text(
                        '正在加载协议正文…',
                        style: theme.typography.body.copyWith(
                          color: theme.color.muted,
                        ),
                      ),
                    ),
                  );
                }

                return YhCard(
                  child: YhSelectableText(
                    snapshot.data!.trim(),
                    semanticLabel: '法律与隐私说明正文',
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
