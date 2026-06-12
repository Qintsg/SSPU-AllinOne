/*
 * 统一数据存储键 — 管理所有持久化键名
 * @Project : SSPU-AllinOne
 * @File : storage_keys.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

part of 'storage_service.dart';

/// 存储键名常量。
/// 新增存储项时在此添加键名，保持集中管理。
class StorageKeys {
  StorageKeys._();

  /// 密码哈希。
  static const String passwordHash = 'app_password_hash';

  /// 系统快速验证开关，仅表示用户是否允许使用本机系统认证解锁应用。
  static const String quickAuthEnabled = 'app_quick_auth_enabled';

  /// 旧版 EULA 接受状态，保留用于兼容旧数据与旧测试夹具。
  static const String eulaAccepted = 'eula_accepted';

  /// 当前完整法律与隐私说明接受状态。
  static const String agreementAccepted = kLegalAgreementAcceptedKey;

  /// 关闭行为偏好（ask / minimize / exit）。
  static const String closeBehavior = 'close_behavior';

  /// 首页是否显示学籍信息卡片。
  static const String homeStudentProfileCardVisible =
      'home_student_profile_card_visible';

  /// 首页是否显示校园卡余额卡片。
  static const String homeCampusCardBalanceCardVisible =
      'home_campus_card_balance_card_visible';

  /// 首页是否显示今日课程磁贴。
  static const String homeTodayCoursesTileVisible =
      'home_today_courses_tile_visible';

  /// 首页是否显示体育考勤磁贴。
  static const String homeSportsAttendanceTileVisible =
      'home_sports_attendance_tile_visible';

  /// 首页是否显示第二课堂磁贴。
  static const String homeStudentReportTileVisible =
      'home_student_report_tile_visible';

  /// 首页是否显示最新消息磁贴。
  static const String homeMessagesTileVisible = 'home_messages_tile_visible';

  /// 首页是否显示邮箱摘要磁贴。
  static const String homeEmailTileVisible = 'home_email_tile_visible';

  /// 首页是否显示快速跳转磁贴。
  static const String homeQuickLinksTileVisible =
      'home_quick_links_tile_visible';

  /// 快速跳转常用入口 URL 列表。
  static const String quickLinkFavoriteUrls = 'quick_link_favorite_urls';

  /// 校园网 / VPN 状态检测间隔（分钟，0 = 关闭自动检测）。
  static const String campusNetworkDetectionIntervalMinutes =
      'campus_network_detection_interval_minutes';

  /// 体育部课外活动考勤自动刷新开关。
  static const String sportsAttendanceAutoRefreshEnabled =
      'sports_attendance_auto_refresh_enabled';

  /// 体育部课外活动考勤自动刷新间隔（分钟）。
  static const String sportsAttendanceAutoRefreshIntervalMinutes =
      'sports_attendance_auto_refresh_interval_minutes';

  /// 校园卡余额自动刷新开关。
  static const String campusCardAutoRefreshEnabled =
      'campus_card_auto_refresh_enabled';

  /// 校园卡余额自动刷新间隔（分钟）。
  static const String campusCardAutoRefreshIntervalMinutes =
      'campus_card_auto_refresh_interval_minutes';

  /// 学校邮箱自动刷新开关。
  static const String emailAutoRefreshEnabled = 'email_auto_refresh_enabled';

  /// 学校邮箱自动刷新间隔（分钟）。
  static const String emailAutoRefreshIntervalMinutes =
      'email_auto_refresh_interval_minutes';

  /// 第二课堂学分自动刷新开关。
  static const String studentReportAutoRefreshEnabled =
      'student_report_auto_refresh_enabled';

  /// 第二课堂学分自动刷新间隔（分钟）。
  static const String studentReportAutoRefreshIntervalMinutes =
      'student_report_auto_refresh_interval_minutes';

  /// 本专科教务只读能力自动刷新开关。
  static const String academicEamsAutoRefreshEnabled =
      'academic_eams_auto_refresh_enabled';

  /// 本专科教务只读能力自动刷新间隔（分钟）。
  static const String academicEamsAutoRefreshIntervalMinutes =
      'academic_eams_auto_refresh_interval_minutes';

  /// 历史全局学期自动切换开关，保留用于迁移清理。
  static const String academicTermAutoSwitchEnabled =
      'academic_term_auto_switch_enabled';

  /// 全局学期选择的学年。
  static const String academicTermManualYear = 'academic_term_manual_year';

  /// 全局学期选择的季节。
  static const String academicTermManualSeason = 'academic_term_manual_season';

  /// 历史全局手动周数，保留用于迁移清理。
  static const String academicTermManualWeek = 'academic_term_manual_week';

  /// 结构化数据前缀（JSON 序列化存储）。
  static const String dataPrefix = 'data_';

  /// 校园卡业务快照缓存集合。
  static const String campusCardCacheCollection = 'cache_campus_card';

  /// 体育部考勤业务快照缓存集合。
  static const String sportsAttendanceCacheCollection =
      'cache_sports_attendance';

  /// 第二课堂学分业务快照缓存集合。
  static const String studentReportCacheCollection = 'cache_student_report';

  /// 本专科教务摘要业务快照缓存集合。
  static const String academicEamsOverviewCacheCollection =
      'cache_academic_eams_overview';

  /// 本专科教务课表业务快照缓存集合。
  static const String academicEamsCourseTableCacheCollection =
      'cache_academic_eams_course_table';

  /// 本专科教务考试安排业务快照缓存集合。
  static const String academicEamsExamScheduleCacheCollection =
      'cache_academic_eams_exam_schedule';

  /// 教务处校历缓存集合。
  static const String academicCalendarCollection = 'cache_academic_calendar';

  /// 校历页面上次自动刷新时间。
  static const String academicCalendarLastAutoRefreshAt =
      'academic_calendar_last_auto_refresh_at';

  /// 学校邮箱业务快照缓存集合。
  static const String emailMailboxCacheCollection = 'cache_email_mailbox';
}
