/*
 * 校历页面 — 展示教务处校历缓存、结构化学期与原始资源入口
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'dart:async';

import '../design/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/academic_calendar.dart';
import '../services/academic_calendar_service.dart';
import '../theme/app_spacing.dart';
import 'academic_calendar_pdf_page.dart';

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

  Future<void> _loadCalendars() async {
    final cached = await widget.service.readCachedCalendars();
    if (mounted && cached.isNotEmpty) {
      setState(() {
        _entries = cached;
        _selected = cached.first;
      });
    }

    try {
      final result = await widget.service.ensureCalendarsForDate();
      if (!mounted) return;
      setState(() {
        _entries = result.entries;
        _selected = _selectPreferred(result.entries, _selected);
        _errorMessage = result.errorMessage;
        _isLoading = false;
      });
      if (result.errorMessage != null && result.entries.isEmpty) {
        await _showParseFailureDialog(result.errorMessage!);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
      await _showParseFailureDialog(error.toString());
    }
  }

  Future<void> _refreshAll() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await widget.service.refreshCalendars();
      final entries = await widget.service.readCachedCalendars();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _selected = _selectPreferred(entries, _selected);
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
      await _showParseFailureDialog(error.toString());
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

  Future<void> _showParseFailureDialog(String detail) async {
    if (!mounted) return;
    return showFluentDialog<void>(
      context: context,
      builder: (dialogContext) {
        return FluentDialog(
          title: const Text('校历解析失败'),
          content: Text('校历获取或解析失败，不会影响课表等核心功能。\n\n$detail'),
          actions: [
            FluentButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('关闭'),
            ),
            FluentButton.primary(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                unawaited(_openIssueUrl(detail));
              },
              child: const Text('提交 issue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openIssueUrl(String detail) async {
    final selected = _selected;
    final title = Uri.encodeComponent(
      '校历解析失败：${selected?.schoolYearLabel ?? '未知学年'}',
    );
    final body = Uri.encodeComponent(
      '## 校历解析失败反馈\n\n'
      '- 学年：${selected?.schoolYearLabel ?? '未知'}\n'
      '- 详情页：${selected?.detailUrl ?? '未知'}\n'
      '- PDF：${selected?.pdfUrl ?? '无'}\n\n'
      '## 错误摘要\n\n$detail',
    );
    final uri = Uri.parse(
      'https://github.com/Qintsg/SSPU-AllinOne/issues/new?title=$title&body=$body',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openPdf(AcademicCalendarCacheEntry entry) {
    Navigator.of(context).push(
      FluentPageRoute(
        builder: (_) => AcademicCalendarPdfPage(
          title: '${entry.schoolYearLabel} 原始 PDF',
          pdfFilePath: entry.pdfFilePath,
          pdfUrl: entry.pdfUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return FluentPage.scrollable(
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
          ],
        ),
      ),
      padding: AppSpacing.regularPagePadding,
      children: [
        _buildStatusCard(),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 720;
            if (narrow) {
              return Column(
                children: [
                  _buildCalendarList(),
                  const SizedBox(height: AppSpacing.md),
                  if (selected != null) _buildCalendarDetail(selected),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: _buildCalendarList()),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: selected == null
                      ? const SizedBox.shrink()
                      : _buildCalendarDetail(selected),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    if (_isLoading && _entries.isEmpty) {
      return const FluentInfoBar(
        title: Text('正在同步校历'),
        content: Text('优先读取本地缓存，缺少当前或临近学年时自动从教务处获取。'),
        severity: FluentInfoSeverity.info,
      );
    }
    if (_errorMessage != null) {
      return FluentInfoBar(
        title: const Text('校历同步存在问题'),
        content: Text(_errorMessage!),
        severity: _entries.isEmpty
            ? FluentInfoSeverity.error
            : FluentInfoSeverity.warning,
      );
    }
    return FluentInfoBar(
      title: const Text('校历已就绪'),
      content: Text('已缓存 ${_entries.length} 个 2021 年以后的校历条目。'),
      severity: FluentInfoSeverity.success,
    );
  }

  Widget _buildCalendarList() {
    if (_entries.isEmpty) {
      return const FluentSurface(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text('暂无校历缓存。'),
      );
    }
    return FluentSurface(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in _entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: FluentSurface(
                subtle: _selected?.schoolYearStart != entry.schoolYearStart,
                elevated: false,
                semanticLabel: '打开${entry.schoolYearLabel}',
                onPressed: () => setState(() => _selected = entry),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      entry.hasStructuredSchedule
                          ? FluentIcons.checkMark
                          : FluentIcons.warning,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.schoolYearLabel),
                          Text(
                            entry.publishDate.isEmpty
                                ? entry.sourceType.label
                                : '${entry.publishDate} · ${entry.sourceType.label}',
                            style: context.fluentType.caption1.copyWith(
                              color: context.fluentColors.neutralForeground2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarDetail(AcademicCalendarCacheEntry entry) {
    final schedule = entry.schedule;
    return FluentSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalendarDetailHeader(entry: entry),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              FluentButton.primaryIcon(
                onPressed: entry.pdfUrl == null && entry.pdfFilePath == null
                    ? null
                    : () => _openPdf(entry),
                icon: const Icon(FluentIcons.documentText),
                label: const Text('查看原始 PDF'),
              ),
              FluentButton.outlineIcon(
                onPressed: entry.errorMessage == null
                    ? null
                    : () => _showParseFailureDialog(entry.errorMessage!),
                icon: const Icon(FluentIcons.searchIssue),
                label: const Text('反馈解析问题'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (entry.errorMessage != null)
            FluentInfoBar(
              title: const Text('结构化解析不可用'),
              content: Text(entry.errorMessage!),
              severity: FluentInfoSeverity.warning,
            ),
          if (schedule != null) ...[
            _buildTermRows(schedule),
            const SizedBox(height: AppSpacing.md),
            _buildSpecialDays(schedule),
            const SizedBox(height: AppSpacing.md),
            _buildPendingNotices(schedule),
          ],
          if (entry.imageUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('图片资源', style: context.fluentType.body1Strong),
            const SizedBox(height: AppSpacing.xs),
            for (final (index, imageUrl) in entry.imageUrls.indexed)
              FluentButton.transparentIcon(
                onPressed: () => _openExternalUrl(imageUrl),
                icon: const Icon(FluentIcons.openInNewWindow, size: 14),
                label: Text('查看图片 ${index + 1}'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTermRows(AcademicCalendarTermSchedule schedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('学期范围', style: context.fluentType.body1Strong),
        const SizedBox(height: AppSpacing.sm),
        _TermRangeRow(
          label: '秋季学期',
          value:
              '${_formatDate(schedule.fallStart)} 至 ${_formatDate(schedule.fallEnd)}',
        ),
        _TermRangeRow(
          label: '春季学期',
          value:
              '${_formatDate(schedule.springStart)} 至 ${_formatDate(schedule.springEnd)}',
        ),
        for (final segment in schedule.summerSegments)
          _TermRangeRow(
            label: '夏季第 ${segment.startWeek}-${segment.endWeek} 周',
            value:
                '${_formatDate(segment.startDate)} 至 ${_formatDate(segment.endDate)}',
          ),
      ],
    );
  }

  Widget _buildSpecialDays(AcademicCalendarTermSchedule schedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('特殊日期', style: context.fluentType.body1Strong),
        const SizedBox(height: AppSpacing.sm),
        if (schedule.dayTags.isEmpty)
          const Text('暂无明确日期标签。')
        else
          for (final tag in schedule.dayTags)
            _TermRangeRow(
              label: tag.type.label,
              value: '${_formatDate(tag.date)} · ${tag.label}',
            ),
      ],
    );
  }

  Widget _buildPendingNotices(AcademicCalendarTermSchedule schedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('未补全说明', style: context.fluentType.body1Strong),
        const SizedBox(height: AppSpacing.sm),
        if (schedule.pendingHolidayNotices.isEmpty)
          const Text('无另行通知类节假日说明。')
        else
          for (final notice in schedule.pendingHolidayNotices)
            Text(notice.sourceText),
      ],
    );
  }
}

Future<void> _openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _TermRangeRow extends StatelessWidget {
  const _TermRangeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final valueStyle = context.fluentType.caption1.copyWith(
      color: context.fluentColors.neutralForeground2,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: valueStyle, softWrap: true),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 112, child: Text(label)),
              Expanded(child: Text(value, style: valueStyle, softWrap: true)),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarDetailHeader extends StatelessWidget {
  const _CalendarDetailHeader({required this.entry});

  final AcademicCalendarCacheEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FluentSurfaceIcon(icon: FluentIcons.calendar),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  entry.title,
                  style: context.fluentType.subtitle2.copyWith(
                    color: context.fluentColors.neutralForeground1,
                  ),
                  softWrap: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                entry.detailUrl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.fluentType.caption1.copyWith(
                  color: context.fluentColors.neutralForeground3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  return date.toIso8601String().split('T').first;
}
