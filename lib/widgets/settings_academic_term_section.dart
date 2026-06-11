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
import 'academic_term_selector.dart';

/// 设置页学期分区。
class SettingsAcademicTermSection extends StatefulWidget {
  SettingsAcademicTermSection({
    super.key,
    AcademicTermService? service,
    this.now,
  }) : service = service ?? AcademicTermService.instance;

  /// 全局学期服务。
  final AcademicTermService service;

  /// 测试专用：覆盖当前日期。
  final DateTime? now;

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
    final stateMessage = _statusMessage(contextSummary);
    final selectedTerm =
        _settings!.selectedTerm ??
        contextSummary?.term ??
        AcademicTermService.defaultTerm;

    return Column(
      key: const Key('settings-academic-term-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluentCard(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
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
                const SizedBox(height: AppSpacing.md),
                AcademicTermSelector(
                  selection: selectedTerm,
                  availableTerms: widget.service.availableTerms,
                  contextSummary: contextSummary,
                  onChanged: _setSelectedTerm,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FluentInfoBar(
          title: Text(_statusTitle(contextSummary)),
          content: Text(stateMessage),
          severity: _statusSeverity(contextSummary),
        ),
        const SizedBox(height: AppSpacing.lg),
        FluentCard(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('规则说明', style: type.body1Strong),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '秋季学期和春季学期各 17 周，其中第 17 周为考试周；夏季学期按官网校历视为一个长学期，教学周段逐年内置，可能是 2+3 或 3+2，中间区间显示为暑假。2023 年以前学期仅保留选择项，暂不提供日期定位。',
                  style: type.caption1.copyWith(
                    color: colors.neutralForeground2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _statusTitle(AcademicTermContext? context) {
    if (context?.hasDifferentQueryTerm == true) {
      return '已定位当前日期所在学期';
    }
    return switch (context?.dateStatus) {
      AcademicTermDateStatus.teaching => '已定位当前教学周',
      AcademicTermDateStatus.summerVacation => '当前处于暑假',
      AcademicTermDateStatus.winterVacation => '当前处于寒假',
      AcademicTermDateStatus.unsupported => '该学期暂无日期定位',
      null => '学期设置已加载',
    };
  }

  String _statusMessage(AcademicTermContext? context) {
    final message = context?.message ?? '当前全局学期已加载。';
    if (context?.hasDifferentQueryTerm != true) return message;
    return '$message\n当前显示：${context!.summaryLabel}\n查询使用：${context.effectiveQueryTerm.label}';
  }

  FluentInfoSeverity _statusSeverity(AcademicTermContext? context) {
    return switch (context?.dateStatus) {
      AcademicTermDateStatus.teaching => FluentInfoSeverity.success,
      AcademicTermDateStatus.summerVacation => FluentInfoSeverity.info,
      AcademicTermDateStatus.winterVacation => FluentInfoSeverity.info,
      AcademicTermDateStatus.unsupported => FluentInfoSeverity.warning,
      null => FluentInfoSeverity.info,
    };
  }
}
