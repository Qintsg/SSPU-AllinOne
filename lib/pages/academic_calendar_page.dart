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

part 'academic_calendar_page_layout.dart';
part 'academic_calendar_page_panels.dart';
part 'academic_calendar_page_evidence.dart';
part 'academic_calendar_page_selector.dart';
part 'academic_calendar_page_viewer.dart';

/// 校历正文查看器 seam；平台集成使用 PDF 实现，视觉测试可注入确定性 adapter。
typedef AcademicCalendarViewerBuilder = Widget Function(
  BuildContext context,
  AcademicCalendarCacheEntry? entry,
);

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

  /// 选择校历时只替换当前查看上下文，不访问远端来源。
  ///
  /// :param entry: 用户选择的校历缓存条目。
  /// :returns: 无返回值。
  void _selectCalendarEntry(AcademicCalendarCacheEntry entry) {
    setState(() => _selected = entry);
  }

  /// 重新读取学期上下文，并保留当前校历与查询选择。
  ///
  /// :returns: 无返回值。
  void _retryTermContext() {
    setState(() => _isTermLoading = true);
    unawaited(_loadTermContext(_generation));
  }

  @override
  Widget build(BuildContext context) => _buildCalendarPage(context);
}
