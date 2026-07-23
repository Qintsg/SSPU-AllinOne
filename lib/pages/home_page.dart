/*
 * 主页 — 应用首屏，展示欢迎信息与最新消息摘要
 * @Project : SSPU-AllinOne
 * @File : home_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

import '../controllers/card_auto_refresh_controller.dart';
import '../design/qingyuan/qingyuan_ui.dart';
import '../models/campus_card.dart';
import '../models/course_period.dart';
import '../models/academic_eams.dart';
import '../models/academic_credentials.dart';
import '../models/email_mailbox.dart';
import '../models/message_item.dart';
import '../models/sports_attendance.dart';
import '../models/student_report.dart';
import '../services/academic_credentials_service.dart';
import '../services/academic_eams_service.dart';
import '../services/campus_card_service.dart';
import '../services/campus_network_status_service.dart';
import '../services/email_service.dart';
import '../services/message_state_service.dart';
import '../services/quick_links_config_service.dart';
import '../services/sports_attendance_service.dart';
import '../services/storage_service.dart';
import '../services/student_report_service.dart';
import '../utils/query_result_messages.dart';
import '../widgets/campus_network_status_indicator.dart';
import '../widgets/refresh_feedback_action.dart';
import 'external_link_confirmation_page.dart';
part 'home_campus_card_balance_card.dart';
part 'home_campus_card_detail_page.dart';
part 'home_dashboard_view.dart';

/// 首页校园卡概览的确定性展示状态，仅用于视觉 fixture 与状态回归测试。
enum HomeCampusCardDisplayState { loading, content, empty, stale, error }

/// 首页整体的确定性展示状态，用于缓存生命周期与视觉回归。
enum HomeDashboardDisplayState { initial, loading, content, stale, error }

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

  /// 测试专用：跳过缓存读取并直接展示固定校园卡结果。
  final CampusCardQueryResult? campusCardResultOverride;

  /// 测试专用：覆盖首页校园卡概览状态。
  final HomeCampusCardDisplayState? campusCardDisplayStateOverride;

  /// 测试专用：固定缓存陈旧判断与详情页相对时间。
  final DateTime? nowOverride;

  /// 测试专用：首页待办使用确定性脱敏消息。
  final List<MessageItem>? messagesOverride;

  /// 测试专用：固定首页本地数据更新时间。
  final DateTime? homeUpdatedAtOverride;

  /// 测试专用：固定首页下一项倒计时文案。
  final int? homeCountdownMinutesOverride;

  /// 测试专用：按课程名固定时间轨显示时刻，不改变课程合法节次。
  final Map<String, String>? homeCourseTimeOverrides;

  /// 测试专用：覆盖首页整体状态并停止从异步加载推断状态。
  final HomeDashboardDisplayState? dashboardDisplayStateOverride;

  /// 测试专用：直接注入首页课表缓存，跳过异步本地读取。
  final AcademicEamsQueryResult? courseTableResultOverride;

  /// 测试专用：直接注入首页教务摘要缓存。
  final AcademicEamsQueryResult? academicOverviewResultOverride;

  /// 测试专用：直接注入首页体育考勤缓存。
  final SportsAttendanceQueryResult? sportsAttendanceResultOverride;

  /// 测试专用：直接注入首页邮箱缓存。
  final EmailMailboxQueryResult? emailResultOverride;

  /// 测试专用：直接注入首页第二课堂缓存。
  final StudentReportQueryResult? studentReportResultOverride;

  /// 测试专用：直接注入首页常用入口。
  final List<QuickLinkItemConfig>? quickLinkFavoritesOverride;

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
    this.campusCardResultOverride,
    this.campusCardDisplayStateOverride,
    this.nowOverride,
    this.messagesOverride,
    this.homeUpdatedAtOverride,
    this.homeCountdownMinutesOverride,
    this.homeCourseTimeOverrides,
    this.dashboardDisplayStateOverride,
    this.courseTableResultOverride,
    this.academicOverviewResultOverride,
    this.sportsAttendanceResultOverride,
    this.emailResultOverride,
    this.studentReportResultOverride,
    this.quickLinkFavoritesOverride,
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
  AcademicEamsQueryResult? _courseTableResult;
  AcademicEamsQueryResult? _academicOverviewResult;
  SportsAttendanceQueryResult? _sportsAttendanceResult;
  EmailMailboxQueryResult? _emailResult;
  StudentReportQueryResult? _studentReportResult;
  List<QuickLinkItemConfig> _quickLinkFavorites = const [];
  AcademicCredentialsStatus _credentialsStatus =
      const AcademicCredentialsStatus.empty();
  bool _dashboardCachesLoading = false;
  Object? _dashboardCacheError;
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
          now: widget.nowOverride == null ? null : () => widget.nowOverride!,
        )..addListener(_handleCampusCardRefreshControllerChanged);
    _campusCardResult = widget.campusCardResultOverride;
    _courseTableResult = widget.courseTableResultOverride;
    _academicOverviewResult = widget.academicOverviewResultOverride;
    _sportsAttendanceResult = widget.sportsAttendanceResultOverride;
    _emailResult = widget.emailResultOverride;
    _studentReportResult = widget.studentReportResultOverride;
    _quickLinkFavorites = widget.quickLinkFavoritesOverride ?? const [];
    _credentialChangeSubscription = AcademicCredentialsService.instance.changes
        .listen((_) {
          _clearAuthenticatedState();
          unawaited(_loadDashboardCaches());
          unawaited(_loadCredentialsStatus());
        });
    if (widget.messagesOverride == null) {
      _loadLatestMessages();
    } else {
      _latestMessages = List<MessageItem>.of(widget.messagesOverride!);
    }
    _loadHomeVisibilitySettings();
    if (widget.campusCardResultOverride == null &&
        widget.campusCardDisplayStateOverride == null) {
      _loadCampusCardCacheAndSettings();
    } else {
      _loadCampusCardAutoRefreshSettings();
    }
    if (widget.courseTableResultOverride == null ||
        widget.academicOverviewResultOverride == null ||
        widget.sportsAttendanceResultOverride == null ||
        widget.emailResultOverride == null ||
        widget.studentReportResultOverride == null ||
        widget.quickLinkFavoritesOverride == null) {
      _loadDashboardCaches();
    }
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
      _courseTableResult = null;
      _academicOverviewResult = null;
      _sportsAttendanceResult = null;
      _emailResult = null;
      _studentReportResult = null;
      _quickLinkFavorites = const [];
      _credentialsStatus = const AcademicCredentialsStatus.empty();
    });
  }

  /// 读取清源首页各语义区域的显隐设置。
  Future<void> _loadHomeVisibilitySettings() async {
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
    final messagesVisible = await StorageService.getBool(
      StorageKeys.homeMessagesTileVisible,
      defaultValue: true,
    );
    final emailVisible = await StorageService.getBool(
      StorageKeys.homeEmailTileVisible,
      defaultValue: true,
    );
    final studentReportVisible = await StorageService.getBool(
      StorageKeys.homeStudentReportTileVisible,
      defaultValue: true,
    );
    final quickLinksVisible = await StorageService.getBool(
      StorageKeys.homeQuickLinksTileVisible,
      defaultValue: true,
    );
    final credentialsStatus = await AcademicCredentialsService.instance
        .getStatus();
    if (!mounted) return;
    setState(() {
      _studentProfileCardVisible = visible;
      _campusCardCardVisible = campusCardVisible;
      _todayCoursesTileVisible = todayCoursesVisible;
      _sportsAttendanceTileVisible = sportsAttendanceVisible;
      _messagesTileVisible = messagesVisible;
      _emailTileVisible = emailVisible;
      _studentReportTileVisible = studentReportVisible;
      _quickLinksTileVisible = quickLinksVisible;
      _credentialsStatus = credentialsStatus;
    });
  }

  Future<void> _loadCredentialsStatus() async {
    final status = await AcademicCredentialsService.instance.getStatus();
    if (!mounted) return;
    setState(() => _credentialsStatus = status);
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
    _dashboardCachesLoading = true;
    _dashboardCacheError = null;
    try {
      final results = await Future.wait<Object?>([
        widget.courseTableResultOverride == null
            ? _academicEamsService.readLatestCachedCourseTable()
            : Future.value(widget.courseTableResultOverride),
        widget.academicOverviewResultOverride == null
            ? _academicEamsService.readLatestCachedOverview()
            : Future.value(widget.academicOverviewResultOverride),
        widget.sportsAttendanceResultOverride == null
            ? _sportsAttendanceService.readLatestCachedAttendanceSummary()
            : Future.value(widget.sportsAttendanceResultOverride),
        widget.emailResultOverride == null
            ? _emailService.readLatestCachedMessages(EmailProtocol.imap)
            : Future.value(widget.emailResultOverride),
        widget.studentReportResultOverride == null
            ? _studentReportService.readLatestCachedSecondClassroomCredits()
            : Future.value(widget.studentReportResultOverride),
        widget.quickLinkFavoritesOverride == null
            ? _loadQuickLinkFavorites()
            : Future.value(widget.quickLinkFavoritesOverride),
      ]);
      if (!mounted) return;
      setState(() {
        _courseTableResult = results[0] as AcademicEamsQueryResult?;
        _academicOverviewResult = results[1] as AcademicEamsQueryResult?;
        _sportsAttendanceResult = results[2] as SportsAttendanceQueryResult?;
        _emailResult = results[3] as EmailMailboxQueryResult?;
        _studentReportResult = results[4] as StudentReportQueryResult?;
        _quickLinkFavorites =
            (results[5] as List<QuickLinkItemConfig>?) ?? const [];
        _dashboardCachesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _dashboardCachesLoading = false;
        _dashboardCacheError = error;
      });
    }
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
    return _buildQingyuanHomePage(context);
  }

  List<AcademicCourseTableEntry> get _todayCourseEntries {
    final weekday = (widget.nowOverride ?? DateTime.now()).weekday;
    final entries = <AcademicCourseTableEntry>[
      ...?_courseTableResult?.snapshot?.courseTable?.entries.where(
        (entry) => entry.weekday == weekday,
      ),
    ];
    entries.sort((a, b) => a.startUnit.compareTo(b.startUnit));
    return entries;
  }
}
