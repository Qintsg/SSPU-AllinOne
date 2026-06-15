/*
 * 教务中心本专科成绩卡片 — 仅展示 GPA 与成绩门数概览
 * @Project : SSPU-AllinOne
 * @File : academic_eams_grade_card.dart
 * @Author : Qintsg
 * @Date : 2026-06-14
 */

part of 'academic_page.dart';

/// 教务中心本专科成绩子卡片。
class AcademicEamsGradeCard extends StatelessWidget {
  /// 最近一次成绩查询结果。
  final AcademicEamsQueryResult? result;

  /// 当前是否正在读取成绩。
  final bool isLoading;

  /// 打开成绩详情页。
  final VoidCallback onOpenDetail;

  const AcademicEamsGradeCard({
    super.key,
    required this.result,
    required this.isLoading,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final accent = context.fluentAccents.academic;
    final snapshot = result?.snapshot?.grades;
    final borderColor = context.fluentColors.neutralStroke1;

    return Container(
      key: const Key('academic-eams-grade-card'),
      decoration: BoxDecoration(
        color: theme.resources.controlAltFillColorSecondary,
        borderRadius: context.fluentRadii.mediumBorder,
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AcademicGradeCardHeader(
              isLoading: isLoading,
              accent: accent,
              onOpenDetail: onOpenDetail,
            ),
            const SizedBox(height: FluentSpacing.m),
            if (isLoading)
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: FluentProgressRing(strokeWidth: 2),
                  ),
                  SizedBox(width: FluentSpacing.s),
                  Text('正在读取成绩...'),
                ],
              )
            else if (result == null)
              Text('随本专科教务刷新读取成绩，或点击右上角查看详情。', style: theme.typography.body)
            else if (result!.isSuccess && snapshot != null)
              _AcademicGradeMetrics(
                gpa: snapshot.weightedGpaForTerm(null),
                courseCount: snapshot.allRecords.length,
              )
            else
              FluentInfoBar(
                title: Text(result!.message),
                content: Text(result!.detail),
                severity: _examSeverity(result!.status),
              ),
          ],
        ),
      ),
    );
  }
}

class _AcademicGradeCardHeader extends StatelessWidget {
  const _AcademicGradeCardHeader({
    required this.isLoading,
    required this.accent,
    required this.onOpenDetail,
  });

  final bool isLoading;
  final Color accent;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluentSurfaceIcon(
          icon: FluentIcons.certificate,
          color: accent,
          size: 36,
        ),
        const SizedBox(width: FluentSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '成绩',
                style: theme.typography.subtitle?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: FluentSpacing.xxs),
              Text(
                isLoading ? '正在同步成绩' : '成绩与绩点',
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: FluentSpacing.s),
        FluentIconButton(
          key: const Key('academic-eams-grade-detail'),
          icon: const Icon(FluentIcons.chevronRight),
          tooltip: '查看成绩详情',
          semanticLabel: '查看成绩详情',
          appearance: FluentIconButtonAppearance.outline,
          onPressed: onOpenDetail,
        ),
      ],
    );
  }
}

class _AcademicGradeMetrics extends StatelessWidget {
  const _AcademicGradeMetrics({required this.gpa, required this.courseCount});

  /// 全部学期学分加权 GPA。
  final double? gpa;

  /// 全部学期课程门数。
  final int courseCount;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final accent = context.fluentAccents.academic;
    if (courseCount == 0) {
      return Text(
        '当前账号暂无可展示的成绩。',
        style: theme.typography.caption?.copyWith(
          color: theme.resources.textFillColorSecondary,
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: _AcademicGradeMetricTile(
            value: gpa == null ? '—' : gpa!.toStringAsFixed(2),
            label: '平均绩点 GPA',
            accent: accent,
          ),
        ),
        const SizedBox(width: FluentSpacing.s),
        Expanded(
          child: _AcademicGradeMetricTile(
            value: courseCount.toString(),
            suffix: '门',
            label: '成绩门数',
            accent: accent,
          ),
        ),
      ],
    );
  }
}

/// 成绩卡片单个指标块：醒目数值 + 说明标签。
class _AcademicGradeMetricTile extends StatelessWidget {
  const _AcademicGradeMetricTile({
    required this.value,
    required this.label,
    required this.accent,
    this.suffix = '',
  });

  final String value;
  final String label;
  final Color accent;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.m,
        vertical: FluentSpacing.s,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: context.fluentRadii.mediumBorder,
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.title?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (suffix.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  suffix,
                  style: theme.typography.caption?.copyWith(color: accent),
                ),
              ],
            ],
          ),
          const SizedBox(height: FluentSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 格式化学分：整数不保留小数，其余按原值展示。
///
/// :param value: 学分数值。
/// :returns: 适合展示的学分文本。
String _formatGradeCredit(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}

/// 成绩文本占位处理：空值回退为占位符。
///
/// :param value: 原始成绩字段文本。
/// :param placeholder: 空值占位符，默认 "-"。
/// :returns: 适合展示的成绩文本。
String _gradeText(String? value, {String placeholder = '-'}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? placeholder : text;
}
