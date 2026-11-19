/*
 * 教务常用查询入口与自适应布局
 * @Project : SSPU-AllinOne
 * @File : academic_query_directory.dart
 * @Author : Codex
 * @Date : 2026-11-19
 */

part of 'academic_page.dart';

class _AcademicQueryDirectory extends StatelessWidget {
  const _AcademicQueryDirectory({required this.entries, required this.enabled});

  final List<(String, String, IconData, VoidCallback)> entries;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhMiuixCard(
      padding: EdgeInsets.all(theme.spacing.m),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = theme.spacing.s;
          final tileMinimum = theme.control.minimumTarget * 3.5;
          final columns =
              constraints.maxWidth >= tileMinimum * 2 + gap &&
                  MediaQuery.textScalerOf(context).scale(16) <= 24
              ? 2
              : 1;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final (title, detail, icon, action) in entries)
                SizedBox(
                  width: width,
                  child: YhMiuixQueryRow(
                    title: title,
                    detail: detail,
                    icon: icon,
                    onPressed: enabled ? action : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
