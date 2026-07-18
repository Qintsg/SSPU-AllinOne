/* 快速跳转 — 清源搜索、分组与常用入口页面。 */

import 'package:url_launcher/url_launcher.dart';

import '../design/qingyuan/qingyuan_ui.dart';
import '../services/academic_credentials_service.dart';
import '../services/quick_links_config_service.dart';
import '../services/quick_links_search_service.dart';
import '../services/storage_service.dart';
import 'external_link_confirmation_page.dart';

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

class _QuickLinksStatusPage extends StatelessWidget {
  const _QuickLinksStatusPage({
    required this.title,
    required this.message,
    this.icon,
    this.action,
    this.loading = false,
  });

  final String title;
  final String message;
  final IconData? icon;
  final Widget? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPageScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = _quickLinksPagePadding(
            theme,
            MediaQuery.sizeOf(context).width,
          );
          return SingleChildScrollView(
            padding: padding,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: theme.layout.pageContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _QuickLinksHeader(),
                    SizedBox(height: theme.spacing.l),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: theme.layout.popoverWidth + theme.spacing.xl,
                      ),
                      child: YhCard(
                        child: Center(
                          child: loading
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: theme.spacing.xl2 * 2,
                                      child: const YhProgress(
                                        showPercent: false,
                                      ),
                                    ),
                                    SizedBox(width: theme.spacing.m),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: theme.typography.h3,
                                          ),
                                          SizedBox(height: theme.spacing.xs),
                                          Text(
                                            message,
                                            style: theme.typography.small
                                                .copyWith(
                                                  color: theme.color.muted,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : _QuickLinksStateMessage(
                                  icon: icon ?? YhIcons.link,
                                  title: title,
                                  message: message,
                                  action: action,
                                ),
                        ),
                      ),
                    ),
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

class _QuickLinksContent extends StatefulWidget {
  const _QuickLinksContent({required this.groups, required this.onOpenItem});

  final List<QuickLinkGroupConfig> groups;
  final Future<void> Function(QuickLinkItemConfig item) onOpenItem;

  @override
  State<_QuickLinksContent> createState() => _QuickLinksContentState();
}

class _QuickLinksContentState extends State<_QuickLinksContent> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Set<String> _favoriteUrls = const {};

  @override
  void initState() {
    super.initState();
    _loadFavoriteUrls();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteUrls() async {
    final urls = await StorageService.getStringList(
      StorageKeys.quickLinkFavoriteUrls,
    );
    if (mounted) setState(() => _favoriteUrls = urls.toSet());
  }

  Future<void> _toggleFavorite(QuickLinkItemConfig item) async {
    final next = Set<String>.from(_favoriteUrls);
    if (!next.add(item.url)) next.remove(item.url);
    setState(() => _favoriteUrls = next);
    await StorageService.setStringList(
      StorageKeys.quickLinkFavoriteUrls,
      next.toList()..sort(),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final searchResults = QuickLinksSearchService.search(
      widget.groups,
      _searchQuery,
    );
    final hasSearchQuery = _searchQuery.trim().isNotEmpty;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _FocusQuickLinkSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _FocusQuickLinkSearchIntent(),
      },
      child: Actions(
        actions: {
          _FocusQuickLinkSearchIntent:
              CallbackAction<_FocusQuickLinkSearchIntent>(
                onInvoke: (_) {
                  _searchFocusNode.requestFocus();
                  return null;
                },
              ),
        },
        child: YhPageScaffold(
          appBar: null,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final pagePadding = _quickLinksPagePadding(
                theme,
                MediaQuery.sizeOf(context).width,
              );
              return SingleChildScrollView(
                padding: pagePadding,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: theme.layout.pageContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _QuickLinksHeader(),
                        SizedBox(height: theme.spacing.l),
                        _buildSearchBar(searchResults),
                        SizedBox(height: theme.spacing.m),
                        if (hasSearchQuery)
                          _buildSearchResults(searchResults)
                        else
                          _buildGroups(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(List<QuickLinkSearchResult> searchResults) {
    return YhSearch(
      key: const Key('quick-links-search-field'),
      controller: _searchController,
      focusNode: _searchFocusNode,
      hint: '搜索教务、图书馆、学习平台',
      onChanged: (value) => setState(() => _searchQuery = value),
      onSubmitted: (_) => _openBestMatch(searchResults),
    );
  }

  Future<void> _openBestMatch(List<QuickLinkSearchResult> results) async {
    if (results.isNotEmpty) await widget.onOpenItem(results.first.item);
  }

  Widget _buildSearchResults(List<QuickLinkSearchResult> results) {
    final theme = context.yhTheme;
    if (results.isEmpty) {
      return YhCard(
        child: Column(
          children: [
            Icon(
              YhIcons.search,
              size: theme.spacing.xl2,
              color: theme.color.muted,
            ),
            SizedBox(height: theme.spacing.s),
            Text(
              '未找到匹配的快捷入口',
              style: theme.typography.h3.copyWith(
                color: theme.color.foreground,
              ),
            ),
            SizedBox(height: theme.spacing.s),
            Text(
              '可以尝试入口名称、所属分组或网址中的关键词。',
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
            SizedBox(height: theme.spacing.m),
            YhButton(
              label: '清除搜索',
              variant: YhButtonVariant.secondary,
              onTap: _clearSearch,
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '搜索结果（${results.length}）',
          style: theme.typography.h3.copyWith(color: theme.color.foreground),
        ),
        SizedBox(height: theme.spacing.s),
        _buildDirectory([
          for (final group in widget.groups)
            if (results.any(
              (result) => result.group.category == group.category,
            ))
              QuickLinkGroupConfig(
                category: group.category,
                items: [
                  for (final result in results)
                    if (result.group.category == group.category) result.item,
                ],
              ),
        ]),
      ],
    );
  }

  Widget _buildGroups() {
    return _buildDirectory(widget.groups);
  }

  Widget _buildDirectory(List<QuickLinkGroupConfig> groups) {
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumCardWidth =
            theme.layout.compactContentWidth + theme.spacing.l;
        final columns =
            constraints.maxWidth >= minimumCardWidth * 3 + theme.spacing.m * 2
            ? 3
            : constraints.maxWidth >= minimumCardWidth * 2 + theme.spacing.m
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - theme.spacing.m * (columns - 1)) / columns;
        return Wrap(
          spacing: theme.spacing.m,
          runSpacing: theme.spacing.m,
          children: [
            for (final group in groups)
              SizedBox(
                key: ValueKey('quick-links-group-${group.category}'),
                width: width,
                child: YhCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.category,
                        style: theme.typography.h3.copyWith(
                          fontWeight: theme.typography.semibold,
                        ),
                      ),
                      SizedBox(height: theme.spacing.xs),
                      Text(
                        _categoryDescription(group.category),
                        style: theme.typography.small.copyWith(
                          color: theme.color.muted,
                        ),
                      ),
                      SizedBox(height: theme.spacing.m + theme.spacing.xs),
                      for (
                        var index = 0;
                        index < group.items.length;
                        index++
                      ) ...[
                        if (index > 0) SizedBox(height: theme.spacing.xs),
                        _QuickLinkDirectoryRow(
                          item: group.items[index],
                          icon: _resolveIcon(
                            group.category,
                            group.items[index],
                          ),
                          color: _resolveColor(
                            group.category,
                            group.items[index],
                          ),
                          description: _itemDescription(group.items[index]),
                          favorite: _favoriteUrls.contains(
                            group.items[index].url,
                          ),
                          onToggleFavorite: () =>
                              _toggleFavorite(group.items[index]),
                          onOpen: () => widget.onOpenItem(group.items[index]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _categoryDescription(String category) {
    if (category.contains('学习') || category.contains('教务')) {
      return '课程、考试与学习资源';
    }
    if (category.contains('服务') || category.contains('资源')) {
      return '生活与公共资源';
    }
    return '办事与公开信息';
  }

  String _itemDescription(QuickLinkItemConfig item) {
    final name = item.name;
    if (name.contains('教务')) return '成绩、选课与考试';
    if (name.contains('学习') || name.contains('教学')) return '课程学习与作业';
    if (name.contains('图书')) return '检索、借阅与续借';
    if (name.contains('校园卡')) return '余额与消费记录';
    if (name.contains('邮箱')) return '收发学校邮件';
    if (name.contains('认证')) return '登录学校在线服务';
    if (name.contains('官网')) return '通知与部门入口';
    return '打开外部校园服务';
  }

  IconData _resolveIcon(String category, QuickLinkItemConfig item) {
    return switch (item.icon?.trim()) {
      'education' => YhIcons.academic,
      'library' => YhIcons.library,
      'mail' => YhIcons.mail,
      'sports' => YhIcons.sports,
      'settings' => YhIcons.settings,
      'security' => YhIcons.lock,
      'people' => YhIcons.profile,
      'finance' => YhIcons.finance,
      'home' => YhIcons.home,
      'video' => YhIcons.video,
      'database' => YhIcons.database,
      'globe' => YhIcons.globe,
      _ => _inferIcon('$category ${item.name}'),
    };
  }

  IconData _inferIcon(String text) {
    if (text.contains('邮箱')) return YhIcons.mail;
    if (text.contains('图书') || text.contains('档案')) return YhIcons.library;
    if (text.contains('体育')) return YhIcons.sports;
    if (text.contains('财务') || text.contains('校园卡')) return YhIcons.finance;
    if (text.contains('课程') || text.contains('教务') || text.contains('教学')) {
      return YhIcons.academic;
    }
    if (text.contains('设置') || text.contains('资产')) return YhIcons.settings;
    return YhIcons.globe;
  }

  Color _resolveColor(String category, QuickLinkItemConfig item) {
    final colors = context.yhTheme.color;
    final text = '$category ${item.name}';
    if (item.name.contains('官网') || item.name.contains('认证')) {
      return colors.serviceQuickLink;
    }
    if (text.contains('财务') || text.contains('校园卡')) {
      return colors.serviceFinance;
    }
    if (text.contains('体育')) return colors.serviceSports;
    if (text.contains('教务') || text.contains('教学') || text.contains('学习')) {
      return colors.serviceAcademic;
    }
    if (text.contains('邮箱')) return colors.serviceMail;
    if (text.contains('新闻') || text.contains('信息')) return colors.serviceNews;
    return colors.serviceQuickLink;
  }
}

class _QuickLinkDirectoryRow extends StatelessWidget {
  const _QuickLinkDirectoryRow({
    required this.item,
    required this.icon,
    required this.color,
    required this.description,
    required this.favorite,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  final QuickLinkItemConfig item;
  final IconData icon;
  final Color color;
  final String description;
  final bool favorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      children: [
        Expanded(
          child: YhPressable(
            semanticLabel: '${item.name}，外部链接，将打开外部应用',
            onPressed: onOpen,
            builder: (context, state, child) => Container(
              padding: EdgeInsets.fromLTRB(
                theme.spacing.s,
                theme.spacing.s,
                0,
                theme.spacing.s,
              ),
              decoration: BoxDecoration(
                color: state.hovered || state.focused
                    ? theme.color.sunken
                    : null,
                borderRadius: BorderRadius.circular(theme.radius.input),
              ),
              child: Row(
                children: [
                  Container(
                    width: theme.control.regular - theme.spacing.xs,
                    height: theme.control.regular - theme.spacing.xs,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        color.withValues(alpha: theme.opacity.domainTint),
                        theme.color.surface,
                      ),
                      borderRadius: BorderRadius.circular(theme.radius.input),
                    ),
                    child: Icon(icon, size: theme.spacing.l, color: color),
                  ),
                  SizedBox(width: theme.spacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body.copyWith(
                            fontWeight: theme.typography.semibold,
                          ),
                        ),
                        SizedBox(height: theme.spacing.xs),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.caption.copyWith(
                            color: theme.color.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    YhIcons.open,
                    size: theme.spacing.m,
                    color: theme.color.muted,
                  ),
                ],
              ),
            ),
            child: const SizedBox.shrink(),
          ),
        ),
        YhIconButton(
          icon: favorite ? YhIcons.favoriteFilled : YhIcons.favorite,
          semanticLabel: favorite ? '取消收藏${item.name}' : '收藏${item.name}',
          variant: YhIconButtonVariant.ghost,
          onTap: onToggleFavorite,
        ),
      ],
    );
  }
}

class _QuickLinksStateMessage extends StatelessWidget {
  const _QuickLinksStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compactGap = theme.spacing.xs + theme.layout.divider * 2;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: theme.control.regular,
              height: theme.control.regular,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.color.brandTint,
                borderRadius: BorderRadius.circular(theme.radius.m),
              ),
              child: Icon(
                icon,
                size: theme.spacing.l,
                color: theme.color.brandStrong,
              ),
            ),
          ),
          SizedBox(height: compactGap),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.typography.h3.copyWith(
                color: theme.color.foreground,
                fontWeight: theme.typography.semibold,
              ),
            ),
          ),
          SizedBox(height: compactGap),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: theme.layout.statusProgressWidth,
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ),
          if (action != null) ...[SizedBox(height: theme.spacing.s), action!],
        ],
      ),
    );
  }
}

class _QuickLinksHeader extends StatelessWidget {
  const _QuickLinksHeader();

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速跳转',
          style: theme.typography.caption.copyWith(
            color: theme.color.brandInk,
            fontWeight: theme.typography.semibold,
          ),
        ),
        SizedBox(height: theme.spacing.xs),
        Semantics(
          header: true,
          child: Text('常用校园入口', style: theme.typography.h1),
        ),
        SizedBox(height: theme.spacing.s),
        Text(
          '名称使用学生熟悉的任务语言；跳转前明确外部网站与当前登录要求。',
          style: theme.typography.body.copyWith(color: theme.color.muted),
        ),
      ],
    );
  }
}

class _FocusQuickLinkSearchIntent extends Intent {
  const _FocusQuickLinkSearchIntent();
}

EdgeInsets _quickLinksPagePadding(YhTheme theme, double viewportWidth) {
  if (viewportWidth < theme.breakpoint.medium) {
    return EdgeInsets.symmetric(
      horizontal: theme.spacing.m,
      vertical: theme.spacing.l + theme.spacing.s,
    );
  }
  final progress =
      ((viewportWidth - theme.breakpoint.medium) /
              (theme.breakpoint.expanded - theme.breakpoint.medium))
          .clamp(0.0, 1.0);
  final horizontal =
      theme.spacing.xl + (theme.spacing.xl2 - theme.spacing.xl) * progress;
  return EdgeInsets.symmetric(
    horizontal: horizontal,
    vertical: theme.spacing.xl + theme.spacing.s,
  );
}
