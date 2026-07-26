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

  bool get _dndEnabled;
  set _dndEnabled(bool value);

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

  bool get _sportsAttendanceAutoRefreshEnabled;
  set _sportsAttendanceAutoRefreshEnabled(bool value);

  int get _sportsAttendanceAutoRefreshIntervalMinutes;
  set _sportsAttendanceAutoRefreshIntervalMinutes(int value);

  bool get _campusCardAutoRefreshEnabled;
  set _campusCardAutoRefreshEnabled(bool value);

  int get _campusCardAutoRefreshIntervalMinutes;
  set _campusCardAutoRefreshIntervalMinutes(int value);

  bool get _emailAutoRefreshEnabled;
  set _emailAutoRefreshEnabled(bool value);

  int get _emailAutoRefreshIntervalMinutes;
  set _emailAutoRefreshIntervalMinutes(int value);

  bool get _studentReportAutoRefreshEnabled;
  set _studentReportAutoRefreshEnabled(bool value);

  int get _studentReportAutoRefreshIntervalMinutes;
  set _studentReportAutoRefreshIntervalMinutes(int value);

  bool get _academicEamsAutoRefreshEnabled;
  set _academicEamsAutoRefreshEnabled(bool value);

  int get _academicEamsAutoRefreshIntervalMinutes;
  set _academicEamsAutoRefreshIntervalMinutes(int value);

  MessageStateService get _messageState;

  /// 加载页面级设置状态。
  Future<void> _loadSettings() async {
    final isSet = await PasswordService.isPasswordSet();
    final quickAuthEnabled = await PasswordService.isQuickAuthEnabled();
    final quickAuthAvailable = await SystemAuthService.instance.isAvailable();
    final behavior = await StorageService.getCloseBehavior();
    await _messageState.init();

    final notifEnabled = await _messageState.isNotificationEnabled();
    final dndOn = await _messageState.isDndEnabled();
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
    final dndStartHour = await _messageState.getDndStartHour();
    final dndStartMinute = await _messageState.getDndStartMinute();
    final dndEndHour = await _messageState.getDndEndHour();
    final dndEndMinute = await _messageState.getDndEndMinute();
    final campusNetworkDetectionInterval = await CampusNetworkStatusService
        .instance
        .getDetectionIntervalMinutes();
    final sportsAttendanceAutoRefreshEnabled = await SportsAttendanceService
        .instance
        .isAutoRefreshEnabled();
    final sportsAttendanceAutoRefreshInterval = await SportsAttendanceService
        .instance
        .getAutoRefreshIntervalMinutes();
    final campusCardAutoRefreshEnabled = await CampusCardService.instance
        .isAutoRefreshEnabled();
    final campusCardAutoRefreshInterval = await CampusCardService.instance
        .getAutoRefreshIntervalMinutes();
    final emailAutoRefreshEnabled = await EmailService.instance
        .isAutoRefreshEnabled();
    final emailAutoRefreshInterval = await EmailService.instance
        .getAutoRefreshIntervalMinutes();
    final studentReportAutoRefreshEnabled = await StudentReportService.instance
        .isAutoRefreshEnabled();
    final studentReportAutoRefreshInterval = await StudentReportService.instance
        .getAutoRefreshIntervalMinutes();
    final academicEamsAutoRefreshEnabled = await AcademicEamsService.instance
        .isAutoRefreshEnabled();
    final academicEamsAutoRefreshInterval = await AcademicEamsService.instance
        .getAutoRefreshIntervalMinutes();

    if (!mounted) return;
    setState(() {
      _isPasswordEnabled = isSet;
      _isQuickAuthEnabled = isSet && quickAuthAvailable && quickAuthEnabled;
      _isQuickAuthAvailable = quickAuthAvailable;
      _closeBehavior = behavior;
      _notificationEnabled = notifEnabled;
      _dndEnabled = dndOn;
      _homeStudentProfileCardVisible = homeStudentProfileCardVisible;
      _homeCampusCardBalanceCardVisible = homeCampusCardBalanceCardVisible;
      _homeTodayCoursesTileVisible = homeTodayCoursesTileVisible;
      _homeSportsAttendanceTileVisible = homeSportsAttendanceTileVisible;
      _homeStudentReportTileVisible = homeStudentReportTileVisible;
      _homeMessagesTileVisible = homeMessagesTileVisible;
      _homeEmailTileVisible = homeEmailTileVisible;
      _homeQuickLinksTileVisible = homeQuickLinksTileVisible;
      _dndStartHour = dndStartHour;
      _dndStartMinute = dndStartMinute;
      _dndEndHour = dndEndHour;
      _dndEndMinute = dndEndMinute;
      _campusNetworkDetectionIntervalMinutes = campusNetworkDetectionInterval;
      _sportsAttendanceAutoRefreshEnabled = sportsAttendanceAutoRefreshEnabled;
      _sportsAttendanceAutoRefreshIntervalMinutes =
          sportsAttendanceAutoRefreshInterval;
      _campusCardAutoRefreshEnabled = campusCardAutoRefreshEnabled;
      _campusCardAutoRefreshIntervalMinutes = campusCardAutoRefreshInterval;
      _emailAutoRefreshEnabled = emailAutoRefreshEnabled;
      _emailAutoRefreshIntervalMinutes = emailAutoRefreshInterval;
      _studentReportAutoRefreshEnabled = studentReportAutoRefreshEnabled;
      _studentReportAutoRefreshIntervalMinutes =
          studentReportAutoRefreshInterval;
      _academicEamsAutoRefreshEnabled = academicEamsAutoRefreshEnabled;
      _academicEamsAutoRefreshIntervalMinutes = academicEamsAutoRefreshInterval;
      _isLoading = false;
    });
  }

  /// 显示操作成功提示。
  void _showSuccessBar(String message) {
    showAppFeedback(
      context,
      message: message,
      severity: AppFeedbackSeverity.success,
    );
  }

  /// 显示操作失败提示。
  void _showErrorBar(String message) {
    showAppFeedback(
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
    await _messageState.setNotificationEnabled(enabled);
    if (!mounted) return;
    setState(() => _notificationEnabled = enabled);
  }

  /// 修改勿扰模式开关。
  Future<void> _onDndChanged(bool enabled) async {
    await _messageState.setDndEnabled(enabled);
    if (!mounted) return;
    setState(() => _dndEnabled = enabled);
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
  }

  /// 修改校园网 / VPN 状态检测间隔。
  Future<void> _onCampusNetworkDetectionIntervalChanged(int minutes) async {
    await CampusNetworkStatusService.instance.setDetectionIntervalMinutes(
      minutes,
    );
    if (!mounted) return;
    setState(() => _campusNetworkDetectionIntervalMinutes = minutes);
  }

  /// 修改体育部课外活动考勤自动刷新开关。
  Future<void> _onSportsAttendanceAutoRefreshChanged(bool enabled) async {
    await SportsAttendanceService.instance.setAutoRefreshEnabled(enabled);
    if (!mounted) return;
    setState(() => _sportsAttendanceAutoRefreshEnabled = enabled);
  }

  /// 修改体育部课外活动考勤自动刷新间隔。
  Future<void> _onSportsAttendanceAutoRefreshIntervalChanged(
    int minutes,
  ) async {
    await SportsAttendanceService.instance.setAutoRefreshIntervalMinutes(
      minutes,
    );
    if (!mounted) return;
    setState(() => _sportsAttendanceAutoRefreshIntervalMinutes = minutes);
  }

  /// 修改校园卡余额自动刷新开关。
  Future<void> _onCampusCardAutoRefreshChanged(bool enabled) async {
    await CampusCardService.instance.setAutoRefreshEnabled(enabled);
    if (!mounted) return;
    setState(() => _campusCardAutoRefreshEnabled = enabled);
  }

  /// 修改校园卡余额自动刷新间隔。
  Future<void> _onCampusCardAutoRefreshIntervalChanged(int minutes) async {
    await CampusCardService.instance.setAutoRefreshIntervalMinutes(minutes);
    if (!mounted) return;
    setState(() => _campusCardAutoRefreshIntervalMinutes = minutes);
  }

  /// 修改学校邮箱自动刷新开关。
  Future<void> _onEmailAutoRefreshChanged(bool enabled) async {
    await EmailService.instance.setAutoRefreshEnabled(enabled);
    if (!mounted) return;
    setState(() => _emailAutoRefreshEnabled = enabled);
  }

  /// 修改学校邮箱自动刷新间隔。
  Future<void> _onEmailAutoRefreshIntervalChanged(int minutes) async {
    await EmailService.instance.setAutoRefreshIntervalMinutes(minutes);
    if (!mounted) return;
    setState(() => _emailAutoRefreshIntervalMinutes = minutes);
  }

  /// 修改第二课堂学分自动刷新开关。
  Future<void> _onStudentReportAutoRefreshChanged(bool enabled) async {
    await StudentReportService.instance.setAutoRefreshEnabled(enabled);
    if (!mounted) return;
    setState(() => _studentReportAutoRefreshEnabled = enabled);
  }

  /// 修改第二课堂学分自动刷新间隔。
  Future<void> _onStudentReportAutoRefreshIntervalChanged(int minutes) async {
    await StudentReportService.instance.setAutoRefreshIntervalMinutes(minutes);
    if (!mounted) return;
    setState(() => _studentReportAutoRefreshIntervalMinutes = minutes);
  }

  /// 修改本专科教务自动刷新开关。
  Future<void> _onAcademicEamsAutoRefreshChanged(bool enabled) async {
    await AcademicEamsService.instance.setAutoRefreshEnabled(enabled);
    if (!mounted) return;
    setState(() => _academicEamsAutoRefreshEnabled = enabled);
  }

  /// 修改本专科教务自动刷新间隔。
  Future<void> _onAcademicEamsAutoRefreshIntervalChanged(int minutes) async {
    await AcademicEamsService.instance.setAutoRefreshIntervalMinutes(minutes);
    if (!mounted) return;
    setState(() => _academicEamsAutoRefreshIntervalMinutes = minutes);
  }

  /// 切换密码保护。
  Future<void> _onPasswordProtectionChanged(bool enabled) async {
    if (enabled) {
      final ok = await showSetPasswordDialog(context);
      if (ok && mounted) {
        setState(() {
          _isPasswordEnabled = true;
          _isQuickAuthEnabled = false;
        });
        _showSuccessBar('密码已设置');
      }
      return;
    }

    final ok = await showRemovePasswordDialog(context);
    if (ok && mounted) {
      setState(() {
        _isPasswordEnabled = false;
        _isQuickAuthEnabled = false;
      });
      _showSuccessBar('密码保护已移除');
    }
  }

  /// 修改密码。
  Future<void> _onChangePassword() async {
    final ok = await showChangePasswordDialog(context);
    if (ok && mounted) {
      setState(() => _isQuickAuthEnabled = false);
      _showSuccessBar('密码已修改');
    }
  }

  /// 修改系统快速验证开关。
  Future<void> _onQuickAuthChanged(bool enabled) async {
    if (!_isPasswordEnabled || _isQuickAuthBusy) return;

    if (!enabled) {
      await PasswordService.setQuickAuthEnabled(false);
      if (!mounted) return;
      setState(() => _isQuickAuthEnabled = false);
      _showSuccessBar('系统快速验证已关闭');
      return;
    }

    if (!_isQuickAuthAvailable) {
      _showErrorBar('当前平台或设备不支持系统快速验证');
      return;
    }

    final passwordConfirmed = await showConfirmCurrentPasswordDialog(
      context,
      title: '启用系统快速验证',
      message: '请输入当前密码。通过后将调用系统认证完成启用确认。',
      confirmLabel: '继续',
    );
    if (!passwordConfirmed || !mounted) return;

    setState(() => _isQuickAuthBusy = true);
    final authResult = await SystemAuthService.instance.authenticate(
      localizedReason: '验证身份以启用 ${AppDisplayName.of(context)} 系统快速解锁',
    );
    if (!mounted) return;

    if (authResult == SystemAuthResult.success) {
      await PasswordService.setQuickAuthEnabled(true);
      if (!mounted) return;
      setState(() {
        _isQuickAuthEnabled = true;
        _isQuickAuthBusy = false;
      });
      _showSuccessBar('系统快速验证已启用');
      return;
    }

    await PasswordService.setQuickAuthEnabled(false);
    if (!mounted) return;
    setState(() {
      _isQuickAuthEnabled = false;
      _isQuickAuthBusy = false;
    });
    _showErrorBar('系统认证未完成，已保留手动密码解锁');
  }

  /// 清除校园业务缓存，保留账户连接和本机偏好。
  Future<bool> _showClearCampusCacheDialog() async {
    final confirmed = await YhDialog.confirm(
      context,
      title: '清除校园缓存',
      message:
          '将清除教务、课表、校园卡、体育、第二课堂、学校邮箱和信息中心的本地缓存。\n\n'
          '账户凭据、主题、通知、首页设置和关注列表会保留。',
      confirmText: '清除校园缓存',
      danger: true,
      barrierDismissible: false,
    );

    if (!confirmed) return false;
    const stages = ['校园业务缓存', '信息中心消息缓存', '信息中心已读状态'];
    final completed = <String>[];
    try {
      await AuthenticatedDataCacheService.clearAll();
      completed.add(stages[0]);
      await StorageService.remove(MessageChannelKeys.persistedMessages);
      completed.add(stages[1]);
      await StorageService.remove(MessageChannelKeys.readMessageIds);
      completed.add(stages[2]);
    } catch (_) {
      throw _dataPrivacyFailure(stages, completed);
    }
    if (mounted) {
      showAppFeedback(
        context,
        message: '校园缓存已清除',
        severity: AppFeedbackSeverity.success,
      );
    }
    return true;
  }

  /// 断开校园账户与微信公众号连接，保留普通偏好和信息中心缓存。
  Future<bool> _showDisconnectAccountsDialog() async {
    final confirmed = await YhDialog.confirm(
      context,
      title: '断开账户连接',
      message:
          '将移除 OA、体育、学校邮箱的本机凭据和登录会话，清除与账户关联的校园业务缓存，并清除微信公众号 Cookie 与 Token。\n\n'
          '主题、通知、首页设置、关注列表和信息中心缓存会保留。',
      confirmText: '断开连接',
      danger: true,
      barrierDismissible: false,
    );

    if (!confirmed) return false;
    const stages = ['OA、体育与邮箱凭据及校园业务缓存', '微信公众号连接'];
    final completed = <String>[];
    try {
      await AcademicCredentialsService.instance.clearAll();
      completed.add(stages[0]);
      await WxmpAuthService.instance.clearAuth();
      completed.add(stages[1]);
      if (mounted) _showSuccessBar('账户连接已断开');
      return true;
    } catch (_) {
      if (mounted) {
        _showErrorBar('断开失败，请确认系统安全存储和本机配置可用');
      }
      throw _dataPrivacyFailure(stages, completed);
    }
  }

  /// 清除所有本地数据并退出。
  Future<bool> _showClearAllDataDialog() async {
    final confirmed = await YhDialog.confirm(
      context,
      title: '确认清除本地数据',
      message:
          '将删除：OA、体育与邮箱凭据，微信连接，全部校园与信息缓存，以及主题、通知、首页和关注设置。\n\n'
          '不会删除：系统账户、设备生物识别信息和校园服务器上的数据。\n\n'
          '操作完成后应用会退出。',
      confirmText: '清除本地数据',
      danger: true,
      barrierDismissible: false,
    );

    if (!confirmed) return false;
    const stages = ['OA、体育与邮箱凭据及校园业务缓存', '微信公众号连接', '本机偏好与信息缓存', '退出应用'];
    final completed = <String>[];
    try {
      await AcademicCredentialsService.instance.clearAll();
      completed.add(stages[0]);
      await WxmpAuthService.instance.clearAuth();
      completed.add(stages[1]);
      await StorageService.clearAll();
      completed.add(stages[2]);
      await AppExitService.instance.exit();
      completed.add(stages[3]);
      return true;
    } catch (_) {
      if (mounted) {
        _showErrorBar('清除失败，请确认系统安全存储可用');
      }
      throw _dataPrivacyFailure(stages, completed);
    }
  }

  SettingsDataPrivacyOperationException _dataPrivacyFailure(
    List<String> stages,
    List<String> completed,
  ) {
    return SettingsDataPrivacyOperationException(
      completedItems: List.unmodifiable(completed),
      remainingItems: List.unmodifiable(
        stages.where((stage) => !completed.contains(stage)),
      ),
    );
  }

  Future<SettingsDataPrivacySnapshot> _loadDataPrivacySnapshot() async {
    final hasCampusCache = await AuthenticatedDataCacheService.hasAny();
    final persistedMessages = await StorageService.getString(
      MessageChannelKeys.persistedMessages,
    );
    final readMessageIds = await StorageService.getString(
      MessageChannelKeys.readMessageIds,
    );
    final hasMessageCache =
        persistedMessages?.isNotEmpty == true ||
        readMessageIds?.isNotEmpty == true;
    final credentials = await AcademicCredentialsService.instance.getStatus();
    final wxmp = await WxmpAuthService.instance.getAuthStatus();
    final connections = <String>[
      if (credentials.hasOaPassword) 'OA',
      if (credentials.hasSportsQueryPassword) '体育',
      if (credentials.hasEmailPassword) '邮箱',
      if (wxmp.isUsable) '微信',
    ];
    final cacheStatus = switch ((hasCampusCache, hasMessageCache)) {
      (true, true) => '已保存校园与信息缓存',
      (true, false) => '已保存校园业务缓存',
      (false, true) => '已保存信息中心缓存',
      (false, false) => '当前无校园或信息缓存',
    };
    return SettingsDataPrivacySnapshot(
      cacheStatus: cacheStatus,
      accountStatus: connections.isEmpty
          ? '当前未连接账户'
          : '已连接：${connections.join('、')}',
      privacyStatus: '随应用提供，可离线查看',
    );
  }
}
