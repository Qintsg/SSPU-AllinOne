/*
 * 教务总览详细来源区 — 聚合既有只读业务卡片
 * @Project : SSPU-AllinOne
 * @File : academic_overview_legacy_sources.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_page.dart';

class _AcademicLegacySources extends StatelessWidget {
  const _AcademicLegacySources({
    super.key,
    required this.focusNode,
    required this.locked,
    required this.primary,
    required this.sports,
    required this.secondClassroom,
  });

  final Widget primary;
  final Widget sports;
  final Widget secondClassroom;
  final FocusNode focusNode;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final content = Focus(
      key: const ValueKey('academic-legacy-sources-focus'),
      focusNode: focusNode,
      canRequestFocus: !locked,
      descendantsAreFocusable: !locked,
      descendantsAreTraversable: !locked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('详细数据源', style: theme.typography.h2),
          SizedBox(height: theme.spacing.m),
          _AcademicDashboardGrid(
            primary: primary,
            sports: sports,
            secondClassroom: secondClassroom,
          ),
          SizedBox(height: theme.spacing.m),
          const YhBanner(text: '只读边界：不提供选课、退课、调课、教学评价、提交申请或任何状态变更入口。'),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: locked ? '详细数据源，协同刷新期间不可用' : '详细数据源',
      enabled: !locked,
      child: ExcludeSemantics(
        excluding: locked,
        child: IgnorePointer(
          ignoring: locked,
          child: Opacity(
            opacity: locked ? theme.opacity.disabled : 1,
            child: content,
          ),
        ),
      ),
    );
  }
}
