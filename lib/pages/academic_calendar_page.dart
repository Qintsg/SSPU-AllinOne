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

import '../design/qingyuan/qingyuan_ui.dart';
import '../models/academic_calendar.dart';
import '../models/academic_term.dart';
import '../services/academic_calendar_service.dart';
import '../services/academic_term_service.dart';
import '../widgets/academic_term_selector.dart';
import '../widgets/empty_state_view.dart';
import 'academic_calendar_pdf_file.dart';
import 'academic_calendar_pdf_page.dart';

/// 校历正文查看器 seam；平台集成使用 PDF 实现，视觉测试可注入确定性 adapter。
typedef AcademicCalendarViewerBuilder =
    Widget Function(BuildContext context, AcademicCalendarCacheEntry? entry);

String _yearLabel(AcademicCalendarCacheEntry entry) =>
    '${entry.schoolYearStart}–${entry.schoolYearStart + 1} 学年';

/// 校历页面。
class AcademicCalendarPage extends StatefulWidget {
  AcademicCalendarPage({
    super.key,
    AcademicCalendarClient? service,
    AcademicTermService? termService,
    this.now,
    this.viewerBuilder,
    this.launchExternalOverride,
  }) : service = service ?? AcademicCalendarService.instance,
       termService =
           termService ??
           AcademicTermService(
             calendarService: service ?? AcademicCalendarService.instance,
           );

  /// 校历服务。
  final AcademicCalendarClient service;

  /// 全局查询学期服务；与校历档案共享同一业务来源，但不建立第二份设置状态。
  final AcademicTermService termService;

  /// 测试与视觉基线使用的固定时钟。
  final DateTime? now;

  /// 可替换的 PDF 查看器 adapter；为空时使用生产 pdfrx 实现。
  final AcademicCalendarViewerBuilder? viewerBuilder;

  /// 系统外部应用启动 seam；测试可注入确定性 adapter。
  final Future<bool> Function(Uri uri)? launchExternalOverride;

  @override
  State<AcademicCalendarPage> createState() => _AcademicCalendarPageState();
}

class _AcademicCalendarPageState extends State<AcademicCalendarPage> {
  List<AcademicCalendarCacheEntry> _entries = const [];
  AcademicCalendarCacheEntry? _selected;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isConfirmingExternal = false;
  bool _isOpeningExternal = false;
  bool _isUpdatingTerm = false;
  bool _isTermLoading = true;
  String? _errorMessage;
  String? _externalError;
  String? _termError;
  AcademicTermContext? _termContext;
  int _generation = 0;

  bool get _remoteOperationLocked =>
      _isLoading ||
      _isRefreshing ||
      _isConfirmingExternal ||
      _isOpeningExternal ||
      _isUpdatingTerm;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCalendars(_generation));
  }

  @override
  void didUpdateWidget(covariant AcademicCalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.service, widget.service) &&
        identical(oldWidget.termService, widget.termService) &&
        oldWidget.now == widget.now) {
      return;
    }
    _generation++;
    setState(() {
      _entries = const [];
      _selected = null;
      _isLoading = true;
      _isRefreshing = false;
      _isConfirmingExternal = false;
      _isOpeningExternal = false;
      _isUpdatingTerm = false;
      _isTermLoading = true;
      _errorMessage = null;
      _externalError = null;
      _termError = null;
      _termContext = null;
    });
    unawaited(_loadCalendars(_generation));
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  /// 读取缓存，并在首次进入或超过一个月时自动刷新。
  Future<void> _loadCalendars(int generation) async {
    final service = widget.service;
    try {
      final cached = await service.readCachedCalendars();
      if (!_isCurrent(generation)) return;
      if (cached.isNotEmpty) {
        setState(() {
          _entries = cached;
          _selected = _selectPreferred(cached, _selected);
        });
      }
    } on Object {
      if (!_isCurrent(generation)) return;
    }

    try {
      final result = await service.ensureCalendarsForViewer();
      if (!_isCurrent(generation)) return;
      final preserveCached =
          result.errorMessage != null &&
          result.entries.isEmpty &&
          _entries.isNotEmpty;
      setState(() {
        if (!preserveCached) {
          _entries = result.entries;
          _selected = _selectPreferred(result.entries, _selected);
        }
        _errorMessage = result.errorMessage;
        _isLoading = false;
      });
    } on Object {
      if (!_isCurrent(generation)) return;
      setState(() {
        _errorMessage = _entries.isEmpty
            ? '暂时无法读取公开校历，请检查网络后重试。'
            : '公开校历刷新未完成；当前有效内容已保留，可稍后重试。';
        _isLoading = false;
      });
    } finally {
      if (_isCurrent(generation)) {
        unawaited(_loadTermContext(generation));
      }
    }
  }

  Future<void> _loadTermContext(int generation) async {
    final service = widget.termService;
    try {
      await service.loadSettings();
      final termContext = await service.getEffectiveContext(now: widget.now);
      if (!_isCurrent(generation)) return;
      setState(() {
        _termContext = termContext;
        _termError = null;
        _isTermLoading = false;
      });
    } on Object {
      if (!_isCurrent(generation)) return;
      setState(() {
        _termError = '学期设置暂时无法读取；校历档案仍可使用，可在原位置重试。';
        _isTermLoading = false;
      });
    }
  }

  Future<void> _setQueryTerm(AcademicTermChoice term) async {
    if (_remoteOperationLocked) return;
    final generation = _generation;
    final previous = _termContext;
    setState(() {
      _isUpdatingTerm = true;
      _termError = null;
    });
    try {
      await widget.termService.setSelectedTerm(term);
      final termContext = await widget.termService.getEffectiveContext(
        now: widget.now,
      );
      if (!_isCurrent(generation)) return;
      setState(() => _termContext = termContext);
    } on Object {
      if (!_isCurrent(generation)) return;
      setState(() {
        _termContext = previous;
        _termError = '查询学期未能保存；原有选择已保留，可在原位置重试。';
      });
    } finally {
      if (_isCurrent(generation)) setState(() => _isUpdatingTerm = false);
    }
  }

  bool _isCurrent(int generation) => mounted && generation == _generation;

  /// 手动刷新全部校历。
  Future<void> _refreshAll() async {
    if (_remoteOperationLocked) return;
    final generation = _generation;
    final service = widget.service;
    setState(() {
      _isRefreshing = true;
      _externalError = null;
    });
    try {
      final entries = await service.refreshCalendars();
      if (!_isCurrent(generation)) return;
      setState(() {
        _entries = entries;
        _selected = _selectPreferred(entries, _selected);
        _errorMessage = null;
      });
    } on Object {
      if (!_isCurrent(generation)) return;
      setState(() {
        _errorMessage = _entries.isEmpty
            ? '暂时无法刷新公开校历，请检查网络后重试。'
            : '公开校历刷新未完成；当前有效内容已保留，可在原位置重试。';
      });
    } finally {
      if (_isCurrent(generation)) {
        setState(() {
          _isRefreshing = false;
          _isTermLoading = true;
        });
        unawaited(_loadTermContext(generation));
      }
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
    if (_remoteOperationLocked) return;
    final target = entry.pdfUrl?.isNotEmpty == true
        ? entry.pdfUrl!
        : entry.detailUrl;
    if (target.isEmpty) {
      setState(() => _externalError = '当前校历没有可外部打开的 PDF 或详情地址。');
      return;
    }
    final uri = Uri.tryParse(target);
    if (uri == null) {
      setState(() => _externalError = '当前校历的外部地址无法识别；所选学年和返回路径已保留。');
      return;
    }
    final generation = _generation;
    final schoolYear = entry.schoolYearStart;
    setState(() => _isConfirmingExternal = true);
    bool confirmed;
    try {
      confirmed = await confirmAcademicCalendarPdfExternalOpen(context, uri);
    } on Object {
      if (_isCurrent(generation)) {
        setState(() {
          _isConfirmingExternal = false;
          _externalError = '暂时无法显示外部打开确认；所选学年和返回路径已保留，可重试。';
        });
      }
      return;
    }
    if (!_isCurrent(generation)) return;
    if (!confirmed || _selected?.schoolYearStart != schoolYear) {
      setState(() => _isConfirmingExternal = false);
      return;
    }
    setState(() {
      _isConfirmingExternal = false;
      _isOpeningExternal = true;
      _externalError = null;
    });
    try {
      final opened = widget.launchExternalOverride != null
          ? await widget.launchExternalOverride!(uri)
          : await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (_isCurrent(generation) &&
          _selected?.schoolYearStart == schoolYear &&
          !opened) {
        setState(() {
          _externalError = '系统未能打开教务处校历 PDF；仍停留在当前学年，可检查默认 PDF 应用后重试。';
        });
      }
    } on Object {
      if (_isCurrent(generation) && _selected?.schoolYearStart == schoolYear) {
        setState(() {
          _externalError = '系统未能打开教务处校历 PDF；仍停留在当前学年，可检查默认 PDF 应用后重试。';
        });
      }
    } finally {
      if (_isCurrent(generation)) setState(() => _isOpeningExternal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final theme = context.yhTheme;
    return YhPageScaffold(
      appBar: YhAppBar(
        title: '校历',
        horizontalPadding: theme.spacing.s,
        actionSpacing: theme.spacing.s,
        leading: YhIconButton(
          icon: YhIcons.back,
          semanticLabel: '返回',
          variant: YhIconButtonVariant.ghost,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          YhIconButton(
            icon: YhIcons.refresh,
            semanticLabel: _isRefreshing ? '正在刷新校历' : '刷新校历',
            onTap: _remoteOperationLocked ? null : _refreshAll,
          ),
          YhIconButton(
            icon: YhIcons.open,
            semanticLabel: '外部打开校历 PDF',
            onTap: selected == null || _remoteOperationLocked
                ? null
                : () => _openExternal(selected),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: theme.layout.pageContentWidth,
            ),
            child: SizedBox.expand(
              child: Padding(
                padding:
                    MediaQuery.sizeOf(context).width < theme.breakpoint.medium
                    ? EdgeInsets.symmetric(
                        horizontal: theme.spacing.m,
                        vertical: theme.spacing.s,
                      )
                    : EdgeInsets.all(theme.spacing.m),
                child: _buildBody(selected),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AcademicCalendarCacheEntry? selected) {
    if (_isLoading && _entries.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.yhTheme.spacing.xl2 * 4,
          ),
          child: const YhProgressBar(value: 0.5, semanticLabel: '正在加载校历'),
        ),
      );
    }
    if (_entries.isEmpty) {
      final failed = _errorMessage != null;
      return YhEmptyState(
        icon: failed ? YhIcons.warning : YhIcons.calendar,
        title: failed ? '暂时无法读取公开校历' : '尚未找到可查看的校历',
        message: failed
            ? '本机没有有效档案，教务处公开页面也未完成读取；可在这里重试。'
            : '读取已完成，但 2021 年以后没有可用 PDF；可刷新公开来源。',
        action: YhButton(
          label: failed ? '重新读取公开校历' : '刷新公开校历',
          onTap: _isRefreshing ? null : _refreshAll,
          variant: YhButtonVariant.secondary,
        ),
      );
    }

    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoading && _entries.isNotEmpty) ...[
          const YhBanner(text: '正在检查公开校历更新；当前学年和 PDF 已从本机恢复，完成前已锁定其它远端操作。'),
          SizedBox(height: theme.spacing.s),
        ] else if (_isRefreshing || _isOpeningExternal) ...[
          _calendarStatusBanner(
            YhBanner(
              text: _isRefreshing
                  ? '正在刷新公开校历；当前学年、PDF 和返回路径保持可用，完成前已锁定其它远端操作。'
                  : '正在交给外部应用；完成前已锁定重复操作，当前学年、PDF 和返回路径保持可用。',
              denseLeading: true,
            ),
          ),
          SizedBox(height: theme.spacing.s),
        ] else if (_externalError != null) ...[
          _calendarStatusBanner(
            YhBanner(
              text: _externalError!,
              kind: YhBannerKind.danger,
              leadingIcon: YhIcons.info,
              denseLeading: true,
            ),
          ),
          SizedBox(height: theme.spacing.s),
        ],
        if (_errorMessage != null) ...[
          _calendarStatusBanner(
            YhBanner(
              text: _errorMessage!,
              kind: selected?.isStale == true
                  ? YhBannerKind.warn
                  : YhBannerKind.danger,
              leadingIcon: YhIcons.info,
              denseLeading: true,
            ),
          ),
          SizedBox(height: theme.spacing.s),
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CalendarSelector(
                      entries: _entries,
                      selected: selected,
                      compact: true,
                      enabled: !_remoteOperationLocked,
                      onSelected: (entry) => setState(() => _selected = entry),
                    ),
                    SizedBox(height: theme.spacing.s),
                    _CalendarTermCard(
                      contextSummary: _termContext,
                      selection:
                          _termContext?.effectiveQueryTerm ??
                          widget.termService.settings.selectedTerm ??
                          AcademicTermService.defaultTerm,
                      availableTerms: widget.termService.availableTerms,
                      loading: _isTermLoading || _isUpdatingTerm,
                      error: _termError,
                      enabled: !_remoteOperationLocked,
                      onChanged: _setQueryTerm,
                      onRetry: () {
                        setState(() => _isTermLoading = true);
                        unawaited(_loadTermContext(_generation));
                      },
                    ),
                    SizedBox(height: theme.spacing.s),
                    _CalendarEvidence(entry: selected, compact: true),
                    SizedBox(height: theme.spacing.s),
                    Expanded(child: _buildViewer(selected)),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: theme.spacing.xl2 * 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CalendarSourceCard(entry: selected),
                        SizedBox(height: theme.spacing.s),
                        _CalendarTermCard(
                          contextSummary: _termContext,
                          selection:
                              _termContext?.effectiveQueryTerm ??
                              widget.termService.settings.selectedTerm ??
                              AcademicTermService.defaultTerm,
                          availableTerms: widget.termService.availableTerms,
                          loading: _isTermLoading || _isUpdatingTerm,
                          error: _termError,
                          enabled: !_remoteOperationLocked,
                          onChanged: _setQueryTerm,
                          onRetry: () {
                            setState(() => _isTermLoading = true);
                            unawaited(_loadTermContext(_generation));
                          },
                        ),
                        SizedBox(height: theme.spacing.s),
                        _CalendarSelector(
                          entries: _entries,
                          selected: selected,
                          compact: false,
                          enabled: !_remoteOperationLocked,
                          onSelected: (entry) =>
                              setState(() => _selected = entry),
                        ),
                        SizedBox(height: theme.spacing.s),
                        Expanded(
                          child: _CalendarEvidence(
                            entry: selected,
                            compact: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: theme.spacing.m),
                  Expanded(child: _buildViewer(selected)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewer(AcademicCalendarCacheEntry? selected) {
    final document =
        widget.viewerBuilder?.call(context, selected) ??
        _CalendarPdfViewer(
          entry: selected,
          onOpenExternal: selected == null || _remoteOperationLocked
              ? null
              : () => _openExternal(selected),
        );
    return _CalendarDocumentPanel(
      entry: selected,
      onFocus: selected == null || _remoteOperationLocked
          ? null
          : () => Navigator.of(context).push(
              YhPageRoute<void>(
                builder: (_) => AcademicCalendarPdfPage(
                  title: selected.title,
                  pdfFilePath: selected.pdfFilePath,
                  pdfUrl: selected.pdfUrl,
                ),
              ),
            ),
      child: document,
    );
  }

  Widget _calendarStatusBanner(Widget banner) {
    final theme = context.yhTheme;
    if (MediaQuery.sizeOf(context).width >= theme.breakpoint.medium) {
      return banner;
    }
    return SizedBox(
      height: theme.control.touch + theme.spacing.s + theme.spacing.xs,
      child: ClipRect(child: banner),
    );
  }
}

class _CalendarSourceCard extends StatelessWidget {
  const _CalendarSourceCard({required this.entry});

  final AcademicCalendarCacheEntry? entry;

  String _updatedAt(DateTime? value) {
    if (value == null) return '等待本机档案时间';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute 更新';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Container(
      constraints: BoxConstraints(
        minHeight: theme.control.touch + theme.spacing.xs,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.s,
      ),
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: Border.all(color: theme.color.border),
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Row(
        children: [
          Container(
            width: theme.spacing.s,
            height: theme.spacing.s,
            decoration: BoxDecoration(
              color: theme.color.serviceAcademic,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: theme.spacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '教务处公开校历',
                  style: theme.typography.small.copyWith(
                    color: theme.color.foreground,
                    fontWeight: theme.typography.semibold,
                  ),
                ),
                Text(
                  '无需登录 · ${_updatedAt(entry?.fetchedAt)}',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
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

class _CalendarTermCard extends StatelessWidget {
  const _CalendarTermCard({
    required this.contextSummary,
    required this.selection,
    required this.availableTerms,
    required this.loading,
    required this.error,
    required this.enabled,
    required this.onChanged,
    required this.onRetry,
  });

  final AcademicTermContext? contextSummary;
  final AcademicTermChoice selection;
  final List<AcademicTermChoice> availableTerms;
  final bool loading;
  final String? error;
  final bool enabled;
  final ValueChanged<AcademicTermChoice> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    return Container(
      key: const Key('academic-calendar-term-context'),
      padding: EdgeInsets.all(compact ? theme.spacing.s : theme.spacing.m),
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: Border.all(color: theme.color.border),
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '统一查询学期',
            style: theme.typography.caption.copyWith(
              color: theme.color.brandStrong,
              fontWeight: theme.typography.semibold,
            ),
          ),
          SizedBox(height: compact ? theme.spacing.xs : theme.spacing.s),
          if (loading && contextSummary == null)
            const YhProgressBar(value: 0.5, semanticLabel: '正在读取当前学期与查询学期')
          else if (error != null && contextSummary == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error!,
                  style: theme.typography.small.copyWith(
                    color: theme.color.danger,
                  ),
                ),
                SizedBox(height: theme.spacing.s),
                YhButton(
                  label: '重试学期设置',
                  variant: YhButtonVariant.secondary,
                  onTap: enabled ? onRetry : null,
                ),
              ],
            )
          else ...[
            AcademicTermSelector(
              selection: selection,
              availableTerms: availableTerms,
              contextSummary: contextSummary,
              enabled: enabled && !loading,
              variant: AcademicTermSelectorVariant.compact,
              onChanged: onChanged,
            ),
            if (error != null) ...[
              SizedBox(height: theme.spacing.s),
              Text(
                error!,
                style: theme.typography.small.copyWith(
                  color: theme.color.danger,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CalendarDocumentPanel extends StatelessWidget {
  const _CalendarDocumentPanel({
    required this.entry,
    required this.onFocus,
    required this.child,
  });

  final AcademicCalendarCacheEntry? entry;
  final VoidCallback? onFocus;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.radius.l),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.color.surface,
          border: Border.all(color: theme.color.border),
          borderRadius: BorderRadius.circular(theme.radius.l),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              constraints: BoxConstraints(minHeight: theme.control.touch),
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.m,
                vertical: theme.spacing.s,
              ),
              decoration: BoxDecoration(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '原始证据',
                          style: theme.typography.caption.copyWith(
                            color: theme.color.serviceAcademic,
                          ),
                        ),
                        Text(
                          entry == null
                              ? '请选择学年'
                              : '${_yearLabel(entry!)}校历 PDF',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body.copyWith(
                            color: theme.color.foreground,
                            fontWeight: theme.typography.semibold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  YhButton(
                    label: '专注查看',
                    variant: YhButtonVariant.secondary,
                    minWidth:
                        MediaQuery.sizeOf(context).width <
                            theme.breakpoint.medium
                        ? theme.control.minimumTarget +
                              theme.spacing.l +
                              theme.spacing.xs
                        : null,
                    onTap: onFocus,
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _CalendarEvidence extends StatelessWidget {
  const _CalendarEvidence({required this.entry, required this.compact});

  final AcademicCalendarCacheEntry? entry;
  final bool compact;

  String _dateRange(DateTime start, DateTime end) {
    String part(DateTime value) =>
        '${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
    return '${part(start)}—${part(end)}';
  }

  int _teachingWeeks(AcademicCalendarTermSchedule schedule) => schedule
      .summerSegments
      .fold(0, (sum, segment) => sum + segment.endWeek - segment.startWeek + 1);

  @override
  Widget build(BuildContext context) {
    final schedule = entry?.schedule;
    if (schedule == null) return const SizedBox.shrink();
    final theme = context.yhTheme;
    final fall = _dateRange(schedule.fallStart, schedule.fallEnd);
    final spring = _dateRange(schedule.springStart, schedule.springEnd);
    final summer = '${_teachingWeeks(schedule)} 个教学周';
    final notices = <String>[
      ...schedule.dayTags.map((tag) => tag.sourceText),
      ...schedule.pendingHolidayNotices.map((notice) => notice.sourceText),
    ];
    if (compact) {
      return Semantics(
        label: '学期边界：秋季 $fall，春季 $spring，夏季 $summer。${notices.join('；')}',
        child: Container(
          constraints: BoxConstraints(minHeight: theme.control.touch),
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.m,
            vertical: theme.spacing.s,
          ),
          decoration: BoxDecoration(
            color: theme.color.sunken,
            border: Border.all(color: theme.color.border),
            borderRadius: BorderRadius.circular(theme.radius.m),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_yearLabel(entry!)} · 秋季 $fall · 春季 $spring · 夏季 $summer',
                style: theme.typography.small.copyWith(
                  color: theme.color.foreground,
                  fontWeight: theme.typography.semibold,
                ),
              ),
              if (notices.isNotEmpty) ...[
                SizedBox(height: theme.spacing.xs),
                Text(
                  notices.join('；'),
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.only(
        left: theme.spacing.m,
        top: theme.spacing.l,
        right: theme.spacing.m,
        bottom: theme.spacing.m,
      ),
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: Border.all(color: theme.color.border),
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '学期边界',
            style: theme.typography.caption.copyWith(
              color: theme.color.brandStrong,
              fontWeight: theme.typography.semibold,
            ),
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            _yearLabel(entry!),
            style: theme.typography.h3.copyWith(
              color: theme.color.foreground,
              fontWeight: theme.typography.semibold,
            ),
          ),
          SizedBox(height: theme.spacing.m),
          _CalendarEvidenceRow(label: '秋季', value: fall),
          _CalendarEvidenceRow(label: '春季', value: spring),
          _CalendarEvidenceRow(label: '夏季', value: summer),
          if (notices.isNotEmpty) ...[
            SizedBox(height: theme.spacing.s),
            Container(height: theme.layout.divider, color: theme.color.border),
            SizedBox(height: theme.spacing.s),
            for (final notice in notices)
              Padding(
                padding: EdgeInsets.only(bottom: theme.spacing.xs),
                child: Text(
                  notice,
                  style: theme.typography.small.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CalendarEvidenceRow extends StatelessWidget {
  const _CalendarEvidenceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: theme.spacing.xl,
            child: Text(
              label,
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.typography.body.copyWith(
                color: theme.color.foreground,
                fontWeight: theme.typography.semibold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarSelector extends StatelessWidget {
  const _CalendarSelector({
    required this.entries,
    required this.selected,
    required this.compact,
    required this.enabled,
    required this.onSelected,
  });

  /// 校历条目。
  final List<AcademicCalendarCacheEntry> entries;

  /// 当前选中条目。
  final AcademicCalendarCacheEntry? selected;

  /// 是否为紧凑横向选择器。
  final bool compact;

  /// 远端操作期间冻结学年切换，避免目标与结果错配。
  final bool enabled;

  /// 选择条目回调。
  final ValueChanged<AcademicCalendarCacheEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (compact) {
      return SizedBox(
        height: theme.control.regular + theme.spacing.m,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: entries.length,
          separatorBuilder: (_, _) => SizedBox(width: theme.spacing.xs),
          itemBuilder: (context, index) => SizedBox(
            width: theme.spacing.xl2 * 4,
            child: _CalendarSelectorItem(
              entry: entries[index],
              selected:
                  selected?.schoolYearStart == entries[index].schoolYearStart,
              onPressed: enabled ? () => onSelected(entries[index]) : null,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, _) => SizedBox(height: theme.spacing.xs),
      itemBuilder: (context, index) => _CalendarSelectorItem(
        entry: entries[index],
        selected: selected?.schoolYearStart == entries[index].schoolYearStart,
        onPressed: enabled ? () => onSelected(entries[index]) : null,
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
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final disabled = onPressed == null;
    return YhPressable(
      semanticLabel: '打开${_yearLabel(entry)}',
      onPressed: onPressed,
      builder: (context, state, child) => AnimatedContainer(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: theme.control.touch + theme.spacing.m,
        ),
        duration: theme.motion.effective(
          theme.motion.fast,
          disableAnimations:
              MediaQuery.maybeOf(context)?.disableAnimations ?? false,
        ),
        curve: theme.motion.curve,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: theme.spacing.s,
        ),
        decoration: BoxDecoration(
          color: selected
              ? disabled
                    ? Color.alphaBlend(
                        theme.color.serviceAcademic.withValues(
                          alpha:
                              theme.opacity.evidenceTint *
                              theme.opacity.disabled,
                        ),
                        theme.color.surface,
                      )
                    : Color.alphaBlend(
                        theme.color.serviceAcademic.withValues(
                          alpha: theme.opacity.evidenceTint,
                        ),
                        theme.color.surface,
                      )
              : state.hovered
              ? theme.color.sunken
              : theme.color.surface,
          border: Border.all(
            color: selected
                ? disabled
                      ? theme.color.serviceAcademic.withValues(
                          alpha: theme.opacity.disabled,
                        )
                      : theme.color.serviceAcademic
                : theme.color.border,
          ),
          borderRadius: BorderRadius.circular(theme.radius.s),
        ),
        child: Opacity(
          opacity: disabled ? theme.opacity.disabled : 1,
          child: child,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _yearLabel(entry),
            overflow: TextOverflow.ellipsis,
            style: theme.typography.body.copyWith(
              color: selected
                  ? theme.color.serviceAcademic
                  : theme.color.foreground,
              fontWeight: theme.typography.semibold,
            ),
          ),
          Text(
            entry.publishDate.isEmpty ? 'PDF' : entry.publishDate,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
        ],
      ),
    );
  }
}

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
