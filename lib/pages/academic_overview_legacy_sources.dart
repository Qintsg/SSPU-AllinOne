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
    required this.locked,
    required this.sports,
    required this.secondClassroom,
  });

  final Widget sports;
  final Widget secondClassroom;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= theme.breakpoint.medium;
        final cards = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: sports),
                  SizedBox(width: theme.spacing.m),
                  Expanded(child: secondClassroom),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sports,
                  SizedBox(height: theme.spacing.m),
                  secondClassroom,
                ],
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cards,
            SizedBox(height: theme.spacing.m),
          ],
        );
      },
    );
    return Semantics(
      container: true,
      label: locked ? '教务辅助数据，协同刷新期间不可用' : '教务辅助数据',
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
