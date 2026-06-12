/*
 * 设置页学期分区组件 — 全局学期与周数设置入口
 * @Project : SSPU-AllinOne
 * @File : settings_academic_term_section.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import '../design/fluent_ui.dart';
import '../models/academic_term.dart';
import '../services/academic_term_service.dart';
import '../theme/app_spacing.dart';
import '../theme/fluent_tokens.dart';
import 'academic_term_selector.dart';

/// 设置页学期分区。
class SettingsAcademicTermSection extends StatefulWidget {
  SettingsAcademicTermSection({
    super.key,
    AcademicTermService? service,
    this.now,
    this.onOpenAcademicCalendar,
  }) : service = service ?? AcademicTermService.instance;

  /// 全局学期服务。
  final AcademicTermService service;

  /// 测试专用：覆盖当前日期。
  final DateTime? now;

  /// 打开校历页面。
  final VoidCallback? onOpenAcademicCalendar;

  @override
  State<SettingsAcademicTermSection> createState() =>
      _SettingsAcademicTermSectionState();
}

class _SettingsAcademicTermSectionState
    extends State<SettingsAcademicTermSection> {
  AcademicTermSettings? _settings;
  AcademicTermContext? _context;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTermSettings();
  }

  Future<void> _loadTermSettings() async {
    final settings = await widget.service.loadSettings();
    final context = await widget.service.getEffectiveContext(now: widget.now);
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _context = context;
      _isLoading = false;
    });
  }

  Future<void> _setSelectedTerm(AcademicTermChoice selection) async {
    await widget.service.setSelectedTerm(selection);
    await _loadTermSettings();
  }

  @override
  Widget build(BuildContext context) {
    final type = context.fluentType;
    final colors = context.fluentColors;

    if (_isLoading || _settings == null) {
      return const FluentCard(child: Center(child: FluentProgressRing()));
    }

    final contextSummary = _context;
    final selectedTerm =
        _settings!.selectedTerm ??
        contextSummary?.term ??
        AcademicTermService.defaultTerm;

    return FluentCard(
      key: const Key('settings-academic-term-section'),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackHeader =
                constraints.maxWidth < FluentBreakpoints.compact;
            final headerText = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text('学期设置', style: type.subtitle1),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '当前全局学期会作为课表、成绩、考试等详情页的统一默认上下文；周数由内置校历按周一自动计算。',
                  style: type.caption1.copyWith(
                    color: colors.neutralForeground2,
                  ),
                ),
              ],
            );
            final calendarButton = FluentButton.outlineIcon(
              key: const Key('settings-academic-term-calendar-button'),
              onPressed: widget.onOpenAcademicCalendar,
              icon: const Icon(FluentIcons.calendarWeek, size: 14),
              label: const Text('查看校历'),
              expand: stackHeader,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stackHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headerText,
                      const SizedBox(height: AppSpacing.sm),
                      calendarButton,
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: headerText),
                      const SizedBox(width: AppSpacing.md),
                      calendarButton,
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                AcademicTermSelector(
                  selection: selectedTerm,
                  availableTerms: widget.service.availableTerms,
                  contextSummary: contextSummary,
                  onChanged: _setSelectedTerm,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
