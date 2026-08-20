/*
 * 关于页开源许可呈现 — 响应式项目列表与设置部件
 * @Project : SSPU-AllinOne
 * @File : about_open_source_widgets.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'about_page.dart';

class _OpenSourceProjectsView extends StatelessWidget {
  const _OpenSourceProjectsView({
    required this.onOpenProject,
    this.operationsLocked = false,
  });

  final ValueChanged<_OpenSourceProject> onOpenProject;
  final bool operationsLocked;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < theme.breakpoint.medium) {
          return Column(
            children: [
              for (final project in _openSourceProjects) ...[
                _OpenSourceProjectCard(
                  project: project,
                  onTap: operationsLocked ? null : () => onOpenProject(project),
                ),
                if (project != _openSourceProjects.last)
                  SizedBox(height: theme.spacing.s),
              ],
            ],
          );
        }
        final projectWidth = theme.spacing.xl2 * 3;
        final usageWidth = theme.spacing.xl2 * 5;
        final licenseWidth = theme.spacing.xl2 * 3;
        final noticeWidth = theme.spacing.xl2 * 7;
        final tableWidth =
            projectWidth + usageWidth + licenseWidth + noticeWidth;
        final borderSide = BorderSide(color: theme.color.border);
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: tableWidth + theme.layout.controlBorder * 2,
            ),
            child: YhCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: {
                    0: FixedColumnWidth(projectWidth),
                    1: FixedColumnWidth(usageWidth),
                    2: FixedColumnWidth(licenseWidth),
                    3: FixedColumnWidth(noticeWidth),
                  },
                  border: TableBorder(
                    top: borderSide,
                    right: borderSide,
                    bottom: borderSide,
                    left: borderSide,
                    horizontalInside: borderSide,
                    verticalInside: borderSide,
                  ),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: theme.color.sunken),
                      children: const [
                        _OpenSourceHeaderCell('项目'),
                        _OpenSourceHeaderCell('使用场景'),
                        _OpenSourceHeaderCell('许可证'),
                        _OpenSourceHeaderCell('许可证说明'),
                      ],
                    ),
                    for (final project in _openSourceProjects)
                      TableRow(
                        children: [
                          _OpenSourceLinkCell(
                            name: project.name,
                            onTap: operationsLocked
                                ? null
                                : () => onOpenProject(project),
                          ),
                          _OpenSourceBodyCell(project.description),
                          _OpenSourceBodyCell(project.license),
                          _OpenSourceBodyCell(project.licenseDescription),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OpenSourceProjectCard extends StatelessWidget {
  const _OpenSourceProjectCard({required this.project, required this.onTap});

  final _OpenSourceProject project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YhPressable(
            semanticLabel: '打开 ${project.name}',
            onPressed: onTap,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: theme.typography.body.copyWith(
                      color: theme.color.brandInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  YhIcons.open,
                  size: theme.spacing.m + theme.layout.divider * 2,
                  color: theme.color.brandStrong,
                ),
              ],
            ),
          ),
          SizedBox(height: theme.spacing.s),
          Text(project.description, style: theme.typography.body),
          SizedBox(height: theme.spacing.s),
          Text(
            project.license,
            style: theme.typography.small.copyWith(
              color: theme.color.brandStrong,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            project.licenseDescription,
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
        ],
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final size = compact ? theme.spacing.xl2 : theme.spacing.xl2 * 2;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.brandTint,
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.s),
        child: Image.asset('assets/images/logo.png', width: size, height: size),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      children: [
        Text('$label：', style: theme.typography.body),
        Flexible(
          child: Text(
            value,
            style: theme.typography.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: title,
      onPressed: onTap,
      builder: (context, state, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: state.pressed
              ? theme.color.brand.withValues(alpha: 0.16)
              : state.hovered
              ? theme.color.brandTint
              : theme.color.surface,
        ),
        child: child,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: theme.spacing.s,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.color.brandStrong),
            SizedBox(width: theme.spacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.typography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    subtitle,
                    style: theme.typography.small.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: theme.spacing.s),
            Icon(YhIcons.chevronRight, size: 20, color: theme.color.muted),
          ],
        ),
      ),
    );
  }
}

class _OpenSourceHeaderCell extends StatelessWidget {
  const _OpenSourceHeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.s,
      ),
      child: Text(
        label,
        style: theme.typography.body.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _OpenSourceBodyCell extends StatelessWidget {
  const _OpenSourceBodyCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.s,
      ),
      child: Text(
        text,
        style: theme.typography.small.copyWith(color: theme.color.muted),
      ),
    );
  }
}

class _OpenSourceLinkCell extends StatelessWidget {
  const _OpenSourceLinkCell({required this.name, required this.onTap});

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: '打开 $name',
      onPressed: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: theme.spacing.s,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              YhIcons.open,
              size: theme.spacing.m + theme.layout.divider * 2,
              color: theme.color.brandStrong,
            ),
            SizedBox(width: theme.spacing.s),
            Flexible(
              child: Text(
                name,
                style: theme.typography.small.copyWith(
                  color: theme.color.brandInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
