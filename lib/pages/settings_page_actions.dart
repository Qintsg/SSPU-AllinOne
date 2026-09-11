/*
 * 设置页操作逻辑 — 加载设置、保存偏好与执行安全动作
 * @Project : SSPU-AllinOne
 * @File : settings_page_actions.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'settings_page.dart';

mixin _SettingsPageActions on State<SettingsPage> {
  bool get _isPasswordEnabled;
  set _isPasswordEnabled(bool value);

  bool get _isQuickAuthEnabled;
  set _isQuickAuthEnabled(bool value);

  bool get _isQuickAuthAvailable;
  set _isQuickAuthAvailable(bool value);

  bool get _isQuickAuthBusy;
  set _isQuickAuthBusy(bool value);

  set _isLoading(bool value);

  String get _closeBehavior;
  set _closeBehavior(String value);

  bool get _notificationEnabled;
  set _notificationEnabled(bool value);

  bool get _messageNotificationEnabled;
  set _messageNotificationEnabled(bool value);

  NotificationPermissionStatus get _notificationPermissionStatus;
  set _notificationPermissionStatus(NotificationPermissionStatus value);

  bool get _dndEnabled;
  set _dndEnabled(bool value);

  bool get _courseReminderEnabled;
  set _courseReminderEnabled(bool value);

  int get _courseReminderLeadMinutes;
  set _courseReminderLeadMinutes(int value);

  bool get _examReminderEnabled;
  set _examReminderEnabled(bool value);

  int get _examReminderLeadMinutes;
  set _examReminderLeadMinutes(int value);

  bool get _homeStudentProfileCardVisible;
  set _homeStudentProfileCardVisible(bool value);

  bool get _homeCampusCardBalanceCardVisible;
  set _homeCampusCardBalanceCardVisible(bool value);

  bool get _homeTodayCoursesTileVisible;
  set _homeTodayCoursesTileVisible(bool value);

  bool get _homeSportsAttendanceTileVisible;
  set _homeSportsAttendanceTileVisible(bool value);

  bool get _homeStudentReportTileVisible;
  set _homeStudentReportTileVisible(bool value);

  bool get _homeMessagesTileVisible;
  set _homeMessagesTileVisible(bool value);

  bool get _homeEmailTileVisible;
  set _homeEmailTileVisible(bool value);

  bool get _homeQuickLinksTileVisible;
  set _homeQuickLinksTileVisible(bool value);

  List<HomeOverviewItem> get _homeOverviewOrder;
  set _homeOverviewOrder(List<HomeOverviewItem> value);

  Map<CampusDataModule, bool> get _dataModuleFetchEnabled;
  set _dataModuleFetchEnabled(Map<CampusDataModule, bool> value);

  int get _dndStartHour;
  set _dndStartHour(int value);

  int get _dndStartMinute;
  set _dndStartMinute(int value);

  int get _dndEndHour;
  set _dndEndHour(int value);

  int get _dndEndMinute;
  set _dndEndMinute(int value);

  int get _campusNetworkDetectionIntervalMinutes;
  set _campusNetworkDetectionIntervalMinutes(int value);

  int get _dataAutoRefreshIntervalMinutes;
  set _dataAutoRefreshIntervalMinutes(int value);

  bool get _sportsAttendanceAutoRefreshEnabled;
  set _sportsAttendanceAutoRefreshEnabled(bool value);

  bool get _campusCardAutoRefreshEnabled;
  set _campusCardAutoRefreshEnabled(bool value);

  bool get _emailAutoRefreshEnabled;
  set _emailAutoRefreshEnabled(bool value);

  bool get _studentReportAutoRefreshEnabled;
  set _studentReportAutoRefreshEnabled(bool value);

  bool get _academicEamsAutoRefreshEnabled;
  set _academicEamsAutoRefreshEnabled(bool value);

  MessageStateService get _messageState;

  /// 加载页面级设置状态。
  Future<void> _loadSettings() async {
    final isSet = await PasswordService.isPasswordSet();
    final quickAuthEnabled = await PasswordService.isQuickAuthEnabled();
    final quickAuthAvailable = await SystemAuthService.instance.isAvailable();
    final behavior = await StorageService.getCloseBehavior();
    await _messageState.init();

    final notifEnabled = await _messageState.isNotificationEnabled();
    final messageNotifEnabled = await _messageState
        .isMessageNotificationEnabled();
    final permissionStatus = await NotificationService.instance
        .permissionStatus();
    final dndOn = await _messageState.isDndEnabled();
    final courseReminderEnabled = await _messageState.isCourseReminderEnabled();
    final examReminderEnabled = await _messageState.isExamReminderEnabled();
    final courseReminderLeadMinutes = await _messageState
        .getCourseReminderLeadMinutes();
    final examReminderLeadMinutes = await _messageState
        .getExamReminderLeadMinutes();
    final homeStudentProfileCardVisible = await StorageService.getBool(
      StorageKeys.homeStudentProfileCardVisible,
      defaultValue: true,
    );
    final homeCampusCardBalanceCardVisible = await StorageService.getBool(
      StorageKeys.homeCampusCardBalanceCardVisible,
      defaultValue: true,
    );
    final homeTodayCoursesTileVisible = await StorageService.getBool(
      StorageKeys.homeTodayCoursesTileVisible,
      defaultValue: true,
    );
    final homeSportsAttendanceTileVisible = await StorageService.getBool(
      StorageKeys.homeSportsAttendanceTileVisible,
      defaultValue: true,
    );
    final homeStudentReportTileVisible = await StorageService.getBool(
      StorageKeys.homeStudentReportTileVisible,
      defaultValue: true,
    );
    final homeMessagesTileVisible = await StorageService.getBool(
      StorageKeys.homeMessagesTileVisible,
      defaultValue: true,
    );
    final homeEmailTileVisible = await StorageService.getBool(
      StorageKeys.homeEmailTileVisible,
      defaultValue: true,
    );
    final homeQuickLinksTileVisible = await StorageService.getBool(
      StorageKeys.homeQuickLinksTileVisible,
      defaultValue: true,
    );
    final homeOverviewOrder = await HomeDashboardPreferences.instance
        .getOverviewOrder();
    final dataModuleFetchEnabled = await DataModulePreferences.instance
        .readAll();
    final dndStartHour = await _messageState.getDndStartHour();
    final dndStartMinute = await _messageState.getDndStartMinute();
    final dndEndHour = await _messageState.getDndEndHour();
    final dndEndMinute = await _messageState.getDndEndMinute();
    final campusNetworkDetectionInterval = await CampusNetworkStatusService
        .instance
        .getDetectionIntervalMinutes();
    final dataAutoRefreshInterval = await DataAutoRefreshPreferences.instance
        .getIntervalMinutes();
    final sportsAttendanceAutoRefreshEnabled = await SportsAttendanceService
        .instance
        .isAutoRefreshEnabled();
    final campusCardAutoRefreshEnabled = await CampusCardService.instance
        .isAutoRefreshEnabled();
    final emailAutoRefreshEnabled = await EmailService.instance
        .isAutoRefreshEnabled();
    final studentReportAutoRefreshEnabled = await StudentReportService.instance
        .isAutoRefreshEnabled();
    final academicEamsAutoRefreshEnabled = await AcademicEamsService.instance
        .isAutoRefreshEnabled();

    if (!mounted) return;
    setState(() {
      _isPasswordEnabled = isSet;
      _isQuickAuthEnabled = isSet && quickAuthAvailable && quickAuthEnabled;
      _isQuickAuthAvailable = quickAuthAvailable;
      _closeBehavior = behavior;
      _notificationEnabled = notifEnabled;
      _messageNotificationEnabled = messageNotifEnabled;
      _notificationPermissionStatus = permissionStatus;
      _dndEnabled = dndOn;
      _courseReminderEnabled = courseReminderEnabled;
      _examReminderEnabled = examReminderEnabled;
      _courseReminderLeadMinutes = courseReminderLeadMinutes;
      _examReminderLeadMinutes = examReminderLeadMinutes;
      _homeStudentProfileCardVisible = homeStudentProfileCardVisible;
      _homeCampusCardBalanceCardVisible = homeCampusCardBalanceCardVisible;
      _homeTodayCoursesTileVisible = homeTodayCoursesTileVisible;
      _homeSportsAttendanceTileVisible = homeSportsAttendanceTileVisible;
      _homeStudentReportTileVisible = homeStudentReportTileVisible;
      _homeMessagesTileVisible = homeMessagesTileVisible;
      _homeEmailTileVisible = homeEmailTileVisible;
      _homeQuickLinksTileVisible = homeQuickLinksTileVisible;
      _homeOverviewOrder = homeOverviewOrder;
      _dataModuleFetchEnabled = dataModuleFetchEnabled;
      _dndStartHour = dndStartHour;
      _dndStartMinute = dndStartMinute;
      _dndEndHour = dndEndHour;
      _dndEndMinute = dndEndMinute;
      _campusNetworkDetectionIntervalMinutes = campusNetworkDetectionInterval;
      _dataAutoRefreshIntervalMinutes = dataAutoRefreshInterval;
      _sportsAttendanceAutoRefreshEnabled = sportsAttendanceAutoRefreshEnabled;
      _campusCardAutoRefreshEnabled = campusCardAutoRefreshEnabled;
      _emailAutoRefreshEnabled = emailAutoRefreshEnabled;
      _studentReportAutoRefreshEnabled = studentReportAutoRefreshEnabled;
      _academicEamsAutoRefreshEnabled = academicEamsAutoRefreshEnabled;
      _isLoading = false;
    });
  }

  /// 显示操作成功提示。
  void _showSuccessBar(String message) {
    showYhFeedback(
      context,
      message: message,
      severity: AppFeedbackSeverity.success,
    );
  }

  /// 显示操作失败提示。
  void _showErrorBar(String message) {
    showYhFeedback(
      context,
      message: message,
      severity: AppFeedbackSeverity.error,
    );
  }

  /// 修改关闭按钮行为。
  Future<void> _onCloseBehaviorChanged(String behavior) async {
    await StorageService.setCloseBehavior(behavior);
    if (!mounted) return;
    setState(() => _closeBehavior = behavior);
  }

  /// 修改消息推送总开关。
  Future<void> _onNotificationChanged(bool enabled) async {
    if (enabled && !await NotificationService.instance.requestPermission()) {
      if (mounted) _showErrorBar('系统通知权限未开启，无法启用消息推送');
      return;
    }
    await _messageState.setNotificationEnabled(enabled);
    if (!mounted) return;
    final permissionStatus = await NotificationService.instance
        .permissionStatus();
    if (!mounted) return;
    setState(() {
      _notificationEnabled = enabled;
      _notificationPermissionStatus = permissionStatus;
    });
    unawaited(AcademicReminderCoordinator.instance.requestSync());
  }

  /// 重新查询系统通知权限并刷新设置页说明。
  Future<void> _refreshNotificationPermission() async {
    final permissionStatus = await NotificationService.instance
        .permissionStatus();
    if (!mounted) return;
    setState(() => _notificationPermissionStatus = permissionStatus);
  }

  /// 修改普通校园消息通知开关。
  Future<void> _onMessageNotificationChanged(bool enabled) async {
    if (enabled && !await NotificationService.instance.requestPermission()) {
      if (mounted) _showErrorBar('系统通知权限未开启，无法启用普通消息通知');
      return;
    }
    await _messageState.setMessageNotificationEnabled(enabled);
    if (!mounted) return;
    final permissionStatus = await NotificationService.instance
        .permissionStatus();
    if (!mounted) return;
    setState(() {
      _messageNotificationEnabled = enabled;
      _notificationPermissionStatus = permissionStatus;
    });
  }

  /// 修改勿扰模式开关。
  Future<void> _onDndChanged(bool enabled) async {
    await _messageState.setDndEnabled(enabled);
    if (!mounted) return;
    setState(() => _dndEnabled = enabled);
    unawaited(AcademicReminderCoordinator.instance.requestSync());
  }

  /// 修改课程提醒开关，并在首次启用时请求系统通知权限。
  Future<void> _onCourseReminderChanged(bool enabled) async {
    if (enabled && !await NotificationService.instance.requestPermission()) {
      if (mounted) _showErrorBar('系统通知权限未开启，无法启用课程提醒');
      return;
    }
    await _messageState.setCourseReminderEnabled(enabled);
    if (!mounted) return;
    setState(() => _courseReminderEnabled = enabled);
    unawaited(AcademicReminderCoordinator.instance.requestSync());
  }

  /// 修改考试提醒开关，并在首次启用时请求系统通知权限。
  Future<void> _onExamReminderChanged(bool enabled) async {
    if (enabled && !await NotificationService.instance.requestPermission()) {
      if (mounted) _showErrorBar('系统通知权限未开启，无法启用考试提醒');
      return;
    }
    await _messageState.setExamReminderEnabled(enabled);
    if (!mounted) return;
    setState(() => _examReminderEnabled = enabled);
    unawaited(AcademicReminderCoordinator.instance.requestSync());
  }

  /// 修改课程提醒提前量，并立即按新时间重排提醒。
  Future<void> _onCourseReminderLeadMinutesChanged(int minutes) async {
    await _messageState.setCourseReminderLeadMinutes(minutes);
    if (!mounted) return;
    setState(() => _courseReminderLeadMinutes = minutes);
    unawaited(AcademicReminderCoordinator.instance.requestSync());
  }

  /// 修改考试提醒提前量，并立即按新时间重排提醒。
  Future<void> _onExamReminderLeadMinutesChanged(int minutes) async {
    await _messageState.setExamReminderLeadMinutes(minutes);
    if (!mounted) return;
    setState(() => _examReminderLeadMinutes = minutes);
    unawaited(AcademicReminderCoordinator.instance.requestSync());
  }

  /// 修改首页学籍信息卡片显示开关。
  Future<void> _onHomeStudentProfileCardVisibleChanged(bool visible) async {
    await StorageService.setBool(
      StorageKeys.homeStudentProfileCardVisible,
      visible,
    );
    if (!mounted) return;
    setState(() => _homeStudentProfileCardVisible = visible);
  }

  /// 修改首页校园卡余额卡片显示开关。
  Future<void> _onHomeCampusCardBalanceCardVisibleChanged(bool visible) async {
    await StorageService.setBool(
      StorageKeys.homeCampusCardBalanceCardVisible,
      visible,
    );
    if (!mounted) return;
    setState(() => _homeCampusCardBalanceCardVisible = visible);
  }

  /// 修改首页今日课程磁贴显示开关。
  Future<void> _onHomeTodayCoursesTileVisibleChanged(bool visible) async {
    await _setHomeTileVisible(
      StorageKeys.homeTodayCoursesTileVisible,
      visible,
      (value) => _homeTodayCoursesTileVisible = value,
    );
  }

  /// 修改首页体育考勤磁贴显示开关。
  Future<void> _onHomeSportsAttendanceTileVisibleChanged(bool visible) async {
    await _setHomeTileVisible(
      StorageKeys.homeSportsAttendanceTileVisible,
      visible,
      (value) => _homeSportsAttendanceTileVisible = value,
    );
  }

  /// 修改首页第二课堂磁贴显示开关。
  Future<void> _onHomeStudentReportTileVisibleChanged(bool visible) async {
    await _setHomeTileVisible(
      StorageKeys.homeStudentReportTileVisible,
      visible,
      (value) => _homeStudentReportTileVisible = value,
    );
  }

  /// 修改首页最新消息磁贴显示开关。
  Future<void> _onHomeMessagesTileVisibleChanged(bool visible) async {
    await _setHomeTileVisible(
      StorageKeys.homeMessagesTileVisible,
      visible,
      (value) => _homeMessagesTileVisible = value,
    );
  }

  /// 修改首页邮箱摘要磁贴显示开关。
  Future<void> _onHomeEmailTileVisibleChanged(bool visible) async {
    await _setHomeTileVisible(
      StorageKeys.homeEmailTileVisible,
      visible,
      (value) => _homeEmailTileVisible = value,
    );
  }

  /// 修改首页快速跳转磁贴显示开关。
  Future<void> _onHomeQuickLinksTileVisibleChanged(bool visible) async {
    await _setHomeTileVisible(
      StorageKeys.homeQuickLinksTileVisible,
      visible,
      (value) => _homeQuickLinksTileVisible = value,
    );
  }

  /// 保存首页服务摘要的展示顺序。
  Future<void> _onHomeOverviewOrderChanged(List<HomeOverviewItem> order) async {
    await HomeDashboardPreferences.instance.setOverviewOrder(order);
    if (!mounted) return;
    setState(() {
      _homeOverviewOrder = HomeDashboardPreferences.normalizeOverviewItems(
        order,
      );
    });
  }

  /// 修改模块级联网获取权限；显隐与自动刷新频率保持独立。
  Future<void> _onDataModuleFetchChanged(
    CampusDataModule module,
    bool enabled,
  ) async {
    await DataModulePreferences.instance.setFetchEnabled(module, enabled);
    if (!mounted) return;
    setState(() {
      _dataModuleFetchEnabled = {..._dataModuleFetchEnabled, module: enabled};
    });
    if (module == CampusDataModule.academicEams) {
      unawaited(AcademicReminderCoordinator.instance.requestSync());
    }
  }

  Future<void> _setHomeTileVisible(
    String key,
    bool visible,
    ValueChanged<bool> apply,
  ) async {
    await StorageService.setBool(key, visible);
    if (!mounted) return;
    setState(() => apply(visible));
  }

  /// 打开校历查看页。
  void _openAcademicCalendar() {
    Navigator.of(
      context,
    ).push(YhPageRoute<void>(builder: (_) => AcademicCalendarPage()));
  }

  /// 修改勿扰开始时间。
  Future<void> _onDndStartChanged(int hour, int minute) async {
    await _messageState.setDndTime(
      startHour: hour,
      startMinute: minute,
      endHour: _dndEndHour,
      endMinute: _dndEndMinute,
    );
    if (!mounted) return;
    setState(() {
      _dndStartHour = hour;
      _dndStartMinute = minute;
    });
    unawaited(AcademicReminderCoordinator.instance.requestSync());
  }

  /// 修改勿扰结束时间。
  Future<void> _onDndEndChanged(int hour, int minute) async {
    await _messageState.setDndTime(
      startHour: _dndStartHour,
      startMinute: _dndStartMinute,
      endHour: hour,
      endMinute: minute,
    );
    if (!mounted) return;
    setState(() {
      _dndEndHour = hour;
      _dndEndMinute = minute;
    });
    unawaited(AcademicReminderCoordinator.instance.requestSync());
  }

  /// 修改校园网 / VPN 状态检测间隔。
  Future<void> _onCampusNetworkDetectionIntervalChanged(int minutes) async {
    await CampusNetworkStatusService.instance.setDetectionIntervalMinutes(
      minutes,
    );
    if (!mounted) return;
    setState(() => _campusNetworkDetectionIntervalMinutes = minutes);
  }

  /// 修改全部校园数据来源共用的自动刷新间隔。
  ///
  /// :param minutes: 新的共享刷新间隔分钟数。
  /// :returns: 偏好保存并更新页面状态后结束。
  Future<void> _onDataAutoRefreshIntervalChanged(int minutes) async {
    await DataAutoRefreshPreferences.instance.setIntervalMinutes(minutes);
    if (!mounted) return;
    setState(() => _dataAutoRefreshIntervalMinutes = minutes);
  }

  /// 修改体育部课外活动考勤自动刷新开关。
  Future<void> _onSportsAttendanceAutoRefreshChanged(bool enabled) async {
    await SportsAttendanceService.instance.setAutoRefreshEnabled(enabled);
    if (!mounted) return;
    setState(() => _sportsAttendanceAutoRefreshEnabled = enabled);
  }

  /// 修改校园卡余额自动刷新开关。
  Future<void> _onCampusCardAutoRefreshChanged(bool enabled) async {
    await CampusCardService.instance.setAutoRefreshEnabled(enabled);
    if (!mounted) return;
    setState(() => _campusCardAutoRefreshEnabled = enabled);
  }

  /// 修改学校邮箱自动刷新开关。
  Future<void> _onEmailAutoRefreshChanged(bool enabled) async {
    await EmailService.instance.setAutoRefreshEnabled(enabled);
    if (!mounted) return;
    setState(() => _emailAutoRefreshEnabled = enabled);
  }

  /// 修改第二课堂学分自动刷新开关。
  Future<void> _onStudentReportAutoRefreshChanged(bool enabled) async {
    await StudentReportService.instance.setAutoRefreshEnabled(enabled);
    if (!mounted) return;
    setState(() => _studentReportAutoRefreshEnabled = enabled);
  }

  /// 修改本专科教务自动刷新开关。
  Future<void> _onAcademicEamsAutoRefreshChanged(bool enabled) async {
    await AcademicEamsService.instance.setAutoRefreshEnabled(enabled);
    if (!mounted) return;
    setState(() => _academicEamsAutoRefreshEnabled = enabled);
  }
}
