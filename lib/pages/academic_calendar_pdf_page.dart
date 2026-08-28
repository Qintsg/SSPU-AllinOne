/*
 * 校历 PDF 页面 — 使用 pdfrx 在应用内查看原始校历 PDF
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_pdf_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'dart:io';

import '../design/qingyuan/qingyuan_ui.dart';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/empty_state_view.dart';
import 'academic_calendar_pdf_file.dart';
import 'academic_calendar_pdf_frame.dart';

/// PDF 正文 seam；平台集成使用 pdfrx，行为与视觉测试可注入确定性 adapter。
typedef AcademicCalendarPdfDocumentBuilder = Widget Function(
  BuildContext context,
  String? source,
  int revision,
  AcademicCalendarPdfDocumentActions actions,
);

/// 注入式 PDF 正文可使用的真实页面恢复动作。
class AcademicCalendarPdfDocumentActions {
  const AcademicCalendarPdfDocumentActions({
    required this.retry,
    required this.openExternal,
    required this.operationLocked,
  });

  final VoidCallback? retry;
  final VoidCallback? openExternal;
  final bool operationLocked;
}

/// PDF 正文的可见生命周期状态。
enum AcademicCalendarPdfDocumentState { loading, content, empty, error }

/// PDF 保存 adapter。
typedef AcademicCalendarPdfDownloadAdapter = Future<void> Function(
  String source,
  String title,
);

/// PDF 外部打开 adapter。
typedef AcademicCalendarPdfExternalAdapter = Future<bool> Function(Uri uri);

/// 在离开应用前展示可信 PDF 目标与本地保护边界。
Future<bool> confirmAcademicCalendarPdfExternalOpen(
  BuildContext context,
  Uri uri,
) async {
  final target = uri.host.isEmpty
      ? (uri.pathSegments.isEmpty ? '本地 PDF 文件' : uri.pathSegments.last)
      : '${uri.host}${uri.path}';
  final result = await YhDialog.show<bool>(
    context,
    builder: (dialogContext) => YhDialog(
      eyebrow: '外部 PDF',
      title: '在外部应用打开校历？',
      headerInset: context.yhTheme.spacing.l,
      titleStyle: context.yhTheme.typography.h3.copyWith(
        fontWeight: context.yhTheme.typography.semibold,
      ),
      content: Text('即将打开 $target。外部应用中的文档不再受本应用本地保护。'),
      actions: [
        YhButton(
          label: '取消',
          variant: YhButtonVariant.secondary,
          minWidth:
              context.yhTheme.control.minimumTarget +
              context.yhTheme.spacing.l +
              context.yhTheme.spacing.xs,
          autofocus: true,
          onTap: () => Navigator.of(dialogContext).pop(false),
        ),
        YhButton(
          label: '继续打开',
          minWidth:
              context.yhTheme.control.minimumTarget +
              context.yhTheme.spacing.l +
              context.yhTheme.spacing.m +
              context.yhTheme.spacing.xs,
          onTap: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

class AcademicCalendarPdfPage extends StatefulWidget {
  const AcademicCalendarPdfPage({
    super.key,
    required this.title,
    this.pdfFilePath,
    this.pdfUrl,
    this.documentBuilder,
    this.downloadOverride,
    this.launchExternalOverride,
    this.initialPageNumber = 1,
    this.initialPageCount,
    this.initialDocumentState,
  });

  /// 页面标题。
  final String title;

  /// 本地 PDF 文件路径。
  final String? pdfFilePath;

  /// 网络 PDF 地址。
  final String? pdfUrl;

  /// 可替换的正文 adapter；为空时使用生产 pdfrx 实现。
  final AcademicCalendarPdfDocumentBuilder? documentBuilder;

  /// 可替换的保存 adapter。
  final AcademicCalendarPdfDownloadAdapter? downloadOverride;

  /// 可替换的外部打开 adapter。
  final AcademicCalendarPdfExternalAdapter? launchExternalOverride;

  /// 恢复或确定性测试使用的初始页码。
  final int initialPageNumber;

  /// 恢复或确定性测试使用的初始总页数；真实查看器就绪后会覆盖。
  final int? initialPageCount;

  /// 恢复与确定性视觉测试使用的初始正文状态。
  final AcademicCalendarPdfDocumentState? initialDocumentState;

  @override
  State<AcademicCalendarPdfPage> createState() =>
      _AcademicCalendarPdfPageState();
}

class _AcademicCalendarPdfPageState extends State<AcademicCalendarPdfPage> {
  final PdfViewerController _pdfController = PdfViewerController();
  late int _pageNumber;
  int? _pageCount;
  int _viewerRevision = 0;
  int _sourceGeneration = 0;
  _PdfOperation? _operation;
  String? _operationError;
  late AcademicCalendarPdfDocumentState _documentState;

  bool get _operationLocked => _operation != null;

  String? get _source => widget.pdfUrl ?? widget.pdfFilePath;

  String get _pagePosition =>
      _pageCount == null ? '当前页码' : '第 $_pageNumber / $_pageCount 页';

  @override
  void initState() {
    super.initState();
    _pageNumber = widget.initialPageNumber;
    _pageCount = widget.initialPageCount;
    _documentState = _initialDocumentState();
  }

  AcademicCalendarPdfDocumentState _initialDocumentState() {
    final explicit = widget.initialDocumentState;
    if (explicit != null) return explicit;
    final source = _source;
    if (source == null || source.isEmpty) {
      return AcademicCalendarPdfDocumentState.empty;
    }
    return widget.documentBuilder == null
        ? AcademicCalendarPdfDocumentState.loading
        : AcademicCalendarPdfDocumentState.content;
  }

  @override
  void didUpdateWidget(covariant AcademicCalendarPdfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfUrl == widget.pdfUrl &&
        oldWidget.pdfFilePath == widget.pdfFilePath &&
        oldWidget.title == widget.title) {
      return;
    }
    _sourceGeneration++;
    setState(() {
      _operation = null;
      _operationError = null;
      _viewerRevision++;
      _pageNumber = widget.initialPageNumber;
      _pageCount = widget.initialPageCount;
      _documentState = _initialDocumentState();
    });
  }

  @override
  void dispose() {
    _sourceGeneration++;
    super.dispose();
  }

  String get _sourceLabel {
    final source = widget.pdfUrl ?? widget.pdfFilePath;
    if (source == null || source.isEmpty) return '未提供文件来源';
    final uri = source.startsWith('http')
        ? Uri.tryParse(source)
        : Uri.file(source);
    if (uri == null) return '无法识别的文件来源';
    final name = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    if (uri.host.isNotEmpty) {
      return name.isEmpty ? uri.host : '${uri.host}/$name';
    }
    return name.isEmpty ? '本地 PDF 文件' : name;
  }

  void _retryPdf() {
    if (_operationLocked) return;
    setState(() {
      _viewerRevision += 1;
      _documentState = AcademicCalendarPdfDocumentState.loading;
    });
  }

  Future<void> _openExternal() async {
    if (_operationLocked) return;
    final target = _source;
    if (target == null || target.isEmpty) {
      setState(() => _operationError = '当前没有可外部打开的 PDF 文件。');
      return;
    }
    final uri = target.startsWith('http')
        ? Uri.tryParse(target)
        : Uri.file(target);
    if (uri == null) {
      setState(() => _operationError = '当前 PDF 来源无法识别，不能交给外部应用。');
      return;
    }
    final generation = _sourceGeneration;
    bool confirmed;
    try {
      confirmed = await confirmAcademicCalendarPdfExternalOpen(context, uri);
    } on Object {
      if (_isCurrentSource(generation, target)) {
        setState(() {
          _operationError = '暂时无法显示外部打开确认；页码、缩放和正文已保留，可重试。';
        });
      }
      return;
    }
    if (!confirmed || !_isCurrentSource(generation, target)) return;
    setState(() {
      _operation = _PdfOperation.openExternal;
      _operationError = null;
    });
    try {
      final opened = widget.launchExternalOverride != null
          ? await widget.launchExternalOverride!(uri)
          : await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (_isCurrentSource(generation, target) && !opened) {
        setState(() {
          _operationError = '系统未能打开校历 PDF；仍停留在 $_pagePosition，可检查默认 PDF 应用后重试。';
        });
      }
    } on Object {
      if (_isCurrentSource(generation, target)) {
        setState(() {
          _operationError = '系统未能打开校历 PDF；仍停留在 $_pagePosition，可检查默认 PDF 应用后重试。';
        });
      }
    } finally {
      if (_isCurrentSource(generation, target)) {
        setState(() => _operation = null);
      }
    }
  }

  Future<void> _download() async {
    if (_operationLocked) return;
    final source = _source;
    if (source == null || source.isEmpty) {
      if (mounted) {
        showYhFeedback(
          context,
          message: '当前没有可下载的 PDF 文件',
          severity: AppFeedbackSeverity.error,
        );
      }
      return;
    }
    final generation = _sourceGeneration;
    setState(() {
      _operation = _PdfOperation.download;
      _operationError = null;
    });
    try {
      if (widget.downloadOverride != null) {
        await widget.downloadOverride!(source, widget.title);
      } else {
        await _downloadToPlatform(source, widget.title);
      }
      if (mounted && _isCurrentSource(generation, source)) {
        showYhFeedback(context, message: '校历 PDF 已保存到下载目录');
      }
    } on Object {
      if (mounted && _isCurrentSource(generation, source)) {
        setState(() {
          _operationError =
              '校历 PDF 未能保存到下载目录；正文和 $_pagePosition位置已保留，可检查权限后重试。';
        });
        showYhFeedback(
          context,
          message: _operationError!,
          severity: AppFeedbackSeverity.error,
        );
      }
    } finally {
      if (_isCurrentSource(generation, source)) {
        setState(() => _operation = null);
      }
    }
  }

  Future<void> _downloadToPlatform(String source, String title) async {
    final directory = await getDownloadsDirectory();
    if (directory == null) {
      throw const FileSystemException('downloads directory unavailable');
    }
    final safeTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final target = File(
      '${directory.path}${Platform.pathSeparator}$safeTitle.pdf',
    );
    if (source.startsWith('http')) {
      await Dio().download(source, target.path);
    } else {
      await File(source).copy(target.path);
    }
  }

  bool _isCurrentSource(int generation, String source) =>
      mounted && generation == _sourceGeneration && _source == source;

  void _viewerReady(PdfDocument document, PdfViewerController controller) {
    if (!mounted) return;
    setState(() {
      _pageNumber = controller.pageNumber ?? 1;
      _pageCount = controller.pageCount;
      _documentState = AcademicCalendarPdfDocumentState.content;
    });
  }

  void _pageChanged(int? pageNumber) {
    if (!mounted || pageNumber == null || pageNumber == _pageNumber) return;
    setState(() => _pageNumber = pageNumber);
  }

  PdfViewerParams _viewerParams(int generation) => PdfViewerParams(
    errorBannerBuilder: _buildErrorBanner,
    onViewerReady: (document, controller) {
      if (generation == _sourceGeneration) _viewerReady(document, controller);
    },
    onPageChanged: (pageNumber) {
      if (generation == _sourceGeneration) _pageChanged(pageNumber);
    },
  );

  @override
  Widget build(BuildContext context) {
    Widget body;
    final sourceGeneration = _sourceGeneration;
    if (widget.documentBuilder != null) {
      body = widget.documentBuilder!(
        context,
        _source,
        _viewerRevision,
        AcademicCalendarPdfDocumentActions(
          retry: _operationLocked ? null : _retryPdf,
          openExternal: _operationLocked ? null : _openExternal,
          operationLocked: _operationLocked,
        ),
      );
    } else if (academicCalendarPdfFileExists(widget.pdfFilePath)) {
      body = PdfViewer.file(
        widget.pdfFilePath!,
        key: ValueKey(_viewerRevision),
        controller: _pdfController,
        params: _viewerParams(sourceGeneration),
      );
    } else if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty) {
      body = PdfViewer.uri(
        Uri.parse(widget.pdfUrl!),
        key: ValueKey(_viewerRevision),
        controller: _pdfController,
        params: _viewerParams(sourceGeneration),
      );
    } else {
      body = EmptyStateView(
        icon: YhIcons.library,
        title: '暂无可查看的 PDF',
        message: '当前校历没有本地文件或可用网络地址；请返回校历档案重新选择。',
        action: YhButton(
          label: '返回校历',
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
      onZoomIn:
          _documentState == AcademicCalendarPdfDocumentState.content &&
              _pdfController.isReady &&
              !_operationLocked
          ? _pdfController.zoomUp
          : null,
      onZoomOut:
          _documentState == AcademicCalendarPdfDocumentState.content &&
              _pdfController.isReady &&
              !_operationLocked
          ? _pdfController.zoomDown
          : null,
      onDownload:
          _documentState == AcademicCalendarPdfDocumentState.content &&
              !_operationLocked
          ? _download
          : null,
      onOpenExternal:
          _documentState != AcademicCalendarPdfDocumentState.loading &&
              _documentState != AcademicCalendarPdfDocumentState.empty &&
              !_operationLocked
          ? _openExternal
          : null,
      statusBanner: _buildOperationBanner(),
    );
  }

  Widget? _buildOperationBanner() {
    final operation = _operation;
    if (operation != null) {
      return YhBanner(
        text: operation == _PdfOperation.download
            ? '正在下载校历 PDF；当前页码、缩放和正文保持可用，完成前已锁定重复操作。'
            : '正在交给外部应用；当前页码、缩放和正文保持可用，完成前已锁定重复操作。',
      );
    }
    final error = _operationError;
    return error == null
        ? null
        : YhBanner(text: error, kind: YhBannerKind.danger);
  }

  Widget _buildErrorBanner(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    PdfDocumentRef documentRef,
  ) {
    final generation = _sourceGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isCurrentSource(generation, _source ?? '') &&
          _documentState != AcademicCalendarPdfDocumentState.error) {
        setState(() => _documentState = AcademicCalendarPdfDocumentState.error);
      }
    });
    return EmptyStateView(
      icon: YhIcons.warning,
      title: 'PDF 加载失败',
      message: '文件来源：$_sourceLabel。无法读取 PDF，请重试或改用外部应用打开。',
      action: Wrap(
        spacing: context.yhTheme.spacing.s,
        runSpacing: context.yhTheme.spacing.s,
        children: [
          YhButton(label: '重试读取', onTap: _operationLocked ? null : _retryPdf),
          YhButton(
            label: '外部打开',
            onTap: _operationLocked ? null : _openExternal,
            variant: YhButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}

enum _PdfOperation { download, openExternal }
