/*
 * 应用主体 — 根据 Fluent 2 窗口尺寸等级切换自适应导航结构
 * @Project : SSPU-AllinOne
 * @File : app.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'design/fluent_ui.dart';
import 'pages/about_page.dart';
import 'pages/academic_page.dart';
import 'pages/course_schedule_page.dart';
import 'pages/email_page.dart';
import 'pages/home_page.dart';
import 'pages/info_page.dart';
import 'pages/quick_links_page.dart';
import 'pages/settings_page.dart';
import 'services/campus_network_status_service.dart';
import 'theme/app_breakpoints.dart';
import 'theme/app_spacing.dart';

part 'app_navigation_items.dart';

/// 仅移动端原生平台需要优先启用底部导航。
bool get _supportsMobileBottomNavigation {
  if (kIsWeb) return false;

  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
}

/// 应用主体骨架。
/// 管理 Fluent 2 自适应导航结构与页面切换。
class AppShell extends StatefulWidget {
  /// 手动上锁回调。
  final VoidCallback? onLock;

  /// 校园网 / VPN 状态检测服务，允许测试或后续平台实现注入。
  final CampusNetworkStatusService? campusNetworkStatusService;

  const AppShell({super.key, this.onLock, this.campusNetworkStatusService});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// 当前选中的导航项索引。
  int _selectedIndex = 0;

  /// 已访问过的页面索引，用于懒加载并保留导航切换后的页面状态。
  final Set<int> _visitedDestinationIndexes = <int>{0};

  List<_AppDestination> get _destinations => [
    _AppDestination(
      title: '主页',
      icon: FluentIcons.home,
      selectedIcon: FluentIcons.home,
      body: HomePage(
        campusNetworkStatusService: widget.campusNetworkStatusService,
      ),
    ),
    const _AppDestination(
      title: '教务',
      icon: FluentIcons.education,
      selectedIcon: FluentIcons.education,
      body: AcademicPage(),
    ),
    const _AppDestination(
      title: '课表',
      icon: FluentIcons.calendar,
      selectedIcon: FluentIcons.calendar,
      body: CourseSchedulePage(),
    ),
    const _AppDestination(
      title: '信息',
      icon: FluentIcons.info,
      selectedIcon: FluentIcons.infoSolid,
      body: InfoPage(),
    ),
    const _AppDestination(
      title: '邮箱',
      icon: FluentIcons.mail,
      selectedIcon: FluentIcons.mail,
      body: EmailPage(),
    ),
    const _AppDestination(
      title: '跳转',
      icon: FluentIcons.link,
      selectedIcon: FluentIcons.link,
      body: QuickLinksPage(),
    ),
    _AppDestination(
      title: '设置',
      icon: FluentIcons.settings,
      selectedIcon: FluentIcons.settings,
      body: SettingsPage(onLock: widget.onLock),
    ),
    const _AppDestination(
      title: '关于',
      icon: FluentIcons.info,
      selectedIcon: FluentIcons.infoSolid,
      body: AboutPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    final sizeClass = AppBreakpoints.of(context);
    final orientation = MediaQuery.orientationOf(context);
    final useBottomNavigation =
        sizeClass == WindowSizeClass.compact ||
        (_supportsMobileBottomNavigation &&
            orientation == Orientation.portrait);

    if (useBottomNavigation) {
      return _CompactNavigationShell(
        destinations: destinations,
        selectedIndex: _selectedIndex,
        visitedIndexes: _visitedDestinationIndexes,
        onChanged: _selectDestination,
      );
    }

    return _FluentNavigationShell(
      destinations: destinations,
      selectedIndex: _selectedIndex,
      visitedIndexes: _visitedDestinationIndexes,
      displayMode:
          (sizeClass == WindowSizeClass.large ||
              sizeClass == WindowSizeClass.extraLarge)
          ? PaneDisplayMode.expanded
          : PaneDisplayMode.compact,
      onChanged: _selectDestination,
    );
  }

  /// 切换当前导航目的地。
  void _selectDestination(int index) {
    final destinations = _destinations;
    if (index < 0 || index >= destinations.length) return;

    setState(() {
      _selectedIndex = index;
      _visitedDestinationIndexes.add(index);
    });
  }
}

class _AppDestination {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget body;

  const _AppDestination({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.body,
  });
}

class _CompactNavigationShell extends StatelessWidget {
  final List<_AppDestination> destinations;
  final int selectedIndex;
  final Set<int> visitedIndexes;
  final ValueChanged<int> onChanged;

  static const List<int> _primaryIndexes = <int>[0, 1, 2, 3];
  static const _moreDestination = _AppDestination(
    title: '更多',
    icon: FluentIcons.more,
    selectedIcon: FluentIcons.more,
    body: SizedBox.shrink(),
  );

  const _CompactNavigationShell({
    required this.destinations,
    required this.selectedIndex,
    required this.visitedIndexes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final primaryIndexes = _primaryIndexes
        .where((index) => index < destinations.length)
        .toList(growable: false);
    final hiddenIndexes = [
      for (var i = 0; i < destinations.length; i++)
        if (!primaryIndexes.contains(i)) i,
    ];
    final moreSelected = hiddenIndexes.contains(selectedIndex);

    return ScaffoldPage(
      content: SafeArea(
        bottom: false,
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: _NavigationBody(
            destinations: destinations,
            selectedIndex: selectedIndex,
            visitedIndexes: visitedIndexes,
          ),
        ),
      ),
      bottomBar: Container(
        key: const Key('mobile-bottom-navigation'),
        decoration: BoxDecoration(
          color: colors.neutralBackground2,
          border: Border(top: BorderSide(color: colors.neutralStrokeDivider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                for (final i in primaryIndexes)
                  Expanded(
                    child: _FluentBottomNavigationItem(
                      destination: destinations[i],
                      selected: selectedIndex == i,
                      onTap: () => onChanged(i),
                    ),
                  ),
                if (hiddenIndexes.isNotEmpty)
                  Expanded(
                    child: _FluentBottomNavigationItem(
                      destination: _moreDestination,
                      selected: moreSelected,
                      onTap: () => _openMoreDestinations(
                        context,
                        hiddenIndexes: hiddenIndexes,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 打开移动端“更多”入口，承载低频页面避免底部导航拥挤。
  Future<void> _openMoreDestinations(
    BuildContext context, {
    required List<int> hiddenIndexes,
  }) {
    return showFluentDialog<void>(
      context: context,
      builder: (dialogContext) {
        return FluentDialog(
          title: const Text('更多功能'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final index in hiddenIndexes)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: index == hiddenIndexes.last ? 0 : AppSpacing.sm,
                  ),
                  child: FluentSurface(
                    subtle: true,
                    elevated: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    semanticLabel: '打开${destinations[index].title}',
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      onChanged(index);
                    },
                    child: Row(
                      children: [
                        Icon(destinations[index].icon, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(destinations[index].title)),
                        if (selectedIndex == index)
                          Icon(
                            FluentIcons.checkMark,
                            size: 18,
                            color: context.fluentColors.brandForeground1,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FluentNavigationShell extends StatelessWidget {
  final List<_AppDestination> destinations;
  final int selectedIndex;
  final Set<int> visitedIndexes;
  final PaneDisplayMode displayMode;
  final ValueChanged<int> onChanged;

  const _FluentNavigationShell({
    required this.destinations,
    required this.selectedIndex,
    required this.visitedIndexes,
    required this.displayMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final type = context.fluentType;

    return NavigationView(
      pane: NavigationPane(
        selected: selectedIndex,
        onChanged: onChanged,
        displayMode: displayMode,
        header: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Text('SSPU-AllinOne', style: type.title2),
        ),
        items: [
          for (final destination in destinations)
            PaneItem(
              icon: Icon(destination.icon),
              title: Text(destination.title),
              body: const SizedBox.shrink(),
            ),
        ],
      ),
      paneBodyBuilder: (_, _) => _NavigationBody(
        destinations: destinations,
        selectedIndex: selectedIndex,
        visitedIndexes: visitedIndexes,
      ),
    );
  }
}

class _NavigationBody extends StatelessWidget {
  const _NavigationBody({
    required this.destinations,
    required this.selectedIndex,
    required this.visitedIndexes,
  });

  final List<_AppDestination> destinations;
  final int selectedIndex;
  final Set<int> visitedIndexes;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: selectedIndex,
      children: [
        for (var i = 0; i < destinations.length; i++)
          KeyedSubtree(
            key: ValueKey('app-destination-$i'),
            child: visitedIndexes.contains(i)
                ? destinations[i].body
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}
