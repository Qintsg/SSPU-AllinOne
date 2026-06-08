/*
 * 主页 — 应用首屏，展示欢迎信息与最新消息摘要
 * @Project : SSPU-AllinOne
 * @File : home_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'dart:async';

import '../design/fluent_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/campus_card.dart';
import '../models/message_item.dart';
import '../services/academic_credentials_service.dart';
import '../services/app_display_name_service.dart';
import '../services/campus_card_service.dart';
import '../services/campus_network_status_service.dart';
import '../services/message_state_service.dart';
import '../theme/fluent_tokens.dart';
import '../utils/webview_env.dart';
import '../widgets/campus_network_status_indicator.dart';
import '../widgets/responsive_layout.dart';
import 'webview_page.dart';

part 'home_campus_card_balance_card.dart';
part 'home_campus_card_detail_page.dart';

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

  const HomePage({
    super.key,
    this.campusCardService,
    this.campusNetworkStatusService,
    this.campusCardAutoRefreshEnabledOverride,
    this.campusCardAutoRefreshIntervalOverride,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 最新消息列表（最多 5 条）
  List<MessageItem> _latestMessages = [];

  CampusCardQueryResult? _campusCardResult;
  bool _isLoadingCampusCard = false;
  bool _campusCardAutoRefreshEnabled = false;
  Timer? _campusCardAutoRefreshTimer;
  StreamSubscription<int>? _credentialChangeSubscription;

  CampusCardBalanceClient get _campusCardService {
    return widget.campusCardService ?? CampusCardService.instance;
  }

  @override
  void initState() {
    super.initState();
    _credentialChangeSubscription = AcademicCredentialsService.instance.changes
        .listen((_) => _clearAuthenticatedState());
    _loadLatestMessages();
    _loadCampusCardCacheAndSettings();
  }

  void _clearAuthenticatedState() {
    if (!mounted) return;
    setState(() {
      _campusCardResult = null;
      _isLoadingCampusCard = false;
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

  /// 读取校园卡自动刷新设置；默认不主动访问 OA / 校园卡系统。
  Future<void> _loadCampusCardAutoRefreshSettings() async {
    final enabled =
        widget.campusCardAutoRefreshEnabledOverride ??
        await CampusCardService.instance.isAutoRefreshEnabled();
    final interval =
        widget.campusCardAutoRefreshIntervalOverride ??
        await CampusCardService.instance.getAutoRefreshIntervalMinutes();
    if (!mounted) return;
    setState(() => _campusCardAutoRefreshEnabled = enabled);
    _restartCampusCardAutoRefreshTimer(enabled, interval);
    if (enabled && _shouldAutoRefresh(_campusCardResult?.checkedAt, interval)) {
      unawaited(_loadCampusCard(silent: true));
    }
  }

  void _restartCampusCardAutoRefreshTimer(bool enabled, int intervalMinutes) {
    _campusCardAutoRefreshTimer?.cancel();
    _campusCardAutoRefreshTimer = null;
    if (!enabled || intervalMinutes <= 0) return;
    _campusCardAutoRefreshTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) {
        if (_shouldAutoRefresh(_campusCardResult?.checkedAt, intervalMinutes)) {
          unawaited(_loadCampusCard(silent: true));
        }
      },
    );
  }

  /// 先显示本地校园卡缓存，再根据设置决定是否静默刷新。
  Future<void> _loadCampusCardCacheAndSettings() async {
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
    if (_isLoadingCampusCard) return;
    if (!silent) setState(() => _isLoadingCampusCard = true);

    final result = await _campusCardService.fetchCampusCard(
      startDate: startDate,
      endDate: endDate,
      requireCampusNetwork: silent,
    );
    if (!mounted) return;
    if (silent && !result.isSuccess) return;
    setState(() {
      _campusCardResult = result;
      if (!silent) _isLoadingCampusCard = false;
    });
  }

  bool _shouldAutoRefresh(DateTime? fetchedAt, int intervalMinutes) {
    if (intervalMinutes <= 0) return false;
    if (fetchedAt == null) return true;
    return DateTime.now().difference(fetchedAt) >=
        Duration(minutes: intervalMinutes);
  }

  @override
  void dispose() {
    _credentialChangeSubscription?.cancel();
    _campusCardAutoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ResponsiveBuilder(
      builder: (context, deviceType, constraints) {
        // 根据设备类型调整页面边距与磁贴尺寸
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
            FluentSurface(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isDark
                              ? FluentDarkColors.backgroundSecondary
                              : FluentLightColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(
                            FluentRadius.xxLarge,
                          ),
                          boxShadow: isDark
                              ? FluentElevation.cardRestDark
                              : FluentElevation.cardRest,
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                      const SizedBox(width: FluentSpacing.l),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '欢迎使用 ${AppDisplayName.of(context)}',
                              style: theme.typography.subtitle,
                            ),
                            const SizedBox(height: FluentSpacing.s),
                            Text(
                              '上海第二工业大学校园综合服务应用',
                              style: theme.typography.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(
                  duration: FluentDuration.slow,
                  curve: FluentEasing.decelerate,
                )
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: FluentSpacing.l),

            _buildCampusCardBalanceCard(context)
                .animate(delay: 100.ms)
                .fadeIn(
                  duration: FluentDuration.slow,
                  curve: FluentEasing.decelerate,
                )
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: FluentSpacing.l),

            FluentSurface(
                  padding: const EdgeInsets.all(FluentSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FluentSectionHeader(
                        title: '最新消息',
                        subtitle: '展示最近 5 条已启用渠道消息',
                        icon: FluentIcons.news,
                      ),
                      const SizedBox(height: FluentSpacing.m),
                      if (_latestMessages.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: FluentSpacing.xl,
                            ),
                            child: Text(
                              '暂无消息，开启信息渠道并等待自动刷新后将在此显示',
                              style: theme.typography.caption,
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (
                              int i = 0;
                              i < _latestMessages.length;
                              i++
                            ) ...[
                              if (i > 0) const Divider(),
                              _buildMessageItem(context, _latestMessages[i]),
                            ],
                          ],
                        ),
                    ],
                  ),
                )
                .animate(delay: 200.ms)
                .fadeIn(
                  duration: FluentDuration.slow,
                  curve: FluentEasing.decelerate,
                )
                .slideY(begin: 0.05, end: 0),
          ],
        );
      },
    );
  }

  /// 构建单条消息项（点击跳转内嵌 WebView）
  Widget _buildMessageItem(BuildContext context, MessageItem msg) {
    final theme = FluentTheme.of(context);
    return FluentHoverButton(
      onPressed: () async {
        // 标记已读并跳转内嵌 WebView。
        MessageStateService.instance.markAsRead(msg.id);
        final webViewEnvironment = await ensureGlobalWebViewEnvironment();
        if (!context.mounted) return;
        Navigator.of(context).push(
          FluentPageRoute(
            builder: (_) => WebViewPage(
              url: msg.url,
              initialTitle: msg.title,
              webViewEnvironment: webViewEnvironment,
            ),
          ),
        );
      },
      builder: (context, states) {
        final isHovered = states.isHovered;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          decoration: BoxDecoration(
            color: isHovered
                ? theme.resources.subtleFillColorSecondary
                : Colors.transparent,
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
