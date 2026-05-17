/*
 * 应用主体 — 根据 Material 3 窗口尺寸等级切换自适应导航结构
 * @Project : SSPU-AllinOne
 * @File : app.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
import 'widgets/campus_network_status_indicator.dart';

/// 仅移动端原生平台需要优先启用底部导航。
bool get _supportsMobileBottomNavigation {
  if (kIsWeb) return false;

  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
}

/// 应用主体骨架。
/// 管理 Material 3 自适应导航结构与页面切换。
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

  List<_AppDestination> get _destinations => [
    const _AppDestination(
      title: '主页',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      body: HomePage(),
    ),
    const _AppDestination(
      title: '教务',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
      body: AcademicPage(),
    ),
    const _AppDestination(
      title: '课表',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      body: CourseSchedulePage(),
    ),
    const _AppDestination(
      title: '信息',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
      body: InfoPage(),
    ),
    const _AppDestination(
      title: '邮箱',
      icon: Icons.mail_outline,
      selectedIcon: Icons.mail,
      body: EmailPage(),
    ),
    const _AppDestination(
      title: '跳转',
      icon: Icons.link_outlined,
      selectedIcon: Icons.link,
      body: QuickLinksPage(),
    ),
    _AppDestination(
      title: '设置',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      body: SettingsPage(onLock: widget.onLock),
    ),
    const _AppDestination(
      title: '关于',
      icon: Icons.help_outline,
      selectedIcon: Icons.help,
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
        (_supportsMobileBottomNavigation && orientation == Orientation.portrait);

    if (useBottomNavigation) {
      return _CompactNavigationShell(
        destinations: destinations,
        selectedIndex: _selectedIndex,
        onChanged: _selectDestination,
      );
    }

    if (sizeClass == WindowSizeClass.large ||
        sizeClass == WindowSizeClass.extraLarge) {
      return _DrawerNavigationShell(
        destinations: destinations,
        selectedIndex: _selectedIndex,
        onChanged: _selectDestination,
        campusNetworkStatusService: widget.campusNetworkStatusService,
      );
    }

    return _RailNavigationShell(
      destinations: destinations,
      selectedIndex: _selectedIndex,
      extended: sizeClass == WindowSizeClass.expanded,
      onChanged: _selectDestination,
      campusNetworkStatusService: widget.campusNetworkStatusService,
    );
  }

  /// 切换当前导航目的地。
  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
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
  final ValueChanged<int> onChanged;

  const _CompactNavigationShell({
    required this.destinations,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: KeyedSubtree(
          key: ValueKey(selectedIndex),
          child: destinations[selectedIndex].body,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('mobile-bottom-navigation'),
        selectedIndex: selectedIndex,
        onDestinationSelected: onChanged,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.title,
              tooltip: destination.title,
            ),
        ],
      ),
    );
  }
}

class _RailNavigationShell extends StatelessWidget {
  final List<_AppDestination> destinations;
  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onChanged;
  final CampusNetworkStatusService? campusNetworkStatusService;

  const _RailNavigationShell({
    required this.destinations,
    required this.selectedIndex,
    required this.extended,
    required this.onChanged,
    required this.campusNetworkStatusService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              extended: extended,
              minExtendedWidth: 176,
              onDestinationSelected: onChanged,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.title),
                  ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: Padding(
                    key: const Key('campus-network-status-pane-item'),
                    padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                    child: CampusNetworkStatusIndicator(
                      service: campusNetworkStatusService,
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: KeyedSubtree(
                key: ValueKey(selectedIndex),
                child: destinations[selectedIndex].body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavigationShell extends StatelessWidget {
  final List<_AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final CampusNetworkStatusService? campusNetworkStatusService;

  const _DrawerNavigationShell({
    required this.destinations,
    required this.selectedIndex,
    required this.onChanged,
    required this.campusNetworkStatusService,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 280,
              child: NavigationDrawer(
                selectedIndex: selectedIndex,
                onDestinationSelected: onChanged,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Text(
                      'SSPU-AllinOne',
                      style: textTheme.titleLarge,
                    ),
                  ),
                  for (final destination in destinations)
                    NavigationDrawerDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: Text(destination.title),
                    ),
                  const Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Divider(),
                  ),
                  Padding(
                    key: const Key('campus-network-status-pane-item'),
                    padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                    child: CampusNetworkStatusIndicator(
                      service: campusNetworkStatusService,
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: KeyedSubtree(
                key: ValueKey(selectedIndex),
                child: destinations[selectedIndex].body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
