/* 清源“关于工大聚合”任务页与设置摘要。 */

import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

import '../design/qingyuan/qingyuan_ui.dart';
import '../services/app_info_service.dart';
import 'about_page.dart';
import 'legal_notice_page.dart';
import 'settings_update_page.dart';

enum SettingsAboutState { loading, content, error }

class SettingsAboutSnapshot {
  const SettingsAboutSnapshot({
    required this.version,
    this.buildNumber = '',
    this.designVersion = '0.4.0',
    this.flutterVersion = '3.44.0',
  });

  final String version;
  final String buildNumber;
  final String designVersion;
  final String flutterVersion;

  String get versionLabel =>
      buildNumber.isEmpty ? '版本 $version' : '版本 $version+$buildNumber';
}

typedef SettingsAboutLoader = Future<SettingsAboutSnapshot> Function();

/// 设置分区中的只读摘要，完整构建信息与许可入口进入独立任务页。
class SettingsAboutSummary extends StatelessWidget {
  const SettingsAboutSummary({super.key, this.onOpenDetails});

  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('关于工大聚合', style: theme.typography.h2),
        SizedBox(height: theme.spacing.m),
        YhCard(
          child: Row(
            children: [
              Icon(YhIcons.info, color: theme.color.brandStrong),
              SizedBox(width: theme.spacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('应用构建、更新与许可', style: theme.typography.body),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      '查看当前版本、清源设计来源、Flutter 基线和第三方许可。',
                      style: theme.typography.small.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (onOpenDetails != null) ...[
          SizedBox(height: theme.spacing.m),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: YhButton(
              label: '打开关于工大聚合',
              variant: YhButtonVariant.secondary,
              onTap: onOpenDetails,
            ),
          ),
        ],
      ],
    );
  }
}

class SettingsAboutPage extends StatefulWidget {
  const SettingsAboutPage({
    super.key,
    this.loader,
    this.onCheckUpdate,
    this.onOpenLegal,
    this.onOpenLicenses,
    this.launchUrlOverride,
    this.previewState,
    this.previewSnapshot = const SettingsAboutSnapshot(version: '1.0.0'),
    this.sourceTimestamp,
  });

  final SettingsAboutLoader? loader;
  final VoidCallback? onCheckUpdate;
  final VoidCallback? onOpenLegal;
  final VoidCallback? onOpenLicenses;
  final Future<bool> Function(Uri uri)? launchUrlOverride;

  @visibleForTesting
  final SettingsAboutState? previewState;

  @visibleForTesting
  final SettingsAboutSnapshot previewSnapshot;

  final String? sourceTimestamp;

  @override
  State<SettingsAboutPage> createState() => _SettingsAboutPageState();
}

class _SettingsAboutPageState extends State<SettingsAboutPage> {
  late SettingsAboutState _state;
  late SettingsAboutSnapshot _snapshot;
  String? _errorMessage;
  String? _noticeMessage;
  bool _openingExternal = false;

  bool get _preview => widget.previewState != null;

  @override
  void initState() {
    super.initState();
    _state = widget.previewState ?? SettingsAboutState.loading;
    _snapshot = _preview
        ? widget.previewSnapshot
        : const SettingsAboutSnapshot(version: '未知');
    if (!_preview) unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return YhTaskPage(
      title: '关于工大聚合',
      kicker: '设置',
      appBarEyebrow: '设置',
      summary: '展示版本、开源许可、更新通道与清源设计语言来源。',
      source: '应用构建信息',
      sourceSymbol: '设',
      sourceTimestamp: widget.sourceTimestamp,
      width: YhTaskPageWidth.fluid,
      bodyFit: YhTaskPageBodyFit.content,
      canPop: !_openingExternal,
      primaryActionLabel: '检查更新',
      onPrimaryAction: _openingExternal ? null : _openUpdate,
      moreActions: [
        YhTaskPageAction(
          label: '查看开源许可',
          onTap: _openingExternal ? null : _openLicenses,
        ),
        YhTaskPageAction(
          label: '查看法律与隐私',
          onTap: _openingExternal ? null : _openLegal,
        ),
        YhTaskPageAction(
          label: _openingExternal ? '正在打开 GitHub' : '打开 GitHub 仓库',
          onTap: _openingExternal ? null : _openGithub,
        ),
      ],
      body: Builder(
        builder: (bodyContext) => Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: bodyContext.yhTheme.layout.formContentWidth,
            ),
            child: _AboutBuildLedger(
              state: _state,
              snapshot: _snapshot,
              errorMessage: _errorMessage,
              noticeMessage: _noticeMessage,
              onVersion: _openingExternal
                  ? null
                  : (_state == SettingsAboutState.error ? _load : _showVersion),
              onDesign: _openingExternal ? null : _showDesign,
              onFlutter: _openingExternal ? null : _openLicenses,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    if (_preview) return;
    setState(() {
      _state = SettingsAboutState.loading;
      _errorMessage = null;
      _noticeMessage = null;
    });
    try {
      final snapshot = await (widget.loader ?? _defaultLoader)();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _state = SettingsAboutState.content;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = SettingsAboutState.error;
        _errorMessage = '无法读取当前应用版本；更新、许可与法律入口仍可使用，可稍后重试版本读取。';
      });
    }
  }

  Future<SettingsAboutSnapshot> _defaultLoader() async {
    final info = await AppInfoService.instance.loadVersionInfo();
    return SettingsAboutSnapshot(
      version: info.version,
      buildNumber: info.buildNumber,
    );
  }

  void _openUpdate() {
    if (_openingExternal) return;
    if (widget.onCheckUpdate != null) {
      widget.onCheckUpdate!();
      return;
    }
    Navigator.of(context)
        .push(YhPageRoute<void>(builder: (_) => const SettingsUpdatePage()));
  }

  void _openLegal() {
    if (_openingExternal) return;
    if (widget.onOpenLegal != null) {
      widget.onOpenLegal!();
      return;
    }
    Navigator.of(context)
        .push(YhPageRoute<void>(builder: (_) => const LegalNoticePage()));
  }

  void _openLicenses() {
    if (_openingExternal) return;
    if (widget.onOpenLicenses != null) {
      widget.onOpenLicenses!();
      return;
    }
    Navigator.of(
      context,
    ).push(YhPageRoute<void>(builder: (_) => const OpenSourceLicensesPage()));
  }

  void _showVersion() {
    _showDetail(
      title: '应用版本',
      message: '${_snapshot.versionLabel}\n更新检查只会在你主动操作时访问 GitHub Releases。',
    );
  }

  void _showDesign() {
    _showDetail(
      title: '清源设计语言',
      message: '清源 ${_snapshot.designVersion}\n颜色、排版、间距、断点和交互状态由清源设计契约统一管理。',
    );
  }

  void _showDetail({required String title, required String message}) {
    YhBottomDrawer.show<void>(
      context,
      title: title,
      builder: (drawerContext) {
        final theme = drawerContext.yhTheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: theme.typography.body),
            SizedBox(height: theme.spacing.l),
            YhButton(
              label: '关闭',
              variant: YhButtonVariant.secondary,
              onTap: () => Navigator.of(drawerContext).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openGithub() async {
    if (_openingExternal || _preview) return;
    final confirmed = await YhDialog.confirm(
      context,
      title: '打开 GitHub 仓库',
      message:
          '即将在系统浏览器打开 github.com/Qintsg/SSPU-AllinOne。离开应用后，网页不再受本应用的本地保护。',
      confirmText: '继续打开',
    );
    if (!confirmed || !mounted) {
      if (mounted) {
        showYhFeedback(context, message: '已取消打开 GitHub', details: '仍停留在关于页面。');
      }
      return;
    }
    setState(() {
      _openingExternal = true;
      _noticeMessage = null;
    });
    try {
      final uri = Uri.parse('https://github.com/Qintsg/SSPU-AllinOne');
      final opened = await (widget.launchUrlOverride ?? _launchExternal)(uri);
      if (!opened && mounted) {
        setState(() {
          _noticeMessage = '系统浏览器未能打开 GitHub；请检查默认浏览器设置后重试。';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _noticeMessage = '系统浏览器未能打开 GitHub；请检查默认浏览器设置后重试。';
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

class _AboutBuildLedger extends StatelessWidget {
  const _AboutBuildLedger({
    required this.state,
    required this.snapshot,
    required this.errorMessage,
    required this.noticeMessage,
    required this.onVersion,
    required this.onDesign,
    required this.onFlutter,
  });

  final SettingsAboutState state;
  final SettingsAboutSnapshot snapshot;
  final String? errorMessage;
  final String? noticeMessage;
  final VoidCallback? onVersion;
  final VoidCallback? onDesign;
  final VoidCallback? onFlutter;

  @override
  Widget build(BuildContext context) {
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (noticeMessage != null)
            YhBanner(text: noticeMessage!, kind: YhBannerKind.danger)
          else if (state == SettingsAboutState.loading)
            const YhBanner(text: '正在读取本机应用构建信息；更新、许可与法律入口保持可用。')
          else if (state == SettingsAboutState.error)
            YhBanner(
              text: errorMessage ?? '无法读取当前应用版本；更新、许可与法律入口仍可使用，可稍后重试版本读取。',
              kind: YhBannerKind.danger,
            ),
          _AboutBuildRow(
            title: switch (state) {
              SettingsAboutState.loading => '应用版本',
              SettingsAboutState.content => snapshot.versionLabel,
              SettingsAboutState.error => '未完成：应用版本',
            },
            status: switch (state) {
              SettingsAboutState.loading => '保留当前设置',
              SettingsAboutState.content => '当前设置',
              SettingsAboutState.error => '版本状态暂不可用',
            },
            actionLabel: switch (state) {
              SettingsAboutState.loading => '处理中',
              SettingsAboutState.content => '版本详情',
              SettingsAboutState.error => '重试',
            },
            onTap: state == SettingsAboutState.loading ? null : onVersion,
          ),
          _AboutBuildRow(
            title: '清源 ${snapshot.designVersion}',
            status: state == SettingsAboutState.loading ? '保留当前设置' : '保存在本机',
            actionLabel: state == SettingsAboutState.loading ? '处理中' : '设计说明',
            onTap: state == SettingsAboutState.loading ? null : onDesign,
          ),
          _AboutBuildRow(
            title: 'Flutter ${snapshot.flutterVersion}',
            status: state == SettingsAboutState.loading ? '保留当前设置' : '保存在本机',
            actionLabel: state == SettingsAboutState.loading ? '处理中' : '许可清单',
            onTap: state == SettingsAboutState.loading ? null : onFlutter,
          ),
        ],
      ),
    );
  }
}

class _AboutBuildRow extends StatelessWidget {
  const _AboutBuildRow({
    required this.title,
    required this.status,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String status;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.color.border,
            width: theme.layout.divider,
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: theme.control.minimumTarget + theme.spacing.m,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: theme.spacing.s),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.typography.body.copyWith(
                        fontWeight: theme.typography.h3.fontWeight,
                      ),
                    ),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      status,
                      style: theme.typography.small.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: theme.spacing.m),
              YhButton(
                label: actionLabel,
                variant: YhButtonVariant.secondary,
                disabled: onTap == null,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
