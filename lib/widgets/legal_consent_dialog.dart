/*
 * 法律协议确认弹窗 — 首次启动时一次确认完整法律与隐私说明
 * @Project : SSPU-AllinOne
 * @File : legal_consent_dialog.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import 'dart:math' as math;

import '../design/qingyuan/qingyuan_ui.dart';
import '../legal/legal_documents.dart';

typedef LegalNoticeLoader = Future<String> Function(Locale? locale);

Future<bool?> showLegalConsentDialog({required BuildContext context}) {
  final theme = context.yhTheme;
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '法律与隐私说明',
    barrierColor: theme.color.scrim,
    transitionDuration: theme.motion.base,
    pageBuilder: (dialogContext, animation, secondaryAnimation) => PopScope(
      canPop: false,
      child: LegalConsentDialog(
        onAccept: () => Navigator.pop(dialogContext, true),
        onDecline: () => Navigator.pop(dialogContext, false),
      ),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: context.yhTheme.motion.curve,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class LegalConsentDialog extends StatelessWidget {
  const LegalConsentDialog({
    super.key,
    required this.onAccept,
    required this.onDecline,
    this.loadLegalNotice = loadLegalNoticeForLocale,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final LegalNoticeLoader loadLegalNotice;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < theme.breakpoint.compact;
          final horizontalMargin = isCompact
              ? theme.spacing.s
              : theme.spacing.xl;
          final verticalMargin = isCompact ? theme.spacing.s : theme.spacing.xl;
          final availableWidth = math.max(
            0.0,
            constraints.maxWidth - horizontalMargin * 2,
          );
          final availableHeight = math.max(
            0.0,
            constraints.maxHeight - verticalMargin * 2,
          );
          final regularWidth = theme.breakpoint.medium + theme.spacing.xl2 * 3;
          final regularHeight = theme.breakpoint.medium - theme.spacing.s;
          final dialogWidth = isCompact
              ? availableWidth
              : math.min(regularWidth, availableWidth);
          final dialogHeight = isCompact
              ? availableHeight
              : math.min(regularHeight, availableHeight);

          return Center(
            child: SizedBox(
              key: const Key('legal-consent-dialog'),
              width: dialogWidth,
              height: dialogHeight,
              child: _LegalConsentSurface(
                isCompact: isCompact,
                onAccept: onAccept,
                onDecline: onDecline,
                loadLegalNotice: loadLegalNotice,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LegalConsentSurface extends StatefulWidget {
  const _LegalConsentSurface({
    required this.isCompact,
    required this.onAccept,
    required this.onDecline,
    required this.loadLegalNotice,
  });

  final bool isCompact;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final LegalNoticeLoader loadLegalNotice;

  @override
  State<_LegalConsentSurface> createState() => _LegalConsentSurfaceState();
}

class _LegalConsentSurfaceState extends State<_LegalConsentSurface> {
  late Future<String> _legalNoticeFuture;
  String? _legalNoticeAsset;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.maybeLocaleOf(context);
    final asset = legalNoticeAssetForLocale(locale);
    if (_legalNoticeAsset != asset) {
      _legalNoticeAsset = asset;
      _legalNoticeFuture = widget.loadLegalNotice(locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.surface,
        borderRadius: BorderRadius.circular(theme.radius.l),
        border: Border.all(color: theme.color.border),
        boxShadow: theme.elevation.e3,
      ),
      child: Padding(
        padding: EdgeInsets.all(
          widget.isCompact ? theme.spacing.m : theme.spacing.l,
        ),
        child: FutureBuilder<String>(
          future: _legalNoticeFuture,
          builder: (context, snapshot) {
            final documentLoaded = snapshot.hasData;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    '法律与隐私说明',
                    style: widget.isCompact
                        ? theme.typography.h2.copyWith(
                            color: theme.color.foreground,
                          )
                        : theme.typography.h1.copyWith(
                            color: theme.color.foreground,
                          ),
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  '请阅读完整文档。一次同意将同时确认免责声明、用户协议、隐私协议、开源许可证与第三方协议。',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
                SizedBox(height: theme.spacing.m),
                Expanded(
                  child: _LegalNoticeDocument(
                    isCompact: widget.isCompact,
                    snapshot: snapshot,
                  ),
                ),
                SizedBox(height: theme.spacing.m),
                Text(
                  documentLoaded
                      ? '点击“同意全部协议并继续”代表您已阅读、理解并同意当前版本的全部协议。'
                      : '协议正文加载完成后才可继续。',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
                SizedBox(height: theme.spacing.s),
                _LegalConsentActions(
                  isCompact: widget.isCompact,
                  acceptEnabled: documentLoaded,
                  onAccept: widget.onAccept,
                  onDecline: widget.onDecline,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LegalNoticeDocument extends StatelessWidget {
  const _LegalNoticeDocument({required this.isCompact, required this.snapshot});

  final bool isCompact;
  final AsyncSnapshot<String> snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      key: const Key('legal-consent-document'),
      decoration: BoxDecoration(
        color: theme.color.sunken,
        borderRadius: BorderRadius.circular(theme.radius.input),
        border: Border.all(color: theme.color.border),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = context.yhTheme;
    final padding = EdgeInsets.all(
      isCompact ? theme.spacing.m : theme.spacing.l,
    );
    if (snapshot.hasError) {
      return Semantics(
        liveRegion: true,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '无法加载协议正文',
                style: theme.typography.h3.copyWith(color: theme.color.danger),
              ),
              SizedBox(height: theme.spacing.s),
              Text('${snapshot.error}'),
            ],
          ),
        ),
      );
    }
    if (!snapshot.hasData) {
      return Center(
        child: Semantics(
          liveRegion: true,
          label: '正在加载协议正文',
          child: Text(
            '正在加载协议正文…',
            style: theme.typography.body.copyWith(color: theme.color.muted),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      key: const Key('legal-consent-document-scroll'),
      padding: padding,
      child: YhSelectableText(
        snapshot.data!.trim(),
        semanticLabel: '法律与隐私说明正文',
      ),
    );
  }
}

class _LegalConsentActions extends StatelessWidget {
  const _LegalConsentActions({
    required this.isCompact,
    required this.acceptEnabled,
    required this.onAccept,
    required this.onDecline,
  });

  final bool isCompact;
  final bool acceptEnabled;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final acceptButton = YhButton(
      key: const Key('legal-consent-accept'),
      label: '同意全部协议并继续',
      leadingIcon: YhIcons.check,
      onTap: acceptEnabled ? onAccept : null,
      disabled: !acceptEnabled,
    );
    final declineButton = YhButton(
      key: const Key('legal-consent-decline'),
      label: '不同意并退出',
      leadingIcon: YhIcons.close,
      variant: YhButtonVariant.secondary,
      onTap: onDecline,
    );

    if (isCompact) {
      return Column(
        key: const Key('legal-consent-actions-compact'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: double.infinity, child: acceptButton),
          SizedBox(height: theme.spacing.xs),
          SizedBox(width: double.infinity, child: declineButton),
        ],
      );
    }
    return Row(
      key: const Key('legal-consent-actions-regular'),
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        declineButton,
        SizedBox(width: theme.spacing.s),
        acceptButton,
      ],
    );
  }
}
