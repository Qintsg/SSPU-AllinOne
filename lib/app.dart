/* 应用主体 — 清源响应式导航壳。 */

import 'design/qingyuan/qingyuan_ui.dart';
import 'pages/academic_page.dart';
import 'pages/course_schedule_page.dart';
import 'pages/email_page.dart';
import 'pages/home_page.dart';
import 'pages/info_page.dart';
import 'pages/quick_links_page.dart';
import 'pages/settings_page.dart';
import 'services/app_display_name_service.dart';
import 'services/campus_network_status_service.dart';

bool get _supportsMobileBottomNavigation {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.onLock,
    this.campusNetworkStatusService,
    this.initialDestinationIndex = 0,
    this.destinationOverrides = const {},
  }) : assert(initialDestinationIndex >= 0 && initialDestinationIndex < 7);

  final VoidCallback? onLock;
  final CampusNetworkStatusService? campusNetworkStatusService;

  /// 测试专用：指定首帧可见的主目的地。
  final int initialDestinationIndex;

  /// 测试专用：按用户可见名称替换页面，保留生产导航壳。
  final Map<String, Widget> destinationOverrides;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _selectedIndex;
  late final Set<int> _visitedDestinationIndexes;
  SettingsLandingRequest? _settingsLandingRequest;

  Widget _destinationBody(String title, Widget fallback) {
    return widget.destinationOverrides[title] ?? fallback;
  }

  List<_AppDestination> get _destinations => [
    _AppDestination(
      title: '主页',
      icon: YhIcons.home,
      body: _destinationBody(
        '主页',
        HomePage(
          campusNetworkStatusService: widget.campusNetworkStatusService,
          onOpenSettings: () => _openSettings(SettingsLandingSection.security),
        ),
      ),
    ),
    _AppDestination(
      title: '教务',
      icon: YhIcons.academic,
      body: _destinationBody('教务', const AcademicPage()),
    ),
    _AppDestination(
      title: '课表',
      icon: YhIcons.calendar,
      body: _destinationBody('课表', const CourseSchedulePage()),
    ),
    _AppDestination(
      title: '信息',
      icon: YhIcons.info,
      body: _destinationBody('信息', const InfoPage()),
    ),
    _AppDestination(
      title: '邮箱',
      icon: YhIcons.mail,
      body: _destinationBody('邮箱', const EmailPage()),
    ),
    _AppDestination(
      title: '跳转',
      icon: YhIcons.link,
      body: _destinationBody('跳转', const QuickLinksPage()),
    ),
    _AppDestination(
      title: '设置',
      icon: YhIcons.settings,
      body: _destinationBody(
        '设置',
        SettingsPage(
          onLock: widget.onLock,
          landingRequest: _settingsLandingRequest,
        ),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialDestinationIndex;
    _visitedDestinationIndexes = <int>{_selectedIndex};
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    final width = MediaQuery.sizeOf(context).width;
    final orientation = MediaQuery.orientationOf(context);
    final useBottomNavigation =
        width < context.yhTheme.breakpoint.medium ||
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
    return _DesktopNavigationShell(
      destinations: destinations,
      selectedIndex: _selectedIndex,
      visitedIndexes: _visitedDestinationIndexes,
      extended: width >= context.yhTheme.breakpoint.expanded,
      onChanged: _selectDestination,
    );
  }

  void _selectDestination(int index) {
    if (index < 0 || index >= _destinations.length) return;
    setState(() {
      _selectedIndex = index;
      _visitedDestinationIndexes.add(index);
    });
  }

  void _openSettings(SettingsLandingSection section) {
    setState(() {
      _settingsLandingRequest = SettingsLandingRequest(section);
      _selectedIndex = _destinations.indexWhere(
        (destination) => destination.title == '设置',
      );
      if (_selectedIndex < 0) _selectedIndex = 0;
      _visitedDestinationIndexes.add(_selectedIndex);
    });
  }
}

class _AppDestination {
  const _AppDestination({
    required this.title,
    required this.icon,
    required this.body,
  });

  final String title;
  final IconData icon;
  final Widget body;

  YhNavigationItem get navigationItem =>
      YhNavigationItem(icon: icon, label: title);
}

class _CompactNavigationShell extends StatelessWidget {
  const _CompactNavigationShell({
    required this.destinations,
    required this.selectedIndex,
    required this.visitedIndexes,
    required this.onChanged,
  });

  static const List<int> _primaryIndexes = <int>[0, 1, 2, 3];

  final List<_AppDestination> destinations;
  final int selectedIndex;
  final Set<int> visitedIndexes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final primaryIndexes = _primaryIndexes
        .where((index) => index < destinations.length)
        .toList(growable: false);
    final hiddenIndexes = [
      for (var index = 0; index < destinations.length; index++)
        if (!primaryIndexes.contains(index)) index,
    ];
    final moreSelected = hiddenIndexes.contains(selectedIndex);
    final navigationItems = [
      for (final index in primaryIndexes) destinations[index].navigationItem,
      if (hiddenIndexes.isNotEmpty)
        const YhNavigationItem(icon: YhIcons.more, label: '更多'),
    ];
    final navigationIndex = moreSelected
        ? navigationItems.length - 1
        : primaryIndexes.indexOf(selectedIndex);

    return ColoredBox(
      color: context.yhTheme.color.background,
      child: Column(
        children: [
          Expanded(
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
          Container(
            key: const Key('mobile-bottom-navigation'),
            color: context.yhTheme.color.surface,
            child: SafeArea(
              top: false,
              child: YhBottomNav(
                items: navigationItems,
                index: navigationIndex < 0 ? 0 : navigationIndex,
                onChanged: (index) {
                  if (index < primaryIndexes.length) {
                    onChanged(primaryIndexes[index]);
                    return;
                  }
                  _openMoreDestinations(context, hiddenIndexes);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMoreDestinations(
    BuildContext context,
    List<int> hiddenIndexes,
  ) {
    return YhBottomDrawer.show<void>(
      context,
      title: '更多',
      builder: (drawerContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var offset = 0; offset < hiddenIndexes.length; offset++) ...[
            YhButton(
              label: destinations[hiddenIndexes[offset]].title,
              leadingIcon: destinations[hiddenIndexes[offset]].icon,
              trailingIcon: selectedIndex == hiddenIndexes[offset]
                  ? YhIcons.check
                  : YhIcons.chevronRight,
              variant: YhButtonVariant.secondary,
              onTap: () {
                Navigator.of(drawerContext).pop();
                onChanged(hiddenIndexes[offset]);
              },
            ),
            if (offset < hiddenIndexes.length - 1)
              SizedBox(height: context.yhTheme.spacing.s),
          ],
        ],
      ),
    );
  }
}

class _DesktopNavigationShell extends StatelessWidget {
  const _DesktopNavigationShell({
    required this.destinations,
    required this.selectedIndex,
    required this.visitedIndexes,
    required this.extended,
    required this.onChanged,
  });

  final List<_AppDestination> destinations;
  final int selectedIndex;
  final Set<int> visitedIndexes;
  final bool extended;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return ColoredBox(
      color: theme.color.background,
      child: Row(
        children: [
          YhNavRail(
            items: [
              for (final destination in destinations)
                destination.navigationItem,
            ],
            index: selectedIndex,
            onChanged: onChanged,
            extended: extended,
            header: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.s),
              child: Text(
                extended ? AppDisplayName.of(context) : '工大',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.h3.copyWith(
                  color: theme.color.structural,
                ),
              ),
            ),
          ),
          Expanded(
            child: _NavigationBody(
              destinations: destinations,
              selectedIndex: selectedIndex,
              visitedIndexes: visitedIndexes,
            ),
          ),
        ],
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
        for (var index = 0; index < destinations.length; index++)
          KeyedSubtree(
            key: ValueKey('app-destination-$index'),
            child: visitedIndexes.contains(index)
                ? destinations[index].body
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}
