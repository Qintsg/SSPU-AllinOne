/*
 * 关于页面 — 展示软件信息、作者、许可证、开源项目列表
 * @Project : SSPU-AllinOne
 * @File : about_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_info_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import 'agreement_page.dart';
import 'privacy_policy_page.dart';

/// 使用/参考的开源项目列表。
/// 若后续用户没有明确说明，不得修改此内容。
const List<_OpenSourceProject> _openSourceProjects = [
  _OpenSourceProject(
    name: 'Flutter',
    description: '跨平台 UI 框架与 Material 3 组件体系',
    license: 'BSD-3-Clause',
    url: 'https://flutter.dev',
  ),
  _OpenSourceProject(
    name: 'Material Design 3',
    description: 'Google Material 3 设计系统，本项目新前端规范来源',
    license: 'Apache-2.0',
    url: 'https://m3.material.io',
  ),
  _OpenSourceProject(
    name: 'shared_preferences',
    description: '本地持久化存储',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/shared_preferences',
  ),
  _OpenSourceProject(
    name: 'crypto',
    description: '加密算法库',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/crypto',
  ),
  _OpenSourceProject(
    name: 'url_launcher',
    description: '打开外部链接',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/url_launcher',
  ),
  _OpenSourceProject(
    name: 'MiSans',
    description: '小米全新系统字体，数字等宽',
    license: 'MiSans EULA',
    url: 'https://hyperos.mi.com/font/zh',
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.regularPagePadding,
          child: Center(
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
                    child: Text('使用/参考的开源项目', style: textTheme.titleMedium),
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
        ),
      ),
    );
  }

  /// 构建应用信息卡片。
  Widget _buildAppInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card.filled(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
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
                        child: Text('SSPU-AllinOne', style: textTheme.titleLarge),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        versionText,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
    return Card.filled(
      child: Column(
        children: [
          _buildActionTile(
            context,
            icon: Icons.code,
            title: 'GitHub 仓库',
            subtitle: 'Qintsg/SSPU-AllinOne',
            onTap: () => _openUrl('https://github.com/Qintsg/SSPU-AllinOne'),
          ),
          const Divider(height: 1),
          _buildActionTile(
            context,
            icon: Icons.description_outlined,
            title: '使用协议',
            subtitle: '查看完整使用协议条款',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AgreementPage()),
            ),
          ),
          const Divider(height: 1),
          _buildActionTile(
            context,
            icon: Icons.shield_outlined,
            title: '隐私协议',
            subtitle: '查看本地数据、凭据和网络访问说明',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建开源项目卡片。
  Widget _buildOpenSourceCard(BuildContext context) {
    return Card.filled(
      child: Column(
        children: _openSourceProjects.asMap().entries.map((entry) {
          final project = entry.value;
          final isLast = entry.key == _openSourceProjects.length - 1;
          return Column(
            children: [
              _buildActionTile(
                context,
                icon: Icons.integration_instructions_outlined,
                title: project.name,
                subtitle: '${project.description} · ${project.license}',
                onTap: () => _openUrl(project.url),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 构建信息行。
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text('$label：', style: textTheme.bodyMedium),
        Flexible(child: Text(value, style: textTheme.titleSmall)),
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
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
