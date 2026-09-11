/*
 * 消息状态服务测试 — 校验渠道默认启用状态和自动刷新间隔
 * @Project : SSPU-AllinOne
 * @File : message_state_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-22
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/channel_config.dart';
import 'package:sspu_allinone/models/message_item.dart';
import 'package:sspu_allinone/services/message_state_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  late Directory storageDirectory;

  setUp(() async {
    storageDirectory = await Directory.systemTemp.createTemp(
      'message_state_storage_',
    );
    StorageService.debugSetStateFilePathForTesting(
      '${storageDirectory.path}${Platform.pathSeparator}app_state.json',
    );
  });

  tearDown(() async {
    StorageService.debugSetStateFilePathForTesting(null);
    if (await storageDirectory.exists()) {
      await storageDirectory.delete(recursive: true);
    }
  });

  test('未写入存储时所有消息渠道默认开启', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    final stateService = MessageStateService.instance;

    final channels = [
      ...departmentChannels,
      ...teachingChannels,
      ...wechatChannels,
    ];
    for (final channel in channels) {
      expect(
        await stateService.isChannelEnabled(channel.id),
        isTrue,
        reason: '${channel.name} 应在首次使用时默认开启',
      );
    }
    expect(await stateService.isWechatServiceEnabled(), isTrue);
  });

  test('未写入存储时使用渠道配置中的默认刷新间隔', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    final stateService = MessageStateService.instance;

    // 官网和微信公众号可分别保留自己的默认刷新周期。
    expect(await stateService.getChannelInterval('jwc'), 60);
    expect(await stateService.getChannelInterval('sspu_activity'), 120);
    expect(await stateService.getChannelInterval('wechat_public'), 120);
    expect(await stateService.getChannelInterval('unknown_channel'), 0);
  });

  test('自动刷新关闭后保留最近一次有效间隔并可恢复', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    final stateService = MessageStateService.instance;

    // 设置页关闭自动刷新时仍需要保留原间隔，重新开启时恢复用户选择。
    await stateService.setChannelInterval('jwc', 30);
    expect(await stateService.isChannelAutoRefreshEnabled('jwc'), isTrue);

    await stateService.setChannelAutoRefreshEnabled('jwc', false);
    expect(await stateService.getChannelInterval('jwc'), 0);
    expect(await stateService.getChannelDisplayInterval('jwc'), 30);

    await stateService.setChannelAutoRefreshEnabled('jwc', true);
    expect(await stateService.getChannelInterval('jwc'), 30);
    expect(await stateService.isChannelAutoRefreshEnabled('jwc'), isTrue);
  });

  test('刷新条数配置限制在正整数安全范围内', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    final stateService = MessageStateService.instance;

    // 数字框只允许正整数；服务层额外兜底，避免异常值进入刷新链路。
    await stateService.setChannelManualFetchCount('jwc', -5);
    await stateService.setChannelAutoFetchCount('jwc', 250);

    expect(await stateService.getChannelManualFetchCount('jwc'), 1);
    expect(await stateService.getChannelAutoFetchCount('jwc'), 200);
  });

  test('课程和考试提醒默认关闭并持久化提前时间', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    final stateService = MessageStateService.instance;

    expect(await stateService.isCourseReminderEnabled(), isFalse);
    expect(await stateService.isExamReminderEnabled(), isFalse);
    expect(await stateService.getCourseReminderLeadMinutes(), 15);
    expect(await stateService.getExamReminderLeadMinutes(), 24 * 60);

    await stateService.setCourseReminderEnabled(true);
    await stateService.setExamReminderEnabled(true);
    await stateService.setCourseReminderLeadMinutes(30);
    await stateService.setExamReminderLeadMinutes(2 * 24 * 60);

    expect(await stateService.isCourseReminderEnabled(), isTrue);
    expect(await stateService.isExamReminderEnabled(), isTrue);
    expect(await stateService.getCourseReminderLeadMinutes(), 30);
    expect(await stateService.getExamReminderLeadMinutes(), 2 * 24 * 60);
  });

  test('普通消息通知默认开启并可独立持久化', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    final stateService = MessageStateService.instance;

    expect(await stateService.isNotificationEnabled(), isTrue);
    expect(await stateService.isMessageNotificationEnabled(), isTrue);
    await stateService.setMessageNotificationEnabled(false);
    expect(await stateService.isMessageNotificationEnabled(), isFalse);
    expect(await stateService.isNotificationEnabled(), isTrue);
  });

  test('计算刷新新增消息时会在本轮按 ID 去重，避免重复通知', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    final stateService = MessageStateService.instance;
    final first = _message('same-id', '第一版');
    final replacement = _message('same-id', '重复版本');
    final second = _message('second-id', '第二条');

    final newMessages = stateService.findNewMessages(
      [first],
      [replacement, replacement, second, second],
    );

    expect(newMessages.map((message) => message.id), ['second-id']);
  });
}

MessageItem _message(String id, String title) {
  return MessageItem(
    id: id,
    title: title,
    date: '2026-09-09',
    url: 'https://example.test/$id',
    sourceType: MessageSourceType.schoolWebsite,
    sourceName: MessageSourceName.sspuOfficial,
    category: MessageCategory.sspuNews,
  );
}
