/*
 * 校历页面 — 直接内嵌展示教务处校历 PDF
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'dart:async';

import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/fluent_ui.dart';
import '../models/academic_calendar.dart';
import '../services/academic_calendar_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state_view.dart';
import 'academic_calendar_pdf_file.dart';

/// 校历页面。
class AcademicCalendarPage extends StatefulWidget {
  AcademicCalendarPage({super.key, AcademicCalendarClient? service})
    : service = service ?? AcademicCalendarService.instance;

  /// 校历服务。
  final AcademicCalendarClient service;

  @override
  State<AcademicCalendarPage> createState() => _AcademicCalendarPageState();
}

class _AcademicCalendarPageState extends State<AcademicCalendarPage> {
  List<AcademicCalendarCacheEntry> _entries = const [];
  AcademicCalendarCacheEntry? _selected;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCalendars());
  }

  /// 读取缓存，并在首次进入或超过一个月时自动刷新。
  Future<void> _loadCalendars() async {
    final cached = await widget.service.readCachedCalendars();
    if (mounted && cached.isNotEmpty) {
      setState(() {
        _entries = cached;
        _selected = _selectPreferred(cached, _selected);
      });
    }

    final result = await widget.service.ensureCalendarsForViewer();
    if (!mounted) return;
    setState(() {
      _entries = result.entries;
      _selected = _selectPreferred(result.entries, _selected);
      _errorMessage = result.errorMessage;
      _isLoading = false;
    });
  }

  /// 手动刷新全部校历。
  Future<void> _refreshAll() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final entries = await widget.service.refreshCalendars();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _selected = _selectPreferred(entries, _selected);
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  AcademicCalendarCacheEntry? _selectPreferred(
    List<AcademicCalendarCacheEntry> entries,
    AcademicCalendarCacheEntry? current,
  ) {
    if (entries.isEmpty) return null;
    if (current != null) {
      for (final entry in entries) {
        if (entry.schoolYearStart == current.schoolYearStart) return entry;
      }
    }
    return entries.first;
  }

  Future<void> _openExternal(AcademicCalendarCacheEntry entry) async {
    final target = entry.pdfUrl ?? entry.detailUrl;
    if (target.isEmpty) return;
    final uri = Uri.tryParse(target);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return FluentPage(
      header: FluentPageHeader(
        title: const Text('校历'),
        commandBar: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.end,
          children: [
            FluentButton.outline(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('返回'),
            ),
            FluentButton.primaryIcon(
              onPressed: _isRefreshing ? null : _refreshAll,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: FluentProgressRing(strokeWidth: 2),
                    )
                  : const Icon(FluentIcons.refresh, size: 14),
              label: const Text('刷新校历'),
            ),
            FluentButton.outlineIcon(
              onPressed: selected == null
                  ? null
                  : () => _openExternal(selected),
              icon: const Icon(FluentIcons.openInNewWindow, size: 14),
              label: const Text('外部打开'),
            ),
          ],
        ),
      ),
      content: Padding(
        padding: AppSpacing.regularPagePadding,
        child: _buildBody(selected),
      ),
    );
  }

  Widget _buildBody(AcademicCalendarCacheEntry? selected) {
    if (_isLoading && _entries.isEmpty) {
      return const Center(child: FluentProgressRing());
    }
    if (_entries.isEmpty) {
      return EmptyStateView(
        icon: FluentIcons.calendar,
        title: '暂无校历 PDF',
        message: _errorMessage ?? '尚未获取到教务处校历资源。',
        action: FluentButton.primary(
          onPressed: _isRefreshing ? null : _refreshAll,
          child: const Text('刷新校历'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CalendarSelector(
                entries: _entries,
                selected: selected,
                compact: true,
                onSelected: (entry) => setState(() => _selected = entry),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: _CalendarPdfViewer(entry: selected)),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 280,
              child: _CalendarSelector(
                entries: _entries,
                selected: selected,
                compact: false,
                onSelected: (entry) => setState(() => _selected = entry),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _CalendarPdfViewer(entry: selected)),
          ],
        );
      },
    );
  }
}

class _CalendarSelector extends StatelessWidget {
  const _CalendarSelector({
    required this.entries,
    required this.selected,
    required this.compact,
    required this.onSelected,
  });

  /// 校历条目。
  final List<AcademicCalendarCacheEntry> entries;

  /// 当前选中条目。
  final AcademicCalendarCacheEntry? selected;

  /// 是否为紧凑横向选择器。
  final bool compact;

  /// 选择条目回调。
  final ValueChanged<AcademicCalendarCacheEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) => SizedBox(
            width: 180,
            child: _CalendarSelectorItem(
              entry: entries[index],
              selected:
                  selected?.schoolYearStart == entries[index].schoolYearStart,
              onPressed: () => onSelected(entries[index]),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) => _CalendarSelectorItem(
        entry: entries[index],
        selected: selected?.schoolYearStart == entries[index].schoolYearStart,
        onPressed: () => onSelected(entries[index]),
      ),
    );
  }
}

class _CalendarSelectorItem extends StatelessWidget {
  const _CalendarSelectorItem({
    required this.entry,
    required this.selected,
    required this.onPressed,
  });

  /// 校历条目。
  final AcademicCalendarCacheEntry entry;

  /// 是否选中。
  final bool selected;

  /// 点击回调。
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FluentSurface(
      subtle: !selected,
      elevated: false,
      semanticLabel: '打开${entry.schoolYearLabel}',
      onPressed: onPressed,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          const Icon(FluentIcons.documentText, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.schoolYearLabel, overflow: TextOverflow.ellipsis),
                Text(
                  entry.publishDate.isEmpty ? 'PDF' : entry.publishDate,
                  overflow: TextOverflow.ellipsis,
                  style: context.fluentType.caption1.copyWith(
                    color: context.fluentColors.neutralForeground2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarPdfViewer extends StatelessWidget {
  const _CalendarPdfViewer({required this.entry});

  /// 当前校历条目。
  final AcademicCalendarCacheEntry? entry;

  @override
  Widget build(BuildContext context) {
    final current = entry;
    if (current == null) {
      return const EmptyStateView(
        icon: FluentIcons.documentText,
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
      icon: FluentIcons.documentText,
      title: '暂无可查看的 PDF',
      message: '该校历未识别到可直接打开的 PDF 资源。',
      action: FluentButton.primary(
        onPressed: current.detailUrl.isEmpty
            ? null
            : () => _openDetail(current.detailUrl),
        child: const Text('打开详情页'),
      ),
    );
  }

  Future<void> _openDetail(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildErrorBanner(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    PdfDocumentRef documentRef,
  ) {
    final current = entry;
    return EmptyStateView(
      icon: FluentIcons.warning,
      title: 'PDF 加载失败',
      message: error.toString(),
      action: current?.pdfUrl == null
          ? null
          : FluentButton.primary(
              onPressed: () => _openDetail(current!.pdfUrl!),
              child: const Text('在浏览器中打开'),
            ),
    );
  }
}
