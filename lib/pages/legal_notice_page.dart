/*
 * 法律与隐私说明页面 — 展示合并后的免责声明、用户协议、隐私协议和第三方协议
 * @Project : SSPU-AllinOne
 * @File : legal_notice_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import '../design/qingyuan/qingyuan_ui.dart';

import '../legal/legal_documents.dart';

part 'legal_notice_page_widgets.dart';

/// 法律阅读页中的一个结构化章节。
@immutable
class LegalNoticeSection {
  const LegalNoticeSection({required this.title, required this.body});

  final String title;
  final String body;
}

/// 完整法律与隐私说明页面。
class LegalNoticePage extends StatefulWidget {
  const LegalNoticePage({
    super.key,
    this.title = '法律声明',
    this.kicker = '法律与许可',
    this.summary = '正文从应用内确定性资源加载，加载失败仍保留返回和重试。',
    this.source = '随应用发布的文本',
    this.sourceTimestamp,
    this.primaryActionLabel = '返回设置',
    this.onPrimaryAction,
    this.sections,
    this.loadLegalNotice = loadLegalNoticeForLocale,
  });

  /// 页面标题。
  final String title;

  /// 标题上方的法律分类。
  final String kicker;

  /// 当前文档的用途与边界摘要。
  final String summary;

  /// 文档来源说明。
  final String source;

  /// 可选的来源版本或更新时间。
  final String? sourceTimestamp;

  /// 标题区主要行动；未提供回调时返回上一页。
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  /// 可替换的结构化正文；为空时加载并解析随应用发布的完整文档。
  final List<LegalNoticeSection>? sections;

  /// 可替换的协议正文加载器，默认读取本地 asset，不访问网络。
  final Future<String> Function(Locale? locale) loadLegalNotice;

  @override
  State<LegalNoticePage> createState() => _LegalNoticePageState();
}

class _LegalNoticePageState extends State<LegalNoticePage> {
  Future<String>? _legalNoticeFuture;
  String? _legalNoticeAsset;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureDocumentLoaded();
  }

  @override
  void didUpdateWidget(LegalNoticePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadLegalNotice != widget.loadLegalNotice ||
        oldWidget.sections != widget.sections) {
      _legalNoticeAsset = null;
      _legalNoticeFuture = null;
      _ensureDocumentLoaded();
    }
  }

  void _ensureDocumentLoaded() {
    if (widget.sections != null) return;
    final locale = Localizations.maybeLocaleOf(context);
    final asset = legalNoticeAssetForLocale(locale);
    if (_legalNoticeAsset == asset && _legalNoticeFuture != null) return;
    _legalNoticeAsset = asset;
    _legalNoticeFuture = widget.loadLegalNotice(locale);
  }

  void _retryLoad() {
    setState(() {
      final locale = Localizations.maybeLocaleOf(context);
      _legalNoticeFuture = widget.loadLegalNotice(locale);
    });
  }

  void _runPrimaryAction() {
    final callback = widget.onPrimaryAction;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return YhPageScaffold(
      appBar: YhAppBar(
        eyebrow: '法律',
        title: widget.source,
        leading: YhIconButton(
          icon: YhIcons.back,
          semanticLabel: '返回',
          variant: YhIconButtonVariant.ghost,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          YhIconButton(
            icon: YhIcons.more,
            semanticLabel: '更多操作',
            variant: YhIconButtonVariant.ghost,
            onTap: _showDocumentInfo,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, _) {
          final theme = context.yhTheme;
          final compact =
              MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
          final horizontalPadding = compact
              ? theme.spacing.m
              : (MediaQuery.sizeOf(context).width *
                        theme.responsive.panelPaddingViewportPercent /
                        100)
                    .clamp(theme.spacing.l, theme.spacing.xl2);
          final content = _buildPageContent(context, compact: compact);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              horizontalPadding,
              horizontalPadding,
              horizontalPadding,
            ),
            child: content,
          );
        },
      ),
    );
  }

  void _showDocumentInfo() {
    YhBottomDrawer.show<void>(
      context,
      title: '文档信息',
      builder: (drawerContext) {
        final theme = drawerContext.yhTheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '来源',
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(widget.source),
            if (widget.sourceTimestamp != null) ...[
              SizedBox(height: theme.spacing.s),
              Text(
                widget.sourceTimestamp!,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ],
            SizedBox(height: theme.spacing.l),
            YhButton(
              label: '关闭',
              onTap: () => Navigator.of(drawerContext).pop(),
              variant: YhButtonVariant.secondary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPageContent(BuildContext context, {required bool compact}) {
    final theme = context.yhTheme;
    final actionLabel = widget.primaryActionLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LegalHeading(
          title: widget.title,
          kicker: widget.kicker,
          summary: widget.summary,
          actionLabel: actionLabel,
          onAction: actionLabel == null ? null : _runPrimaryAction,
          compact: compact,
        ),
        SizedBox(height: compact ? theme.spacing.m : theme.spacing.l),
        _LegalSourceStrip(
          source: widget.source,
          timestamp: widget.sourceTimestamp,
        ),
        SizedBox(height: compact ? theme.spacing.m : theme.spacing.l),
        _buildDocumentState(context),
      ],
    );
  }

  Widget _buildDocumentState(BuildContext context) {
    final providedSections = widget.sections;
    if (providedSections != null) {
      return _LegalSectionsCard(sections: providedSections);
    }

    return FutureBuilder<String>(
      future: _legalNoticeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LegalLoadState(
            title: '无法加载协议正文',
            message: '${snapshot.error}',
            actionLabel: '重新加载',
            onAction: _retryLoad,
            danger: true,
          );
        }

        if (!snapshot.hasData) {
          return const _LegalLoadState(
            title: '正在加载协议正文…',
            message: '正文保存在应用资源中，不会为阅读协议访问网络。',
          );
        }

        return _LegalSectionsCard(sections: _parseLegalNotice(snapshot.data!));
      },
    );
  }
}
