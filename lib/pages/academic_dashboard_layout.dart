/*
 * 教务仪表盘展示布局 — 自适应网格与入场动效
 * @Project : SSPU-AllinOne
 * @File : academic_dashboard_layout.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'academic_page.dart';

class _AcademicDashboardGrid extends StatelessWidget {
  const _AcademicDashboardGrid({
    required this.primary,
    required this.sports,
    required this.secondClassroom,
  });

  final Widget primary;
  final Widget sports;
  final Widget secondClassroom;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >=
            theme.breakpoint.expanded -
                theme.spacing.xl2 * 3 -
                theme.spacing.m) {
          return Column(
            children: [
              _AcademicAnimatedCard(index: 0, child: primary),
              SizedBox(height: theme.spacing.m),
              _AcademicEqualHeightRow(
                left: _AcademicAnimatedCard(index: 1, child: sports),
                right: _AcademicAnimatedCard(index: 2, child: secondClassroom),
              ),
            ],
          );
        }

        if (constraints.maxWidth >=
            theme.breakpoint.medium - theme.spacing.xl2) {
          return Column(
            children: [
              _AcademicAnimatedCard(index: 0, child: primary),
              SizedBox(height: theme.spacing.m),
              _AcademicEqualHeightRow(
                left: _AcademicAnimatedCard(index: 1, child: sports),
                right: _AcademicAnimatedCard(index: 2, child: secondClassroom),
              ),
            ],
          );
        }

        return Column(
          children: [
            _AcademicAnimatedCard(index: 0, child: primary),
            SizedBox(height: theme.spacing.m),
            _AcademicAnimatedCard(index: 1, child: sports),
            SizedBox(height: theme.spacing.m),
            _AcademicAnimatedCard(index: 2, child: secondClassroom),
          ],
        );
      },
    );
  }
}

class _AcademicEqualHeightRow extends StatelessWidget {
  const _AcademicEqualHeightRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          SizedBox(width: theme.spacing.m),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _AcademicAnimatedCard extends StatelessWidget {
  const _AcademicAnimatedCard({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) return child;
    final theme = context.yhTheme;
    return child
        .animate(delay: theme.motion.fast * index)
        .fadeIn(duration: theme.motion.slow, curve: theme.motion.curve)
        .slideY(begin: 0.05, end: 0);
  }
}
