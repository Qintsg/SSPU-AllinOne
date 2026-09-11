/*
 * 设置、反馈、频道与微信配置回归测试
 * @Project : SSPU-AllinOne
 * @File : widget_test_settings.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'widget_test.dart';

/// 注册设置、反馈、频道与微信配置测试。
///
/// :returns: 无返回值。
void _registerSettingsTests() {
  testWidgets('自动刷新设置分区使用一个共享时长并在窄屏完整显示文本', (WidgetTester tester) async {
    var selectedShortcut = 0;
    await tester.binding.setSurfaceSize(const Size(360, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      YhApp(
        home: YhPageScaffold(
          body: SingleChildScrollView(
            child: SettingsAutoRefreshSection(
              campusNetworkDetectionIntervalMinutes: 15,
              dataAutoRefreshIntervalMinutes: 30,
              sportsAttendanceAutoRefreshEnabled: true,
              campusCardAutoRefreshEnabled: true,
              emailAutoRefreshEnabled: true,
              studentReportAutoRefreshEnabled: true,
              academicEamsAutoRefreshEnabled: true,
              onCampusNetworkDetectionIntervalChanged: (_) async {},
              onDataAutoRefreshIntervalChanged: (_) async {},
              onSportsAttendanceAutoRefreshChanged: (_) async {},
              onCampusCardAutoRefreshChanged: (_) async {},
              onEmailAutoRefreshChanged: (_) async {},
              onStudentReportAutoRefreshChanged: (_) async {},
              onAcademicEamsAutoRefreshChanged: (_) async {},
              onOpenDepartmentRefreshSettings: () => selectedShortcut = 3,
              onOpenTeachingRefreshSettings: () => selectedShortcut = 4,
              onOpenWechatRefreshSettings: () => selectedShortcut = 5,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('校园网 / VPN 状态检测'), findsOneWidget);
    expect(find.text('统一刷新频率'), findsOneWidget);
    expect(find.text('体育考勤'), findsOneWidget);
    expect(find.text('校园卡余额'), findsOneWidget);
    expect(find.text('学校邮箱'), findsOneWidget);
    expect(find.text('第二课堂'), findsOneWidget);
    expect(find.text('本专科教务'), findsOneWidget);
    expect(find.text('15 分钟'), findsOneWidget);
    expect(find.text('30 分钟'), findsOneWidget);
    expect(find.text('职能部门'), findsOneWidget);
    expect(find.text('教学单位'), findsOneWidget);
    expect(find.text('微信推文'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('管理').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('管理').first);
    await tester.pump(const Duration(milliseconds: 150));
    expect(selectedShortcut, 3);
  });

  testWidgets('常规设置分区显示首页业务卡片开关', (WidgetTester tester) async {
    var studentVisible = true;
    var campusCardVisible = true;
    var todayCoursesVisible = true;
    var sportsVisible = true;
    var studentReportVisible = true;
    var messagesVisible = true;
    var emailVisible = true;
    var quickLinksVisible = true;
    var messageNotificationEnabled = true;
    var courseReminderEnabled = false;
    var examReminderEnabled = false;
    var courseReminderLeadMinutes = 15;
    var examReminderLeadMinutes = 24 * 60;
    var overviewOrder = HomeDashboardPreferences.defaultOverviewOrder;
    var fetchEnabled = {
      for (final module in CampusDataModule.values) module: true,
    };
    await tester.pumpWidget(
      YhApp(
        home: YhPageScaffold(
          body: SingleChildScrollView(
            child: SettingsGeneralSection(
              closeBehavior: 'ask',
              notificationEnabled: true,
              messageNotificationEnabled: true,
              notificationPermissionStatus:
                  NotificationPermissionStatus.granted,
              dndEnabled: false,
              courseReminderEnabled: courseReminderEnabled,
              examReminderEnabled: examReminderEnabled,
              courseReminderLeadMinutes: courseReminderLeadMinutes,
              examReminderLeadMinutes: examReminderLeadMinutes,
              homeStudentProfileCardVisible: true,
              homeCampusCardBalanceCardVisible: true,
              homeTodayCoursesTileVisible: true,
              homeSportsAttendanceTileVisible: true,
              homeStudentReportTileVisible: true,
              homeMessagesTileVisible: true,
              homeEmailTileVisible: true,
              homeQuickLinksTileVisible: true,
              homeOverviewOrder: overviewOrder,
              dataModuleFetchEnabled: fetchEnabled,
              dndStartHour: 22,
              dndStartMinute: 0,
              dndEndHour: 7,
              dndEndMinute: 0,
              onCloseBehaviorChanged: (_) {},
              onNotificationChanged: (_) {},
              onMessageNotificationChanged: (value) =>
                  messageNotificationEnabled = value,
              onNotificationPermissionRefresh: () {},
              onDndChanged: (_) {},
              onCourseReminderChanged: (value) => courseReminderEnabled = value,
              onExamReminderChanged: (value) => examReminderEnabled = value,
              onCourseReminderLeadMinutesChanged: (value) =>
                  courseReminderLeadMinutes = value,
              onExamReminderLeadMinutesChanged: (value) =>
                  examReminderLeadMinutes = value,
              onHomeStudentProfileCardVisibleChanged: (value) =>
                  studentVisible = value,
              onHomeCampusCardBalanceCardVisibleChanged: (value) =>
                  campusCardVisible = value,
              onHomeTodayCoursesTileVisibleChanged: (value) =>
                  todayCoursesVisible = value,
              onHomeSportsAttendanceTileVisibleChanged: (value) =>
                  sportsVisible = value,
              onHomeStudentReportTileVisibleChanged: (value) =>
                  studentReportVisible = value,
              onHomeMessagesTileVisibleChanged: (value) =>
                  messagesVisible = value,
              onHomeEmailTileVisibleChanged: (value) => emailVisible = value,
              onHomeQuickLinksTileVisibleChanged: (value) =>
                  quickLinksVisible = value,
              onHomeOverviewOrderChanged: (value) => overviewOrder = value,
              onDataModuleFetchChanged: (module, value) {
                fetchEnabled = {...fetchEnabled, module: value};
              },
              onDndStartChanged: (_, _) async {},
              onDndEndChanged: (_, _) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('首页显示'), findsOneWidget);
    expect(find.text('时间与行动'), findsOneWidget);
    expect(find.text('服务摘要'), findsOneWidget);
    expect(find.text('培养方案'), findsOneWidget);
    expect(find.text('校园卡余额'), findsOneWidget);
    expect(find.text('今日学程时间轨'), findsOneWidget);
    expect(find.text('体育考勤'), findsOneWidget);
    expect(find.text('第二课堂'), findsOneWidget);
    expect(find.text('最近校园待办'), findsOneWidget);
    expect(find.text('学校邮箱'), findsOneWidget);
    expect(find.text('常用入口'), findsOneWidget);
    expect(find.text('普通消息通知'), findsOneWidget);
    expect(find.text('联网获取'), findsOneWidget);
    expect(find.text('本专科教务数据'), findsOneWidget);
    expect(find.text('应用体验'), findsOneWidget);
    expect(find.text('课程提醒'), findsOneWidget);
    expect(find.text('考试提醒'), findsOneWidget);
    expect(find.text('在课程开始前 15 分钟提醒'), findsOneWidget);
    expect(find.text('在考试开始前 24 小时提醒'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('settings-message-notification-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settings-message-notification-switch')),
    );
    await tester.pump();
    expect(messageNotificationEnabled, isFalse);
    await tester.ensureVisible(
      find.byKey(const Key('settings-home-student-profile-card-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settings-home-student-profile-card-switch')),
    );
    await tester.pump();
    expect(studentVisible, isFalse);
    await tester.ensureVisible(
      find.byKey(const Key('settings-home-campus-card-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-home-campus-card-switch')));
    await tester.pump();
    expect(campusCardVisible, isFalse);
    await tester.ensureVisible(
      find.byKey(const Key('settings-module-email-fetch-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settings-module-email-fetch-switch')),
    );
    await tester.pump();
    expect(fetchEnabled[CampusDataModule.email], isFalse);
    await tester.ensureVisible(
      find.byKey(const Key('settings-course-reminder-lead-select')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settings-course-reminder-lead-select')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('提前 30 分钟'));
    await tester.pumpAndSettle();
    expect(courseReminderLeadMinutes, 30);
    await tester.ensureVisible(
      find.byKey(const Key('settings-course-reminder-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-course-reminder-switch')));
    await tester.pump();
    expect(courseReminderEnabled, isTrue);
    await tester.ensureVisible(
      find.byKey(const Key('settings-exam-reminder-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-exam-reminder-switch')));
    await tester.pump();
    expect(examReminderEnabled, isTrue);
    await tester.ensureVisible(
      find.byKey(const Key('settings-exam-reminder-lead-select')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settings-exam-reminder-lead-select')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('提前 48 小时'));
    await tester.pumpAndSettle();
    expect(examReminderLeadMinutes, 48 * 60);
    await tester.ensureVisible(
      find.byKey(const Key('settings-home-today-courses-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settings-home-today-courses-switch')),
    );
    await tester.pump();
    expect(todayCoursesVisible, isFalse);
    await tester.ensureVisible(
      find.byKey(const Key('settings-home-sports-attendance-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settings-home-sports-attendance-switch')),
    );
    await tester.pump();
    expect(sportsVisible, isFalse);
    await tester.ensureVisible(
      find.byKey(const Key('settings-home-student-report-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settings-home-student-report-switch')),
    );
    await tester.pump();
    expect(studentReportVisible, isFalse);
    await tester.ensureVisible(
      find.byKey(const Key('settings-home-messages-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-home-messages-switch')));
    await tester.pump();
    expect(messagesVisible, isFalse);
    await tester.ensureVisible(
      find.byKey(const Key('settings-home-email-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-home-email-switch')));
    await tester.pump();
    expect(emailVisible, isFalse);
    await tester.ensureVisible(
      find.byKey(const Key('settings-home-quick-links-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-home-quick-links-switch')));
    await tester.pump();
    expect(quickLinksVisible, isFalse);
    final campusCardUp = find.byKey(
      const Key('settings-home-overview-campus-card-up'),
    );
    await tester.ensureVisible(campusCardUp);
    await tester.pumpAndSettle();
    await tester.tap(campusCardUp);
    await tester.pump();
    expect(overviewOrder.take(2), [
      HomeOverviewItem.campusCard,
      HomeOverviewItem.trainingPlan,
    ]);
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('页面反馈连续显示时替换上一条紧凑浮层', (WidgetTester tester) async {
    await tester.pumpWidget(
      YhApp(
        home: YhPageScaffold(
          body: Builder(
            builder: (context) => YhButton(
              label: '显示反馈',
              onTap: () {
                showYhFeedback(context, message: '第一条反馈');
                showYhFeedback(context, message: '第二条反馈');
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示反馈'));
    await tester.pump();

    expect(find.text('第一条反馈'), findsNothing);
    expect(find.text('第二条反馈'), findsOneWidget);
    final toast = find.byKey(const Key('app-feedback-toast'));
    expect(toast, findsOneWidget);
    expect(tester.getTopLeft(toast).dy, lessThan(120));
    expect(tester.getBottomLeft(toast).dy, lessThan(260));
    expect(find.byType(YhBanner), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    expect(toast, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(toast, findsNothing);
  });

  testWidgets('WebView 遇到无效链接时显示错误页', (WidgetTester tester) async {
    await tester.pumpWidget(
      const YhApp(
        home: WebViewPage(
          url: 'https://wywh.sspu.edu.cnjavascript:void(0);',
          initialTitle: '无效链接',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // 历史缓存中的非法 URL 不应继续传给 WebView 构造器。
    expect(find.text('链接无效，无法打开'), findsOneWidget);
    expect(find.text('返回'), findsOneWidget);
  });

  testWidgets('设置页窄屏使用顶部下拉切换分区', (WidgetTester tester) async {
    await _configureMobileView(tester);

    try {
      await tester.pumpWidget(
        const qingyuan.YhApp(home: _SettingsNavigationLayoutHarness()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 仅覆盖响应式导航结构，避免完整设置页服务初始化拖慢组件测试。
      expect(find.text('常规'), findsOneWidget);
      expect(find.text('系统设置'), findsNothing);
      expect(
        find.byKey(const Key('settings-narrow-tab-combo')),
        findsOneWidget,
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await _resetMobileView(tester);
    }
  });

  testWidgets('设置页窄屏选择框弹层避开移动端状态栏', (WidgetTester tester) async {
    await _expectSettingsSelectPopupAvoidsStatusBar(
      tester,
      TargetPlatform.android,
    );
    await _expectSettingsSelectPopupAvoidsStatusBar(tester, TargetPlatform.iOS);
  });

  testWidgets('清源弹窗使用紧凑按钮区并支持点击外部取消', (WidgetTester tester) async {
    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) {
            return YhButton(
              label: '打开弹窗',
              onTap: () {
                YhDialog.show<void>(
                  context,
                  builder: (dialogContext) => YhDialog(
                    title: '关闭应用',
                    content: const Text(
                      '请选择点击窗口关闭按钮时的处理方式。\n点击弹窗外的空白区域取消本次操作。',
                    ),
                    actions: [
                      YhButton(
                        label: '最小化到托盘',
                        variant: YhButtonVariant.secondary,
                        onTap: () => Navigator.of(dialogContext).pop(),
                      ),
                      YhButton(
                        label: '退出应用',
                        onTap: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('打开弹窗'));
    await tester.pumpAndSettle();

    expect(find.byType(YhDialog), findsOneWidget);
    expect(find.text('最小化到托盘'), findsOneWidget);
    expect(find.text('退出应用'), findsOneWidget);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.byType(YhDialog), findsNothing);
  });

  testWidgets('职能部门和教学单位设置使用总览与轻量频道卡布局', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);

    Future<void> pumpChannelSection({
      required double width,
      required String title,
      required List<ChannelConfig> channels,
    }) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        YhApp(
          home: YhPageScaffold(
            body: SingleChildScrollView(
              child: ChannelListSection(title: title, channels: channels),
            ),
          ),
        ),
      );
      await pumpUntilFound(tester, find.text(title));
      await tester.pump(const Duration(milliseconds: 100));
    }

    try {
      await pumpChannelSection(
        width: 1280,
        title: '职能部门',
        channels: departmentChannels,
      );
      expect(find.text('统一管理学校官网消息来源，启用后会在信息中心筛选和刷新中生效。'), findsOneWidget);
      expect(find.text('共 24 个渠道'), findsOneWidget);
      expect(find.text('已接入 24 个'), findsOneWidget);
      expect(find.text('刷新设置'), findsOneWidget);
      expect(find.text('手动刷新'), findsOneWidget);
      expect(find.text('自动抓取'), findsOneWidget);
      expect(find.text('公开信息'), findsOneWidget);
      expect(find.text('已接入'), findsWidgets);
      expect(find.text('显示中'), findsWidgets);
      expect(tester.takeException(), isNull);

      await pumpChannelSection(
        width: 390,
        title: '教学单位',
        channels: teachingChannels,
      );
      expect(find.text('教学单位'), findsOneWidget);
      expect(find.text('共 20 个渠道'), findsOneWidget);
      expect(find.text('计算机与信息工程学院'), findsOneWidget);
      expect(find.text('内容分类'), findsWidgets);
      expect(find.text('3 项'), findsWidgets);
      expect(tester.takeException(), isNull);
    } finally {
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('微信推文设置显示认证摘要并从独立页统一管理操作', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final configDirectory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'settings_page_wechat_actions_${DateTime.now().microsecondsSinceEpoch}',
    );
    StorageService.debugSetStateFilePathForTesting(
      '${configDirectory.path}${Platform.pathSeparator}app_state.json',
    );
    await tester.runAsync(StorageService.init);
    WxmpConfigService.instance.debugSetConfigPathForTesting(
      '${configDirectory.path}${Platform.pathSeparator}wxmp_config.toml',
    );
    final controller = SettingsWechatController();
    await tester.runAsync(controller.load);

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    try {
      await tester.pumpWidget(
        YhApp(
          home: YhPageScaffold(
            body: SingleChildScrollView(
              child: SettingsWechatSection(controller: controller),
            ),
          ),
        ),
      );
      await pumpUntilFound(tester, find.text('管理微信公众号认证'));

      expect(find.text('管理微信公众号认证'), findsOneWidget);
      expect(find.text('编辑认证配置'), findsNothing);
      expect(find.text('清除认证'), findsNothing);
      expect(find.text('打开配置文件所在文件夹'), findsNothing);
      expect(find.text('外部打开'), findsNothing);
      expect(find.text('校验有效性'), findsNothing);
      expect(find.text('使用 Visual Studio Code 打开配置文件'), findsNothing);
      expect(find.text('刷新设置'), findsOneWidget);
      expect(find.text('全部开启通知'), findsOneWidget);
      expect(find.text('全部关闭通知'), findsOneWidget);
      expect(find.textContaining('矩阵开关'), findsNothing);
      expect(find.text('微信矩阵'), findsOneWidget);
      expect(find.text('SSPU 微信矩阵'), findsNothing);
      expect(find.text('微信公众平台注册方式'), findsNothing);
      expect(find.textContaining('若频率过快'), findsNothing);

      await tester.tap(find.text('管理微信公众号认证'));
      await tester.pumpAndSettle();
      expect(find.text('微信公众号认证'), findsOneWidget);
      expect(find.text('生成登录二维码'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('更多操作'));
      await tester.pumpAndSettle();
      expect(find.text('编辑认证配置'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
      WxmpConfigService.instance.debugSetConfigPathForTesting(null);
      StorageService.debugSetStateFilePathForTesting(null);
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
      await tester.runAsync(() => deleteDirectoryWithRetry(configDirectory));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('微信推文配置编辑器使用自适应字段表单', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(390, 844));

    try {
      await tester.pumpWidget(
        qingyuan.YhApp(
          home: Center(
            child: qingyuan.YhButton(
              label: '打开编辑器',
              onTap: () {
                showSettingsWechatConfigDialog(
                  context: tester.element(find.text('打开编辑器')),
                  initialConfig: WxmpConfig.defaults(),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开编辑器'));
      await pumpUntilFound(tester, find.text('Cookie'));

      expect(find.text('Cookie'), findsOneWidget);
      expect(find.text('Token'), findsOneWidget);
      expect(find.text('App ID'), findsOneWidget);
      expect(find.text('User-Agent'), findsOneWidget);
      expect(find.text('单次抓取数量'), findsOneWidget);
      expect(find.text('请求间隔（毫秒）'), findsOneWidget);
      expect(find.textContaining('保存后会立即重新加载配置'), findsNothing);

      final dialogBox = tester.renderObject<RenderBox>(
        find.byType(qingyuan.YhDialog),
      );
      expect(dialogBox.size.width <= 390, isTrue);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('微信推文配置编辑器宽屏使用双列布局', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    try {
      await tester.pumpWidget(
        qingyuan.YhApp(
          home: Center(
            child: qingyuan.YhButton(
              label: '打开编辑器',
              onTap: () {
                showSettingsWechatConfigDialog(
                  context: tester.element(find.text('打开编辑器')),
                  initialConfig: WxmpConfig.defaults(),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开编辑器'));
      await pumpUntilFound(tester, find.text('Cookie'));

      final contentBox = tester.renderObject<RenderBox>(
        find.byKey(const Key('wechat-config-dialog-content')),
      );
      expect(contentBox.size.width >= 760, isTrue);
      expect(contentBox.size.width <= 920, isTrue);

      final cookieTop = tester.getTopLeft(find.text('Cookie')).dy;
      final tokenTop = tester.getTopLeft(find.text('Token')).dy;
      expect((cookieTop - tokenTop).abs() < 1, isTrue);

      final appIdTop = tester.getTopLeft(find.text('App ID')).dy;
      final userAgentTop = tester.getTopLeft(find.text('User-Agent')).dy;
      expect((appIdTop - userAgentTop).abs() < 1, isTrue);

      final fieldFocusOrder = tester
          .widgetList<EditableText>(
            find.descendant(
              of: find.byType(qingyuan.YhDialog),
              matching: find.byType(EditableText),
            ),
          )
          .map((field) => field.focusNode.debugLabel)
          .toList();
      expect(fieldFocusOrder, [
        'Cookie',
        'Token',
        'App ID',
        'User-Agent',
        '单次抓取数量',
        '请求间隔（毫秒）',
      ]);

      final actionLabels = tester
          .widgetList<qingyuan.YhButton>(
            find.descendant(
              of: find.byType(qingyuan.YhDialog),
              matching: find.byType(qingyuan.YhButton),
            ),
          )
          .map((button) => button.label)
          .toList();
      expect(actionLabels, ['取消', '保存配置']);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });
}

class _SettingsNavigationLayoutHarness extends StatelessWidget {
  const _SettingsNavigationLayoutHarness();

  @override
  Widget build(BuildContext context) {
    return qingyuan.YhPageScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          return isNarrow
              ? const _NarrowSettingsNavigation()
              : const _WideSettingsNavigation();
        },
      ),
    );
  }
}

class _NarrowSettingsNavigation extends StatelessWidget {
  const _NarrowSettingsNavigation({this.selectedValue = 0});

  final int selectedValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(qingyuan.YhIcons.menu, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: qingyuan.YhSelect<int>(
            key: const Key('settings-narrow-tab-combo'),
            label: '设置分区',
            showLabel: false,
            value: selectedValue,
            options: const [
              qingyuan.YhSelectOption(value: 0, label: '常规'),
              qingyuan.YhSelectOption(value: 1, label: '学期'),
              qingyuan.YhSelectOption(value: 2, label: '自动刷新'),
              qingyuan.YhSelectOption(value: 3, label: '安全'),
              qingyuan.YhSelectOption(value: 4, label: '职能部门'),
              qingyuan.YhSelectOption(value: 5, label: '教学单位'),
              qingyuan.YhSelectOption(value: 6, label: '微信推文'),
              qingyuan.YhSelectOption(value: 7, label: '关于'),
            ],
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }
}

class _WideSettingsNavigation extends StatelessWidget {
  const _WideSettingsNavigation();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [Text('系统设置'), SizedBox(height: 8), Text('常规')],
    );
  }
}
