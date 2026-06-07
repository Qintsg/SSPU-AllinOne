/*
 * 法律与隐私说明页面 — 展示合并后的免责声明、用户协议、隐私协议和第三方协议
 * @Project : SSPU-AllinOne
 * @File : legal_notice_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import '../design/fluent_ui.dart';

import '../legal/legal_documents.dart';
import '../theme/app_spacing.dart';

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
    return FluentPage.scrollable(
      header: FluentPageHeader(title: Text(widget.title)),
      padding: AppSpacing.regularPagePadding,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: FutureBuilder<String>(
              future: _legalNoticeFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return FluentInfoBar(
                    severity: FluentInfoSeverity.error,
                    title: const Text('无法加载协议正文'),
                    content: Text('${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: FluentProgressRing());
                }

                return FluentCard(
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: SelectableText(
                      snapshot.data!.trim(),
                      style: FluentTheme.of(context).typography.body,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
