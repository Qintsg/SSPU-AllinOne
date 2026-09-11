/*
 * 快捷入口目录 — 搜索、收藏、分组与键盘操作
 * @Project : SSPU-AllinOne
 * @File : quick_links_directory.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'quick_links_page.dart';

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
              final viewportWidth = MediaQuery.sizeOf(context).width;
              final pagePadding = _quickLinksPagePadding(theme, viewportWidth);
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
                        SizedBox(
                          height: _quickLinksSectionGap(theme, viewportWidth),
                        ),
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
                      SizedBox(height: theme.spacing.l),
                      for (
                        var index = 0;
                        index < group.items.length;
                        index++
                      ) ...[
                        if (index > 0) SizedBox(height: theme.spacing.s),
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
    if (item.kind == QuickLinkKind.app) return '在已安装的应用中打开';
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
