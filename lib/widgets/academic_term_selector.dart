/*
 * 学期选择组件 — 可复用的全局学年与学期切换控件
 * @Project : SSPU-AllinOne
 * @File : academic_term_selector.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import '../design/fluent_ui.dart';
import '../models/academic_term.dart';
import '../theme/app_spacing.dart';

/// 学期选择组件展示模式。
enum AcademicTermSelectorVariant {
  /// 设置页完整模式。
  settings,

  /// 详情页紧凑模式。
  compact,
}

/// 可复用学期选择组件。
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

  /// 当前选择。
  final AcademicTermChoice selection;

  /// 选择变化回调。
  final ValueChanged<AcademicTermChoice> onChanged;

  /// 可选学期。
  final List<AcademicTermChoice> availableTerms;

  /// 当前生效上下文，用于设置页展示自动计算结果。
  final AcademicTermContext? contextSummary;

  /// 控件是否可操作。
  final bool enabled;

  /// 展示模式。
  final AcademicTermSelectorVariant variant;

  @override
  Widget build(BuildContext context) {
    final type = context.fluentType;
    final colors = context.fluentColors;
    final sourceText = _sourceText(contextSummary);
    final summaryText = contextSummary?.summaryLabel ?? selection.label;

    final form = LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 520;
        final controls = [
          _buildYearSelector(selection),
          _buildSeasonSelector(selection),
        ];

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < controls.length; i++) ...[
                controls[i],
                if (i < controls.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: controls,
        );
      },
    );

    return Column(
      key: const Key('academic-term-selector'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        form,
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              FluentIcons.calendarWeek,
              size: 16,
              color: colors.neutralForeground2,
            ),
            Text(summaryText, style: type.caption1),
            Text(
              sourceText,
              style: type.caption1.copyWith(
                color: contextSummary?.isUnsupported == true
                    ? colors.statusWarningForeground
                    : colors.neutralForeground2,
              ),
            ),
          ],
        ),
        if (contextSummary?.hasDifferentQueryTerm == true) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                FluentIcons.search,
                size: 16,
                color: colors.neutralForeground2,
              ),
              Text(
                '查询使用：${contextSummary!.effectiveQueryTerm.label}',
                style: type.caption1.copyWith(color: colors.neutralForeground2),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildYearSelector(AcademicTermChoice current) {
    final years =
        availableTerms.map((term) => term.academicYear).toSet().toList()
          ..sort();
    return _TermFieldShell(
      label: '学年',
      child: FluentSelect<int>(
        key: const Key('academic-term-year-select'),
        value: current.academicYear,
        isExpanded: true,
        items: years
            .map(
              (year) => FluentSelectItem<int>(
                value: year,
                child: Text('$year-${year + 1} 学年'),
              ),
            )
            .toList(),
        onChanged: enabled
            ? (year) {
                if (year != null) {
                  onChanged(current.copyWith(academicYear: year));
                }
              }
            : null,
      ),
    );
  }

  Widget _buildSeasonSelector(AcademicTermChoice current) {
    return _TermFieldShell(
      label: '学期',
      child: FluentSelect<AcademicTermSeason>(
        key: const Key('academic-term-season-select'),
        value: current.season,
        isExpanded: true,
        items: AcademicTermSeason.values
            .map(
              (season) => FluentSelectItem<AcademicTermSeason>(
                value: season,
                child: Text(season.label),
              ),
            )
            .toList(),
        onChanged: enabled
            ? (season) {
                if (season != null) onChanged(current.copyWith(season: season));
              }
            : null,
      ),
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

class _TermFieldShell extends StatelessWidget {
  const _TermFieldShell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final type = context.fluentType;
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: type.caption1),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}
