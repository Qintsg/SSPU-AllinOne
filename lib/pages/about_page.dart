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
import '../theme/fluent_tokens.dart';
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
    name: 'open_filex',
    description: '打开本地文件、安装包或所在文件夹',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/open_filex',
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

  /// 许可证使用说明。
  String get licenseDescription {
    return switch (license) {
      'BSD-3-Clause' => '宽松许可证；使用与分发时保留版权声明、许可文本和免责声明。',
      'MIT' => '宽松许可证；允许使用、复制、修改与分发，需保留版权和许可声明。',
      'Apache-2.0' => '宽松许可证；包含专利授权条款，分发时保留许可证与必要 NOTICE。',
      'MPL-2.0' => '文件级弱 copyleft；若修改 MPL 覆盖文件，需按 MPL 提供对应源代码。',
      'Microsoft Design Guidelines' =>
        '设计指南与品牌资源规则；本项目仅参考界面语言，不声明 Microsoft 背书。',
      'MiSans EULA' => '字体最终用户许可；随应用使用与分发时遵守小米字体许可条款。',
      _ => '请以项目发布的许可证正文为准。',
    };
  }
}

/// 关于页面。
/// 若后续用户没有明确说明，不得修改此页面内容。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentPage.scrollable(
      header: const FluentPageHeader(title: Text('关于')),
      padding: AppSpacing.regularPagePadding,
      children: const [AboutSettingsSection()],
    );
  }
}

/// 设置页中的关于分区。
class AboutSettingsSection extends StatelessWidget {
  const AboutSettingsSection({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).typography;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppInfoCard(context)
                .animate()
                .fadeIn(duration: AppMotion.medium, curve: Curves.easeOutCubic)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.lg),
            _buildActionCard(context)
                .animate(delay: 100.ms)
                .fadeIn(duration: AppMotion.medium, curve: Curves.easeOutCubic)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text('使用/参考的开源项目', style: typography.subtitle),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildOpenSourceCard(context)
                .animate(delay: 200.ms)
                .fadeIn(duration: AppMotion.medium, curve: Curves.easeOutCubic)
                .slideY(begin: 0.05, end: 0),
          ],
        ),
      ),
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
    final theme = FluentTheme.of(context);
    final resources = theme.resources;
    final borderSide = BorderSide(
      color: resources.controlStrokeColorDefault,
      width: context.fluentStroke.thin,
    );

    return FluentCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: FluentAppMetrics.readableMaxWidth,
          ),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(160),
              1: FixedColumnWidth(260),
              2: FixedColumnWidth(150),
              3: FixedColumnWidth(350),
            },
            border: TableBorder(
              top: borderSide,
              right: borderSide,
              bottom: borderSide,
              left: borderSide,
              horizontalInside: borderSide,
              verticalInside: borderSide,
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: resources.controlFillColorSecondary,
                ),
                children: const [
                  _OpenSourceHeaderCell('项目'),
                  _OpenSourceHeaderCell('使用场景'),
                  _OpenSourceHeaderCell('许可证'),
                  _OpenSourceHeaderCell('许可证说明'),
                ],
              ),
              for (final project in _openSourceProjects)
                TableRow(
                  children: [
                    _OpenSourceLinkCell(
                      name: project.name,
                      onTap: () => _openUrl(project.url),
                    ),
                    _OpenSourceBodyCell(project.description),
                    _OpenSourceBodyCell(project.license),
                    _OpenSourceBodyCell(project.licenseDescription),
                  ],
                ),
            ],
          ),
        ),
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

/// 开源项目表头单元格。
class _OpenSourceHeaderCell extends StatelessWidget {
  const _OpenSourceHeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).typography;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(label, style: typography.bodyStrong),
    );
  }
}

/// 开源项目正文单元格。
class _OpenSourceBodyCell extends StatelessWidget {
  const _OpenSourceBodyCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        text,
        style: theme.typography.caption?.copyWith(
          color: theme.resources.textFillColorSecondary,
        ),
      ),
    );
  }
}

/// 开源项目链接单元格。
class _OpenSourceLinkCell extends StatelessWidget {
  const _OpenSourceLinkCell({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.openSource,
              size: 16,
              color: theme.accentColor.defaultBrushFor(theme.brightness),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: Text(name, style: theme.typography.bodyStrong)),
          ],
        ),
      ),
    );
  }
}
