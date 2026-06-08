/*
 * 校历 PDF 页面 — 使用 pdfrx 在应用内查看原始校历 PDF
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_pdf_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import '../design/fluent_ui.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/empty_state_view.dart';
import '../widgets/webview_compact_toolbar.dart';
import 'academic_calendar_pdf_file.dart';

/// 校历 PDF 查看页。
class AcademicCalendarPdfPage extends StatelessWidget {
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

  Future<void> _openExternal() async {
    final target = pdfUrl ?? pdfFilePath;
    if (target == null || target.isEmpty) return;
    final uri = target.startsWith('http')
        ? Uri.parse(target)
        : Uri.file(target);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (academicCalendarPdfFileExists(pdfFilePath)) {
      body = PdfViewer.file(
        pdfFilePath!,
        params: PdfViewerParams(errorBannerBuilder: _buildErrorBanner),
      );
    } else if (pdfUrl != null && pdfUrl!.isNotEmpty) {
      body = PdfViewer.uri(
        Uri.parse(pdfUrl!),
        params: PdfViewerParams(errorBannerBuilder: _buildErrorBanner),
      );
    } else {
      body = EmptyStateView(
        icon: FluentIcons.documentText,
        title: '暂无可查看的 PDF',
        message: '该校历未解析到可用的原始 PDF。',
        action: FluentButton.primary(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('返回'),
        ),
      );
    }

    return FluentPage(
      content: Column(
        children: [
          WebViewCompactToolbar(
            title: title,
            onBackPressed: () => Navigator.of(context).maybePop(),
            actions: [
              FluentIconButton(
                tooltip: '外部打开',
                semanticLabel: '外部打开校历 PDF',
                icon: const Icon(FluentIcons.openInNewWindow),
                onPressed: _openExternal,
                size: 32,
              ),
            ],
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    PdfDocumentRef documentRef,
  ) {
    return EmptyStateView(
      icon: FluentIcons.warning,
      title: 'PDF 加载失败',
      message: error.toString(),
      action: FluentButton.primary(
        onPressed: _openExternal,
        child: const Text('在浏览器中打开'),
      ),
    );
  }
}
