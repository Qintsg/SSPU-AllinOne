/*
 * 法律协议确认弹窗 — 首次启动时一次确认完整法律与隐私说明
 * @Project : SSPU-AllinOne
 * @File : legal_consent_dialog.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import 'dart:async';
import 'dart:math' as math;

import '../design/qingyuan/qingyuan_ui.dart';
import '../legal/legal_documents.dart';

typedef LegalNoticeLoader = Future<String> Function(Locale? locale);
typedef LegalConsentAction = FutureOr<void> Function();

Future<bool?> showLegalConsentDialog({
  required BuildContext context,
  required Future<void> Function() onAccept,
}) {
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
        onAccept: () async {
          await onAccept();
          if (dialogContext.mounted) Navigator.pop(dialogContext, true);
        },
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

  final LegalConsentAction onAccept;
  final LegalConsentAction onDecline;
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
  final LegalConsentAction onAccept;
  final LegalConsentAction onDecline;
  final LegalNoticeLoader loadLegalNotice;

  @override
  State<_LegalConsentSurface> createState() => _LegalConsentSurfaceState();
}

class _LegalConsentSurfaceState extends State<_LegalConsentSurface> {
  late Future<String> _legalNoticeFuture;
  String? _legalNoticeAsset;
  Locale? _legalNoticeLocale;
  bool _isAccepting = false;
  bool _acceptFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.maybeLocaleOf(context);
    final asset = legalNoticeAssetForLocale(locale);
    if (_legalNoticeAsset != asset) {
      _legalNoticeAsset = asset;
      _legalNoticeLocale = locale;
      _legalNoticeFuture = widget.loadLegalNotice(_legalNoticeLocale);
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
                Text(
                  '首次使用',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.brandStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Semantics(
                  header: true,
                  child: Text(
                    '法律与隐私说明',
                    style: theme.typography.h1.copyWith(
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
                    onRetry: _retryLegalNotice,
                  ),
                ),
                if (_isAccepting || _acceptFailed) ...[
                  SizedBox(height: theme.spacing.m),
                  YhBanner(
                    kind: _acceptFailed
                        ? YhBannerKind.danger
                        : YhBannerKind.info,
                    text: _acceptFailed
                        ? '未能保存协议选择；当前不会视为已同意。请检查本机存储后重试，或退出应用。'
                        : '正在将协议选择安全保存到本机，完成前请保持应用开启。',
                  ),
                ],
                SizedBox(height: theme.spacing.m),
                Text(
                  documentLoaded ? '同意后仍可在设置中查看协议并清除本地数据。' : '协议正文加载完成后才可继续。',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
                SizedBox(height: theme.spacing.s),
                _LegalConsentActions(
                  isCompact: widget.isCompact,
                  acceptEnabled: documentLoaded,
                  accepting: _isAccepting,
                  persistenceFailed: _acceptFailed,
                  onAccept: _accept,
                  onDecline: _decline,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _accept() async {
    if (_isAccepting) return;
    setState(() {
      _isAccepting = true;
      _acceptFailed = false;
    });
    try {
      await widget.onAccept();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAccepting = false;
        _acceptFailed = true;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _isAccepting = false);
  }

  void _decline() {
    if (_isAccepting) return;
    widget.onDecline();
  }

  void _retryLegalNotice() {
    setState(() {
      _legalNoticeFuture = widget.loadLegalNotice(_legalNoticeLocale);
    });
  }
}

class _LegalNoticeDocument extends StatelessWidget {
  const _LegalNoticeDocument({
    required this.isCompact,
    required this.snapshot,
    required this.onRetry,
  });

  final bool isCompact;
  final AsyncSnapshot<String> snapshot;
  final VoidCallback onRetry;

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
              const Text('本地协议文件未就绪；当前不会记录同意，可在这里重试。'),
              SizedBox(height: theme.spacing.m),
              YhButton(
                label: '重试加载协议',
                leadingIcon: YhIcons.refresh,
                variant: YhButtonVariant.secondary,
                onTap: onRetry,
              ),
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
      child: _StructuredLegalNotice(snapshot.data!.trim()),
    );
  }
}

class _StructuredLegalNotice extends StatelessWidget {
  const _StructuredLegalNotice(this.notice);

  final String notice;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final blocks = notice
        .split(RegExp(r'\r?\n\s*\r?\n'))
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty)
        .toList(growable: false);
    if (blocks.isEmpty) return const SizedBox.shrink();

    bool isSectionHeading(String block) {
      if (block.contains('\n') || block.length > 48) return false;
      return RegExp(r'^[一二三四五六七八九十]+、').hasMatch(block) ||
          RegExp(r'^\d+\.\s+\S').hasMatch(block);
    }

    return Semantics(
      label: '法律与隐私说明正文',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: YhSelectableText(
              blocks.first,
              style: theme.typography.h3.copyWith(
                color: theme.color.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (var index = 1; index < blocks.length; index++) ...[
            SizedBox(
              height: isSectionHeading(blocks[index])
                  ? theme.spacing.l
                  : isSectionHeading(blocks[index - 1])
                  ? theme.spacing.s
                  : theme.spacing.m,
            ),
            Semantics(
              header: isSectionHeading(blocks[index]),
              child: YhSelectableText(
                blocks[index],
                style: isSectionHeading(blocks[index])
                    ? theme.typography.body.copyWith(
                        color: theme.color.foreground,
                        fontWeight: FontWeight.w600,
                      )
                    : theme.typography.body.copyWith(
                        color: theme.color.foreground,
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegalConsentActions extends StatelessWidget {
  const _LegalConsentActions({
    required this.isCompact,
    required this.acceptEnabled,
    required this.accepting,
    required this.persistenceFailed,
    required this.onAccept,
    required this.onDecline,
  });

  final bool isCompact;
  final bool acceptEnabled;
  final bool accepting;
  final bool persistenceFailed;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final acceptButton = YhButton(
      key: const Key('legal-consent-accept'),
      label: accepting
          ? '正在保存…'
          : persistenceFailed
          ? '重试保存并继续'
          : '同意全部协议并继续',
      leadingIcon: YhIcons.check,
      minWidth: isCompact ? theme.breakpoint.compact : null,
      onTap: acceptEnabled && !accepting ? onAccept : null,
      disabled: !acceptEnabled || accepting,
    );
    final declineButton = YhButton(
      key: const Key('legal-consent-decline'),
      label: '不同意并退出',
      leadingIcon: YhIcons.close,
      variant: YhButtonVariant.secondary,
      minWidth: isCompact ? theme.breakpoint.compact : null,
      onTap: accepting ? null : onDecline,
      disabled: accepting,
    );

    if (isCompact) {
      return Column(
        key: const Key('legal-consent-actions-compact'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: double.infinity, child: declineButton),
          SizedBox(height: theme.spacing.xs),
          SizedBox(width: double.infinity, child: acceptButton),
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
