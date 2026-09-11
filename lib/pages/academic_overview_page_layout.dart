/*
 * 教务总览页面框架 — 标题、状态编排与页面阅读流
 * @Project : SSPU-AllinOne
 * @File : academic_overview_page_layout.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_page.dart';

class _AcademicOverviewPage extends StatelessWidget {
  const _AcademicOverviewPage({
    required this.state,
    required this.termLabel,
    required this.gpa,
    required this.earnedCredits,
    required this.gradeCount,
    required this.nextExam,
    required this.completionValue,
    required this.completedCredits,
    required this.totalCredits,
    required this.failedSources,
    required this.failedSourcesWithoutFallback,
    required this.hasContent,
    required this.credentialsIncomplete,
    required this.oaStatusLabel,
    required this.oaStatusKind,
    required this.refreshSourceCount,
    required this.staleCheckedAt,
    required this.backgroundRefreshing,
    required this.onRefresh,
    required this.onOpenGrades,
    required this.onOpenExams,
    required this.onOpenSchedule,
    required this.onOpenProgramPlan,
    required this.onOpenFreeClassrooms,
    required this.onOpenAccountConnections,
    required this.onAdjustAcademicTerm,
    required this.onOpenDetailedSources,
    required this.legacyDetails,
  });

  final AcademicOverviewDisplayState state;
  final String termLabel;
  final double? gpa;
  final double? earnedCredits;
  final int? gradeCount;
  final AcademicExamRecord? nextExam;
  final double completionValue;
  final double? completedCredits;
  final double totalCredits;
  final Set<String> failedSources;
  final Set<String> failedSourcesWithoutFallback;
  final bool hasContent;
  final bool credentialsIncomplete;
  final String oaStatusLabel;
  final YhStatusKind oaStatusKind;
  final int refreshSourceCount;
  final DateTime? staleCheckedAt;
  final bool backgroundRefreshing;
  final VoidCallback? onRefresh;
  final VoidCallback? onOpenGrades;
  final VoidCallback? onOpenExams;
  final VoidCallback? onOpenSchedule;
  final VoidCallback? onOpenProgramPlan;
  final VoidCallback? onOpenFreeClassrooms;
  final VoidCallback? onOpenAccountConnections;
  final VoidCallback? onAdjustAcademicTerm;
  final VoidCallback? onOpenDetailedSources;
  final Widget legacyDetails;

  bool get _showsContent =>
      state == AcademicOverviewDisplayState.content ||
      state == AcademicOverviewDisplayState.stale ||
      state == AcademicOverviewDisplayState.partialError ||
      (state == AcademicOverviewDisplayState.operationLocked && hasContent);

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPageScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
          final viewportWidth = MediaQuery.sizeOf(context).width;
          final pagePadding = compact
              ? theme.spacing.m
              : (viewportWidth *
                        theme.responsive.panelPaddingViewportPercent /
                        100)
                    .clamp(theme.spacing.l, theme.spacing.xl2);
          final balancedGrid =
              !compact && viewportWidth < theme.breakpoint.expanded;
          return SingleChildScrollView(
            key: const PageStorageKey('academic-overview-scroll'),
            padding: EdgeInsets.fromLTRB(
              pagePadding,
              compact ? theme.spacing.xl : theme.spacing.xl + theme.spacing.s,
              pagePadding,
              theme.spacing.xl2,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: theme.layout.pageContentWidth,
                  minHeight: constraints.maxHeight - theme.spacing.xl2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AcademicHeading(
                      compact: compact,
                      balanced: balancedGrid,
                      onRefresh: onRefresh,
                    ),
                    if (_showsContent) ...[
                      Wrap(
                        spacing: theme.spacing.s,
                        runSpacing: theme.spacing.s,
                        children: [
                          YhStatusPill(
                            label: oaStatusLabel,
                            kind: oaStatusKind,
                          ),
                          const YhStatusPill(
                            label: '本地快照可用',
                            kind: YhStatusKind.success,
                          ),
                          const YhStatusPill(
                            label: '只读访问',
                            kind: YhStatusKind.info,
                          ),
                          if (backgroundRefreshing)
                            Semantics(
                              liveRegion: true,
                              child: const YhStatusPill(
                                label: '正在更新',
                                kind: YhStatusKind.info,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: theme.spacing.m),
                      if (credentialsIncomplete) ...[
                        YhBanner(
                          kind: YhBannerKind.warn,
                          text: _academicCredentialWarningText(
                            refreshSourceCount,
                          ),
                          action: onOpenAccountConnections == null
                              ? null
                              : YhButton(
                                  label: '连接设置',
                                  variant: YhButtonVariant.secondary,
                                  onTap: onOpenAccountConnections,
                                ),
                        ),
                        SizedBox(height: theme.spacing.m),
                      ],
                      if (state == AcademicOverviewDisplayState.stale) ...[
                        YhBanner(
                          kind: YhBannerKind.warn,
                          text:
                              '当前显示 ${_formatAcademicCheckedAt(staleCheckedAt)} 的本地教务快照；刷新失败不会删除这些内容。',
                        ),
                        SizedBox(height: theme.spacing.m),
                      ],
                      if (state ==
                          AcademicOverviewDisplayState.partialError) ...[
                        YhBanner(
                          kind: YhBannerKind.warn,
                          text: _academicPartialFailureText(
                            failedSources,
                            failedSourcesWithoutFallback,
                          ),
                        ),
                        SizedBox(height: theme.spacing.m),
                      ],
                      if (state ==
                          AcademicOverviewDisplayState.operationLocked) ...[
                        Semantics(
                          liveRegion: true,
                          child: YhBanner(
                            text:
                                '正在协同刷新 $refreshSourceCount 个可用只读来源；完成前已锁定重复刷新和详情导航。',
                          ),
                        ),
                        SizedBox(height: theme.spacing.m),
                      ],
                      _AcademicContentGrid(
                        compact: compact,
                        balanced: balancedGrid,
                        termLabel: termLabel,
                        gpa: gpa,
                        earnedCredits: earnedCredits,
                        gradeCount: gradeCount,
                        nextExam: nextExam,
                        completionValue: completionValue,
                        completedCredits: completedCredits,
                        totalCredits: totalCredits,
                        onOpenGrades: onOpenGrades,
                        onOpenExams: onOpenExams,
                        onOpenSchedule: onOpenSchedule,
                        onOpenProgramPlan: onOpenProgramPlan,
                        onOpenFreeClassrooms: onOpenFreeClassrooms,
                      ),
                    ] else
                      _AcademicStatePanel(
                        state: state,
                        refreshSourceCount: refreshSourceCount,
                        onRefresh: onRefresh,
                        onOpenAccountConnections: onOpenAccountConnections,
                        onAdjustAcademicTerm: onAdjustAcademicTerm,
                      ),
                    SizedBox(height: theme.spacing.xl),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: YhButton(
                        key: const ValueKey(
                          'academic-overview-detailed-sources',
                        ),
                        label: '查看详细数据源',
                        variant: YhButtonVariant.secondary,
                        leadingIcon: YhIcons.info,
                        onTap: onOpenDetailedSources,
                      ),
                    ),
                    SizedBox(height: theme.spacing.xl),
                    legacyDetails,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _formatAcademicCheckedAt(DateTime? value) {
  if (value == null) return '最近一次保存';
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.month} 月 ${value.day} 日 ${value.hour}:$minute';
}

String _academicPartialFailureText(
  Set<String> failedSources,
  Set<String> failedSourcesWithoutFallback,
) {
  final retainedSources = failedSources.difference(
    failedSourcesWithoutFallback,
  );
  return '${['${failedSources.join('、')}未完成', if (retainedSources.isNotEmpty) '${retainedSources.join('、')}继续显示最后有效数据', if (failedSourcesWithoutFallback.isNotEmpty) '${failedSourcesWithoutFallback.join('、')}暂无可保留数据', '可使用页面顶部刷新按钮重试'].join('；')}。';
}

String _academicCredentialWarningText(int refreshSourceCount) {
  if (refreshSourceCount == 4) {
    return '体育考勤连接未完成；刷新只会访问其余 4 个可用只读来源。';
  }
  if (refreshSourceCount == 1) {
    return 'OA 连接未完成；刷新只会访问体育考勤，成绩、考试与第二课堂保持本地快照。';
  }
  return '部分教务连接未完成；刷新只会访问已配置的只读来源。';
}
