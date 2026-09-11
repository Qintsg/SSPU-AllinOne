/* 快速跳转 — 清源搜索、分组与常用入口页面。 */

import 'package:url_launcher/url_launcher.dart';

import '../design/qingyuan/qingyuan_ui.dart';
import '../services/academic_credentials_service.dart';
import '../services/quick_links_availability_service.dart';
import '../services/quick_links_config_service.dart';
import '../services/quick_links_search_service.dart';
import '../services/storage_service.dart';
import '../utils/app_web_launcher.dart';
import '../utils/webview_env.dart';
import 'external_link_confirmation_page.dart';
import 'webview_page.dart';

part 'quick_links_status_page.dart';
part 'quick_links_directory.dart';
part 'quick_links_row.dart';
part 'quick_links_presentation.dart';

typedef QuickLinksGroupsLoader = Future<List<QuickLinkGroupConfig>> Function();
typedef QuickLinksAvailabilityResolver =
    Future<List<QuickLinkGroupConfig>> Function(
      List<QuickLinkGroupConfig> groups,
    );
typedef QuickLinkOpenCallback = Future<void> Function(String url);
typedef QuickLinkAuthenticationResolver =
    Future<bool> Function(QuickLinkItemConfig item);

class QuickLinksPage extends StatefulWidget {
  const QuickLinksPage({
    super.key,
    this.groupsLoader,
    this.availabilityResolver,
    this.onOpenUrl,
    this.authenticationResolver,
  });

  final QuickLinksGroupsLoader? groupsLoader;
  final QuickLinksAvailabilityResolver? availabilityResolver;
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
    if (oldWidget.groupsLoader != widget.groupsLoader ||
        oldWidget.availabilityResolver != widget.availabilityResolver) {
      _groupsFuture = _loadGroups();
    }
  }

  Future<List<QuickLinkGroupConfig>> _loadGroups() async {
    final groups =
        await (widget.groupsLoader?.call() ??
            QuickLinksConfigService.instance.loadGroups());
    return widget.availabilityResolver?.call(groups) ??
        QuickLinksAvailabilityService.filterCurrentGroups(groups);
  }

  void _retryLoad() {
    final next = _loadGroups();
    setState(() {
      _groupsFuture = next;
    });
  }

  Future<void> _openItem(QuickLinkItemConfig item) async {
    final uri = Uri.tryParse(item.url);
    if (uri == null || uri.scheme.isEmpty) return;
    if (item.kind == QuickLinkKind.app) {
      await _openAppItem(item, uri);
      return;
    }
    if (uri.host.isEmpty) return;
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
          openInApp: widget.onOpenUrl == null,
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    if (widget.onOpenUrl != null) {
      await widget.onOpenUrl!(item.url);
      return;
    }
    if (authenticationRequired) {
      await _openAuthenticatedOa(item, uri);
      return;
    }
    await openAppWebUrl(context, url: item.url, title: item.name);
  }

  /// 在应用内打开 OA 入口，并把当前已认证会话限制在目标 OA 域名的首次请求。
  ///
  /// 会话缺失时不会偷偷触发登录或退回系统浏览器；入口确认页已经负责阻止
  /// 这种跳转并给出返回路径。
  Future<void> _openAuthenticatedOa(QuickLinkItemConfig item, Uri uri) async {
    final cookieHeader = await AcademicCredentialsService.instance
        .readOaCookieHeaderFor(uri);
    if (cookieHeader == null || cookieHeader.isEmpty || !mounted) return;
    final environment = await ensureGlobalWebViewEnvironment();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      YhPageRoute<void>(
        builder: (_) => WebViewPage(
          url: item.url,
          initialTitle: item.name,
          webViewEnvironment: environment,
          initialHeaders: <String, String>{'Cookie': cookieHeader},
        ),
      ),
    );
  }

  Future<void> _openAppItem(QuickLinkItemConfig item, Uri uri) async {
    if (widget.onOpenUrl != null) {
      await widget.onOpenUrl!(item.url);
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      showYhFeedback(
        context,
        message: '无法打开${item.name}，请确认应用仍已安装',
        severity: AppFeedbackSeverity.warning,
      );
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
    if (item.kind == QuickLinkKind.oa) return true;
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
