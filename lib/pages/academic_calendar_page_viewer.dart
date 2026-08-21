/*
 * 校历页面查看器 — 嵌入式 PDF 正文与恢复提示
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_page_viewer.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_calendar_page.dart';

class _CalendarPdfViewer extends StatelessWidget {
  const _CalendarPdfViewer({required this.entry, required this.onOpenExternal});

  /// 当前校历条目。
  final AcademicCalendarCacheEntry? entry;
  final VoidCallback? onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final current = entry;
    if (current == null) {
      return const EmptyStateView(
        icon: YhIcons.library,
        title: '请选择校历',
        message: '从左侧选择一个学年查看原始 PDF。',
      );
    }
    if (academicCalendarPdfFileExists(current.pdfFilePath)) {
      return PdfViewer.file(
        current.pdfFilePath!,
        params: PdfViewerParams(errorBannerBuilder: _buildErrorBanner),
      );
    }
    if (current.pdfUrl != null && current.pdfUrl!.isNotEmpty) {
      return PdfViewer.uri(
        Uri.parse(current.pdfUrl!),
        params: PdfViewerParams(errorBannerBuilder: _buildErrorBanner),
      );
    }
    return EmptyStateView(
      icon: YhIcons.library,
      title: '暂无可查看的 PDF',
      message: '该校历未识别到可直接打开的 PDF 资源。',
      action: YhButton(
        label: '打开详情页',
        onTap: current.detailUrl.isEmpty ? null : onOpenExternal,
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
      icon: YhIcons.warning,
      title: 'PDF 加载失败',
      message: '当前 PDF 暂时无法读取；所选学年和返回路径已保留，可重试外部打开。',
      action: onOpenExternal == null
          ? null
          : YhButton(label: '外部打开', onTap: onOpenExternal),
    );
  }
}
