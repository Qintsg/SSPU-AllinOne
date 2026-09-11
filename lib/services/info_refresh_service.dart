/*
 * 信息中心刷新服务 — 保持官网与微信推文刷新进度和后台任务
 * @Project : SSPU-AllinOne
 * @File : info_refresh_service.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import 'package:flutter/foundation.dart';

import '../models/message_item.dart';
import 'auto_refresh_service.dart';
import 'message_state_service.dart';
import 'wechat_article_service.dart';

enum InfoRefreshKind { all, schoolWebsite, wechat }

class InfoRefreshSnapshot {
  final bool isRefreshing;
  final InfoRefreshKind? kind;
  final String text;
  final int completed;
  final int total;

  const InfoRefreshSnapshot({
    required this.isRefreshing,
    required this.kind,
    required this.text,
    required this.completed,
    required this.total,
  });

  const InfoRefreshSnapshot.idle()
    : isRefreshing = false,
      kind = null,
      text = '',
      completed = 0,
      total = 0;
}

/// 信息中心刷新协调器。
/// 切换页面时任务仍在单例服务内运行，页面返回后可继续读取当前进度。
class InfoRefreshService extends ChangeNotifier {
  InfoRefreshService._();

  static final InfoRefreshService instance = InfoRefreshService._();

  final MessageStateService _stateService = MessageStateService.instance;
  final AutoRefreshService _autoRefreshService = AutoRefreshService.instance;

  InfoRefreshSnapshot _snapshot = const InfoRefreshSnapshot.idle();
  Future<void>? _runningTask;

  InfoRefreshSnapshot get snapshot => _snapshot;

  bool get isRefreshing => _snapshot.isRefreshing;
  bool get isRefreshingSchoolWebsite =>
      _snapshot.kind == InfoRefreshKind.schoolWebsite && _snapshot.isRefreshing;
  bool get isRefreshingWechat =>
      _snapshot.kind == InfoRefreshKind.wechat && _snapshot.isRefreshing;

  Future<bool> startSchoolWebsiteRefresh() async {
    if (_runningTask != null) return false;
    _runningTask = _runSchoolWebsiteRefresh();
    notifyListeners();
    await _runningTask;
    return true;
  }

  Future<bool> startWechatRefresh() async {
    if (_runningTask != null) return false;
    _runningTask = _runWechatRefresh();
    notifyListeners();
    await _runningTask;
    return true;
  }

  /// 一次刷新全部已启用的官网与微信渠道。
  Future<bool> startAllEnabledRefresh() async {
    if (_runningTask != null) return false;
    _runningTask = _runAllEnabledRefresh();
    notifyListeners();
    await _runningTask;
    return true;
  }

  Future<void> _runAllEnabledRefresh() async {
    final websiteEnabled = await _autoRefreshService
        .hasEnabledSchoolWebsiteChannel();
    final wechatEnabled = await WechatArticleService.instance
        .hasConfiguredRefreshTarget();
    final totalEnabled = (websiteEnabled ? 1 : 0) + (wechatEnabled ? 1 : 0);
    _update(
      InfoRefreshSnapshot(
        isRefreshing: true,
        kind: InfoRefreshKind.all,
        text: totalEnabled == 0 ? '没有启用的刷新渠道' : '正在刷新全部启用渠道…',
        completed: 0,
        total: totalEnabled,
      ),
    );
    try {
      if (websiteEnabled) {
        await _runSchoolWebsiteRefresh(
          finishWhenDone: false,
          kind: InfoRefreshKind.all,
        );
      }
      if (wechatEnabled) {
        await _runWechatRefresh(
          finishWhenDone: false,
          kind: InfoRefreshKind.all,
        );
      }
      _update(
        InfoRefreshSnapshot(
          isRefreshing: true,
          kind: InfoRefreshKind.all,
          text: '全部启用渠道刷新完成',
          completed: totalEnabled,
          total: totalEnabled,
        ),
      );
    } finally {
      _finishSoon();
    }
  }

  Future<void> _runSchoolWebsiteRefresh({
    bool finishWhenDone = true,
    InfoRefreshKind kind = InfoRefreshKind.schoolWebsite,
  }) async {
    if (!await _autoRefreshService.hasEnabledSchoolWebsiteChannel()) {
      _update(
        InfoRefreshSnapshot(
          isRefreshing: true,
          kind: kind,
          text: '当前未启用任何官网消息刷新渠道',
          completed: 0,
          total: 0,
        ),
      );
      if (finishWhenDone) _finishSoon();
      return;
    }

    _update(
      InfoRefreshSnapshot(
        isRefreshing: true,
        kind: kind,
        text: '正在准备刷新官网消息...',
        completed: 0,
        total: 0,
      ),
    );

    try {
      final fetched = await _autoRefreshService
          .fetchEnabledSchoolWebsiteMessages(
            onBatchCompleted: (messages, completed, total) async {
              await _mergeAndPersist(messages);
              _update(
                InfoRefreshSnapshot(
                  isRefreshing: true,
                  kind: kind,
                  text: '已完成 $completed / $total 个渠道，新增 ${messages.length} 条',
                  completed: completed,
                  total: total,
                ),
              );
            },
          );
      _update(
        InfoRefreshSnapshot(
          isRefreshing: true,
          kind: kind,
          text: '官网消息刷新完成，获取 ${fetched.length} 条候选消息',
          completed: _snapshot.total,
          total: _snapshot.total,
        ),
      );
    } catch (error) {
      _update(
        InfoRefreshSnapshot(
          isRefreshing: true,
          kind: kind,
          text: '官网消息刷新失败：$error',
          completed: _snapshot.completed,
          total: _snapshot.total,
        ),
      );
    } finally {
      if (finishWhenDone) _finishSoon();
    }
  }

  Future<void> _runWechatRefresh({
    bool finishWhenDone = true,
    InfoRefreshKind kind = InfoRefreshKind.wechat,
  }) async {
    if (!await WechatArticleService.instance.hasConfiguredRefreshTarget()) {
      _update(
        InfoRefreshSnapshot(
          isRefreshing: true,
          kind: kind,
          text: '当前未启用任何微信推文刷新项',
          completed: 0,
          total: 0,
        ),
      );
      if (finishWhenDone) _finishSoon();
      return;
    }

    _update(
      InfoRefreshSnapshot(
        isRefreshing: true,
        kind: kind,
        text: '正在刷新最新微信推文...',
        completed: 0,
        total: 0,
      ),
    );

    try {
      final persistedMessages = await _stateService.loadMessages();
      final maxCount = await _stateService.getChannelManualFetchCount(
        'wechat_public',
        defaultValue: 10,
      );
      final result = await WechatArticleService.instance.fetchArticlesDetailed(
        maxCount: maxCount,
        knownMessageIds: persistedMessages.map((msg) => msg.id).toSet(),
        validateBeforeFetch: true,
        onAccountCompleted: (messages, completed, total, accountName) async {
          await _mergeAndPersist(messages);
          _update(
            InfoRefreshSnapshot(
              isRefreshing: true,
              kind: kind,
              text:
                  '已完成 $completed / $total 个公众号：$accountName，新增 ${messages.length} 条',
              completed: completed,
              total: total,
            ),
          );
        },
      );
      _update(
        InfoRefreshSnapshot(
          isRefreshing: true,
          kind: kind,
          text: result.summary,
          completed: result.completedAccounts,
          total: result.totalAccounts,
        ),
      );
    } catch (error) {
      _update(
        InfoRefreshSnapshot(
          isRefreshing: true,
          kind: kind,
          text: '微信推文刷新失败：$error',
          completed: _snapshot.completed,
          total: _snapshot.total,
        ),
      );
    } finally {
      if (finishWhenDone) _finishSoon();
    }
  }

  Future<void> _mergeAndPersist(List<MessageItem> messages) async {
    if (messages.isEmpty) return;
    final existingMessages = await _stateService.loadMessages();
    final merged = _stateService.mergeMessages(existingMessages, messages);
    await _stateService.saveMessages(merged);
  }

  void _update(InfoRefreshSnapshot snapshot) {
    _snapshot = snapshot;
    notifyListeners();
  }

  void _finishSoon() {
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      _snapshot = const InfoRefreshSnapshot.idle();
      _runningTask = null;
      notifyListeners();
    });
  }
}
