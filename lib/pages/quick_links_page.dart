/* 快速跳转 — 清源搜索、分组与常用入口页面。 */

import 'package:url_launcher/url_launcher.dart';

import '../design/qingyuan/qingyuan_ui.dart';
import '../services/academic_credentials_service.dart';
import '../services/quick_links_config_service.dart';
import '../services/quick_links_search_service.dart';
import '../services/storage_service.dart';
import 'external_link_confirmation_page.dart';

part 'quick_links_status_page.dart';
part 'quick_links_directory.dart';
part 'quick_links_row.dart';
part 'quick_links_presentation.dart';

typedef QuickLinksGroupsLoader = Future<List<QuickLinkGroupConfig>> Function();
typedef QuickLinkOpenCallback = Future<void> Function(String url);
typedef QuickLinkAuthenticationResolver =
    Future<bool> Function(QuickLinkItemConfig item);

class QuickLinksPage extends StatefulWidget {
  const QuickLinksPage({
    super.key,
    this.groupsLoader,
    this.onOpenUrl,
    this.authenticationResolver,
  });

  final QuickLinksGroupsLoader? groupsLoader;
  final QuickLinkOpenCallback? onOpenUrl;
  final QuickLinkAuthenticationResolver? authenticationResolver;

  @override
  State<QuickLinksPage> createState() => _QuickLinksPageState();
}

class _QuickLinksPageState extends State<QuickLinksPage> {
  late Future<List<QuickLinkGroupConfig>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = _loadGroups();
  }

  @override
  void didUpdateWidget(QuickLinksPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupsLoader != widget.groupsLoader) {
      _groupsFuture = _loadGroups();
    }
  }

  Future<List<QuickLinkGroupConfig>> _loadGroups() =>
      widget.groupsLoader?.call() ??
      QuickLinksConfigService.instance.loadGroups();

  void _retryLoad() {
    final next = _loadGroups();
    setState(() {
      _groupsFuture = next;
    });
  }

  Future<void> _openItem(QuickLinkItemConfig item) async {
    final uri = Uri.tryParse(item.url);
    if (uri == null || uri.host.isEmpty) return;
    final authenticationRequired = _requiresOaAuthentication(item);
    final authenticationReady = await _resolveAuthentication(item);
    if (!mounted) return;
    final confirmed = await Navigator.of(context).push<bool>(
      YhPageRoute<bool>(
        builder: (_) => ExternalLinkConfirmationPage(
          displayName: item.name,
          uri: uri,
          authenticationRequired: authenticationRequired,
          authenticationReady: authenticationReady,
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    if (widget.onOpenUrl != null) {
      await widget.onOpenUrl!(item.url);
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> _resolveAuthentication(QuickLinkItemConfig item) async {
    if (!_requiresOaAuthentication(item)) return true;
    if (widget.authenticationResolver != null) {
      return widget.authenticationResolver!(item);
    }
    final session = await AcademicCredentialsService.instance
        .readOaLoginSession();
    return session != null;
  }

  bool _requiresOaAuthentication(QuickLinkItemConfig item) {
    final host = Uri.tryParse(item.url)?.host.toLowerCase() ?? '';
    return host == 'oa.sspu.edu.cn' ||
        item.name.contains('（OA）') ||
        item.name.contains('统一身份认证');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuickLinkGroupConfig>>(
      future: _groupsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _QuickLinksStatusPage(
            title: '正在读取校园入口',
            message: '正在加载本地快捷入口配置。',
            loading: true,
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _QuickLinksStatusPage(
            title: '无法加载快捷入口',
            message:
                '请检查应用内 ${QuickLinksConfigService.assetPath} 后重试；已有收藏不会被删除。',
            icon: YhIcons.info,
            action: YhButton(label: '重试', onTap: _retryLoad),
          );
        }
        if (snapshot.data!.isEmpty) {
          return const _QuickLinksStatusPage(
            title: '暂无快捷入口',
            message: '当前配置没有可用的校园服务入口。',
            icon: YhIcons.link,
          );
        }
        return _QuickLinksContent(
          groups: snapshot.data!,
          onOpenItem: _openItem,
        );
      },
    );
  }
}
