/*
 * 设置页 — 页面级状态与分区切换入口
 * @Project : SSPU-AllinOne
 * @File : settings_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

// ignore_for_file: use_build_context_synchronously

import '../design/fluent_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/channel_config.dart';
import '../services/academic_eams_service.dart';
import '../services/app_display_name_service.dart';
import '../services/app_exit_service.dart';
import '../services/academic_credentials_service.dart';
import '../services/campus_card_service.dart';
import '../services/campus_network_status_service.dart';
import '../services/email_service.dart';
import '../services/message_state_service.dart';
import '../services/password_service.dart';
import '../services/sports_attendance_service.dart';
import '../services/storage_service.dart';
import '../services/student_report_service.dart';
import '../services/system_auth_service.dart';
import '../theme/fluent_tokens.dart';
import '../widgets/channel_list_section.dart';
import '../widgets/app_feedback.dart';
import '../widgets/password_dialogs.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/settings_academic_term_section.dart';
import '../widgets/settings_auto_refresh_section.dart';
import '../widgets/settings_general_section.dart';
import '../widgets/settings_security_section.dart';
import '../widgets/settings_wechat_section.dart';
import '../widgets/settings_widgets.dart';
import 'about_page.dart';

part 'settings_page_actions.dart';
part 'settings_page_layout.dart';

/// 设置页面。
/// 页面本身只负责分区切换、常规/安全状态与顶部布局；
/// 微信推文等复杂模块交由独立组件维护，降低入口文件耦合度。
class SettingsPage extends StatefulWidget {
  /// 手动上锁回调。
  final VoidCallback? onLock;

  /// 测试专用：覆盖学期设置页当前日期。
  final DateTime? academicTermNow;

  /// 初始或后续定位请求。
  final SettingsLandingRequest? landingRequest;

  const SettingsPage({
    super.key,
    this.onLock,
    this.academicTermNow,
    this.landingRequest,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with _SettingsPageActions, _SettingsPageLayout {
  /// 是否已设置密码保护。
  @override
  bool _isPasswordEnabled = false;

  /// 是否已启用系统快速验证。
  @override
  bool _isQuickAuthEnabled = false;

  /// 当前平台/设备是否支持系统快速验证。
  @override
  bool _isQuickAuthAvailable = false;

  /// 是否正在处理系统快速验证开关。
  @override
  bool _isQuickAuthBusy = false;

  /// 是否正在加载设置。
  @override
  bool _isLoading = true;

  /// 关闭按钮行为偏好（ask / minimize / exit）。
  @override
  String _closeBehavior = 'ask';

  /// 消息推送总开关。
  @override
  bool _notificationEnabled = true;

  /// 勿扰模式开关。
  @override
  bool _dndEnabled = false;

  /// 首页是否显示学籍信息卡片。
  @override
  bool _homeStudentProfileCardVisible = true;

  /// 首页是否显示校园卡余额卡片。
  @override
  bool _homeCampusCardBalanceCardVisible = true;

  /// 首页是否显示今日课程磁贴。
  @override
  bool _homeTodayCoursesTileVisible = true;

  /// 首页是否显示体育考勤磁贴。
  @override
  bool _homeSportsAttendanceTileVisible = true;

  /// 首页是否显示第二课堂磁贴。
  @override
  bool _homeStudentReportTileVisible = true;

  /// 首页是否显示最新消息磁贴。
  @override
  bool _homeMessagesTileVisible = true;

  /// 首页是否显示邮箱摘要磁贴。
  @override
  bool _homeEmailTileVisible = true;

  /// 首页是否显示快速跳转磁贴。
  @override
  bool _homeQuickLinksTileVisible = true;

  /// 勿扰开始时间。
  @override
  int _dndStartHour = 22;
  @override
  int _dndStartMinute = 0;

  /// 勿扰结束时间。
  @override
  int _dndEndHour = 7;
  @override
  int _dndEndMinute = 0;

  /// 校园网 / VPN 状态自动检测间隔，单位分钟。
  @override
  int _campusNetworkDetectionIntervalMinutes =
      CampusNetworkStatusService.defaultDetectionIntervalMinutes;

  /// 体育部课外活动考勤自动刷新开关。
  @override
  bool _sportsAttendanceAutoRefreshEnabled = false;

  /// 体育部课外活动考勤自动刷新间隔，单位分钟。
  @override
  int _sportsAttendanceAutoRefreshIntervalMinutes =
      SportsAttendanceService.defaultAutoRefreshIntervalMinutes;

  /// 校园卡余额自动刷新开关。
  @override
  bool _campusCardAutoRefreshEnabled = false;

  /// 校园卡余额自动刷新间隔，单位分钟。
  @override
  int _campusCardAutoRefreshIntervalMinutes =
      CampusCardService.defaultAutoRefreshIntervalMinutes;

  /// 学校邮箱自动刷新开关。
  @override
  bool _emailAutoRefreshEnabled = false;

  /// 学校邮箱自动刷新间隔，单位分钟。
  @override
  int _emailAutoRefreshIntervalMinutes =
      EmailService.defaultAutoRefreshIntervalMinutes;

  /// 第二课堂学分自动刷新开关。
  @override
  bool _studentReportAutoRefreshEnabled = false;

  /// 第二课堂学分自动刷新间隔，单位分钟。
  @override
  int _studentReportAutoRefreshIntervalMinutes =
      StudentReportService.defaultAutoRefreshIntervalMinutes;

  /// 本专科教务自动刷新开关。
  @override
  bool _academicEamsAutoRefreshEnabled = false;

  /// 本专科教务自动刷新间隔，单位分钟。
  @override
  int _academicEamsAutoRefreshIntervalMinutes =
      AcademicEamsService.defaultAutoRefreshIntervalMinutes;

  /// 当前选中的设置分区索引。
  /// 0=常规 1=学期 2=自动刷新 3=安全 4=职能部门 5=教学单位 6=微信推文 7=关于
  @override
  int _selectedTab = 0;

  /// 消息状态服务引用。
  @override
  final MessageStateService _messageState = MessageStateService.instance;

  @override
  void initState() {
    super.initState();
    _selectedTab = _tabIndexForLanding(widget.landingRequest?.section);
    _loadSettings();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final request = widget.landingRequest;
    if (request == null || identical(request, oldWidget.landingRequest)) {
      return;
    }
    setState(() => _selectedTab = _tabIndexForLanding(request.section));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const FluentPage(content: Center(child: FluentProgressRing()));
    }

    return FluentPage(
      header: const FluentPageHeader(title: Text('设置')),
      content: ResponsiveBuilder(
        builder: (context, deviceType, constraints) {
          return deviceType == DeviceType.phone
              ? _buildNarrowSettingsLayout(context)
              : _buildWideSettingsLayout(context);
        },
      ),
    );
  }
}

/// 设置页定位目标。
enum SettingsLandingSection {
  /// 常规。
  general,

  /// 学期。
  academicTerm,

  /// 自动刷新。
  autoRefresh,

  /// 安全。
  security,

  /// 职能部门。
  departments,

  /// 教学单位。
  teaching,

  /// 微信推文。
  wechat,

  /// 关于。
  about,
}

/// 设置页定位请求。
class SettingsLandingRequest {
  /// 构造设置页定位请求。
  SettingsLandingRequest(this.section) : issuedAt = DateTime.now();

  /// 目标分区。
  final SettingsLandingSection section;

  /// 请求创建时间，用于重复定位到同一分区时触发更新。
  final DateTime issuedAt;
}

int _tabIndexForLanding(SettingsLandingSection? section) {
  return switch (section) {
    SettingsLandingSection.general || null => 0,
    SettingsLandingSection.academicTerm => 1,
    SettingsLandingSection.autoRefresh => 2,
    SettingsLandingSection.security => 3,
    SettingsLandingSection.departments => 4,
    SettingsLandingSection.teaching => 5,
    SettingsLandingSection.wechat => 6,
    SettingsLandingSection.about => 7,
  };
}
