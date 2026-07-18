/*
 * 设置页布局 — 响应式导航与设置分区内容切换
 * @Project : SSPU-AllinOne
 * @File : settings_page_layout.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'settings_page.dart';

mixin _SettingsPageLayout on State<SettingsPage>, _SettingsPageActions {
  int get _selectedTab;
  set _selectedTab(int value);

  /// 宽屏布局。
  Widget _buildWideSettingsLayout(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: theme.spacing.xl2 * 4,
          child: Padding(
            padding: EdgeInsets.only(
              left: theme.spacing.l,
              top: theme.spacing.s,
            ),
            child: _buildSettingsNavigation(context),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: theme.spacing.s),
          child: SizedBox(
            width: theme.layout.divider,
            child: ColoredBox(color: theme.color.border),
          ),
        ),
        Expanded(
          child: _buildScrollableContent(
            EdgeInsets.symmetric(
              horizontal: theme.spacing.l,
              vertical: theme.spacing.s,
            ),
          ),
        ),
      ],
    );
  }

  /// 窄屏布局。
  Widget _buildNarrowSettingsLayout(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            theme.spacing.m,
            0,
            theme.spacing.m,
            theme.spacing.s,
          ),
          child: _buildSettingsTabCombo(context),
        ),
        SizedBox(
          height: theme.layout.divider,
          width: double.infinity,
          child: ColoredBox(color: theme.color.border),
        ),
        Expanded(
          child: _buildScrollableContent(
            EdgeInsets.symmetric(
              horizontal: theme.spacing.m,
              vertical: theme.spacing.s,
            ),
          ),
        ),
      ],
    );
  }

  /// 左侧导航。
  Widget _buildSettingsNavigation(BuildContext context) {
    final theme = context.yhTheme;
    final captionStyle = theme.typography.caption.copyWith(
      color: theme.color.muted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            theme.spacing.s,
            theme.spacing.xs,
            theme.spacing.s,
            theme.spacing.s,
          ),
          child: Text('系统设置', style: captionStyle),
        ),
        buildSettingsNavItem(
          context: context,
          index: 0,
          selectedIndex: _selectedTab,
          icon: YhIcons.settings,
          label: '常规',
          onTap: () => setState(() => _selectedTab = 0),
        ),
        SizedBox(height: theme.spacing.xs),
        buildSettingsNavItem(
          context: context,
          index: 1,
          selectedIndex: _selectedTab,
          icon: YhIcons.calendar,
          label: '学期',
          onTap: () => setState(() => _selectedTab = 1),
        ),
        SizedBox(height: theme.spacing.xs),
        buildSettingsNavItem(
          context: context,
          index: 2,
          selectedIndex: _selectedTab,
          icon: YhIcons.sync,
          label: '自动刷新',
          onTap: () => setState(() => _selectedTab = 2),
        ),
        SizedBox(height: theme.spacing.xs),
        buildSettingsNavItem(
          context: context,
          index: 3,
          selectedIndex: _selectedTab,
          icon: YhIcons.lock,
          label: '安全',
          onTap: () => setState(() => _selectedTab = 3),
        ),
        _buildSettingsDivider(context),
        Padding(
          padding: EdgeInsets.fromLTRB(
            theme.spacing.s,
            0,
            theme.spacing.s,
            theme.spacing.s,
          ),
          child: Text('消息推送设置', style: captionStyle),
        ),
        buildSettingsNavItem(
          context: context,
          index: 4,
          selectedIndex: _selectedTab,
          icon: YhIcons.education,
          label: '职能部门',
          onTap: () => setState(() => _selectedTab = 4),
        ),
        SizedBox(height: theme.spacing.xs),
        buildSettingsNavItem(
          context: context,
          index: 5,
          selectedIndex: _selectedTab,
          icon: YhIcons.library,
          label: '教学单位',
          onTap: () => setState(() => _selectedTab = 5),
        ),
        SizedBox(height: theme.spacing.xs),
        buildSettingsNavItem(
          context: context,
          index: 6,
          selectedIndex: _selectedTab,
          icon: YhIcons.chat,
          label: '微信推文',
          onTap: () => setState(() => _selectedTab = 6),
        ),
        _buildSettingsDivider(context),
        buildSettingsNavItem(
          context: context,
          index: 7,
          selectedIndex: _selectedTab,
          icon: YhIcons.info,
          label: '关于',
          onTap: () => setState(() => _selectedTab = 7),
        ),
      ],
    );
  }

  Widget _buildSettingsDivider(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.s,
        horizontal: theme.spacing.s,
      ),
      child: SizedBox(
        height: theme.layout.divider,
        width: double.infinity,
        child: ColoredBox(color: theme.color.border),
      ),
    );
  }

  /// 窄屏顶部下拉。
  Widget _buildSettingsTabCombo(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      children: [
        Icon(YhIcons.menu, size: theme.spacing.l, color: theme.color.muted),
        SizedBox(width: theme.spacing.s),
        Expanded(
          child: YhSelect<int>(
            key: const Key('settings-narrow-tab-combo'),
            label: '设置分区',
            showLabel: false,
            value: _selectedTab,
            options: const [
              YhSelectOption(value: 0, label: '常规'),
              YhSelectOption(value: 1, label: '学期'),
              YhSelectOption(value: 2, label: '自动刷新'),
              YhSelectOption(value: 3, label: '安全'),
              YhSelectOption(value: 4, label: '职能部门'),
              YhSelectOption(value: 5, label: '教学单位'),
              YhSelectOption(value: 6, label: '微信推文'),
              YhSelectOption(value: 7, label: '关于'),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedTab = value);
            },
          ),
        ),
      ],
    );
  }

  /// 带动画的滚动内容区。
  Widget _buildScrollableContent(EdgeInsets padding) {
    final theme = context.yhTheme;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = theme.motion.effective(
      theme.motion.slow,
      disableAnimations: disableAnimations,
    );
    return SingleChildScrollView(
      primary: false,
      padding: padding,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: theme.motion.curve,
        switchOutCurve: theme.motion.curve,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_selectedTab),
          child: _buildContentPanel(context),
        ),
      ),
    );
  }

  /// 根据分区索引切换内容。
  Widget _buildContentPanel(BuildContext context) {
    switch (_selectedTab) {
      case 0:
        return SettingsGeneralSection(
          closeBehavior: _closeBehavior,
          notificationEnabled: _notificationEnabled,
          dndEnabled: _dndEnabled,
          homeStudentProfileCardVisible: _homeStudentProfileCardVisible,
          homeCampusCardBalanceCardVisible: _homeCampusCardBalanceCardVisible,
          homeTodayCoursesTileVisible: _homeTodayCoursesTileVisible,
          homeSportsAttendanceTileVisible: _homeSportsAttendanceTileVisible,
          homeStudentReportTileVisible: _homeStudentReportTileVisible,
          homeMessagesTileVisible: _homeMessagesTileVisible,
          homeEmailTileVisible: _homeEmailTileVisible,
          homeQuickLinksTileVisible: _homeQuickLinksTileVisible,
          dndStartHour: _dndStartHour,
          dndStartMinute: _dndStartMinute,
          dndEndHour: _dndEndHour,
          dndEndMinute: _dndEndMinute,
          onCloseBehaviorChanged: _onCloseBehaviorChanged,
          onNotificationChanged: _onNotificationChanged,
          onDndChanged: _onDndChanged,
          onHomeStudentProfileCardVisibleChanged:
              _onHomeStudentProfileCardVisibleChanged,
          onHomeCampusCardBalanceCardVisibleChanged:
              _onHomeCampusCardBalanceCardVisibleChanged,
          onHomeTodayCoursesTileVisibleChanged:
              _onHomeTodayCoursesTileVisibleChanged,
          onHomeSportsAttendanceTileVisibleChanged:
              _onHomeSportsAttendanceTileVisibleChanged,
          onHomeStudentReportTileVisibleChanged:
              _onHomeStudentReportTileVisibleChanged,
          onHomeMessagesTileVisibleChanged: _onHomeMessagesTileVisibleChanged,
          onHomeEmailTileVisibleChanged: _onHomeEmailTileVisibleChanged,
          onHomeQuickLinksTileVisibleChanged:
              _onHomeQuickLinksTileVisibleChanged,
          onDndStartChanged: _onDndStartChanged,
          onDndEndChanged: _onDndEndChanged,
        );
      case 1:
        return SettingsAcademicTermSection(
          now: widget.academicTermNow,
          onOpenAcademicCalendar: _openAcademicCalendar,
        );
      case 2:
        return SettingsAutoRefreshSection(
          campusNetworkDetectionIntervalMinutes:
              _campusNetworkDetectionIntervalMinutes,
          onCampusNetworkDetectionIntervalChanged:
              _onCampusNetworkDetectionIntervalChanged,
          sportsAttendanceAutoRefreshEnabled:
              _sportsAttendanceAutoRefreshEnabled,
          sportsAttendanceAutoRefreshIntervalMinutes:
              _sportsAttendanceAutoRefreshIntervalMinutes,
          onSportsAttendanceAutoRefreshChanged:
              _onSportsAttendanceAutoRefreshChanged,
          onSportsAttendanceAutoRefreshIntervalChanged:
              _onSportsAttendanceAutoRefreshIntervalChanged,
          campusCardAutoRefreshEnabled: _campusCardAutoRefreshEnabled,
          campusCardAutoRefreshIntervalMinutes:
              _campusCardAutoRefreshIntervalMinutes,
          onCampusCardAutoRefreshChanged: _onCampusCardAutoRefreshChanged,
          onCampusCardAutoRefreshIntervalChanged:
              _onCampusCardAutoRefreshIntervalChanged,
          emailAutoRefreshEnabled: _emailAutoRefreshEnabled,
          emailAutoRefreshIntervalMinutes: _emailAutoRefreshIntervalMinutes,
          onEmailAutoRefreshChanged: _onEmailAutoRefreshChanged,
          onEmailAutoRefreshIntervalChanged: _onEmailAutoRefreshIntervalChanged,
          studentReportAutoRefreshEnabled: _studentReportAutoRefreshEnabled,
          studentReportAutoRefreshIntervalMinutes:
              _studentReportAutoRefreshIntervalMinutes,
          onStudentReportAutoRefreshChanged: _onStudentReportAutoRefreshChanged,
          onStudentReportAutoRefreshIntervalChanged:
              _onStudentReportAutoRefreshIntervalChanged,
          academicEamsAutoRefreshEnabled: _academicEamsAutoRefreshEnabled,
          academicEamsAutoRefreshIntervalMinutes:
              _academicEamsAutoRefreshIntervalMinutes,
          onAcademicEamsAutoRefreshChanged: _onAcademicEamsAutoRefreshChanged,
          onAcademicEamsAutoRefreshIntervalChanged:
              _onAcademicEamsAutoRefreshIntervalChanged,
          onOpenDepartmentRefreshSettings: () =>
              setState(() => _selectedTab = 4),
          onOpenTeachingRefreshSettings: () => setState(() => _selectedTab = 5),
          onOpenWechatRefreshSettings: () => setState(() => _selectedTab = 6),
        );
      case 3:
        return SettingsSecuritySection(
          isPasswordEnabled: _isPasswordEnabled,
          onPasswordProtectionChanged: _onPasswordProtectionChanged,
          onChangePassword: _onChangePassword,
          isQuickAuthEnabled: _isQuickAuthEnabled,
          isQuickAuthAvailable: _isQuickAuthAvailable,
          isQuickAuthBusy: _isQuickAuthBusy,
          onQuickAuthChanged: _onQuickAuthChanged,
          onLock: widget.onLock,
          onClearMessageCache: _showClearMessageCacheDialog,
          onClearAllData: _showClearAllDataDialog,
        );
      case 4:
        return ChannelListSection(
          key: const ValueKey('department'),
          title: '职能部门',
          channels: departmentChannels,
        );
      case 5:
        return ChannelListSection(
          key: const ValueKey('teaching'),
          title: '教学单位',
          channels: teachingChannels,
        );
      case 6:
        return const SettingsWechatSection();
      case 7:
        return const AboutSettingsSection();
      default:
        return const SizedBox.shrink();
    }
  }
}
