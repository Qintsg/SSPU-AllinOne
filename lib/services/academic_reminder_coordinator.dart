/* 教务提醒协调器 — 连接缓存、用户意愿、勿扰与系统调度。 */

import 'dart:async';

import '../models/academic_eams.dart';
import '../models/academic_term.dart';
import 'academic_eams_service.dart';
import 'academic_reminder_planner.dart';
import 'academic_term_service.dart';
import 'data_module_preferences.dart';
import 'message_state_service.dart';
import 'notification_service.dart';

enum AcademicReminderSyncStatus {
  scheduled,
  noData,
  globalDisabled,
  moduleDisabled,
  remindersDisabled,
  permissionDenied,
  unsupported,
  failed,
}

class AcademicReminderSyncResult {
  const AcademicReminderSyncResult({
    required this.status,
    required this.scheduledCount,
  });

  final AcademicReminderSyncStatus status;
  final int scheduledCount;
}

typedef AcademicReminderCourseLoader =
    Future<AcademicCourseTableSnapshot?> Function();
typedef AcademicReminderExamLoader = Future<AcademicExamSnapshot?> Function();
typedef AcademicReminderTermLoader = Future<AcademicTermContext> Function();
typedef AcademicReminderDndChecker = Future<bool> Function(DateTime time);

/// 根据当前缓存和通知意愿重建课程/考试的本地调度。
class AcademicReminderCoordinator {
  AcademicReminderCoordinator({
    required this.delivery,
    required this.isNotificationEnabled,
    required this.isCourseReminderEnabled,
    required this.isExamReminderEnabled,
    required this.isAcademicFetchEnabled,
    required this.loadCourseTable,
    required this.loadExams,
    required this.loadTermContext,
    required this.isInDndPeriodAt,
    this.getCourseLeadMinutes = _defaultCourseLeadMinutes,
    this.getExamLeadMinutes = _defaultExamLeadMinutes,
    DateTime Function()? now,
    this.horizon = const Duration(days: 45),
  }) : now = now ?? (() => campusWallClockNow());

  /// 连接应用真实缓存、设置与系统通知的全局实例。
  static final AcademicReminderCoordinator
  instance = AcademicReminderCoordinator(
    delivery: NotificationService.instance,
    isNotificationEnabled: MessageStateService.instance.isNotificationEnabled,
    isCourseReminderEnabled:
        MessageStateService.instance.isCourseReminderEnabled,
    isExamReminderEnabled: MessageStateService.instance.isExamReminderEnabled,
    isAcademicFetchEnabled: () => DataModulePreferences.instance.isFetchEnabled(
      CampusDataModule.academicEams,
    ),
    loadCourseTable: _loadCachedCourseTable,
    loadExams: _loadCachedExams,
    loadTermContext: AcademicTermService.instance.getEffectiveContext,
    isInDndPeriodAt: MessageStateService.instance.isInDndPeriodAt,
    getCourseLeadMinutes:
        MessageStateService.instance.getCourseReminderLeadMinutes,
    getExamLeadMinutes: MessageStateService.instance.getExamReminderLeadMinutes,
  );

  final AcademicReminderDelivery delivery;
  final Future<bool> Function() isNotificationEnabled;
  final Future<bool> Function() isCourseReminderEnabled;
  final Future<bool> Function() isExamReminderEnabled;
  final Future<bool> Function() isAcademicFetchEnabled;
  final AcademicReminderCourseLoader loadCourseTable;
  final AcademicReminderExamLoader loadExams;
  final AcademicReminderTermLoader loadTermContext;
  final AcademicReminderDndChecker isInDndPeriodAt;
  final Future<int> Function() getCourseLeadMinutes;
  final Future<int> Function() getExamLeadMinutes;
  final DateTime Function() now;
  final Duration horizon;

  bool _started = false;
  bool _syncRequested = false;
  Future<void>? _syncLoop;
  AcademicReminderSyncResult? _lastResult;
  StreamSubscription<void>? _academicCacheSubscription;
  StreamSubscription<CampusDataModule>? _moduleSubscription;

  /// 监听缓存、学期和模块设置变化；重复调用不会重复订阅。
  void start() {
    if (_started) return;
    _started = true;
    _academicCacheSubscription = AcademicEamsService.instance.cacheChanges
        .listen((_) => unawaited(requestSync()));
    _moduleSubscription = DataModulePreferences.instance.changes.listen((
      module,
    ) {
      if (module == CampusDataModule.academicEams) {
        unawaited(requestSync());
      }
    });
    AcademicTermService.instance.addListener(_handleTermChanged);
    unawaited(requestSync());
  }

  /// 串行合并短时间内的同步请求，避免旧缓存计划覆盖新缓存计划。
  Future<AcademicReminderSyncResult> requestSync() async {
    _syncRequested = true;
    final activeLoop = _syncLoop;
    if (activeLoop != null) {
      await activeLoop;
      return _lastResult!;
    }

    final completer = Completer<void>();
    _syncLoop = completer.future;
    try {
      do {
        _syncRequested = false;
        _lastResult = await sync();
      } while (_syncRequested);
      return _lastResult!;
    } finally {
      _syncLoop = null;
      completer.complete();
    }
  }

  void _handleTermChanged() => unawaited(requestSync());

  /// 测试或应用退出时释放监听。
  Future<void> dispose() async {
    AcademicTermService.instance.removeListener(_handleTermChanged);
    await _academicCacheSubscription?.cancel();
    await _moduleSubscription?.cancel();
    _academicCacheSubscription = null;
    _moduleSubscription = null;
    _started = false;
  }

  Future<AcademicReminderSyncResult> sync() async {
    if (!await isNotificationEnabled()) {
      await delivery.replaceAcademicReminders(const []);
      return const AcademicReminderSyncResult(
        status: AcademicReminderSyncStatus.globalDisabled,
        scheduledCount: 0,
      );
    }
    if (!await isAcademicFetchEnabled()) {
      await delivery.replaceAcademicReminders(const []);
      return const AcademicReminderSyncResult(
        status: AcademicReminderSyncStatus.moduleDisabled,
        scheduledCount: 0,
      );
    }
    final permission = await delivery.permissionStatus();
    if (permission == NotificationPermissionStatus.denied) {
      await delivery.replaceAcademicReminders(const []);
      return const AcademicReminderSyncResult(
        status: AcademicReminderSyncStatus.permissionDenied,
        scheduledCount: 0,
      );
    }
    if (!delivery.supportsScheduling) {
      await delivery.replaceAcademicReminders(const []);
      return const AcademicReminderSyncResult(
        status: AcademicReminderSyncStatus.unsupported,
        scheduledCount: 0,
      );
    }
    final courseEnabled = await isCourseReminderEnabled();
    final examEnabled = await isExamReminderEnabled();
    if (!courseEnabled && !examEnabled) {
      await delivery.replaceAcademicReminders(const []);
      return const AcademicReminderSyncResult(
        status: AcademicReminderSyncStatus.remindersDisabled,
        scheduledCount: 0,
      );
    }

    try {
      final courseTable = courseEnabled ? await loadCourseTable() : null;
      final exams = examEnabled ? await loadExams() : null;
      final term = courseEnabled ? (await loadTermContext()).definition : null;
      if (courseEnabled && term == null && exams == null) {
        await delivery.replaceAcademicReminders(const []);
        return const AcademicReminderSyncResult(
          status: AcademicReminderSyncStatus.noData,
          scheduledCount: 0,
        );
      }
      final planned = AcademicReminderPlanner.plan(
        courseTable: courseTable,
        exams: exams,
        term: term,
        now: now(),
        horizon: horizon,
        courseLeadTime: Duration(minutes: await getCourseLeadMinutes()),
        examLeadTime: Duration(minutes: await getExamLeadMinutes()),
      );
      final reminders = <AcademicReminderRequest>[];
      for (final reminder in planned) {
        if (!await isInDndPeriodAt(reminder.scheduledAt)) {
          reminders.add(reminder);
        }
      }
      await delivery.replaceAcademicReminders(reminders);
      return AcademicReminderSyncResult(
        status: reminders.isEmpty
            ? AcademicReminderSyncStatus.noData
            : AcademicReminderSyncStatus.scheduled,
        scheduledCount: reminders.length,
      );
    } catch (_) {
      await delivery.replaceAcademicReminders(const []);
      return const AcademicReminderSyncResult(
        status: AcademicReminderSyncStatus.failed,
        scheduledCount: 0,
      );
    }
  }

  static Future<int> _defaultCourseLeadMinutes() async => 15;

  static Future<int> _defaultExamLeadMinutes() async => 24 * 60;

  static Future<AcademicCourseTableSnapshot?> _loadCachedCourseTable() async {
    final dedicated = await AcademicEamsService.instance
        .readLatestCachedCourseTable();
    if (dedicated?.snapshot?.courseTable case final courseTable?) {
      return courseTable;
    }
    return (await AcademicEamsService.instance.readLatestCachedOverview())
        ?.snapshot
        ?.courseTable;
  }

  static Future<AcademicExamSnapshot?> _loadCachedExams() async {
    final dedicated = await AcademicEamsService.instance
        .readLatestCachedExamSchedule();
    if (dedicated?.snapshot?.exams case final exams?) return exams;
    return (await AcademicEamsService.instance.readLatestCachedOverview())
        ?.snapshot
        ?.exams;
  }
}
