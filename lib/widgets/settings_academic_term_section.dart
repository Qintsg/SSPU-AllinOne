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

  Future<void> _setAutoSwitchEnabled(bool enabled) async {
    await widget.service.setAutoSwitchEnabled(enabled);
    await _loadTermSettings();
  }

  Future<void> _setManualSelection(AcademicTermSelection selection) async {
    await widget.service.setManualSelection(selection);
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
    final stateMessage = contextSummary?.message ?? '当前学期设置已加载。';

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
                  '当前学年、学期和周数会作为课表、成绩、考试等详情页的统一默认上下文。',
                  style: type.caption1.copyWith(
                    color: colors.neutralForeground2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AcademicTermSelector(
                  selection: _settings!.manualSelection,
                  contextSummary: contextSummary,
                  autoSwitchEnabled: _settings!.autoSwitchEnabled,
                  onAutoSwitchChanged: _setAutoSwitchEnabled,
                  onChanged: _setManualSelection,
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
                  '秋季学期和春季学期各 17 周，其中第 17 周为考试周；夏季学期共 5 周，允许按校历拆分为春季结束后的前 2 周和秋季开学前的后 3 周。',
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
    return switch (context?.source) {
      AcademicTermContextSource.automatic => '已自动计算当前学期',
      AcademicTermContextSource.unresolved => '当前日期未命中内置校历',
      AcademicTermContextSource.manual => '当前使用手动学期设置',
      null => '学期设置已加载',
    };
  }

  FluentInfoSeverity _statusSeverity(AcademicTermContext? context) {
    return switch (context?.source) {
      AcademicTermContextSource.automatic => FluentInfoSeverity.success,
      AcademicTermContextSource.unresolved => FluentInfoSeverity.warning,
      AcademicTermContextSource.manual => FluentInfoSeverity.info,
      null => FluentInfoSeverity.info,
    };
  }
}
