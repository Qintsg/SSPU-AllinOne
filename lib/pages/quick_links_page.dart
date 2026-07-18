/* 快速跳转 — 清源搜索、分组与常用入口页面。 */

import 'package:url_launcher/url_launcher.dart';

import '../design/qingyuan/qingyuan_ui.dart';
import '../services/quick_links_config_service.dart';
import '../services/quick_links_search_service.dart';
import '../services/storage_service.dart';

typedef QuickLinksGroupsLoader = Future<List<QuickLinkGroupConfig>> Function();
typedef QuickLinkOpenCallback = Future<void> Function(String url);

class QuickLinksPage extends StatefulWidget {
  const QuickLinksPage({super.key, this.groupsLoader, this.onOpenUrl});

  final QuickLinksGroupsLoader? groupsLoader;
  final QuickLinkOpenCallback? onOpenUrl;

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

  Future<void> _openUrl(String url) async {
    if (widget.onOpenUrl != null) {
      await widget.onOpenUrl!(url);
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuickLinkGroupConfig>>(
      future: _groupsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _QuickLinksStatusPage(message: '正在读取快捷入口…');
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _QuickLinksStatusPage(
            message: '快捷跳转配置加载失败',
            detail: '${snapshot.error ?? '配置为空'}',
            danger: true,
          );
        }
        return _QuickLinksContent(groups: snapshot.data!, onOpenUrl: _openUrl);
      },
    );
  }
}

class _QuickLinksStatusPage extends StatelessWidget {
  const _QuickLinksStatusPage({
    required this.message,
    this.detail,
    this.danger = false,
  });

  final String message;
  final String? detail;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPageScaffold(
      appBar: const YhAppBar(title: '快速跳转'),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.m),
          child: YhBanner(
            text: detail == null ? message : '$message：$detail',
            kind: danger ? YhBannerKind.danger : YhBannerKind.info,
          ),
        ),
      ),
    );
  }
}

class _QuickLinksContent extends StatefulWidget {
  const _QuickLinksContent({required this.groups, required this.onOpenUrl});

  final List<QuickLinkGroupConfig> groups;
  final QuickLinkOpenCallback onOpenUrl;

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
          appBar: const YhAppBar(title: '快速跳转'),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final pagePadding = constraints.maxWidth < theme.breakpoint.medium
                  ? theme.spacing.m
                  : constraints.maxWidth < theme.breakpoint.expanded
                  ? theme.spacing.l
                  : theme.spacing.xl;
              return SingleChildScrollView(
                padding: EdgeInsets.all(pagePadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: theme.breakpoint.expanded - theme.spacing.l,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchBar(searchResults, hasSearchQuery),
                        SizedBox(height: theme.spacing.l),
                        if (hasSearchQuery)
                          _buildSearchResults(
                            searchResults,
                            constraints.maxWidth,
                          )
                        else
                          _buildGroups(constraints.maxWidth),
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

  Widget _buildSearchBar(
    List<QuickLinkSearchResult> searchResults,
    bool hasSearchQuery,
  ) {
    final theme = context.yhTheme;
    return YhCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: YhTextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              label: '搜索快捷入口',
              hint: '输入任务名称或网址',
              prefixIcon: YhIcons.search,
              suffix: hasSearchQuery
                  ? YhIconButton(
                      icon: YhIcons.close,
                      semanticLabel: '清除搜索',
                      onTap: _clearSearch,
                    )
                  : null,
              onChanged: (value) => setState(() => _searchQuery = value),
              onSubmitted: (_) => _openBestMatch(searchResults),
            ),
          ),
          SizedBox(width: theme.spacing.s),
          YhButton(
            label: '打开最佳匹配',
            leadingIcon: YhIcons.open,
            onTap: searchResults.isEmpty
                ? null
                : () => _openBestMatch(searchResults),
            disabled: searchResults.isEmpty,
          ),
        ],
      ),
    );
  }

  Future<void> _openBestMatch(List<QuickLinkSearchResult> results) async {
    if (results.isNotEmpty) await widget.onOpenUrl(results.first.item.url);
  }

  Widget _buildSearchResults(
    List<QuickLinkSearchResult> results,
    double width,
  ) {
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
        Wrap(
          spacing: theme.spacing.m,
          runSpacing: theme.spacing.m,
          children: [
            for (final result in results)
              _buildTile(
                result.group,
                result.item,
                width,
                subtitle: result.group.category,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroups(double width) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < widget.groups.length; index++) ...[
          if (index > 0) SizedBox(height: theme.spacing.l),
          Text(
            widget.groups[index].category,
            style: theme.typography.h3.copyWith(color: theme.color.foreground),
          ),
          SizedBox(height: theme.spacing.s),
          Wrap(
            spacing: theme.spacing.m,
            runSpacing: theme.spacing.m,
            children: [
              for (final item in widget.groups[index].items)
                _buildTile(widget.groups[index], item, width),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTile(
    QuickLinkGroupConfig group,
    QuickLinkItemConfig item,
    double availableWidth, {
    String? subtitle,
  }) {
    final theme = context.yhTheme;
    final width = availableWidth < theme.breakpoint.compact
        ? (availableWidth - theme.spacing.m * 3) / 2
        : availableWidth < theme.breakpoint.expanded
        ? theme.breakpoint.compact / 4 - theme.spacing.s
        : theme.control.regular * 3 + theme.spacing.m;
    return YhQuickLink(
      icon: _resolveIcon(group.category, item),
      label: item.name,
      subtitle: subtitle,
      color: _resolveColor(group.category, item),
      width: width,
      favorite: _favoriteUrls.contains(item.url),
      onToggleFavorite: () => _toggleFavorite(item),
      onTap: () => widget.onOpenUrl(item.url),
    );
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

class _FocusQuickLinkSearchIntent extends Intent {
  const _FocusQuickLinkSearchIntent();
}
