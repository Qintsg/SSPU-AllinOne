/*
 * 关于页面 — 展示软件信息、作者、许可证、开源项目列表
 * @Project : SSPU-AllinOne
 * @File : about_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'package:url_launcher/url_launcher.dart';

import '../design/qingyuan/qingyuan_ui.dart';
import '../services/app_display_name_service.dart';
import '../services/app_info_service.dart';
import '../widgets/app_feedback.dart';
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
    name: 'fluentui_system_icons',
    description: 'YhIcons 语义图标门面的底层字形资源',
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
  const _OpenSourceProject({
    required this.name,
    required this.description,
    required this.license,
    required this.url,
  });

  final String name;
  final String description;
  final String license;
  final String url;

  String get licenseDescription => switch (license) {
    'BSD-3-Clause' => '宽松许可证；使用与分发时保留版权声明、许可文本和免责声明。',
    'MIT' => '宽松许可证；允许使用、复制、修改与分发，需保留版权和许可声明。',
    'Apache-2.0' => '宽松许可证；包含专利授权条款，分发时保留许可证与必要 NOTICE。',
    'MPL-2.0' => '文件级弱 copyleft；若修改 MPL 覆盖文件，需按 MPL 提供对应源代码。',
    'Microsoft Design Guidelines' => '设计指南与品牌资源规则；本项目仅参考界面语言，不声明 Microsoft 背书。',
    'MiSans EULA' => '字体最终用户许可；随应用使用与分发时遵守小米字体许可条款。',
    _ => '请以项目发布的许可证正文为准。',
  };
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPageScaffold(
      appBar: YhAppBar(
        title: '关于',
        leading: YhIconButton(
          icon: YhIcons.back,
          semanticLabel: '返回',
          variant: YhIconButtonVariant.ghost,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.spacing.m),
        child: const AboutSettingsSection(),
      ),
    );
  }
}

/// 设置“关于”中的独立开源许可任务页。
class OpenSourceLicensesPage extends StatefulWidget {
  const OpenSourceLicensesPage({super.key, this.launchUrlOverride});

  final Future<bool> Function(Uri uri)? launchUrlOverride;

  @override
  State<OpenSourceLicensesPage> createState() => _OpenSourceLicensesPageState();
}

class _OpenSourceLicensesPageState extends State<OpenSourceLicensesPage> {
  bool _openingExternal = false;
  String? _externalError;

  @override
  Widget build(BuildContext context) {
    return YhTaskPage(
      title: '开源许可',
      kicker: '关于工大聚合',
      appBarEyebrow: '设置',
      summary: '按项查看应用使用的开源软件、字体与平台能力许可。',
      source: '随应用发布的许可清单',
      sourceSymbol: '许',
      width: YhTaskPageWidth.fluid,
      canPop: !_openingExternal,
      primaryActionLabel: '返回关于',
      onPrimaryAction: _openingExternal
          ? null
          : () => Navigator.of(context).maybePop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_openingExternal) ...[
            const YhBanner(text: '正在交给系统浏览器；完成前已锁定其它外部链接。'),
            SizedBox(height: context.yhTheme.spacing.m),
          ] else if (_externalError != null) ...[
            YhBanner(text: _externalError!, kind: YhBannerKind.danger),
            SizedBox(height: context.yhTheme.spacing.m),
          ],
          _OpenSourceProjectsView(
            onOpenProject: _openProject,
            operationsLocked: _openingExternal,
          ),
        ],
      ),
    );
  }

  Future<void> _openProject(_OpenSourceProject project) async {
    if (_openingExternal) return;
    final confirmed = await YhDialog.confirm(
      context,
      title: '打开 ${project.name}',
      message: '即将在系统浏览器打开 ${Uri.parse(project.url).host}。离开应用后，网页不再受本应用的本地保护。',
      confirmText: '继续打开',
    );
    if (!confirmed || !mounted) {
      if (mounted) {
        showAppFeedback(
          context,
          message: '已取消打开 ${project.name}',
          details: '许可清单和阅读位置均已保留。',
        );
      }
      return;
    }
    setState(() {
      _openingExternal = true;
      _externalError = null;
    });
    try {
      final uri = Uri.parse(project.url);
      final opened = await (widget.launchUrlOverride ?? _launchExternal)(uri);
      if (!opened && mounted) {
        setState(() {
          _externalError = '系统浏览器未能打开 ${project.name}；请检查默认浏览器设置后重试。';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _externalError = '系统浏览器未能打开 ${project.name}；请检查默认浏览器设置后重试。';
        });
      }
    } finally {
      if (mounted) setState(() => _openingExternal = false);
    }
  }

  Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

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
    final theme = context.yhTheme;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.breakpoint.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppInfoCard(context),
            SizedBox(height: theme.spacing.l),
            _buildActionCard(context),
            SizedBox(height: theme.spacing.l),
            Semantics(
              header: true,
              child: Text('使用/参考的开源项目', style: theme.typography.h3),
            ),
            SizedBox(height: theme.spacing.s),
            _buildOpenSourceCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      padding: EdgeInsets.all(theme.spacing.m),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < theme.breakpoint.compact;
          final logo = _AppLogo(compact: compact);
          final info = Expanded(
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
                        style: theme.typography.h2,
                      ),
                    ),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      versionText,
                      style: theme.typography.small.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                    SizedBox(height: theme.spacing.m),
                    _InfoRow(label: '著作人', value: 'Qintsg'),
                    SizedBox(height: theme.spacing.s),
                    _InfoRow(label: '许可证', value: 'Artistic License 2.0'),
                  ],
                );
              },
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                logo,
                SizedBox(height: theme.spacing.m),
                Row(children: [info]),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              logo,
              SizedBox(width: theme.spacing.m),
              info,
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ActionTile(
            icon: YhIcons.open,
            title: 'GitHub 仓库',
            subtitle: 'Qintsg/SSPU-AllinOne',
            onTap: () => _openUrl('https://github.com/Qintsg/SSPU-AllinOne'),
          ),
          ColoredBox(
            color: theme.color.border,
            child: SizedBox(
              height: theme.layout.divider,
              width: double.infinity,
            ),
          ),
          _ActionTile(
            icon: YhIcons.library,
            title: '法律与隐私说明',
            subtitle: '查看免责声明、用户协议、隐私协议和第三方协议',
            onTap: () => Navigator.of(
              context,
            ).push(YhPageRoute<void>(builder: (_) => const LegalNoticePage())),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenSourceCard(BuildContext context) {
    return _OpenSourceProjectsView(
      onOpenProject: (project) => _openUrl(project.url),
    );
  }
}

class _OpenSourceProjectsView extends StatelessWidget {
  const _OpenSourceProjectsView({
    required this.onOpenProject,
    this.operationsLocked = false,
  });

  final ValueChanged<_OpenSourceProject> onOpenProject;
  final bool operationsLocked;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < theme.breakpoint.medium) {
          return Column(
            children: [
              for (final project in _openSourceProjects) ...[
                _OpenSourceProjectCard(
                  project: project,
                  onTap: operationsLocked ? null : () => onOpenProject(project),
                ),
                if (project != _openSourceProjects.last)
                  SizedBox(height: theme.spacing.s),
              ],
            ],
          );
        }
        final borderSide = BorderSide(color: theme.color.border);
        return YhCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                0: FixedColumnWidth(theme.spacing.xl2 * 3),
                1: FixedColumnWidth(theme.spacing.xl2 * 5),
                2: FixedColumnWidth(theme.spacing.xl2 * 3),
                3: FixedColumnWidth(theme.spacing.xl2 * 7),
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
                  decoration: BoxDecoration(color: theme.color.sunken),
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
                        onTap: operationsLocked
                            ? null
                            : () => onOpenProject(project),
                      ),
                      _OpenSourceBodyCell(project.description),
                      _OpenSourceBodyCell(project.license),
                      _OpenSourceBodyCell(project.licenseDescription),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OpenSourceProjectCard extends StatelessWidget {
  const _OpenSourceProjectCard({required this.project, required this.onTap});

  final _OpenSourceProject project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YhPressable(
            semanticLabel: '打开 ${project.name}',
            onPressed: onTap,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: theme.typography.body.copyWith(
                      color: theme.color.brandInk,
                      fontWeight: theme.typography.feed.fontWeight,
                    ),
                  ),
                ),
                Icon(
                  YhIcons.open,
                  size: theme.spacing.m + theme.layout.divider * 2,
                  color: theme.color.brandStrong,
                ),
              ],
            ),
          ),
          SizedBox(height: theme.spacing.s),
          Text(project.description, style: theme.typography.body),
          SizedBox(height: theme.spacing.s),
          Text(
            project.license,
            style: theme.typography.small.copyWith(
              color: theme.color.brandStrong,
              fontWeight: theme.typography.feed.fontWeight,
            ),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            project.licenseDescription,
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
        ],
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final size = compact ? theme.spacing.xl2 : theme.spacing.xl2 * 2;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.brandTint,
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.s),
        child: Image.asset('assets/images/logo.png', width: size, height: size),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      children: [
        Text('$label：', style: theme.typography.body),
        Flexible(
          child: Text(
            value,
            style: theme.typography.body.copyWith(
              fontWeight: theme.typography.feed.fontWeight,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: title,
      onPressed: onTap,
      builder: (context, state, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: state.pressed
              ? theme.color.brand.withValues(alpha: 0.16)
              : state.hovered
              ? theme.color.brandTint
              : theme.color.surface,
        ),
        child: child,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: theme.spacing.s,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.color.brandStrong),
            SizedBox(width: theme.spacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.typography.body.copyWith(
                      fontWeight: theme.typography.feed.fontWeight,
                    ),
                  ),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    subtitle,
                    style: theme.typography.small.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: theme.spacing.s),
            Icon(YhIcons.chevronRight, size: 20, color: theme.color.muted),
          ],
        ),
      ),
    );
  }
}

class _OpenSourceHeaderCell extends StatelessWidget {
  const _OpenSourceHeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.s,
      ),
      child: Text(
        label,
        style: theme.typography.body.copyWith(
          fontWeight: theme.typography.feed.fontWeight,
        ),
      ),
    );
  }
}

class _OpenSourceBodyCell extends StatelessWidget {
  const _OpenSourceBodyCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.s,
      ),
      child: Text(
        text,
        style: theme.typography.small.copyWith(color: theme.color.muted),
      ),
    );
  }
}

class _OpenSourceLinkCell extends StatelessWidget {
  const _OpenSourceLinkCell({required this.name, required this.onTap});

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: '打开 $name',
      onPressed: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: theme.spacing.s,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              YhIcons.open,
              size: theme.spacing.m + theme.layout.divider * 2,
              color: theme.color.brandStrong,
            ),
            SizedBox(width: theme.spacing.s),
            Flexible(
              child: Text(
                name,
                style: theme.typography.small.copyWith(
                  color: theme.color.brandInk,
                  fontWeight: theme.typography.feed.fontWeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
