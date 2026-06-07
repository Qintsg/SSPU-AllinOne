/*
 * 法律协议确认弹窗 — 首次启动时一次确认完整法律与隐私说明
 * @Project : SSPU-AllinOne
 * @File : legal_consent_dialog.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import 'dart:math' as math;

import '../design/fluent_ui.dart';

import '../legal/legal_documents.dart';
import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';

/// 弹出首次启动法律协议确认弹窗。
Future<bool?> showLegalConsentDialog({required BuildContext context}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    dismissWithEsc: false,
    builder: (dialogContext) => LegalConsentDialog(
      onAccept: () => Navigator.pop(dialogContext, true),
      onDecline: () => Navigator.pop(dialogContext, false),
    ),
  );
}

/// 首次启动法律协议确认弹窗。
class LegalConsentDialog extends StatelessWidget {
  const LegalConsentDialog({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  /// 用户同意完整协议后的回调。
  final VoidCallback onAccept;

  /// 用户拒绝完整协议后的回调。
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;
          final horizontalMargin = isCompact ? AppSpacing.sm : AppSpacing.xl;
          final verticalMargin = isCompact ? AppSpacing.sm : AppSpacing.xl;
          final availableWidth = math.max(
            0.0,
            constraints.maxWidth - horizontalMargin * 2,
          );
          final availableHeight = math.max(
            0.0,
            constraints.maxHeight - verticalMargin * 2,
          );
          final dialogWidth = isCompact
              ? availableWidth
              : math.min(920.0, availableWidth);
          final dialogHeight = isCompact
              ? availableHeight
              : math.min(760.0, availableHeight);

          return Center(
            child: SizedBox(
              key: const Key('legal-consent-dialog'),
              width: dialogWidth,
              height: dialogHeight,
              child: _LegalConsentSurface(
                isCompact: isCompact,
                onAccept: onAccept,
                onDecline: onDecline,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LegalConsentSurface extends StatelessWidget {
  const _LegalConsentSurface({
    required this.isCompact,
    required this.onAccept,
    required this.onDecline,
  });

  final bool isCompact;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final resources = theme.resources;
    final typography = theme.typography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.menuColor,
        borderRadius: AppShapes.xl,
        border: Border.all(color: resources.controlStrokeColorDefault),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(
          isCompact ? AppSpacing.md : AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                '法律与隐私说明',
                style: isCompact ? typography.subtitle : typography.title,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '请阅读完整文档。一次同意将同时确认免责声明、用户协议、隐私协议、开源许可证与第三方协议。',
              style: typography.caption?.copyWith(
                color: resources.textFillColorSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _LegalNoticeDocument(isCompact: isCompact)),
            const SizedBox(height: AppSpacing.md),
            Text(
              '点击“同意全部协议并继续”代表您已阅读、理解并同意当前版本的全部协议。',
              style: typography.caption?.copyWith(
                color: resources.textFillColorSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _LegalConsentActions(
              isCompact: isCompact,
              onAccept: onAccept,
              onDecline: onDecline,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalNoticeDocument extends StatefulWidget {
  const _LegalNoticeDocument({required this.isCompact});

  final bool isCompact;

  @override
  State<_LegalNoticeDocument> createState() => _LegalNoticeDocumentState();
}

class _LegalNoticeDocumentState extends State<_LegalNoticeDocument> {
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
    final theme = FluentTheme.of(context);
    final resources = theme.resources;

    return DecoratedBox(
      key: const Key('legal-consent-document'),
      decoration: BoxDecoration(
        color: resources.controlFillColorSecondary,
        borderRadius: AppShapes.md,
        border: Border.all(color: resources.controlStrokeColorDefault),
      ),
      child: FutureBuilder<String>(
        future: _legalNoticeFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: AppSpacing.cardPadding,
              child: FluentInfoBar(
                severity: FluentInfoSeverity.error,
                title: const Text('无法加载协议正文'),
                content: Text('${snapshot.error}'),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: FluentProgressRing());
          }

          return Scrollbar(
            child: SingleChildScrollView(
              key: const Key('legal-consent-document-scroll'),
              padding: EdgeInsetsDirectional.all(
                widget.isCompact ? AppSpacing.md : AppSpacing.lg,
              ),
              child: SelectableText(
                snapshot.data!.trim(),
                style: theme.typography.body?.copyWith(height: 1.45),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LegalConsentActions extends StatelessWidget {
  const _LegalConsentActions({
    required this.isCompact,
    required this.onAccept,
    required this.onDecline,
  });

  final bool isCompact;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final acceptButton = FluentButton.primary(
      key: const Key('legal-consent-accept'),
      expand: isCompact,
      icon: FluentIcons.checkMark,
      onPressed: onAccept,
      child: const Text('同意全部协议并继续'),
    );
    final declineButton = FluentButton.secondary(
      key: const Key('legal-consent-decline'),
      expand: isCompact,
      icon: FluentIcons.clear,
      onPressed: onDecline,
      child: const Text('不同意并退出'),
    );

    if (isCompact) {
      return Column(
        key: const Key('legal-consent-actions-compact'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          acceptButton,
          const SizedBox(height: AppSpacing.xs),
          declineButton,
        ],
      );
    }

    return Row(
      key: const Key('legal-consent-actions-regular'),
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        declineButton,
        const SizedBox(width: AppSpacing.sm),
        acceptButton,
      ],
    );
  }
}
