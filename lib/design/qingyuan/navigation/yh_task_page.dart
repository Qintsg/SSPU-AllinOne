/*
 * 清源次级任务页 — 统一标题、来源、主要行动与响应式正文
 * @Project : SSPU-AllinOne
 * @File : yh_task_page.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

import 'package:flutter/widgets.dart';

import '../components/yh_bottom_drawer.dart';
import '../components/yh_button.dart';
import '../components/yh_icon_button.dart';
import '../icons/yh_icons.dart';
import '../theme/yh_theme.dart';
import 'yh_app_bar.dart';
import 'yh_page_scaffold.dart';

enum YhTaskAccent { brand, structural }

enum YhTaskPageWidth { constrained, reading, fluid }

enum YhTaskPageRhythm { standard, relaxedCompact }

enum YhTaskPageBodyFit { fill, content }

class YhTaskPageAction {
  const YhTaskPageAction({
    required this.label,
    required this.onTap,
    this.variant = YhButtonVariant.secondary,
  });

  final String label;
  final VoidCallback? onTap;
  final YhButtonVariant variant;
}

class YhTaskPage extends StatefulWidget {
  const YhTaskPage({
    super.key,
    required this.title,
    required this.kicker,
    required this.summary,
    required this.source,
    required this.sourceSymbol,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.body,
    this.primaryActionKey,
    this.sourceTimestamp,
    this.accent = YhTaskAccent.brand,
    this.width = YhTaskPageWidth.constrained,
    this.rhythm = YhTaskPageRhythm.standard,
    this.bodyFit = YhTaskPageBodyFit.fill,
    this.onBack,
    this.canPop = true,
    this.appBarEyebrow,
    this.appBarTitle,
    this.moreActions = const [],
  });

  final String title;
  final String kicker;
  final String summary;
  final String source;
  final String sourceSymbol;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final Key? primaryActionKey;
  final Widget body;
  final String? sourceTimestamp;
  final YhTaskAccent accent;
  final YhTaskPageWidth width;
  final YhTaskPageRhythm rhythm;
  final YhTaskPageBodyFit bodyFit;
  final VoidCallback? onBack;
  final bool canPop;
  final String? appBarEyebrow;
  final String? appBarTitle;
  final List<YhTaskPageAction> moreActions;

  @override
  State<YhTaskPage> createState() => _YhTaskPageState();
}

class _YhTaskPageState extends State<YhTaskPage> {
  final FocusNode _moreActionsFocusNode = FocusNode(
    debugLabel: 'YhTaskPage.moreActions',
  );

  @override
  void dispose() {
    _moreActionsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.canPop,
      child: YhPageScaffold(
        appBar: YhAppBar(
          eyebrow: widget.appBarEyebrow ?? widget.kicker,
          title: widget.appBarTitle ?? widget.source,
          leading: YhIconButton(
            icon: YhIcons.back,
            semanticLabel: '返回',
            variant: YhIconButtonVariant.ghost,
            onTap: widget.canPop
                ? widget.onBack ?? () => Navigator.of(context).maybePop()
                : null,
          ),
          actions: [
            YhIconButton(
              icon: YhIcons.more,
              semanticLabel: '更多操作',
              variant: YhIconButtonVariant.ghost,
              focusNode: _moreActionsFocusNode,
              onTap: () => _showSourceInfo(context),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final theme = context.yhTheme;
            final compact =
                MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
            final pagePadding = compact
                ? theme.spacing.m
                : (MediaQuery.sizeOf(context).width *
                          theme.responsive.panelPaddingViewportPercent /
                          100)
                      .clamp(theme.spacing.l, theme.spacing.xl2);
            final relaxedCompact =
                widget.rhythm == YhTaskPageRhythm.relaxedCompact;
            final topPagePadding = compact
                ? pagePadding +
                      (widget.width == YhTaskPageWidth.reading
                          ? theme.spacing.xs
                          : 0) +
                      (relaxedCompact
                          ? theme.spacing.xs + theme.layout.controlBorder
                          : 0)
                : pagePadding +
                      (relaxedCompact &&
                              MediaQuery.sizeOf(context).width ==
                                  theme.breakpoint.medium
                          ? theme.spacing.xs
                          : 0);
            final minimumBodyHeight = _minimumBodyHeight(
              theme,
              compact: compact,
              bodyHeight: constraints.maxHeight,
              pagePadding: pagePadding,
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                pagePadding,
                topPagePadding,
                pagePadding,
                pagePadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: switch (widget.width) {
                      YhTaskPageWidth.constrained =>
                        theme.layout.pageContentWidth,
                      YhTaskPageWidth.reading =>
                        theme.layout.pageContentWidth - theme.spacing.xl2 * 2,
                      YhTaskPageWidth.fluid => double.infinity,
                    },
                    minHeight:
                        constraints.maxHeight - topPagePadding - pagePadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TaskHeading(
                        title: widget.title,
                        kicker: widget.kicker,
                        summary: widget.summary,
                        actionLabel: widget.primaryActionLabel,
                        onAction: widget.onPrimaryAction,
                        actionKey: widget.primaryActionKey,
                        compact: compact,
                        accent: widget.accent,
                      ),
                      SizedBox(
                        height: compact ? theme.spacing.m : theme.spacing.l,
                      ),
                      _TaskSourceStrip(
                        source: widget.source,
                        sourceSymbol: widget.sourceSymbol,
                        timestamp: widget.sourceTimestamp,
                        accent: widget.accent,
                      ),
                      SizedBox(
                        height: compact ? theme.spacing.m : theme.spacing.l,
                      ),
                      if (widget.bodyFit == YhTaskPageBodyFit.fill)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: minimumBodyHeight,
                          ),
                          child: widget.body,
                        )
                      else
                        widget.body,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _minimumBodyHeight(
    YhTheme theme, {
    required bool compact,
    required double bodyHeight,
    required double pagePadding,
  }) {
    if (compact) {
      return theme.control.regular *
          (widget.width == YhTaskPageWidth.reading ? 7 : 9);
    }
    final small = theme.typography.small;
    final display = theme.typography.display;
    final bodyStyle = theme.typography.body;
    final headingHeight =
        small.fontSize! * small.height! +
        display.fontSize! * display.height! +
        bodyStyle.fontSize! * bodyStyle.height! +
        theme.spacing.s * 2;
    final fixedHeight =
        pagePadding * 2 +
        headingHeight +
        theme.spacing.l * 2 +
        theme.control.minimumTarget;
    return (bodyHeight - fixedHeight).clamp(
      theme.control.regular * 7,
      double.infinity,
    );
  }

  Future<void> _showSourceInfo(BuildContext context) async {
    final selectedAction = await YhBottomDrawer.show<YhTaskPageAction>(
      context,
      title: '来源信息',
      builder: (drawerContext) {
        final theme = drawerContext.yhTheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.source),
            if (widget.sourceTimestamp != null) ...[
              SizedBox(height: theme.spacing.s),
              Text(
                widget.sourceTimestamp!,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ],
            for (final action in widget.moreActions) ...[
              SizedBox(height: theme.spacing.s),
              YhButton(
                label: action.label,
                variant: action.variant,
                onTap: action.onTap == null
                    ? null
                    : () => Navigator.of(drawerContext).pop(action),
              ),
            ],
            SizedBox(height: theme.spacing.l),
            YhButton(
              label: '关闭',
              variant: YhButtonVariant.secondary,
              onTap: () => Navigator.of(drawerContext).pop(),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    _moreActionsFocusNode.requestFocus();
    selectedAction?.onTap?.call();
  }
}

class _TaskHeading extends StatelessWidget {
  const _TaskHeading({
    required this.title,
    required this.kicker,
    required this.summary,
    required this.actionLabel,
    required this.onAction,
    required this.actionKey,
    required this.compact,
    required this.accent,
  });

  final String title;
  final String kicker;
  final String summary;
  final String actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final bool compact;
  final YhTaskAccent accent;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accentColor = accent == YhTaskAccent.structural
        ? theme.color.structural
        : theme.color.brandInk;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker,
          style: theme.typography.small.copyWith(
            color: accentColor,
            fontWeight: theme.typography.h3.fontWeight,
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
    final action = YhButton(
      key: actionKey,
      label: actionLabel,
      onTap: onAction,
      minWidth: compact ? double.infinity : null,
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          copy,
          SizedBox(height: theme.spacing.m - theme.layout.controlBorder * 2),
          action,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: copy),
        SizedBox(width: theme.spacing.xl),
        action,
      ],
    );
  }
}

class _TaskSourceStrip extends StatelessWidget {
  const _TaskSourceStrip({
    required this.source,
    required this.sourceSymbol,
    required this.timestamp,
    required this.accent,
  });

  final String source;
  final String sourceSymbol;
  final String? timestamp;
  final YhTaskAccent accent;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    final accentColor = accent == YhTaskAccent.structural
        ? theme.color.structural
        : theme.color.brandStrong;
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
          child: compact
              ? Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: theme.spacing.s,
                  runSpacing: theme.spacing.xs,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(theme.radius.full),
                      ),
                      child: SizedBox.square(dimension: theme.spacing.s),
                    ),
                    Text(
                      '$sourceSymbol  $source',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.small.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(theme.radius.full),
                      ),
                      child: SizedBox.square(dimension: theme.spacing.s),
                    ),
                    SizedBox(width: theme.spacing.s),
                    Expanded(
                      child: Text(
                        '$sourceSymbol  $source',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.small.copyWith(
                          color: theme.color.muted,
                        ),
                      ),
                    ),
                    if (timestamp != null)
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
