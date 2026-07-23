/*
 * 校历 PDF 页面 — 使用 pdfrx 在应用内查看原始校历 PDF
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_pdf_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import '../design/qingyuan/qingyuan_ui.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/empty_state_view.dart';
import 'academic_calendar_pdf_file.dart';

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
  });

  final String title;
  final Widget document;
  final VoidCallback onBack;
  final String pageLabel;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomIn;
  final VoidCallback onDownload;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) => YhPageScaffold(
    appBar: YhAppBar(
      title: title,
      leading: YhIconButton(
        key: const Key('webview-back-close-button'),
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
class AcademicCalendarPdfPage extends StatefulWidget {
  const AcademicCalendarPdfPage({
    super.key,
    required this.title,
    this.pdfFilePath,
    this.pdfUrl,
  });

  /// 页面标题。
  final String title;

  /// 本地 PDF 文件路径。
  final String? pdfFilePath;

  /// 网络 PDF 地址。
  final String? pdfUrl;

  @override
  State<AcademicCalendarPdfPage> createState() =>
      _AcademicCalendarPdfPageState();
}

class _AcademicCalendarPdfPageState extends State<AcademicCalendarPdfPage> {
  final PdfViewerController _pdfController = PdfViewerController();
  int _pageNumber = 1;
  int? _pageCount;

  Future<void> _openExternal() async {
    final target = widget.pdfUrl ?? widget.pdfFilePath;
    if (target == null || target.isEmpty) return;
    final uri = target.startsWith('http')
        ? Uri.parse(target)
        : Uri.file(target);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _viewerReady(PdfDocument document, PdfViewerController controller) {
    if (!mounted) return;
    setState(() {
      _pageNumber = controller.pageNumber ?? 1;
      _pageCount = controller.pageCount;
    });
  }

  void _pageChanged(int? pageNumber) {
    if (!mounted || pageNumber == null || pageNumber == _pageNumber) return;
    setState(() => _pageNumber = pageNumber);
  }

  PdfViewerParams get _viewerParams => PdfViewerParams(
    errorBannerBuilder: _buildErrorBanner,
    onViewerReady: _viewerReady,
    onPageChanged: _pageChanged,
  );

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (academicCalendarPdfFileExists(widget.pdfFilePath)) {
      body = PdfViewer.file(
        widget.pdfFilePath!,
        controller: _pdfController,
        params: _viewerParams,
      );
    } else if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty) {
      body = PdfViewer.uri(
        Uri.parse(widget.pdfUrl!),
        controller: _pdfController,
        params: _viewerParams,
      );
    } else {
      body = EmptyStateView(
        icon: YhIcons.library,
        title: '暂无可查看的 PDF',
        message: '该校历未解析到可用的原始 PDF。',
        action: YhButton(
          label: '返回',
          onTap: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    return AcademicCalendarPdfFrame(
      title: widget.title,
      document: body,
      onBack: () => Navigator.of(context).maybePop(),
      pageLabel: _pageCount == null
          ? '页码加载中'
          : '第 $_pageNumber / $_pageCount 页',
      onZoomOut: _pdfController.isReady ? _pdfController.zoomDown : null,
      onZoomIn: _pdfController.isReady ? _pdfController.zoomUp : null,
      onDownload: _openExternal,
      onOpenExternal: _openExternal,
    );
  }

  Widget _buildErrorBanner(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    PdfDocumentRef documentRef,
  ) {
    return EmptyStateView(
      icon: YhIcons.warning,
      title: 'PDF 加载失败',
      message: error.toString(),
      action: YhButton(label: '在浏览器中打开', onTap: _openExternal),
    );
  }
}
