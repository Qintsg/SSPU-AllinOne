/*
 * 法律页的章节展示部件与正文解析辅助 — 纯展示与纯解析，不持有页面状态
 * @Project : SSPU-AllinOne
 * @File : legal_notice_page_widgets.dart
 * @Author : Qintsg
 * @Date : 2026-08-21
 */

part of 'legal_notice_page.dart';

class _LegalHeading extends StatelessWidget {
  const _LegalHeading({
    required this.title,
    required this.kicker,
    required this.summary,
    required this.actionLabel,
    required this.onAction,
    required this.compact,
  });

  final String title;
  final String kicker;
  final String summary;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker,
          style: theme.typography.small.copyWith(
            color: theme.color.structural,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: theme.spacing.s),
        Semantics(
          header: true,
          child: Text(
            title,
            style: (compact ? theme.typography.h1 : theme.typography.display)
                .copyWith(color: theme.color.foreground),
          ),
        ),
        SizedBox(height: theme.spacing.s),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.control.regular * 16),
          child: Text(
            summary,
            maxLines: compact ? 2 : null,
            overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
            style: theme.typography.body.copyWith(color: theme.color.muted),
          ),
        ),
      ],
    );

    final action = actionLabel == null
        ? null
        : YhButton(
            label: actionLabel!,
            onTap: onAction,
            minWidth: compact
                ? double.infinity
                : theme.spacing.xl2 +
                      theme.typography.body.fontSize! *
                          actionLabel!.runes.length,
          );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          copy,
          if (action != null) ...[
            SizedBox(height: theme.spacing.m - theme.layout.controlBorder * 2),
            action,
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: copy),
        if (action != null) ...[SizedBox(width: theme.spacing.xl), action],
      ],
    );
  }
}

class _LegalSourceStrip extends StatelessWidget {
  const _LegalSourceStrip({required this.source, this.timestamp});

  final String source;
  final String? timestamp;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: Border.all(color: theme.color.border),
        borderRadius: BorderRadius.circular(theme.radius.input),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: theme.control.minimumTarget),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.m,
            vertical: theme.spacing.s,
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.color.structural,
                  borderRadius: BorderRadius.circular(theme.radius.full),
                ),
                child: SizedBox.square(dimension: theme.spacing.s),
              ),
              SizedBox(width: theme.spacing.s),
              Expanded(
                child: Text(
                  '§  $source',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.small.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ),
              if (!compact && timestamp != null)
                Text(
                  timestamp!,
                  style: theme.typography.small.copyWith(
                    color: theme.color.muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSectionsCard extends StatelessWidget {
  const _LegalSectionsCard({required this.sections});

  final List<LegalNoticeSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              theme.control.regular * 17 +
              theme.spacing.l * 2 +
              theme.layout.controlBorder * 2,
        ),
        child: DecoratedBox(
          key: const Key('legal-sections-card'),
          decoration: BoxDecoration(
            color: theme.color.surface,
            border: Border.all(
              color: theme.color.border,
              width: theme.layout.controlBorder,
            ),
            borderRadius: BorderRadius.circular(theme.radius.m),
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.l),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: theme.control.regular * 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < sections.length; index++)
                    _LegalSectionBlock(
                      section: sections[index],
                      showDivider: true,
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

class _LegalSectionBlock extends StatelessWidget {
  const _LegalSectionBlock({required this.section, required this.showDivider});

  final LegalNoticeSection section;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: theme.color.border))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: theme.spacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YhSelectableText(
              section.title,
              style: theme.typography.h2.copyWith(
                color: theme.color.foreground,
              ),
              semanticLabel: '${section.title}章节标题',
            ),
            SizedBox(height: theme.spacing.s),
            YhSelectableText(
              section.body,
              style: theme.typography.body.copyWith(color: theme.color.muted),
              semanticLabel: '${section.title}正文',
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalLoadState extends StatelessWidget {
  const _LegalLoadState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.danger = false,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Semantics(
      liveRegion: true,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.layout.formContentWidth),
          child: YhCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.typography.h3.copyWith(
                    color: danger ? theme.color.danger : theme.color.foreground,
                  ),
                ),
                SizedBox(height: theme.spacing.s),
                Text(
                  message,
                  style: theme.typography.body.copyWith(
                    color: theme.color.muted,
                  ),
                ),
                if (actionLabel != null) ...[
                  SizedBox(height: theme.spacing.l),
                  YhButton(
                    label: actionLabel!,
                    onTap: onAction,
                    variant: YhButtonVariant.secondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<LegalNoticeSection> _parseLegalNotice(String rawDocument) {
  final normalized = rawDocument.replaceAll('\r\n', '\n').trim();
  if (normalized.isEmpty) {
    return const [LegalNoticeSection(title: '协议正文', body: '')];
  }

  final lines = normalized.split('\n');
  final sections = <LegalNoticeSection>[];
  var title = '说明与确认';
  final body = <String>[];

  void flush() {
    final text = body.join('\n').trim();
    if (text.isNotEmpty) {
      sections.add(LegalNoticeSection(title: title, body: text));
    }
    body.clear();
  }

  for (final line in lines) {
    final trimmed = line.trim();
    if (_isMajorLegalHeading(trimmed)) {
      flush();
      title = trimmed;
    } else {
      body.add(line);
    }
  }
  flush();
  return sections;
}

bool _isMajorLegalHeading(String line) {
  if (RegExp(r'^[一二三四五六七八九十]+、').hasMatch(line)) return true;
  return RegExp(
    r'^\d+\.\s+(Disclaimer|Terms of Use|Privacy Policy|Open Source)',
  ).hasMatch(line);
}
