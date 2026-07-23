/*
 * 主页 — 应用首屏，展示欢迎信息与最新消息摘要
 * @Project : SSPU-AllinOne
 * @File : home_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'dart:async';

import '../controllers/card_auto_refresh_controller.dart';
import '../design/qingyuan/qingyuan_ui.dart';
import '../models/campus_card.dart';
import '../models/course_period.dart';
import '../models/academic_eams.dart';
import '../models/email_mailbox.dart';
import '../models/message_item.dart';
import '../models/sports_attendance.dart';
import '../services/academic_credentials_service.dart';
import '../services/academic_eams_service.dart';
import '../services/campus_card_service.dart';
import '../services/campus_network_status_service.dart';
import '../services/email_service.dart';
import '../services/message_state_service.dart';
import '../services/sports_attendance_service.dart';
import '../services/storage_service.dart';
import '../services/student_report_service.dart';
import '../utils/query_result_messages.dart';
import '../widgets/campus_network_status_indicator.dart';
import '../widgets/refresh_feedback_action.dart';
part 'home_campus_card_balance_card.dart';
part 'home_campus_card_detail_page.dart';
part 'home_dashboard_view.dart';

/// 首页校园卡概览的确定性展示状态，仅用于视觉 fixture 与状态回归测试。
enum HomeCampusCardDisplayState { loading, content, empty, stale, error }

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

  /// 测试专用：直接注入首页课表缓存，跳过异步本地读取。
  final AcademicEamsQueryResult? courseTableResultOverride;

  /// 测试专用：直接注入首页教务摘要缓存。
  final AcademicEamsQueryResult? academicOverviewResultOverride;

  /// 测试专用：直接注入首页体育考勤缓存。
  final SportsAttendanceQueryResult? sportsAttendanceResultOverride;

  /// 测试专用：直接注入首页邮箱缓存。
  final EmailMailboxQueryResult? emailResultOverride;

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
    this.courseTableResultOverride,
    this.academicOverviewResultOverride,
    this.sportsAttendanceResultOverride,
    this.emailResultOverride,
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
  bool _studentProfileCardVisible = true;
  bool _campusCardCardVisible = true;
  bool _todayCoursesTileVisible = true;
  bool _sportsAttendanceTileVisible = true;
  bool _messagesTileVisible = true;
  bool _emailTileVisible = true;
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
    _credentialChangeSubscription = AcademicCredentialsService.instance.changes
        .listen((_) {
          _clearAuthenticatedState();
          unawaited(_loadDashboardCaches());
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
    if (widget.courseTableResultOverride == null &&
        widget.academicOverviewResultOverride == null &&
        widget.sportsAttendanceResultOverride == null &&
        widget.emailResultOverride == null) {
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
    if (!mounted) return;
    setState(() {
      _studentProfileCardVisible = visible;
      _campusCardCardVisible = campusCardVisible;
      _todayCoursesTileVisible = todayCoursesVisible;
      _sportsAttendanceTileVisible = sportsAttendanceVisible;
      _messagesTileVisible = messagesVisible;
      _emailTileVisible = emailVisible;
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
      _academicEamsService.readLatestCachedOverview(),
      _sportsAttendanceService.readLatestCachedAttendanceSummary(),
      _emailService.readLatestCachedMessages(EmailProtocol.imap),
    ]);
    if (!mounted) return;
    setState(() {
      _courseTableResult = results[0] as AcademicEamsQueryResult?;
      _academicOverviewResult = results[1] as AcademicEamsQueryResult?;
      _sportsAttendanceResult = results[2] as SportsAttendanceQueryResult?;
      _emailResult = results[3] as EmailMailboxQueryResult?;
    });
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
