/*
 * 微信公众号平台文章批量抓取 — 已关注账号分页读取与增量停止
 * @Project : SSPU-AllinOne
 * @File : wxmp_article_fetch.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'wxmp_article_service.dart';

extension WxmpArticleFetch on WxmpArticleService {
  /// 获取所有已关注公众号的最新文章，转为 MessageItem。
  /// [maxCount] 单个公众号最多读取的文章数上限。
  /// [knownMessageIds] 已持久化消息 ID，用于遇到旧文章时停止当前公众号解析。
  Future<List<MessageItem>> fetchArticles({
    int maxCount = 50,
    Set<String>? knownMessageIds,
    bool validateBeforeFetch = true,
    WxmpFetchProgressCallback? onAccountCompleted,
  }) async => (await fetchArticlesDetailed(
    maxCount: maxCount,
    knownMessageIds: knownMessageIds,
    validateBeforeFetch: validateBeforeFetch,
    onAccountCompleted: onAccountCompleted,
  )).messages;

  /// 获取文章并返回认证/限流/单来源失败等结构化结果。
  Future<WxmpFetchResult> fetchArticlesDetailed({
    int maxCount = 50,
    Set<String>? knownMessageIds,
    bool validateBeforeFetch = true,
    WxmpFetchProgressCallback? onAccountCompleted,
  }) async {
    final authStatus = await _auth.getAuthStatus();
    if (!authStatus.isUsable) {
      return WxmpFetchResult(
        messages: const [],
        completedAccounts: 0,
        totalAccounts: 0,
        failures: [
          WxmpAccountFetchFailure(
            accountName: '微信公众平台',
            kind: WxmpFetchFailureKind.authentication,
            message: authStatus.message,
          ),
        ],
      );
    }
    if (validateBeforeFetch) {
      final validation = await validateAuth();
      if (!validation.isValid) {
        return WxmpFetchResult(
          messages: const [],
          completedAccounts: 0,
          totalAccounts: 0,
          failures: [
            WxmpAccountFetchFailure(
              accountName: '微信公众平台',
              kind: WxmpFetchFailureKind.authentication,
              message: validation.message,
            ),
          ],
        );
      }
    }

    final followedMps = await getLocalFollowedMps();
    if (followedMps.isEmpty) {
      return const WxmpFetchResult(
        messages: [],
        completedAccounts: 0,
        totalAccounts: 0,
      );
    }

    // 文章抓取和系统通知是两条独立链路：单来源通知关闭后，
    // 该来源新文仍要进入消息中心，只在后续投递层跳过系统通知。
    final refreshEntries = followedMps.entries.toList(growable: false);

    final storedMessageIds =
        knownMessageIds ??
        (await _stateService.loadMessages()).map((msg) => msg.id).toSet();
    // 同一轮分页/多账号抓取也可能返回重复文章；将新 ID 立即加入集合，
    // 使后续页面和通知层都只看到一次。
    final seenMessageIds = <String>{...storedMessageIds};
    final allMessages = <MessageItem>[];
    final failures = <WxmpAccountFetchFailure>[];
    final config = await _loadConfigOrDefault();
    final perRequestLimit = config.perRequestArticleCount;
    final requestDelayMs = config.requestDelayMs;
    var completedAccounts = 0;
    for (final entry in refreshEntries) {
      final fakeid = entry.key;
      final mpInfo = entry.value;
      final mpName = _resolveAccountName(mpInfo, fakeid);
      final mpDisplayId = _resolveAccountDisplayId(mpInfo);
      final accountMessages = <MessageItem>[];
      final perRequestCount = maxCount > 0 && maxCount < perRequestLimit
          ? maxCount
          : perRequestLimit;
      var fetchedForMp = 0;
      var page = 0;
      var reachedKnownMessage = false;

      try {
        while (fetchedForMp < maxCount && !reachedKnownMessage) {
          final articles = await getArticles(
            fakeid,
            page: page,
            count: perRequestCount,
          );
          if (articles.isEmpty) break;

          for (final article in articles) {
            final msgItem = _articleToMessageItem(
              article,
              mpName,
              fakeid,
              mpDisplayId: mpDisplayId,
            );
            if (msgItem == null) continue;
            if (!seenMessageIds.add(msgItem.id)) {
              // 只有命中刷新前已持久化的消息才表示可以停止翻页；
              // 本轮新结果的重复项应跳过但不能截断后续文章。
              if (storedMessageIds.contains(msgItem.id)) {
                reachedKnownMessage = true;
                break;
              }
              continue;
            }
            allMessages.add(msgItem);
            accountMessages.add(msgItem);
            fetchedForMp++;
            if (fetchedForMp >= maxCount) break;
          }

          if (articles.length < perRequestCount) break;
          page++;

          // 翻页请求同样需要限速，避免单个公众号连续请求触发平台限制。
          if (fetchedForMp < maxCount && !reachedKnownMessage) {
            await Future.delayed(Duration(milliseconds: requestDelayMs));
          }
        }
      } on WxmpSessionExpiredException {
        failures.add(
          WxmpAccountFetchFailure(
            accountName: mpName,
            kind: WxmpFetchFailureKind.sessionExpired,
            message: '会话已过期，请重新扫码登录',
          ),
        );
        break;
      } on WxmpFrequencyLimitException {
        failures.add(
          WxmpAccountFetchFailure(
            accountName: mpName,
            kind: WxmpFetchFailureKind.frequencyLimited,
            message: '平台限制了当前请求频率，请稍后重试',
          ),
        );
        break;
      } on WxmpInvalidCsrfException {
        failures.add(
          WxmpAccountFetchFailure(
            accountName: mpName,
            kind: WxmpFetchFailureKind.invalidCsrf,
            message: '认证令牌已失效，请重新扫码登录',
          ),
        );
        break;
      } catch (error) {
        failures.add(
          WxmpAccountFetchFailure(
            accountName: mpName,
            kind: WxmpFetchFailureKind.source,
            message: '来源刷新失败：${error.runtimeType}',
          ),
        );
      } finally {
        completedAccounts++;
        await onAccountCompleted?.call(
          accountMessages,
          completedAccounts,
          refreshEntries.length,
          mpName,
        );
      }
    }

    return WxmpFetchResult(
      messages: List.unmodifiable(allMessages),
      completedAccounts: completedAccounts,
      totalAccounts: refreshEntries.length,
      failures: List.unmodifiable(failures),
    );
  }
}
