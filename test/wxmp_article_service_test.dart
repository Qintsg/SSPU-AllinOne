/*
 * 微信公众号平台文章服务测试 — 校验认证探针错误码处理
 * @Project : SSPU-AllinOne
 * @File : wxmp_article_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/message_item.dart';
import 'package:sspu_allinone/services/message_state_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/services/wechat_article_service.dart';
import 'package:sspu_allinone/services/wxmp_article_service.dart';
import 'package:sspu_allinone/services/wxmp_auth_service.dart';
import 'package:sspu_allinone/services/wxmp_config_service.dart';

void main() {
  late Directory configDirectory;

  setUp(() async {
    configDirectory = await Directory.systemTemp.createTemp(
      'wxmp_article_test_',
    );
    WxmpConfigService.instance.debugSetConfigPathForTesting(
      '${configDirectory.path}${Platform.pathSeparator}wxmp_config.toml',
    );
  });

  tearDown(() async {
    WxmpConfigService.instance.debugSetConfigPathForTesting(null);
    if (await configDirectory.exists()) {
      await configDirectory.delete(recursive: true);
    }
  });

  test('统一刷新结果区分部分失败与认证失效', () {
    final partial = WxmpFetchResult(
      messages: [
        MessageItem(
          id: '1',
          title: '已成功文章',
          date: '2026-09-09',
          url: 'https://example.invalid/1',
          sourceType: MessageSourceType.wechatPublic,
          sourceName: MessageSourceName.wechatPublicPlaceholder,
          category: MessageCategory.wechatArticle,
        ),
      ],
      completedAccounts: 2,
      totalAccounts: 2,
      failures: const [
        WxmpAccountFetchFailure(
          accountName: '服务号 A',
          kind: WxmpFetchFailureKind.source,
          message: '网络失败',
        ),
      ],
    );
    const expired = WxmpFetchResult(
      messages: [],
      completedAccounts: 0,
      totalAccounts: 1,
      failures: [
        WxmpAccountFetchFailure(
          accountName: '公众号 B',
          kind: WxmpFetchFailureKind.sessionExpired,
          message: '会话失效',
        ),
      ],
    );

    expect(partial.summary, contains('已保留 1 条新推文'));
    expect(partial.summary, contains('刷新失败'));
    expect(expired.requiresReauthentication, isTrue);
    expect(expired.summary, contains('重新扫码登录'));
  });

  test('关闭单公众号通知仍保留已配置刷新目标', () async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    addTearDown(() {
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
    });
    await StorageService.init();

    const fakeid = 'configured-source-with-muted-notifications';
    await WxmpArticleService.instance.followMp(fakeid, '青春二工大');
    await MessageStateService.instance.setMpNotificationEnabled(fakeid, false);

    expect(
      await WechatArticleService.instance.hasConfiguredRefreshTarget(),
      isTrue,
    );
  });

  test('关闭单公众号通知仍抓取并返回该来源文章', () async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    addTearDown(() {
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
    });
    await StorageService.init();

    const fakeid = 'muted-source';
    await WxmpAuthService.instance.saveAuth('test-cookie', '123456');
    await WxmpArticleService.instance.followMp(fakeid, '青春二工大');
    await MessageStateService.instance.setMpNotificationEnabled(fakeid, false);

    final dio = Dio()..httpClientAdapter = _WxmpArticleHttpAdapter();
    final service = WxmpArticleService.debugWithDio(dio);
    final result = await service.fetchArticlesDetailed(
      maxCount: 1,
      validateBeforeFetch: false,
    );

    expect(result.totalAccounts, 1);
    expect(result.messages, hasLength(1));
    expect(result.messages.single.title, '静音来源文章');
    expect(result.messages.single.mpBookId, fakeid);
  });

  test('searchbiz 返回 200040 时判定为 CSRF 认证失效', () {
    final result = debugValidationResultForRet(WxmpApiError.invalidCsrfToken);

    // 200040 表示 Cookie 与 Token 不匹配，刷新和关注接口都会被同样拦截。
    expect(result.isValid, isFalse);
    expect(result.message, contains('CSRF'));
  });

  test('未知公众号平台错误码仍判定为不可用', () {
    final result = debugValidationResultForRet(999999);

    expect(result.isValid, isFalse);
    expect(result.message, contains('999999'));
  });

  test('公众号账号显示名优先使用推荐名并显式处理缺失值', () {
    expect(
      debugResolveWxmpAccountName({
        'name': '平台昵称',
        'recommended_name': '青春二工大',
      }, 'fakeid-name'),
      '青春二工大',
    );
    expect(debugResolveWxmpAccountName({}, 'fakeid-missing'), '公众号名称未知');
  });

  test('公众号账号显示 ID 优先使用推荐微信号再回退 alias', () {
    expect(
      debugResolveWxmpAccountDisplayId({
        'alias': 'platform_alias',
        'recommended_wx_account': 'ssputw',
      }),
      'ssputw',
    );
    expect(
      debugResolveWxmpAccountDisplayId({'alias': 'platform_alias'}),
      'platform_alias',
    );
    expect(debugResolveWxmpAccountDisplayId({}), isNull);
  });

  test('文章转换为 MessageItem 时保留公众号显示 ID', () {
    final message = debugArticleToMessageItem(
      {
        'title': '微信文章标题',
        'link': 'https://mp.weixin.qq.com/s/article-id',
        'update_time': 1777075200,
      },
      mpName: '青春二工大',
      fakeid: 'fakeid-article',
      mpDisplayId: 'ssputw',
    );

    expect(message, isNotNull);
    expect(message?.sourceType, MessageSourceType.wechatPublic);
    expect(message?.mpBookId, 'fakeid-article');
    expect(message?.mpName, '青春二工大');
    expect(message?.mpDisplayId, 'ssputw');
  });
}

class _WxmpArticleHttpAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path != '/cgi-bin/appmsgpublish') {
      return ResponseBody.fromString('not found', 404);
    }
    final publishInfo = jsonEncode({
      'appmsgex': [
        {
          'title': '静音来源文章',
          'link': 'https://mp.weixin.qq.com/s/muted-source-article',
          'update_time': 1777075200,
        },
      ],
    });
    final publishPage = jsonEncode({
      'publish_list': [
        {'publish_info': publishInfo},
      ],
    });
    return ResponseBody.fromString(
      jsonEncode({
        'base_resp': {'ret': WxmpApiError.success},
        'publish_page': publishPage,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
