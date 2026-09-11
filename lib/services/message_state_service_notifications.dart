part of 'message_state_service.dart';

mixin MessageStateServiceNotifications {
  // ==================== 消息推送与勿扰模式 ====================

  /// 获取消息推送全局开关（默认开启）
  Future<bool> isNotificationEnabled() async {
    return await StorageService.getBool(
      MessageChannelKeys.notificationEnabled,
      defaultValue: true,
    );
  }

  /// 设置消息推送全局开关
  Future<void> setNotificationEnabled(bool enabled) async {
    await StorageService.setBool(
      MessageChannelKeys.notificationEnabled,
      enabled,
    );
  }

  /// 普通校园消息通知是否开启，默认开启以兼容既有全局通知行为。
  Future<bool> isMessageNotificationEnabled() {
    return StorageService.getBool(
      MessageChannelKeys.messageNotificationEnabled,
      defaultValue: true,
    );
  }

  /// 保存普通校园消息通知开关。
  Future<void> setMessageNotificationEnabled(bool enabled) {
    return StorageService.setBool(
      MessageChannelKeys.messageNotificationEnabled,
      enabled,
    );
  }

  /// 课程提醒是否开启，默认关闭以避免未经用户选择请求系统权限。
  Future<bool> isCourseReminderEnabled() {
    return StorageService.getBool(
      MessageChannelKeys.courseReminderEnabled,
      defaultValue: false,
    );
  }

  /// 保存课程提醒开关。
  Future<void> setCourseReminderEnabled(bool enabled) {
    return StorageService.setBool(
      MessageChannelKeys.courseReminderEnabled,
      enabled,
    );
  }

  /// 考试提醒是否开启，默认关闭。
  Future<bool> isExamReminderEnabled() {
    return StorageService.getBool(
      MessageChannelKeys.examReminderEnabled,
      defaultValue: false,
    );
  }

  /// 保存考试提醒开关。
  Future<void> setExamReminderEnabled(bool enabled) {
    return StorageService.setBool(
      MessageChannelKeys.examReminderEnabled,
      enabled,
    );
  }

  /// 课程默认提前 15 分钟提醒。
  Future<int> getCourseReminderLeadMinutes() async {
    return await StorageService.getInt(
          MessageChannelKeys.courseReminderLeadMinutes,
        ) ??
        15;
  }

  /// 保存课程提醒提前量，最长 7 天。
  Future<void> setCourseReminderLeadMinutes(int minutes) {
    return StorageService.setInt(
      MessageChannelKeys.courseReminderLeadMinutes,
      minutes.clamp(0, 7 * 24 * 60),
    );
  }

  /// 考试默认提前 1 天提醒。
  Future<int> getExamReminderLeadMinutes() async {
    return await StorageService.getInt(
          MessageChannelKeys.examReminderLeadMinutes,
        ) ??
        24 * 60;
  }

  /// 保存考试提醒提前量，最长 7 天。
  Future<void> setExamReminderLeadMinutes(int minutes) {
    return StorageService.setInt(
      MessageChannelKeys.examReminderLeadMinutes,
      minutes.clamp(0, 7 * 24 * 60),
    );
  }

  /// 获取勿扰模式是否开启（默认关闭）
  Future<bool> isDndEnabled() async {
    return await StorageService.getBool(MessageChannelKeys.dndEnabled);
  }

  /// 设置勿扰模式开关
  Future<void> setDndEnabled(bool enabled) async {
    await StorageService.setBool(MessageChannelKeys.dndEnabled, enabled);
  }

  /// 获取勿扰开始时间（默认 22:00）
  Future<int> getDndStartHour() async {
    return (await StorageService.getInt(MessageChannelKeys.dndStartHour)) ?? 22;
  }

  /// 获取勿扰开始分钟（默认 0）
  Future<int> getDndStartMinute() async {
    return (await StorageService.getInt(MessageChannelKeys.dndStartMinute)) ??
        0;
  }

  /// 获取勿扰结束时间（默认 7:00）
  Future<int> getDndEndHour() async {
    return (await StorageService.getInt(MessageChannelKeys.dndEndHour)) ?? 7;
  }

  /// 获取勿扰结束分钟（默认 0）
  Future<int> getDndEndMinute() async {
    return (await StorageService.getInt(MessageChannelKeys.dndEndMinute)) ?? 0;
  }

  /// 设置勿扰时间段（一次性保存开始和结束时间）
  Future<void> setDndTime({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    await StorageService.setInt(MessageChannelKeys.dndStartHour, startHour);
    await StorageService.setInt(MessageChannelKeys.dndStartMinute, startMinute);
    await StorageService.setInt(MessageChannelKeys.dndEndHour, endHour);
    await StorageService.setInt(MessageChannelKeys.dndEndMinute, endMinute);
  }

  /// 判断当前时间是否在勿扰时段内
  /// 支持跨午夜时段（如 22:00–7:00）
  Future<bool> isInDndPeriod() async {
    return isInDndPeriodAt(DateTime.now());
  }

  /// 判断指定本地时刻是否落在勿扰时段。
  Future<bool> isInDndPeriodAt(DateTime time) async {
    final enabled = await isDndEnabled();
    if (!enabled) return false;

    final startH = await getDndStartHour();
    final startM = await getDndStartMinute();
    final endH = await getDndEndHour();
    final endM = await getDndEndMinute();

    // 将时间转为当天分钟数以便比较
    final nowMinutes = time.hour * 60 + time.minute;
    final startMinutes = startH * 60 + startM;
    final endMinutes = endH * 60 + endM;

    if (startMinutes <= endMinutes) {
      // 同天时段，如 8:00–12:00
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // 跨午夜时段，如 22:00–7:00
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }
}
