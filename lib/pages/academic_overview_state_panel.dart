/*
 * 教务总览状态面板 — 初始、加载、空与恢复路径
 * @Project : SSPU-AllinOne
 * @File : academic_overview_state_panel.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_page.dart';

class _AcademicStatePanel extends StatelessWidget {
  const _AcademicStatePanel({
    required this.state,
    required this.refreshSourceCount,
    required this.onRefresh,
    required this.onOpenAccountConnections,
    required this.onAdjustAcademicTerm,
  });

  final AcademicOverviewDisplayState state;
  final int refreshSourceCount;
  final VoidCallback? onRefresh;
  final VoidCallback? onOpenAccountConnections;
  final VoidCallback? onAdjustAcademicTerm;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (state == AcademicOverviewDisplayState.loading ||
        state == AcademicOverviewDisplayState.operationLocked) {
      final operationLocked =
          state == AcademicOverviewDisplayState.operationLocked;
      return _AcademicRecoverySurface(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: theme.control.regular,
              child: const YhProgress(showPercent: false),
            ),
            SizedBox(width: theme.spacing.m),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    liveRegion: operationLocked,
                    child: Text(
                      operationLocked
                          ? '正在读取 $refreshSourceCount 个可用教务来源'
                          : '正在恢复本机教务快照',
                      style: theme.typography.h3,
                    ),
                  ),
                  SizedBox(height: theme.spacing.s),
                  Text(
                    operationLocked
                        ? '完成前已锁定重复刷新和详情导航；若部分来源失败，将保留各自最后有效数据。'
                        : '页面结构与已有导航保持可用；网络读取完成后再替换各区域。',
                    style: theme.typography.small.copyWith(
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
    final (icon, title, message, label, action, variant) = switch (state) {
      AcademicOverviewDisplayState.initial => (
        YhIcons.academic,
        '尚未读取教务快照',
        '先从本机恢复已保存内容；只有你主动刷新时才访问校园服务。',
        '读取教务数据',
        onRefresh,
        YhButtonVariant.primary,
      ),
      AcademicOverviewDisplayState.empty => (
        YhIcons.academic,
        '当前学期没有可展示的学习记录',
        '读取已完成，但成绩、考试和课表均为空；可调整学期或查看账户范围。',
        '调整学期',
        onAdjustAcademicTerm,
        YhButtonVariant.secondary,
      ),
      AcademicOverviewDisplayState.credentialsRequired => (
        YhIcons.academic,
        '需要先完成教务账户连接',
        '尚未保存 OA 账号或密码；现在不会发起任何校园服务请求。',
        '前往账户与连接',
        onOpenAccountConnections,
        YhButtonVariant.primary,
      ),
      _ => (
        YhIcons.info,
        '无法读取教务数据',
        '未读取到可用快照；请检查校园网络或 VPN 后重试。',
        '检查后重试',
        onRefresh,
        YhButtonVariant.primary,
      ),
    };
    return _AcademicRecoverySurface(
      child: _AcademicStateEmpty(
        icon: icon,
        title: title,
        message: message,
        action: YhButton(label: label, variant: variant, onTap: action),
      ),
    );
  }
}

class _AcademicRecoverySurface extends StatelessWidget {
  const _AcademicRecoverySurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.layout.formContentWidth),
        child: SizedBox(
          width: double.infinity,
          child: YhCard(child: child),
        ),
      ),
    );
  }
}

class _AcademicStateEmpty extends StatelessWidget {
  const _AcademicStateEmpty({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.color.brandTint,
                borderRadius: BorderRadius.circular(theme.radius.m),
              ),
              child: SizedBox.square(
                dimension: theme.control.regular,
                child: Icon(icon, color: theme.color.brandStrong),
              ),
            ),
            SizedBox(height: theme.spacing.m),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.typography.h3.copyWith(
                color: theme.color.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: theme.spacing.s),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: theme.layout.compactContentWidth,
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ),
            SizedBox(height: theme.spacing.m),
            action,
          ],
        ),
      ),
    );
  }
}
