/*
 * 关于页面 — 展示软件信息、作者、许可证、开源项目列表
 * @Project : SSPU-AllinOne
 * @File : about_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import '../design/fluent_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_display_name_service.dart';
import '../services/app_info_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import 'legal_notice_page.dart';

/// 使用/参考的开源项目列表。
/// 若后续用户没有明确说明，不得修改此内容。
const List<_OpenSourceProject> _openSourceProjects = [
  _OpenSourceProject(
    name: 'Flutter',
    description: '跨平台 UI 框架与渲染基础能力',
    license: 'BSD-3-Clause',
    url: 'https://flutter.dev',
  ),
  _OpenSourceProject(
    name: 'Fluent 2 Design System',
    description: 'Microsoft Fluent 2 设计系统，本项目前端视觉规范来源',
    license: 'Microsoft Design Guidelines',
    url: 'https://fluent2.microsoft.design/',
  ),
  _OpenSourceProject(
    name: 'fluent_ui',
    description: 'Fluent 风格桌面与跨平台控件',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/fluent_ui',
  ),
  _OpenSourceProject(
    name: 'fluentui_system_icons',
    description: 'Microsoft Fluent System Icons 图标库',
    license: 'MIT',
    url: 'https://pub.dev/packages/fluentui_system_icons',
  ),
  _OpenSourceProject(
    name: 'shared_preferences',
    description: '本地持久化存储',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/shared_preferences',
  ),
  _OpenSourceProject(
    name: 'path_provider',
    description: '平台应用支持目录解析',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/path_provider',
  ),
  _OpenSourceProject(
    name: 'crypto',
    description: 'SHA-256 等哈希算法',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/crypto',
  ),
  _OpenSourceProject(
    name: 'flutter_secure_storage',
    description: '系统安全存储凭据保存',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/flutter_secure_storage',
  ),
  _OpenSourceProject(
    name: 'local_auth',
    description: '系统 PIN / 生物识别快速验证',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/local_auth',
  ),
  _OpenSourceProject(
    name: 'url_launcher',
    description: '打开外部链接',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/url_launcher',
  ),
  _OpenSourceProject(
    name: 'window_manager',
    description: 'Flutter 桌面窗口管理',
    license: 'MIT',
    url: 'https://pub.dev/packages/window_manager',
  ),
  _OpenSourceProject(
    name: 'tray_manager',
    description: '系统托盘图标管理',
    license: 'MIT',
    url: 'https://pub.dev/packages/tray_manager',
  ),
  _OpenSourceProject(
    name: 'dio',
    description: '强大的 HTTP 客户端库',
    license: 'MIT',
    url: 'https://pub.dev/packages/dio',
  ),
  _OpenSourceProject(
    name: 'local_notifier',
    description: 'Windows 本地系统通知推送',
    license: 'MIT',
    url: 'https://pub.dev/packages/local_notifier',
  ),
  _OpenSourceProject(
    name: 'html',
    description: 'HTML 解析库',
    license: 'MIT',
    url: 'https://pub.dev/packages/html',
  ),
  _OpenSourceProject(
    name: 'gbk_codec',
    description: 'GBK / GB2312 页面解码',
    license: 'MIT',
    url: 'https://pub.dev/packages/gbk_codec',
  ),
  _OpenSourceProject(
    name: 'flutter_animate',
    description: '页面入场与微交互动效',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/flutter_animate',
  ),
  _OpenSourceProject(
    name: 'flutter_inappwebview',
    description: '内嵌 WebView 与 WebView2 能力',
    license: 'Apache-2.0',
    url: 'https://pub.dev/packages/flutter_inappwebview',
  ),
  _OpenSourceProject(
    name: 'package_info_plus',
    description: '应用版本与包信息读取',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/package_info_plus',
  ),
  _OpenSourceProject(
    name: 'enough_mail',
    description: '学校邮箱 IMAP / POP / SMTP 协议客户端',
    license: 'MPL-2.0',
    url: 'https://pub.dev/packages/enough_mail',
  ),
  _OpenSourceProject(
    name: 'pdfrx',
    description: '应用内 PDF 查看与 PDF 渲染能力',
    license: 'MIT',
    url: 'https://pub.dev/packages/pdfrx',
  ),
  _OpenSourceProject(
    name: 'pdfrx_engine',
    description: 'PDF 文本抽取与底层 PDFium 封装',
    license: 'MIT',
    url: 'https://pub.dev/packages/pdfrx_engine',
  ),
  _OpenSourceProject(
    name: 'MiSans',
    description: '小米系统字体，数字等宽',
    license: 'MiSans EULA',
    url: 'https://hyperos.mi.com/font/zh',
  ),
];

class _OpenSourceProject {
  final String name;
  final String description;
  final String license;
  final String url;

  const _OpenSourceProject({
    required this.name,
    required this.description,
    required this.license,
    required this.url,
  });
}

/// 关于页面。
/// 若后续用户没有明确说明，不得修改此页面内容。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).typography;

    return FluentPage.scrollable(
      header: const FluentPageHeader(title: Text('关于')),
      padding: AppSpacing.regularPagePadding,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppInfoCard(context)
                    .animate()
                    .fadeIn(
                      duration: AppMotion.medium,
                      curve: Curves.easeOutCubic,
                    )
                    .slideY(begin: 0.05, end: 0),
                const SizedBox(height: AppSpacing.lg),
                _buildActionCard(context)
                    .animate(delay: 100.ms)
                    .fadeIn(
                      duration: AppMotion.medium,
                      curve: Curves.easeOutCubic,
                    )
                    .slideY(begin: 0.05, end: 0),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text('使用/参考的开源项目', style: typography.subtitle),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildOpenSourceCard(context)
                    .animate(delay: 200.ms)
                    .fadeIn(
                      duration: AppMotion.medium,
                      curve: Curves.easeOutCubic,
                    )
                    .slideY(begin: 0.05, end: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建应用信息卡片。
  Widget _buildAppInfoCard(BuildContext context) {
    final theme = FluentTheme.of(context);
    final typography = theme.typography;
    final resources = theme.resources;

    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: resources.controlFillColorSecondary,
                borderRadius: AppShapes.lg,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 80,
                  height: 80,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FutureBuilder<AppVersionInfo>(
                future: AppInfoService.instance.loadVersionInfo(),
                builder: (context, snapshot) {
                  final versionText = snapshot.data?.displayText ?? '版本加载中...';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          AppDisplayName.of(context),
                          style: typography.titleLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        versionText,
                        style: typography.caption?.copyWith(
                          color: resources.textFillColorSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildInfoRow(context, '著作人', 'Qintsg'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow(context, '许可证', 'Artistic License 2.0'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建操作入口卡片。
  Widget _buildActionCard(BuildContext context) {
    return FluentCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildActionTile(
            context,
            icon: FluentIcons.code,
            title: 'GitHub 仓库',
            subtitle: 'Qintsg/SSPU-AllinOne',
            onTap: () => _openUrl('https://github.com/Qintsg/SSPU-AllinOne'),
          ),
          const Divider(),
          _buildActionTile(
            context,
            icon: FluentIcons.documentText,
            title: '法律与隐私说明',
            subtitle: '查看免责声明、用户协议、隐私协议和第三方协议',
            onTap: () => Navigator.of(
              context,
            ).push(FluentPageRoute(builder: (_) => const LegalNoticePage())),
          ),
        ],
      ),
    );
  }

  /// 构建开源项目卡片。
  Widget _buildOpenSourceCard(BuildContext context) {
    return FluentCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: _openSourceProjects.asMap().entries.map((entry) {
          final project = entry.value;
          final isLast = entry.key == _openSourceProjects.length - 1;
          return Column(
            children: [
              _buildActionTile(
                context,
                icon: FluentIcons.openSource,
                title: project.name,
                subtitle: '${project.description} · ${project.license}',
                onTap: () => _openUrl(project.url),
              ),
              if (!isLast) const Divider(),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 构建信息行。
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final typography = FluentTheme.of(context).typography;
    return Row(
      children: [
        Text('$label：', style: typography.body),
        Flexible(child: Text(value, style: typography.bodyStrong)),
      ],
    );
  }

  /// 构建可点击操作行。
  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = FluentTheme.of(context);
    final typography = theme.typography;
    final resources = theme.resources;
    final accent = theme.accentColor.defaultBrushFor(theme.brightness);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: typography.bodyStrong),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: typography.caption?.copyWith(
                      color: resources.textFillColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              FluentIcons.chevronRight,
              color: resources.textFillColorSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
