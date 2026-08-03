/*
 * 学期选择组件 — 可复用的全局学年与学期切换控件
 * @Project : SSPU-AllinOne
 * @File : academic_term_selector.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import '../design/qingyuan/qingyuan_ui.dart';
import '../models/academic_term.dart';

enum AcademicTermSelectorVariant { settings, compact }

class AcademicTermSelector extends StatelessWidget {
  const AcademicTermSelector({
    super.key,
    required this.selection,
    required this.onChanged,
    required this.availableTerms,
    this.contextSummary,
    this.enabled = true,
    this.variant = AcademicTermSelectorVariant.settings,
  });

  final AcademicTermChoice selection;
  final ValueChanged<AcademicTermChoice> onChanged;
  final List<AcademicTermChoice> availableTerms;
  final AcademicTermContext? contextSummary;
  final bool enabled;
  final AcademicTermSelectorVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final sourceText = _sourceText(contextSummary);
    final summaryText = contextSummary?.summaryLabel ?? selection.label;
    final years =
        availableTerms.map((term) => term.academicYear).toSet().toList()
          ..sort();

    return Column(
      key: const Key('academic-term-selector'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stack =
                variant != AcademicTermSelectorVariant.compact &&
                constraints.maxWidth < theme.breakpoint.compact;
            final compactWidth = (constraints.maxWidth - theme.spacing.s) / 2;
            final controlWidth = variant == AcademicTermSelectorVariant.compact
                ? compactWidth
                : theme.spacing.xl2 * 4;
            final controls = [
              SizedBox(
                width: controlWidth,
                child: YhSelect<int>(
                  key: const Key('academic-term-year-select'),
                  label: '学年',
                  value: selection.academicYear,
                  enabled: enabled,
                  options: [
                    for (final year in years)
                      YhSelectOption(
                        value: year,
                        label: variant == AcademicTermSelectorVariant.compact
                            ? '$year–${(year + 1).toString().substring(2)} 学年'
                            : '$year-${year + 1} 学年',
                      ),
                  ],
                  onChanged: (year) {
                    if (year != null) {
                      onChanged(selection.copyWith(academicYear: year));
                    }
                  },
                ),
              ),
              SizedBox(
                width: controlWidth,
                child: YhSelect<AcademicTermSeason>(
                  key: const Key('academic-term-season-select'),
                  label: '学期',
                  value: selection.season,
                  enabled: enabled,
                  options: [
                    for (final season in AcademicTermSeason.values)
                      YhSelectOption(value: season, label: season.label),
                  ],
                  onChanged: (season) {
                    if (season != null) {
                      onChanged(selection.copyWith(season: season));
                    }
                  },
                ),
              ),
            ];
            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  controls.first,
                  SizedBox(height: theme.spacing.s),
                  controls.last,
                ],
              );
            }
            return Wrap(
              spacing: theme.spacing.s,
              runSpacing: theme.spacing.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: controls,
            );
          },
        ),
        SizedBox(height: theme.spacing.s),
        if (variant == AcademicTermSelectorVariant.compact) ...[
          Text('当前实际：$summaryText', style: theme.typography.small),
          Text(
            sourceText,
            style: theme.typography.small.copyWith(
              color: contextSummary?.isUnsupported == true
                  ? theme.color.warning
                  : theme.color.muted,
            ),
          ),
          if (contextSummary?.hasDifferentQueryTerm == true)
            Text(
              '查询使用：${contextSummary!.effectiveQueryTerm.label}',
              style: theme.typography.small,
            ),
        ] else ...[
          _TermContextLine(
            icon: YhIcons.calendar,
            primary: '当前实际：$summaryText',
            secondary: sourceText,
            warning: contextSummary?.isUnsupported == true,
          ),
          if (contextSummary?.hasDifferentQueryTerm == true) ...[
            SizedBox(height: theme.spacing.xs),
            _TermContextLine(
              icon: YhIcons.search,
              primary: '查询使用：${contextSummary!.effectiveQueryTerm.label}',
            ),
          ],
        ],
      ],
    );
  }

  String _sourceText(AcademicTermContext? context) {
    if (context == null) return '等待校历定位';
    if (context.hasDifferentQueryTerm) return '当前日期';
    return switch (context.source) {
      AcademicTermContextSource.selected => '全局学期',
      AcademicTermContextSource.automatic => '自动匹配',
      AcademicTermContextSource.unsupported => '暂无内置定位',
    };
  }
}

class _TermContextLine extends StatelessWidget {
  const _TermContextLine({
    required this.icon,
    required this.primary,
    this.secondary,
    this.warning = false,
  });

  final IconData icon;
  final String primary;
  final String? secondary;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final muted = warning ? theme.color.warning : theme.color.muted;
    return Wrap(
      spacing: theme.spacing.xs,
      runSpacing: theme.spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(icon, size: theme.spacing.m, color: muted),
        Text(primary, style: theme.typography.small),
        if (secondary != null)
          Text(
            secondary!,
            style: theme.typography.small.copyWith(color: muted),
          ),
      ],
    );
  }
}
