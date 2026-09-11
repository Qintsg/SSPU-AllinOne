/*
 * 设置页布局 — 响应式导航与设置分区内容切换
 * @Project : SSPU-AllinOne
 * @File : settings_page_layout.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'settings_page.dart';

mixin _SettingsPageLayout
    on
        State<SettingsPage>,
        _SettingsPageActions,
        _SettingsPageSecurityPrivacyActions {
  int get _selectedTab;
  set _selectedTab(int value);

  final FocusNode _settingsSectionTriggerFocusNode = FocusNode(
    debugLabel: 'Settings section trigger',
  );

  static const _settingsSections = <({String label, IconData icon})>[
    (label: '常规', icon: YhIcons.settings),
    (label: '学期', icon: YhIcons.calendar),
    (label: '自动刷新', icon: YhIcons.sync),
    (label: '安全', icon: YhIcons.lock),
    (label: '职能部门', icon: YhIcons.education),
    (label: '教学单位', icon: YhIcons.library),
    (label: '微信推文', icon: YhIcons.chat),
    (label: '关于', icon: YhIcons.info),
  ];

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
            child: _buildSettingsNavigationWidget(
              context: context,
              selectedIndex: _selectedTab,
              onSelect: (index) => setState(() => _selectedTab = index),
            ),
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
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: theme.breakpoint.medium),
              child: _buildScrollableContent(
                EdgeInsets.symmetric(
                  horizontal: theme.spacing.l,
                  vertical: theme.spacing.s,
                ),
              ),
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
          child: _buildSettingsTabCombo(
            context: context,
            selectedIndex: _selectedTab,
            sections: _settingsSections,
            focusNode: _settingsSectionTriggerFocusNode,
            onOpenDrawer: () => _showSettingsSectionDrawer(context),
          ),
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

  /// 中屏使用顶部页签，避免左侧导航挤压内容。
  Widget _buildMediumSettingsLayout(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.l),
          child: YhTabs<int>(
            key: const Key('settings-medium-tabs'),
            value: _selectedTab,
            tabs: [
              for (var index = 0; index < _settingsSections.length; index++)
                YhTab<int>(value: index, label: _settingsSections[index].label),
            ],
            onChanged: (value) => setState(() => _selectedTab = value),
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

  /// 打开紧凑端设置分区抽屉并在关闭后归还焦点。
  Future<void> _showSettingsSectionDrawer(BuildContext context) async {
    await YhBottomDrawer.show<void>(
      context,
      title: '设置分区',
      builder: (drawerContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < _settingsSections.length; index++) ...[
            buildSettingsNavItem(
              context: drawerContext,
              index: index,
              selectedIndex: _selectedTab,
              icon: _settingsSections[index].icon,
              label: _settingsSections[index].label,
              autofocus: index == _selectedTab,
              onTap: () {
                Navigator.of(drawerContext).pop();
                if (mounted) setState(() => _selectedTab = index);
              },
            ),
            if (index < _settingsSections.length - 1)
              SizedBox(height: drawerContext.yhTheme.spacing.xs),
          ],
        ],
      ),
    );
    if (mounted) _settingsSectionTriggerFocusNode.requestFocus();
  }

  void disposeSettingsNavigation() {
    _settingsSectionTriggerFocusNode.dispose();
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
          themeMode: widget.themeMode,
          onOpenAppearance: widget.onThemeModeChanged == null
              ? null
              : _openAppearanceSettings,
          onOpenUpdate: _openUpdateSettings,
          closeBehavior: _closeBehavior,
          notificationEnabled: _notificationEnabled,
          messageNotificationEnabled: _messageNotificationEnabled,
          notificationPermissionStatus: _notificationPermissionStatus,
          dndEnabled: _dndEnabled,
          courseReminderEnabled: _courseReminderEnabled,
          examReminderEnabled: _examReminderEnabled,
          courseReminderLeadMinutes: _courseReminderLeadMinutes,
          examReminderLeadMinutes: _examReminderLeadMinutes,
          homeStudentProfileCardVisible: _homeStudentProfileCardVisible,
          homeCampusCardBalanceCardVisible: _homeCampusCardBalanceCardVisible,
          homeTodayCoursesTileVisible: _homeTodayCoursesTileVisible,
          homeSportsAttendanceTileVisible: _homeSportsAttendanceTileVisible,
          homeStudentReportTileVisible: _homeStudentReportTileVisible,
          homeMessagesTileVisible: _homeMessagesTileVisible,
          homeEmailTileVisible: _homeEmailTileVisible,
          homeQuickLinksTileVisible: _homeQuickLinksTileVisible,
          homeOverviewOrder: _homeOverviewOrder,
          dataModuleFetchEnabled: _dataModuleFetchEnabled,
          dndStartHour: _dndStartHour,
          dndStartMinute: _dndStartMinute,
          dndEndHour: _dndEndHour,
          dndEndMinute: _dndEndMinute,
          onCloseBehaviorChanged: _onCloseBehaviorChanged,
          onNotificationChanged: _onNotificationChanged,
          onMessageNotificationChanged: _onMessageNotificationChanged,
          onNotificationPermissionRefresh: () =>
              unawaited(_refreshNotificationPermission()),
          onDndChanged: _onDndChanged,
          onCourseReminderChanged: _onCourseReminderChanged,
          onExamReminderChanged: _onExamReminderChanged,
          onCourseReminderLeadMinutesChanged:
              _onCourseReminderLeadMinutesChanged,
          onExamReminderLeadMinutesChanged: _onExamReminderLeadMinutesChanged,
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
          onHomeOverviewOrderChanged: _onHomeOverviewOrderChanged,
          onDataModuleFetchChanged: _onDataModuleFetchChanged,
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
          dataAutoRefreshIntervalMinutes: _dataAutoRefreshIntervalMinutes,
          onCampusNetworkDetectionIntervalChanged:
              _onCampusNetworkDetectionIntervalChanged,
          onDataAutoRefreshIntervalChanged: _onDataAutoRefreshIntervalChanged,
          sportsAttendanceAutoRefreshEnabled:
              _sportsAttendanceAutoRefreshEnabled,
          onSportsAttendanceAutoRefreshChanged:
              _onSportsAttendanceAutoRefreshChanged,
          campusCardAutoRefreshEnabled: _campusCardAutoRefreshEnabled,
          onCampusCardAutoRefreshChanged: _onCampusCardAutoRefreshChanged,
          emailAutoRefreshEnabled: _emailAutoRefreshEnabled,
          onEmailAutoRefreshChanged: _onEmailAutoRefreshChanged,
          studentReportAutoRefreshEnabled: _studentReportAutoRefreshEnabled,
          onStudentReportAutoRefreshChanged: _onStudentReportAutoRefreshChanged,
          academicEamsAutoRefreshEnabled: _academicEamsAutoRefreshEnabled,
          onAcademicEamsAutoRefreshChanged: _onAcademicEamsAutoRefreshChanged,
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
          onOpenDataPrivacy: _openDataPrivacySettings,
          credentialsStatusLoader: widget.credentialsStatusLoaderForTesting,
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
        return SettingsAboutSummary(onOpenDetails: _openAboutSettings);
      default:
        return const SizedBox.shrink();
    }
  }

  void _openAppearanceSettings() {
    Navigator.of(context).push(
      YhPageRoute<void>(
        builder: (_) => SettingsAppearancePage(
          themeMode: widget.themeMode,
          onChanged: widget.onThemeModeChanged,
          onApply: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }

  void _openDataPrivacySettings() {
    Navigator.of(context).push(
      YhPageRoute<void>(
        builder: (_) => SettingsDataPrivacyPage(
          onClearCampusCache: _showClearCampusCacheDialog,
          onDisconnectAccounts: _showDisconnectAccountsDialog,
          onClearAllData: _showClearAllDataDialog,
          loadSnapshot: _loadDataPrivacySnapshot,
          onOpenPrivacy: () => Navigator.of(context).push(
            YhPageRoute<void>(
              builder: (_) => LegalNoticePage(
                title: '隐私说明',
                kicker: '法律与隐私',
                summary: '按数据类型说明收集目的、存储位置、联网时机和删除方式。',
                primaryActionLabel: '返回数据与隐私',
                onPrimaryAction: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openUpdateSettings() {
    Navigator.of(
      context,
    ).push(YhPageRoute<void>(builder: (_) => const SettingsUpdatePage()));
  }

  void _openAboutSettings() {
    Navigator.of(
      context,
    ).push(YhPageRoute<void>(builder: (_) => const SettingsAboutPage()));
  }
}
