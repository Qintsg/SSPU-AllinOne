/*
 * 校历 PDF 页面框架 — 工具栏 + 页码/缩放行 + 正文槽位
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_pdf_frame.dart
 * @Author : Qintsg
 * @Date : 2026-08-21
 */

import '../design/qingyuan/qingyuan_ui.dart';

/// PDF 清源页面框架；真实 pdfrx 与确定性外部区域 fixture 共享工具栏。
class AcademicCalendarPdfFrame extends StatelessWidget {
  const AcademicCalendarPdfFrame({
    super.key,
    required this.title,
    required this.document,
    required this.onBack,
    required this.pageLabel,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onDownload,
    required this.onOpenExternal,
    this.statusBanner,
  });

  final String title;
  final Widget document;
  final VoidCallback onBack;
  final String pageLabel;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomIn;
  final VoidCallback? onDownload;
  final VoidCallback? onOpenExternal;
  final Widget? statusBanner;

  @override
  Widget build(BuildContext context) => YhPageScaffold(
    appBar: YhAppBar(
      title: title,
      horizontalPadding: context.yhTheme.spacing.s,
      actionSpacing: context.yhTheme.spacing.s,
      leading: YhIconButton(
        key: const Key('pdf-back-close-button'),
        icon: YhIcons.back,
        semanticLabel: '返回',
        variant: YhIconButtonVariant.ghost,
        onTap: onBack,
      ),
      actions: [
        YhIconButton(
          icon: YhIcons.download,
          semanticLabel: '下载校历 PDF',
          onTap: onDownload,
        ),
        YhIconButton(
          icon: YhIcons.open,
          semanticLabel: '外部打开校历 PDF',
          onTap: onOpenExternal,
        ),
      ],
    ),
    body: Column(
      children: [
        if (statusBanner != null)
          MediaQuery.sizeOf(context).width < context.yhTheme.breakpoint.medium
              ? Padding(
                  padding: EdgeInsets.only(
                    left: context.yhTheme.spacing.s,
                    top: context.yhTheme.spacing.s,
                    right: context.yhTheme.spacing.s,
                  ),
                  child: SizedBox(
                    height:
                        context.yhTheme.control.touch +
                        context.yhTheme.spacing.s +
                        context.yhTheme.spacing.xs,
                    child: ClipRect(child: statusBanner),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.yhTheme.spacing.s,
                    vertical: context.yhTheme.spacing.xs,
                  ),
                  child: statusBanner,
                ),
        Builder(
          builder: (context) {
            final theme = context.yhTheme;
            return Container(
              constraints: BoxConstraints(minHeight: theme.control.touch),
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
              decoration: BoxDecoration(
                color: theme.color.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.color.border,
                    width: theme.layout.divider,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'PDF 页码：$pageLabel',
                      child: Text(pageLabel, style: theme.typography.small),
                    ),
                  ),
                  YhIconButton(
                    icon: YhIcons.zoomOut,
                    semanticLabel: '缩小 PDF',
                    variant: YhIconButtonVariant.ghost,
                    onTap: onZoomOut,
                  ),
                  YhIconButton(
                    icon: YhIcons.zoomIn,
                    semanticLabel: '放大 PDF',
                    variant: YhIconButtonVariant.ghost,
                    onTap: onZoomIn,
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(child: document),
      ],
    ),
  );
}

/// 校历 PDF 查看页。
