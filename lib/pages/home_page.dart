/*
 * 主页 — 应用首屏，展示欢迎信息与最新消息摘要
 * @Project : SSPU-AllinOne
 * @File : home_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'dart:async';

import '../controllers/card_auto_refresh_controller.dart';
import '../design/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/campus_card.dart';
import '../models/academic_credentials.dart';
import '../models/academic_eams.dart';
import '../models/email_mailbox.dart';
import '../models/message_item.dart';
import '../models/sports_attendance.dart';
import '../models/student_report.dart';
import '../services/academic_credentials_service.dart';
import '../services/academic_eams_service.dart';
import '../services/app_display_name_service.dart';
import '../services/campus_card_service.dart';
import '../services/campus_network_status_service.dart';
import '../services/email_service.dart';
import '../services/message_state_service.dart';
import '../services/quick_links_config_service.dart';
import '../services/sports_attendance_service.dart';
import '../services/storage_service.dart';
import '../services/student_report_service.dart';
import '../theme/fluent_tokens.dart';
import '../utils/query_result_messages.dart';
import '../utils/app_web_launcher.dart';
import '../widgets/campus_network_status_indicator.dart';
import '../widgets/refresh_feedback_action.dart';
import '../widgets/responsive_layout.dart';
import 'course_schedule_page.dart';
part 'home_campus_card_balance_card.dart';
part 'home_campus_card_detail_page.dart';
part 'home_student_profile_card.dart';

/// 主页
/// 展示欢迎信息与最新消息列表
class HomePage extends StatefulWidget {
  /// 校园卡余额查询服务，测试中可替换为 fake。
  final CampusCardBalanceClient? campusCardService;

  /// 校园网 / VPN 状态检测服务，测试中可替换为 fake。
  final CampusNetworkStatusService? campusNetworkStatusService;

  /// 测试专用：覆盖校园卡余额自动刷新开关。
  final bool? campusCardAutoRefreshEnabledOverride;

  /// 测试专用：覆盖校园卡余额自动刷新间隔。
  final int? campusCardAutoRefreshIntervalOverride;

  /// 本专科教务服务，测试中可替换为 fake。
  final AcademicEamsClient? academicEamsService;

  /// 体育考勤服务，测试中可替换为 fake。
  final SportsAttendanceClient? sportsAttendanceService;

  /// 第二课堂服务，测试中可替换为 fake。
  final StudentReportClient? studentReportService;

  /// 学校邮箱服务，测试中可替换为 fake。
  final EmailMailboxClient? emailService;

  /// 打开设置页回调。
  final VoidCallback? onOpenSettings;

  const HomePage({
    super.key,
    this.campusCardService,
    this.campusNetworkStatusService,
    this.campusCardAutoRefreshEnabledOverride,
    this.campusCardAutoRefreshIntervalOverride,
    this.academicEamsService,
    this.sportsAttendanceService,
    this.studentReportService,
    this.emailService,
    this.onOpenSettings,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 最新消息列表（最多 5 条）
  List<MessageItem> _latestMessages = [];

  CampusCardQueryResult? _campusCardResult;
  AcademicCredentialsStatus _credentialsStatus =
      const AcademicCredentialsStatus.empty();
  AcademicEamsProfile? _studentProfile;
  AcademicEamsQueryResult? _courseTableResult;
  SportsAttendanceQueryResult? _sportsAttendanceResult;
  StudentReportQueryResult? _studentReportResult;
  EmailMailboxQueryResult? _emailResult;
  List<QuickLinkItemConfig> _quickLinkFavorites = const [];
  bool _isLoadingStudentProfile = false;
  bool _studentProfileCardVisible = true;
  bool _campusCardCardVisible = true;
  bool _todayCoursesTileVisible = true;
  bool _sportsAttendanceTileVisible = true;
  bool _studentReportTileVisible = true;
  bool _messagesTileVisible = true;
  bool _emailTileVisible = true;
  bool _quickLinksTileVisible = true;
  late final CardAutoRefreshController<CampusCardQueryResult>
  _campusCardRefreshController;
  StreamSubscription<int>? _credentialChangeSubscription;

  CampusCardBalanceClient get _campusCardService {
    return widget.campusCardService ?? CampusCardService.instance;
  }

  AcademicEamsClient get _academicEamsService {
    return widget.academicEamsService ?? AcademicEamsService.instance;
  }

  SportsAttendanceClient get _sportsAttendanceService {
    return widget.sportsAttendanceService ?? SportsAttendanceService.instance;
  }

  StudentReportClient get _studentReportService {
    return widget.studentReportService ?? StudentReportService.instance;
  }

  EmailMailboxClient get _emailService {
    return widget.emailService ?? EmailService.instance;
  }

  @override
  void initState() {
    super.initState();
    _campusCardRefreshController =
        CardAutoRefreshController<CampusCardQueryResult>(
          refreshTask: _fetchCampusCardForController,
          isSuccess: (result) => result.isSuccess,
          applyResult: _applyCampusCardResult,
          checkedAt: () => _campusCardResult?.checkedAt,
          failureReason: _campusCardRefreshFailureReason,
        )..addListener(_handleCampusCardRefreshControllerChanged);
    _credentialChangeSubscription = AcademicCredentialsService.instance.changes
        .listen((_) {
          _clearAuthenticatedState();
          unawaited(_loadStudentProfileCard(forceRefresh: true));
        });
    _loadLatestMessages();
    _loadStudentProfileCard();
    _loadCampusCardCacheAndSettings();
    _loadDashboardCaches();
  }

  void _handleCampusCardRefreshControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _clearAuthenticatedState() {
    if (!mounted) return;
    _campusCardRefreshController.clearTransientState();
    setState(() {
      _campusCardResult = null;
      _studentProfile = null;
      _courseTableResult = null;
      _sportsAttendanceResult = null;
      _studentReportResult = null;
      _emailResult = null;
      _credentialsStatus = const AcademicCredentialsStatus.empty();
      _isLoadingStudentProfile = false;
    });
  }

  /// 读取首页学籍卡片设置和安全缓存，必要时静默补全。
  Future<void> _loadStudentProfileCard({bool forceRefresh = false}) async {
    final visible = await StorageService.getBool(
      StorageKeys.homeStudentProfileCardVisible,
      defaultValue: true,
    );
    final campusCardVisible = await StorageService.getBool(
      StorageKeys.homeCampusCardBalanceCardVisible,
      defaultValue: true,
    );
    final todayCoursesVisible = await StorageService.getBool(
      StorageKeys.homeTodayCoursesTileVisible,
      defaultValue: true,
    );
    final sportsAttendanceVisible = await StorageService.getBool(
      StorageKeys.homeSportsAttendanceTileVisible,
      defaultValue: true,
    );
    final studentReportVisible = await StorageService.getBool(
      StorageKeys.homeStudentReportTileVisible,
      defaultValue: true,
    );
    final messagesVisible = await StorageService.getBool(
      StorageKeys.homeMessagesTileVisible,
      defaultValue: true,
    );
    final emailVisible = await StorageService.getBool(
      StorageKeys.homeEmailTileVisible,
      defaultValue: true,
    );
    final quickLinksVisible = await StorageService.getBool(
      StorageKeys.homeQuickLinksTileVisible,
      defaultValue: true,
    );
    final status = await AcademicCredentialsService.instance.getStatus();
    final cachedProfile = await _academicEamsService.readCachedStudentProfile();
    if (!mounted) return;
    setState(() {
      _studentProfileCardVisible = visible;
      _campusCardCardVisible = campusCardVisible;
      _todayCoursesTileVisible = todayCoursesVisible;
      _sportsAttendanceTileVisible = sportsAttendanceVisible;
      _studentReportTileVisible = studentReportVisible;
      _messagesTileVisible = messagesVisible;
      _emailTileVisible = emailVisible;
      _quickLinksTileVisible = quickLinksVisible;
      _credentialsStatus = status;
      _studentProfile = cachedProfile;
    });
    if (!visible || status.oaAccount.trim().isEmpty || !status.hasOaPassword) {
      return;
    }
    if (!forceRefresh && cachedProfile?.hasHomeSummary == true) return;
    setState(() => _isLoadingStudentProfile = true);
    final refreshedProfile = await _academicEamsService
        .refreshStudentProfileIfIncomplete(forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() {
      _studentProfile = refreshedProfile ?? _studentProfile;
      _isLoadingStudentProfile = false;
    });
  }

  /// 从本地存储加载消息并取前 5 条
  Future<void> _loadLatestMessages() async {
    final all = await MessageStateService.instance.loadMessages();
    // 按日期降序排列，取前 5 条
    all.sort((a, b) => b.date.compareTo(a.date));
    if (mounted) {
      setState(() => _latestMessages = all.take(5).toList());
    }
  }

  /// 读取首页仪表盘其它磁贴所需的本地缓存。
  Future<void> _loadDashboardCaches() async {
    final results = await Future.wait<Object?>([
      _academicEamsService.readLatestCachedCourseTable(),
      _sportsAttendanceService.readLatestCachedAttendanceSummary(),
      _studentReportService.readLatestCachedSecondClassroomCredits(),
      _emailService.readLatestCachedMessages(EmailProtocol.imap),
      _loadQuickLinkFavorites(),
    ]);
    if (!mounted) return;
    setState(() {
      _courseTableResult = results[0] as AcademicEamsQueryResult?;
      _sportsAttendanceResult = results[1] as SportsAttendanceQueryResult?;
      _studentReportResult = results[2] as StudentReportQueryResult?;
      _emailResult = results[3] as EmailMailboxQueryResult?;
      _quickLinkFavorites =
          (results[4] as List<QuickLinkItemConfig>?) ?? const [];
    });
  }

  Future<List<QuickLinkItemConfig>> _loadQuickLinkFavorites() async {
    try {
      final groups = await QuickLinksConfigService.instance.loadGroups();
      final allItems = groups.expand((group) => group.items).toList();
      final favoriteUrls = await StorageService.getStringList(
        StorageKeys.quickLinkFavoriteUrls,
      );
      if (favoriteUrls.isNotEmpty) {
        final favorites = [
          for (final url in favoriteUrls)
            for (final item in allItems)
              if (item.url == url) item,
        ];
        if (favorites.isNotEmpty) return favorites.take(6).toList();
      }
      return allItems.take(6).toList();
    } catch (_) {
      return const [];
    }
  }

  /// 读取校园卡自动刷新设置；默认不主动访问 OA / 校园卡系统。
  Future<void> _loadCampusCardAutoRefreshSettings() async {
    final enabled =
        widget.campusCardAutoRefreshEnabledOverride ??
        await CampusCardService.instance.isAutoRefreshEnabled();
    final interval =
        widget.campusCardAutoRefreshIntervalOverride ??
        await CampusCardService.instance.getAutoRefreshIntervalMinutes();
    if (!mounted) return;
    _campusCardRefreshController.configureAutoRefresh(
      enabled: enabled,
      intervalMinutes: interval,
    );
  }

  /// 先显示本地校园卡缓存，再根据设置决定是否静默刷新。
  Future<void> _loadCampusCardCacheAndSettings() async {
    final visible = await StorageService.getBool(
      StorageKeys.homeCampusCardBalanceCardVisible,
      defaultValue: true,
    );
    if (mounted) setState(() => _campusCardCardVisible = visible);
    final cachedResult = await _campusCardService.readLatestCachedCampusCard();
    if (mounted && cachedResult != null) {
      setState(() => _campusCardResult = cachedResult);
    }
    await _loadCampusCardAutoRefreshSettings();
  }

  /// 读取校园卡余额、状态和交易记录。
  Future<void> _loadCampusCard({
    DateTime? startDate,
    DateTime? endDate,
    bool silent = false,
  }) async {
    if (startDate != null || endDate != null) {
      await _loadCampusCardWithDateRange(
        startDate: startDate,
        endDate: endDate,
        silent: silent,
      );
      return;
    }
    await _campusCardRefreshController.runRefresh(silent: silent);
  }

  Future<CampusCardQueryResult> _fetchCampusCardForController({
    required bool silent,
  }) {
    return _campusCardService.fetchCampusCard(
      requireCampusNetwork: silent,
      syncAllTransactions: true,
    );
  }

  Future<void> _loadCampusCardWithDateRange({
    DateTime? startDate,
    DateTime? endDate,
    required bool silent,
  }) async {
    final result = await _campusCardService.fetchCampusCard(
      startDate: startDate,
      endDate: endDate,
      requireCampusNetwork: silent,
      syncAllTransactions: true,
    );
    if (!mounted) return;
    if (silent && !result.isSuccess) return;
    _applyCampusCardResult(result);
  }

  void _applyCampusCardResult(CampusCardQueryResult result) {
    if (!mounted) return;
    setState(() => _campusCardResult = result);
  }

  String _campusCardRefreshFailureReason(CampusCardQueryResult result) {
    return switch (result.status) {
      CampusCardQueryStatus.success => '',
      CampusCardQueryStatus.missingOaAccount => '未设置OA账号',
      CampusCardQueryStatus.missingOaPassword => '未设置OA密码',
      CampusCardQueryStatus.campusNetworkUnavailable => '校园网/VPN不可用',
      CampusCardQueryStatus.oaLoginRequired => 'OA登录失效',
      CampusCardQueryStatus.cardSystemUnavailable => '校园卡系统不可用',
      CampusCardQueryStatus.parseFailed ||
      CampusCardQueryStatus.networkError ||
      CampusCardQueryStatus.unexpectedError => firstNonEmptyText(
        result.detail,
        result.message,
        fallback: '查询失败',
      ),
    };
  }

  @override
  void dispose() {
    _credentialChangeSubscription?.cancel();
    _campusCardRefreshController
      ..removeListener(_handleCampusCardRefreshControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, constraints) {
        final pagePadding = switch (deviceType) {
          DeviceType.phone => FluentSpacing.m,
          DeviceType.tablet => FluentSpacing.xl,
          DeviceType.desktop => FluentSpacing.xxl,
        };

        return FluentPage.scrollable(
          header: FluentPageHeader(
            title: const Text('主页'),
            commandBar: CampusNetworkStatusIndicator(
              service: widget.campusNetworkStatusService,
              variant: CampusNetworkStatusIndicatorVariant.home,
              indicatorKey: const Key('campus-network-status-home'),
            ),
          ),
          padding: EdgeInsets.all(pagePadding),
          children: [
            FluentContentWidth(
              child: fluentEntrance(
                context: context,
                child: _buildDashboardHero(context),
              ),
            ),
            const SizedBox(height: FluentSpacing.l),
            FluentContentWidth(child: _buildDashboardGrid(context)),
          ],
        );
      },
    );
  }

  /// 构建校园仪表盘头部。
  Widget _buildDashboardHero(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final spacing = context.fluentSpacing;
    final radii = context.fluentRadii;
    final todayCourseCount = _todayCourseEntries.length;
    final unreadCount = _latestMessages.length;

    return FluentMaterialSurface(
      padding: EdgeInsets.all(spacing.xl),
      borderRadius: radii.xLargeBorder,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: context.fluentGradients.dashboardHero,
          borderRadius: radii.xLargeBorder,
        ),
        child: Padding(
          padding: EdgeInsets.all(spacing.l),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final logo = Image.asset(
                'assets/images/logo.png',
                width: compact ? 56 : 72,
                height: compact ? 56 : 72,
              );
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppDisplayName.of(context),
                    style: (compact ? type.title3 : type.title2).copyWith(
                      color: colors.neutralForeground1,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    '今日课程 $todayCourseCount 门 · 最近消息 $unreadCount 条',
                    style: type.body1.copyWith(
                      color: colors.neutralForeground2,
                    ),
                  ),
                ],
              );
              final metrics = Wrap(
                spacing: spacing.s,
                runSpacing: spacing.s,
                children: [
                  _DashboardHeroPill(
                    label: '校园卡',
                    value: _campusCardBalanceText,
                    color: context.fluentAccents.finance,
                  ),
                  _DashboardHeroPill(
                    label: '二课',
                    value: _studentReportCreditText,
                    color: context.fluentAccents.secondClassroom,
                  ),
                  _DashboardHeroPill(
                    label: '邮箱',
                    value: _emailSummaryText,
                    color: context.fluentAccents.mail,
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        logo,
                        SizedBox(width: spacing.m),
                        Expanded(child: title),
                      ],
                    ),
                    SizedBox(height: spacing.l),
                    metrics,
                  ],
                );
              }
              return Row(
                children: [
                  logo,
                  SizedBox(width: spacing.l),
                  Expanded(child: title),
                  SizedBox(width: spacing.l),
                  Flexible(child: metrics),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建首页仪表盘网格。
  Widget _buildDashboardGrid(BuildContext context) {
    final tiles = <Widget>[
      if (_studentProfileCardVisible) _buildStudentProfileCard(context),
      if (_campusCardCardVisible) _buildCampusCardBalanceCard(context),
      if (_todayCoursesTileVisible) _buildTodayCoursesTile(context),
      if (_sportsAttendanceTileVisible) _buildSportsAttendanceTile(context),
      if (_studentReportTileVisible) _buildSecondClassroomTile(context),
      if (_messagesTileVisible) _buildMessagesTile(context),
      if (_emailTileVisible) _buildEmailTile(context),
      if (_quickLinksTileVisible) _buildQuickLinksTile(context),
    ];
    if (tiles.isEmpty) {
      return FluentDashboardTile(
        title: '首页磁贴',
        icon: FluentIcons.home,
        state: FluentDataState.notConfigured,
        actions: [
          FluentButton.primary(
            onPressed: widget.onOpenSettings,
            child: const Text('前往设置'),
          ),
        ],
        child: Text(
          '所有首页磁贴均已隐藏，可在设置的“首页显示”中重新开启。',
          style: context.fluentType.body1.copyWith(
            color: context.fluentColors.neutralForeground2,
          ),
        ),
      );
    }

    return FluentMasonryGrid(
      gap: FluentSpacing.l,
      columnsForWidth: (width) {
        if (width >= 1180) return 3;
        if (width >= 700) return 2;
        return 1;
      },
      children: tiles,
    );
  }

  /// 今日课程磁贴。
  Widget _buildTodayCoursesTile(BuildContext context) {
    final entries = _todayCourseEntries;
    final hasCredentials =
        _credentialsStatus.oaAccount.trim().isNotEmpty &&
        _credentialsStatus.hasOaPassword;
    final state = !hasCredentials
        ? FluentDataState.notConfigured
        : _courseTableResult == null
        ? FluentDataState.degraded
        : entries.isEmpty
        ? FluentDataState.degraded
        : FluentDataState.ready;

    return FluentDashboardTile(
      key: const Key('home-today-courses-tile'),
      title: '今日课程',
      subtitle: _courseTableResult?.snapshot?.courseTable?.termName ?? '当前学期',
      icon: FluentIcons.calendar,
      state: state,
      accentColor: context.fluentAccents.schedule,
      actions: [
        FluentButton.transparentIcon(
          onPressed: _openCourseSchedulePage,
          icon: const Icon(FluentIcons.chevronRight, size: 14),
          label: const Text('课表'),
        ),
      ],
      child: !hasCredentials
          ? _buildSettingsPrompt(context, '需要先保存 OA 账号密码')
          : entries.isEmpty
          ? _buildMutedText(context, '暂无今日课程缓存，打开课表页刷新后会显示。')
          : _buildTodayCourseRows(entries),
    );
  }

  /// 体育考勤磁贴。
  Widget _buildSportsAttendanceTile(BuildContext context) {
    final result = _sportsAttendanceResult;
    final summary = result?.summary;
    final hasCredentials = _credentialsStatus.oaAccount.trim().isNotEmpty;
    final state = !hasCredentials
        ? FluentDataState.notConfigured
        : result == null
        ? FluentDataState.degraded
        : result.isSuccess
        ? FluentDataState.ready
        : FluentDataState.failed;

    return FluentDashboardTile(
      key: const Key('home-sports-attendance-tile'),
      title: '体育考勤',
      icon: FluentIcons.running,
      state: state,
      accentColor: context.fluentAccents.sports,
      child: !hasCredentials
          ? _buildSettingsPrompt(context, '需要先保存学工号')
          : summary == null
          ? _buildMutedText(context, result?.message ?? '暂无体育考勤缓存')
          : Wrap(
              spacing: FluentSpacing.s,
              runSpacing: FluentSpacing.s,
              children: [
                _MetricText(label: '总次数', value: '${summary.totalCount} 次'),
                _MetricText(
                  label: '课外活动',
                  value: '${summary.extracurricularActivityCount} 次',
                ),
                _MetricText(
                  label: '早操',
                  value: '${summary.morningExerciseCount} 次',
                ),
              ],
            ),
    );
  }

  /// 第二课堂磁贴。
  Widget _buildSecondClassroomTile(BuildContext context) {
    final result = _studentReportResult;
    final summary = result?.summary;
    final totals = summary?.totals;
    final hasCredentials =
        _credentialsStatus.oaAccount.trim().isNotEmpty &&
        _credentialsStatus.hasOaPassword;
    final state = !hasCredentials
        ? FluentDataState.notConfigured
        : result == null
        ? FluentDataState.degraded
        : result.isSuccess
        ? FluentDataState.ready
        : FluentDataState.failed;

    return FluentDashboardTile(
      key: const Key('home-second-classroom-tile'),
      title: '第二课堂',
      icon: FluentIcons.education,
      state: state,
      accentColor: context.fluentAccents.secondClassroom,
      child: !hasCredentials
          ? _buildSettingsPrompt(context, '需要先保存 OA 账号密码')
          : summary == null
          ? _buildMutedText(context, result?.message ?? '暂无第二课堂缓存')
          : Wrap(
              spacing: FluentSpacing.s,
              runSpacing: FluentSpacing.s,
              children: [
                _MetricText(
                  label: '已获',
                  value: _formatCredit(totals?.totalEarnedCredit),
                ),
                _MetricText(
                  label: '必修',
                  value: _formatCredit(totals?.totalRequiredCredit),
                ),
                _MetricText(
                  label: '详情',
                  value: '${summary.detailRecords.length} 条',
                ),
              ],
            ),
    );
  }

  /// 最新消息磁贴。
  Widget _buildMessagesTile(BuildContext context) {
    return FluentDashboardTile(
      key: const Key('home-messages-tile'),
      title: '最新消息',
      subtitle: '最近 5 条已启用渠道消息',
      icon: FluentIcons.news,
      state: _latestMessages.isEmpty
          ? FluentDataState.degraded
          : FluentDataState.ready,
      accentColor: context.fluentAccents.information,
      child: _latestMessages.isEmpty
          ? _buildMutedText(context, '暂无消息，开启信息渠道并等待自动刷新后会显示。')
          : _buildLatestMessageRows(context),
    );
  }

  /// 邮箱摘要磁贴。
  Widget _buildEmailTile(BuildContext context) {
    final result = _emailResult;
    final snapshot = result?.snapshot;
    final hasCredentials = _credentialsStatus.oaAccount.trim().isNotEmpty;
    final state = !hasCredentials
        ? FluentDataState.notConfigured
        : result == null
        ? FluentDataState.degraded
        : result.isSuccess
        ? FluentDataState.ready
        : FluentDataState.failed;

    return FluentDashboardTile(
      key: const Key('home-email-tile'),
      title: '邮箱摘要',
      icon: FluentIcons.mail,
      state: state,
      accentColor: context.fluentAccents.mail,
      child: !hasCredentials
          ? _buildSettingsPrompt(context, '需要先保存学工号')
          : snapshot == null
          ? _buildMutedText(context, result?.message ?? '暂无邮箱缓存')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricText(
                  label: snapshot.protocol.label,
                  value: '${snapshot.messages.length} 封',
                ),
                const SizedBox(height: FluentSpacing.s),
                Text(
                  snapshot.messages.isEmpty
                      ? '最近邮件为空'
                      : snapshot.messages.first.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.fluentType.body1Strong,
                ),
              ],
            ),
    );
  }

  /// 快速跳转磁贴。
  Widget _buildQuickLinksTile(BuildContext context) {
    return FluentDashboardTile(
      key: const Key('home-quick-links-tile'),
      title: '快速跳转',
      subtitle: '常用校园入口',
      icon: FluentIcons.link,
      state: _quickLinkFavorites.isEmpty
          ? FluentDataState.degraded
          : FluentDataState.ready,
      accentColor: context.fluentAccents.quickLink,
      child: _quickLinkFavorites.isEmpty
          ? _buildMutedText(context, '快捷入口配置加载中或暂无可用入口。')
          : Wrap(
              spacing: FluentSpacing.s,
              runSpacing: FluentSpacing.s,
              children: [
                for (final item in _quickLinkFavorites)
                  Button(
                    onPressed: () => _openExternalUrl(item.url),
                    child: Text(item.name),
                  ),
              ],
            ),
    );
  }

  List<AcademicCourseTableEntry> get _todayCourseEntries {
    final weekday = DateTime.now().weekday;
    final entries = <AcademicCourseTableEntry>[
      ...?_courseTableResult?.snapshot?.courseTable?.entries.where(
        (entry) => entry.weekday == weekday,
      ),
    ];
    entries.sort((a, b) => a.startUnit.compareTo(b.startUnit));
    return entries;
  }

  Widget _buildTodayCourseRows(List<AcademicCourseTableEntry> entries) {
    final visibleEntries = entries.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visibleEntries.length; i++) ...[
          _CourseMiniRow(entry: visibleEntries[i]),
          if (i < visibleEntries.length - 1)
            const SizedBox(height: FluentSpacing.s),
        ],
      ],
    );
  }

  Widget _buildLatestMessageRows(BuildContext context) {
    final visibleMessages = _latestMessages.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visibleMessages.length; i++) ...[
          _buildMessageItem(context, visibleMessages[i]),
          if (i < visibleMessages.length - 1) const Divider(),
        ],
      ],
    );
  }

  String get _campusCardBalanceText {
    final balance = _campusCardResult?.snapshot?.balance;
    if (balance == null) return '未读取';
    return '¥${balance.toStringAsFixed(2)}';
  }

  String get _studentReportCreditText {
    final earned = _studentReportResult?.summary?.totals?.totalEarnedCredit;
    return earned == null ? '未读取' : earned.toStringAsFixed(2);
  }

  String get _emailSummaryText {
    final count = _emailResult?.snapshot?.messages.length;
    return count == null ? '未读取' : '$count 封';
  }

  Widget _buildSettingsPrompt(BuildContext context, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMutedText(context, label),
        const SizedBox(height: FluentSpacing.s),
        FluentButton.primary(
          onPressed: widget.onOpenSettings,
          child: const Text('前往设置'),
        ),
      ],
    );
  }

  Widget _buildMutedText(BuildContext context, String text) {
    return Text(
      text,
      style: context.fluentType.body1.copyWith(
        color: context.fluentColors.neutralForeground2,
      ),
    );
  }

  void _openCourseSchedulePage() {
    Navigator.of(context).push(
      FluentPageRoute(
        builder: (_) => CourseSchedulePage(
          academicEamsService: _academicEamsService,
          initialResult: _courseTableResult,
        ),
      ),
    );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatCredit(double? value) {
    return value == null ? '未读取' : value.toStringAsFixed(2);
  }

  /// 构建单条消息项（点击跳转内嵌 WebView）
  Widget _buildMessageItem(BuildContext context, MessageItem msg) {
    final theme = FluentTheme.of(context);
    return FluentHoverButton(
      onPressed: () async {
        // 标记已读并在 iOS 使用 Safari View Controller 打开。
        MessageStateService.instance.markAsRead(msg.id);
        if (!context.mounted) return;
        await openAppWebUrl(
          context,
          url: msg.url,
          title: msg.title,
        );
      },
      builder: (context, states) {
        final isHovered = states.isHovered;
        return AnimatedContainer(
          duration: context.fluentMotion.durationFast,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          decoration: BoxDecoration(
            color: isHovered ? theme.resources.subtleFillColorSecondary : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(msg.title, style: theme.typography.bodyStrong),
                    const SizedBox(height: 4),
                    Text(
                      '${msg.category.label} · ${msg.sourceName.label}',
                      style: theme.typography.caption,
                    ),
                  ],
                ),
              ),
              Text(
                msg.date,
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeroPill extends StatelessWidget {
  const _DashboardHeroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.m,
        vertical: FluentSpacing.s,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FluentRadius.circular),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: type.caption1.copyWith(color: colors.neutralForeground2),
          ),
          const SizedBox(width: FluentSpacing.xs),
          Text(value, style: type.caption1Strong.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _CourseMiniRow extends StatelessWidget {
  const _CourseMiniRow({required this.entry});

  final AcademicCourseTableEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final color = context.fluentCoursePalette.colorFor(entry.courseName);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(FluentRadius.circular),
          ),
        ),
        const SizedBox(width: FluentSpacing.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.courseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.body1Strong.copyWith(
                  color: colors.neutralForeground1,
                ),
              ),
              const SizedBox(height: FluentSpacing.xxs),
              Text(
                [
                  entry.timeText,
                  if (entry.location?.trim().isNotEmpty == true)
                    entry.location!.trim(),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.caption1.copyWith(color: colors.neutralForeground3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: type.caption1.copyWith(color: colors.neutralForeground3),
          ),
          const SizedBox(height: FluentSpacing.xxs),
          Text(
            value,
            style: type.subtitle2Stronger.copyWith(
              color: colors.neutralForeground1,
            ),
          ),
        ],
      ),
    );
  }
}
