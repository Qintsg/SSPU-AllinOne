/* 系统通知服务 — 五端即时通知与教务定时提醒。 */

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'academic_reminder_planner.dart';
import 'app_display_name_service.dart';
import 'storage_service.dart';

timezone.Location? _campusTimeZone;

timezone.Location _ensureCampusTimeZone() {
  final existing = _campusTimeZone;
  if (existing != null) return existing;
  timezone_data.initializeTimeZones();
  final location = timezone.getLocation('Asia/Shanghai');
  timezone.setLocalLocation(location);
  _campusTimeZone = location;
  return location;
}

/// 将一个绝对时刻转换为上海校历使用的无时区墙上时间。
DateTime campusWallClockNow([DateTime? instant]) {
  final shanghai = timezone.TZDateTime.from(
    (instant ?? DateTime.now()).toUtc(),
    _ensureCampusTimeZone(),
  );
  return DateTime(
    shanghai.year,
    shanghai.month,
    shanghai.day,
    shanghai.hour,
    shanghai.minute,
    shanghai.second,
    shanghai.millisecond,
    shanghai.microsecond,
  );
}

/// 把教务来源中的上海墙上时间转换为可交给通知插件的带时区时间。
timezone.TZDateTime campusScheduledDate(DateTime wallClock) {
  return timezone.TZDateTime(
    _ensureCampusTimeZone(),
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
    wallClock.millisecond,
    wallClock.microsecond,
  );
}

/// 当前系统通知权限状态。
enum NotificationPermissionStatus {
  granted,
  denied,
  unknown,
  unsupported,
  notRequired,
}

/// 教务提醒协调器使用的最小投递接口。
abstract class AcademicReminderDelivery {
  bool get supportsScheduling;

  Future<bool> requestPermission();

  /// 查询通知权限；旧测试投递器默认返回未知。
  Future<NotificationPermissionStatus> permissionStatus() async =>
      NotificationPermissionStatus.unknown;

  Future<void> replaceAcademicReminders(
    List<AcademicReminderRequest> reminders,
  );
}

/// 系统通知平台适配接口。
abstract class SystemNotificationAdapter {
  Future<void> initialize();

  Future<bool> requestPermission();

  /// 查询通知权限；无法查询的平台返回未知。
  Future<NotificationPermissionStatus> permissionStatus() async =>
      NotificationPermissionStatus.unknown;

  Future<void> show({required int id, required String title, String? body});

  Future<void> schedule(AcademicReminderRequest reminder);

  Future<void> cancel(int id);
}

/// 系统通知服务。
class NotificationService implements AcademicReminderDelivery {
  NotificationService({
    SystemNotificationAdapter? adapter,
    bool Function()? isAvailableResolver,
    bool Function()? supportsSchedulingResolver,
  }) : _adapter = adapter ?? FlutterLocalNotificationsAdapter(),
       _isAvailableResolver = isAvailableResolver ?? _defaultIsAvailable,
       _supportsSchedulingResolver =
           supportsSchedulingResolver ?? _defaultSupportsScheduling;

  static final NotificationService instance = NotificationService();

  final SystemNotificationAdapter _adapter;
  final bool Function() _isAvailableResolver;
  final bool Function() _supportsSchedulingResolver;
  bool _initialized = false;

  /// Web/Fuchsia 不在当前发布目标，其余五端支持即时通知。
  bool get isAvailable => _isAvailableResolver();

  @override
  bool get supportsScheduling => isAvailable && _supportsSchedulingResolver();

  /// 初始化当前平台的通知适配器，不主动弹出权限请求。
  Future<void> init() async {
    if (_initialized || !isAvailable) return;
    await _adapter.initialize();
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!isAvailable) return false;
    await init();
    return _adapter.requestPermission();
  }

  /// 查询当前平台的通知权限状态，不让插件查询失败阻断设置页。
  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    if (!isAvailable) return NotificationPermissionStatus.unsupported;
    try {
      await init();
      return await _adapter.permissionStatus();
    } catch (_) {
      return NotificationPermissionStatus.unknown;
    }
  }

  /// 发送一条即时系统通知。
  Future<void> show({required String title, String? body}) async {
    if (!isAvailable) return;
    await init();
    await _adapter.show(
      id: DateTime.now().microsecondsSinceEpoch & 0x7fffffff,
      title: title,
      body: body,
    );
  }

  /// 发送带副标题的即时通知。
  Future<void> showDetailed({
    required String title,
    String? subtitle,
    String? body,
  }) {
    final content = [
      if (subtitle != null && subtitle.trim().isNotEmpty) subtitle.trim(),
      if (body != null && body.trim().isNotEmpty) body.trim(),
    ].join('\n');
    return show(title: title, body: content.isEmpty ? null : content);
  }

  /// 用新计划原子替换本应用之前登记的教务提醒。
  @override
  Future<void> replaceAcademicReminders(
    List<AcademicReminderRequest> reminders,
  ) async {
    final previousIds = await StorageService.getStringList(
      StorageKeys.academicReminderNotificationIds,
    );
    if (isAvailable) {
      await init();
      for (final value in previousIds) {
        final id = int.tryParse(value);
        if (id != null) await _adapter.cancel(id);
      }
    }

    final scheduledIds = <String>[];
    if (supportsScheduling) {
      for (final reminder in reminders) {
        try {
          await _adapter.schedule(reminder);
          scheduledIds.add('${reminder.id}');
        } catch (error) {
          debugPrint('[NotificationService] 提醒调度失败: $error');
        }
      }
    }
    await StorageService.setStringList(
      StorageKeys.academicReminderNotificationIds,
      scheduledIds,
    );
  }

  static bool _defaultIsAvailable() {
    return !kIsWeb &&
        (Platform.isAndroid ||
            Platform.isIOS ||
            Platform.isWindows ||
            Platform.isMacOS ||
            Platform.isLinux);
  }

  static bool _defaultSupportsScheduling() {
    // Linux 通知服务器没有统一的持久化调度协议，保留即时通知。
    return !kIsWeb &&
        (Platform.isAndroid ||
            Platform.isIOS ||
            Platform.isWindows ||
            Platform.isMacOS);
  }
}

/// `flutter_local_notifications` 五端适配实现。
class FlutterLocalNotificationsAdapter implements SystemNotificationAdapter {
  FlutterLocalNotificationsAdapter({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'academic_reminders',
      '课程与考试提醒',
      channelDescription: '开课和考试前的本地提醒',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(threadIdentifier: 'academic-reminders'),
    macOS: DarwinNotificationDetails(threadIdentifier: 'academic-reminders'),
    linux: LinuxNotificationDetails(defaultActionName: '打开工大聚合'),
    windows: WindowsNotificationDetails(),
  );

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize() async {
    _ensureCampusTimeZone();
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('ic_launcher'),
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: const LinuxInitializationSettings(defaultActionName: '打开工大聚合'),
        windows: WindowsInitializationSettings(
          appName: AppDisplayName.currentPlatformName,
          appUserModelId: 'Qintsg.SSPUAllinOne.App',
          guid: '3f429a8e-7808-4bce-845f-f3d3f60493c1',
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    if (Platform.isMacOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    if (kIsWeb) return NotificationPermissionStatus.unsupported;
    if (Platform.isAndroid) {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      if (enabled == null) return NotificationPermissionStatus.unknown;
      return enabled
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    }
    if (Platform.isIOS) {
      final permissions = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      if (permissions == null) return NotificationPermissionStatus.unknown;
      return permissions.isEnabled
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    }
    if (Platform.isMacOS) {
      final permissions = await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      if (permissions == null) return NotificationPermissionStatus.unknown;
      return permissions.isEnabled
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    }
    if (Platform.isWindows || Platform.isLinux) {
      return NotificationPermissionStatus.notRequired;
    }
    return NotificationPermissionStatus.unsupported;
  }

  @override
  Future<void> show({required int id, required String title, String? body}) {
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  @override
  Future<void> schedule(AcademicReminderRequest reminder) {
    return _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: campusScheduledDate(reminder.scheduledAt),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'academic:${reminder.kind.name}',
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
