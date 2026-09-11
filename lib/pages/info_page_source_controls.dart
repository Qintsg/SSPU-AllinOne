/*
 * 资讯页面来源控件 — 紧凑来源条、桌面面板与筛选入口
 * @Project : SSPU-AllinOne
 * @File : info_page_source_controls.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'info_page.dart';

class _InfoCompactSourceStrip extends StatelessWidget {
  const _InfoCompactSourceStrip({required this.state});

  final _InfoPageState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth <= theme.breakpoint.compact;
        final sourceStrip = SingleChildScrollView(
          key: const Key('info-compact-source-strip'),
          scrollDirection: Axis.horizontal,
          child: Row(children: _infoSourceButtons(context, state)),
        );
        if (!narrow) {
          return SingleChildScrollView(
            key: const Key('info-compact-source-strip'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._infoSourceButtons(context, state),
                SizedBox(width: theme.spacing.xs),
                _InfoSourceButton(
                  key: const Key('info-mobile-filter-button'),
                  label: '更多筛选',
                  selected: _hasInfoFilters(state),
                  onTap: () => _showInfoFilterDrawer(context, state),
                ),
              ],
            ),
          );
        }
        return Row(
          children: [
            Expanded(child: sourceStrip),
            SizedBox(width: theme.spacing.xs),
            _InfoSourceButton(
              key: const Key('info-mobile-filter-button'),
              label: '筛选',
              selected: _hasInfoFilters(state),
              onTap: () => _showInfoFilterDrawer(context, state),
            ),
          ],
        );
      },
    );
  }
}

class _InfoSourcePanel extends StatelessWidget {
  const _InfoSourcePanel({required this.state});

  final _InfoPageState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      key: const Key('info-source-panel'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('来源', style: theme.typography.h3),
          SizedBox(height: theme.spacing.xs),
          Text(
            '${_infoEnabledPrimarySourceCount(state)} 个来源已启用',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          ..._infoSourceButtons(context, state, vertical: true),
          SizedBox(height: theme.spacing.s),
          YhButton(
            key: const Key('info-regular-filter-button'),
            label: '更多筛选与操作',
            variant: YhButtonVariant.text,
            onTap: () => _showInfoFilterDrawer(context, state),
          ),
        ],
      ),
    );
  }
}

List<Widget> _infoSourceButtons(
  BuildContext context,
  _InfoPageState state, {
  bool vertical = false,
}) {
  final theme = context.yhTheme;
  final options = <(_InfoPrimarySource, String, int)>[
    (_InfoPrimarySource.all, '全部信息', state._allMessages.length),
    (
      _InfoPrimarySource.schoolWebsite,
      '学校官网',
      state._allMessages
          .where(
            (message) => message.sourceType == MessageSourceType.schoolWebsite,
          )
          .length,
    ),
    (
      _InfoPrimarySource.wechat,
      '微信公众号/服务号',
      state._allMessages
          .where(
            (message) =>
                message.sourceType == MessageSourceType.wechatPublic ||
                message.sourceType == MessageSourceType.wechatService,
          )
          .length,
    ),
  ];
  return [
    for (var index = 0; index < options.length; index++) ...[
      if (index > 0)
        SizedBox(
          width: vertical ? 0 : theme.spacing.xs,
          height: vertical ? theme.spacing.xs : 0,
        ),
      _InfoSourceButton(
        label: '${options[index].$2} · ${options[index].$3}',
        selected: state._primarySource == options[index].$1,
        onTap: () {
          state._primarySource = options[index].$1;
          state._applyFilters();
        },
      ),
    ],
  ];
}

class _InfoSourceButton extends StatelessWidget {
  const _InfoSourceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: label,
      selected: selected,
      onPressed: onTap,
      builder: (context, pressState, child) => AnimatedContainer(
        duration: theme.motion.fast,
        curve: theme.motion.curve,
        constraints: BoxConstraints(minHeight: theme.control.minimumTarget),
        alignment: AlignmentDirectional.centerStart,
        padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
        decoration: BoxDecoration(
          color: selected
              ? theme.color.brandTint
              : pressState.hovered
              ? theme.color.sunken
              : null,
          borderRadius: BorderRadius.circular(theme.radius.s),
        ),
        child: Text(
          label,
          style: theme.typography.body.copyWith(
            color: selected ? theme.color.brandInk : theme.color.muted,
            fontWeight: selected ? theme.typography.semibold : null,
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

int _infoEnabledPrimarySourceCount(_InfoPageState state) =>
    [_InfoPrimarySource.schoolWebsite, _InfoPrimarySource.wechat]
        .where(
          (source) => state._allMessages.any(
            (message) => _matchesInfoPrimarySource(message, source),
          ),
        )
        .length;
