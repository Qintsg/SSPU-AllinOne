/*
 * 清源组件工作台布局与视觉 fixture 辅助
 * @Project : SSPU-AllinOne
 * @File : qingyuan_component_workbench.dart
 * @Author : Qintsg
 * @Date : 2026-08-17
 */

part of 'qingyuan_component_visual_panels.dart';

class _ComponentGroup {
  const _ComponentGroup({
    required this.title,
    required this.summary,
    required this.child,
    this.wide = false,
  });

  final String title;
  final String summary;
  final Widget child;
  final bool wide;
}

Widget _componentPanel(
  String title,
  String summary,
  List<_ComponentGroup> groups,
) => YhPageScaffold(
  appBar: YhAppBar(
    title: title,
    leading: Builder(
      builder: (context) => Text(
        '组件契约',
        style: context.yhTheme.typography.caption.copyWith(
          color: context.yhTheme.color.muted,
        ),
      ),
    ),
  ),
  body: LayoutBuilder(
    builder: (context, constraints) {
      final theme = context.yhTheme;
      final compactThreshold = theme.breakpoint.medium - theme.spacing.xl2;
      final expandedThreshold = theme.breakpoint.expanded - theme.spacing.xl2;
      final pagePadding = constraints.maxWidth < theme.breakpoint.expanded
          ? theme.spacing.m
          : theme.spacing.l;
      final maxWidth = theme.layout.formContentWidth * 2 + theme.spacing.xl;
      final availableWidth = (constraints.maxWidth - pagePadding * 2).clamp(
        0.0,
        maxWidth,
      );
      final columns = availableWidth < compactThreshold
          ? 1
          : availableWidth < expandedThreshold
          ? 2
          : 3;
      final gap = theme.spacing.m;
      final cardWidth = (availableWidth - gap * (columns - 1)) / columns;
      final cards = groups.map((group) {
        final width = group.wide && columns > 1
            ? cardWidth * 2 + gap
            : cardWidth;
        return SizedBox(
          width: width,
          child: _componentGroupCard(context, group),
        );
      }).toList();
      return SingleChildScrollView(
        key: const ValueKey('component-workbench-scroll'),
        padding: EdgeInsets.symmetric(
          horizontal: pagePadding,
          vertical: pagePadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _componentIntro(context, title, summary),
                SizedBox(
                  height: constraints.maxWidth < compactThreshold
                      ? theme.spacing.m
                      : theme.spacing.l,
                ),
                Wrap(
                  key: const ValueKey('component-workbench-grid'),
                  spacing: gap,
                  runSpacing: gap,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: cards,
                ),
              ],
            ),
          ),
        ),
      );
    },
  ),
);

Widget _componentIntro(BuildContext context, String title, String summary) {
  final theme = context.yhTheme;
  final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
  return Column(
    key: const ValueKey('component-workbench-intro'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '清源组件 · 0.4',
        style: theme.typography.small.copyWith(
          color: theme.color.brandStrong,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: theme.spacing.xs),
      Text(
        title,
        style: (compact ? theme.typography.h2 : theme.typography.h1).copyWith(
          color: theme.color.foreground,
        ),
      ),
      SizedBox(height: theme.spacing.s),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.layout.formContentWidth),
        child: Text(
          summary,
          style: (compact ? theme.typography.small : theme.typography.body)
              .copyWith(color: theme.color.muted),
        ),
      ),
    ],
  );
}

Widget _componentGroupCard(BuildContext context, _ComponentGroup group) {
  final theme = context.yhTheme;
  final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
  return YhCard(
    key: ValueKey('component-group-${group.title}'),
    padding: EdgeInsets.all(compact ? theme.spacing.m : theme.spacing.l),
    radius: compact ? theme.radius.m : theme.radius.l,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _groupIndex(group),
              style: theme.typography.caption.copyWith(
                color: theme.color.brandStrong,
              ),
            ),
            SizedBox(width: theme.spacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    style: theme.typography.body.copyWith(
                      color: theme.color.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    group.summary,
                    style: theme.typography.small.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: theme.spacing.m),
        group.child,
      ],
    ),
  );
}

String _groupIndex(_ComponentGroup group) => switch (group.title) {
  '按钮与行动' || '文字输入' || '内容容器' || '页内导航' || '状态与身份' || '今日与课程' => '01',
  '选择与开关' || '结构化选择' || '即时反馈' || '紧凑目的地' || '指标与进度' || '校园服务' => '02',
  _ => '03',
};

class _LabeledSearch extends StatelessWidget {
  const _LabeledSearch();

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '搜索',
          style: theme.typography.small.copyWith(color: theme.color.muted),
        ),
        SizedBox(height: theme.spacing.s - theme.spacing.xs / 2),
        const YhSearch(hint: '搜索课程、邮件或资讯'),
      ],
    );
  }
}

class _OtpPreview extends StatefulWidget {
  @override
  State<_OtpPreview> createState() => _OtpPreviewState();
}

class _OtpPreviewState extends State<_OtpPreview> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '260719');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YhOtp(controller: _controller);
}

class _ErrorEmailPreview extends StatefulWidget {
  const _ErrorEmailPreview();

  @override
  State<_ErrorEmailPreview> createState() => _ErrorEmailPreviewState();
}

class _ErrorEmailPreviewState extends State<_ErrorEmailPreview> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: 'student@');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      YhTextField(label: '邮箱', controller: _controller, errorText: '邮箱格式不正确');
}
