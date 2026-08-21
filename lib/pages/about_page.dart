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
import 'legal_notice_page.dart';

part 'about_open_source_data.dart';
part 'about_open_source_widgets.dart';

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
      bodyFit: YhTaskPageBodyFit.content,
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
        showYhFeedback(
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
