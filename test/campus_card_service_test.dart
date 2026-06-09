/*
 * 校园卡查询服务测试 — 校验 OA 会话、自动刷新设置与余额明细解析
 * @Project : SSPU-AllinOne
 * @File : campus_card_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-30
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/academic_credentials.dart';
import 'package:sspu_allinone/models/academic_login_validation.dart';
import 'package:sspu_allinone/models/campus_card.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/campus_card_service.dart';
import 'package:sspu_allinone/services/campus_network_status_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    SharedPreferences.setMockInitialValues({});
  });

  test('校园卡自动刷新设置默认关闭并可持久化间隔', () async {
    final service = _buildService(
      gateway: _FakeCampusCardGateway(),
      campusReachable: true,
    );

    expect(await service.isAutoRefreshEnabled(), isFalse);
    expect(
      await service.getAutoRefreshIntervalMinutes(),
      CampusCardService.defaultAutoRefreshIntervalMinutes,
    );

    await service.setAutoRefreshEnabled(true);
    await service.setAutoRefreshIntervalMinutes(60);

    expect(await service.isAutoRefreshEnabled(), isTrue);
    expect(await service.getAutoRefreshIntervalMinutes(), 60);
  });

  test('未保存学工号时不访问校园卡入口', () async {
    final gateway = _FakeCampusCardGateway();
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchCampusCard();

    expect(result.status, CampusCardQueryStatus.missingOaAccount);
    expect(gateway.openCount, 0);
  });

  test('校园网或 VPN 不可达时先刷新 OA 会话再停止校园卡查询', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final gateway = _FakeCampusCardGateway();
    final calls = <Map<String, bool>>[];
    final service = _buildService(
      gateway: gateway,
      campusReachable: false,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            calls.add({
              'forceRefresh': forceRefresh,
              'requireCampusNetwork': requireCampusNetwork,
            });
            await AcademicCredentialsService.instance.saveOaLoginSession(
              _sessionSnapshot,
            );
            return _loginSuccessResult();
          },
    );

    final result = await service.fetchCampusCard();

    expect(result.status, CampusCardQueryStatus.campusNetworkUnavailable);
    expect(result.detail, contains('OA 登录会话已刷新'));
    expect(gateway.openCount, 0);
    expect(calls, [
      {'forceRefresh': true, 'requireCampusNetwork': false},
    ]);
  });

  test('校园网或 VPN 不可达且 OA 刷新失败时提示网络环境', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final gateway = _FakeCampusCardGateway();
    final service = _buildService(
      gateway: gateway,
      campusReachable: false,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            return AcademicLoginValidationResult(
              status: AcademicLoginValidationStatus.networkError,
              message: 'OA 登录网络失败',
              detail: '无法连接 OA 登录页',
              checkedAt: DateTime(2026, 4, 30),
              entranceUri: _oaEntranceUri,
            );
          },
    );

    final result = await service.fetchCampusCard();

    expect(result.status, CampusCardQueryStatus.oaLoginRequired);
    expect(result.detail, contains('当前网络环境不是校园网或 VPN'));
    expect(result.detail, contains('OA 登录可在当前网络下刷新'));
    expect(gateway.openCount, 0);
  });

  test('手动刷新可绕过校园网前置检测并尝试查询', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final gateway = _FakeCampusCardGateway();
    final service = _buildService(gateway: gateway, campusReachable: false);

    final result = await service.fetchCampusCard(
      requireCampusNetwork: false,
      queryTransactions: true,
    );

    expect(result.status, CampusCardQueryStatus.success);
    expect(gateway.openCount, 1);
  });

  test('OA 会话失效时刷新登录态后解析余额状态和记录', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    var refreshCount = 0;
    final gateway = _FakeCampusCardGateway(requireAuthFirst: true);
    final service = _buildService(
      gateway: gateway,
      campusReachable: true,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            refreshCount++;
            await AcademicCredentialsService.instance.saveOaLoginSession(
              _sessionSnapshot,
            );
            return AcademicLoginValidationResult(
              status: AcademicLoginValidationStatus.success,
              message: 'OA 登录校验通过',
              detail: '已刷新 OA 会话',
              checkedAt: DateTime(2026, 4, 30),
              entranceUri: _oaEntranceUri,
              finalUri: _oaEntranceUri,
              sessionSnapshot: _sessionSnapshot,
            );
          },
    );

    final result = await service.fetchCampusCard();

    expect(result.status, CampusCardQueryStatus.success);
    expect(refreshCount, 1);
    expect(gateway.openCount, 2);
    expect(gateway.resetCookieHeaders.last['oa.sspu.edu.cn'], contains('OA='));
    expect(result.snapshot?.balance, 23.45);
    expect(result.snapshot?.status, '正常');
    expect(result.snapshot?.records.length, 1);
    expect(result.snapshot?.records.single.merchant, '一食堂');
  });

  test('已有可用 OA 会话时不会重新获取登录凭证', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    var refreshCount = 0;
    final service = _buildService(
      gateway: _FakeCampusCardGateway(),
      campusReachable: true,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            refreshCount++;
            return _loginSuccessResult();
          },
    );

    final result = await service.fetchCampusCard();

    expect(result.status, CampusCardQueryStatus.success);
    expect(refreshCount, 0);
  });

  test('已有 OA 会话失效时强制刷新登录凭证', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final forceRefreshValues = <bool>[];
    final service = _buildService(
      gateway: _FakeCampusCardGateway(requireAuthFirst: true),
      campusReachable: true,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            forceRefreshValues.add(forceRefresh);
            await AcademicCredentialsService.instance.saveOaLoginSession(
              _sessionSnapshot,
            );
            return _loginSuccessResult();
          },
    );

    final result = await service.fetchCampusCard();

    expect(result.status, CampusCardQueryStatus.success);
    expect(forceRefreshValues, [true]);
  });

  test('交易记录查询会携带日期范围和 CSRF 并解析 XML 表格', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final gateway = _FakeCampusCardGateway(
      queryPage: CampusCardHttpSnapshot(
        finalUri: CampusCardService.defaultTransactionQueryUri,
        statusCode: 200,
        body: '''
<ajax-response><![CDATA[
<table>
  <tr><td>2026-04-28 08:12</td><td>充值</td><td>线上充值</td><td>+50.00</td><td>73.45</td></tr>
</table>
]]></ajax-response>
''',
      ),
    );
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchCampusCard(
      startDate: DateTime(2026, 4, 1),
      endDate: DateTime(2026, 4, 30),
    );

    expect(result.status, CampusCardQueryStatus.success);
    expect(gateway.submittedFields?['starttime'], '2026-04-01');
    expect(gateway.submittedFields?['endtime'], '2026-04-30');
    expect(gateway.submittedFields?['_csrf'], 'csrf-token');
    expect(result.snapshot?.records.length, 1);
    expect(result.snapshot?.records.single.type, '充值');
    expect(result.snapshot?.records.single.amount, 50.00);
  });

  test('交易表头状态和操作不会被误解析为卡状态', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final service = _buildService(
      gateway: _FakeCampusCardGateway(
        entryPage: _cardSnapshot('''
<html><body><div>账户余额：23.45 元</div></body></html>
'''),
        homePage: _cardSnapshot('''
<html><body><div>账户余额：23.45 元</div></body></html>
'''),
        transactionPage: CampusCardHttpSnapshot(
          finalUri: CampusCardService.defaultTransactionIndexUri,
          statusCode: 200,
          body: '''
<html>
  <head><meta name="_csrf" content="csrf-token" /></head>
  <body>
    <table>
      <tr><th>创建时间</th><th>名称</th><th>交易号</th><th>对方</th><th>金额</th><th>明细</th><th>状态</th><th>操作</th></tr>
      <tr><td>2026-06-09 12:47</td><td>POS 消费</td><td>T202606090001</td><td>一食堂</td><td>12.50</td><td>午餐</td><td>成功</td><td>详情</td></tr>
    </table>
  </body>
</html>
''',
        ),
      ),
      campusReachable: true,
    );

    final result = await service.fetchCampusCard();

    expect(result.status, CampusCardQueryStatus.success);
    expect(result.snapshot?.status, isNot('操作'));
    expect(result.snapshot?.status, isEmpty);
    expect(result.snapshot?.records.single.status, '成功');
  });

  test('真实 epay 风格交易表解析扩展字段并推断金额符号', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final gateway = _FakeCampusCardGateway(
      queryPage: CampusCardHttpSnapshot(
        finalUri: CampusCardService.defaultTransactionQueryUri,
        statusCode: 200,
        body: '''
<ajax-response><![CDATA[
<table>
  <tr><th>创建时间</th><th>名称</th><th>交易号</th><th>对方</th><th>金额</th><th>明细</th><th>付款方式</th><th>状态</th><th>操作</th></tr>
  <tr><td>2026-06-09 12:47</td><td>POS 消费</td><td>T202606090001</td><td>一食堂</td><td>12.50</td><td>午餐</td><td>校园卡</td><td>成功</td><td>详情</td></tr>
  <tr><td>2026-06-08 08:10</td><td>充值</td><td>T202606080001</td><td>线上平台</td><td>50.00</td><td>账户充值</td><td>支付宝</td><td>成功</td><td>详情</td></tr>
</table>
]]></ajax-response>
''',
      ),
    );
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchCampusCard(
      requireCampusNetwork: false,
      queryTransactions: true,
    );

    expect(result.status, CampusCardQueryStatus.success);
    expect(gateway.submittedFields?['starttime'], isEmpty);
    expect(gateway.submittedFields?['endtime'], isEmpty);
    expect(gateway.submittedFields?['pageNo'], '1');
    expect(gateway.submittedFields?['pager.offset'], '0');
    expect(gateway.submittedFields?['_csrf'], 'csrf-token');
    final records = result.snapshot!.records;
    expect(records.length, 2);
    final consumption = records.first;
    expect(consumption.title, 'POS 消费');
    expect(consumption.transactionId, 'T202606090001');
    expect(consumption.counterparty, '一食堂');
    expect(consumption.paymentMethod, '校园卡');
    expect(consumption.status, '成功');
    expect(consumption.amount, -12.50);
    expect(records.last.amount, 50.00);
  });

  test('交易记录查询失败时返回失败状态而不伪造空成功结果', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final service = _buildService(
      gateway: _FakeCampusCardGateway(
        queryPage: CampusCardHttpSnapshot(
          finalUri: CampusCardService.defaultTransactionQueryUri,
          statusCode: 500,
          body: '<html><body>error</body></html>',
        ),
      ),
      campusReachable: true,
    );

    final result = await service.fetchCampusCard(
      requireCampusNetwork: false,
      queryTransactions: true,
    );

    expect(result.status, CampusCardQueryStatus.cardSystemUnavailable);
    expect(result.snapshot, isNull);
  });

  test('成功查询写入校园卡缓存且失败不会覆盖最近缓存', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final service = _buildService(
      gateway: _FakeCampusCardGateway(),
      campusReachable: true,
    );

    final result = await service.fetchCampusCard();
    final cachedResult = await service.readLatestCachedCampusCard();

    expect(result.status, CampusCardQueryStatus.success);
    expect(cachedResult?.snapshot?.balance, 23.45);

    final failedService = _buildService(
      gateway: _FakeCampusCardGateway(),
      campusReachable: false,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            await AcademicCredentialsService.instance.saveOaLoginSession(
              _sessionSnapshot,
            );
            return _loginSuccessResult();
          },
    );
    final failedResult = await failedService.fetchCampusCard();
    final cachedAfterFailure = await failedService.readLatestCachedCampusCard();

    expect(failedResult.status, CampusCardQueryStatus.campusNetworkUnavailable);
    expect(cachedAfterFailure?.snapshot?.balance, 23.45);
  });

  test('查询过程中切换账号时不会把旧账号校园卡写入新账号缓存', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final service = _buildService(
      gateway: _FakeCampusCardGateway(),
      campusReachable: true,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            await AcademicCredentialsService.instance.saveCredentials(
              oaAccount: '20260002',
              oaPassword: 'oa-pass',
            );
            await AcademicCredentialsService.instance.saveOaLoginSession(
              _sessionSnapshot,
            );
            return AcademicLoginValidationResult(
              status: AcademicLoginValidationStatus.success,
              message: 'OA 登录校验通过',
              detail: '已刷新 OA 会话',
              checkedAt: DateTime(2026, 4, 30),
              entranceUri: _oaEntranceUri,
              finalUri: _oaEntranceUri,
              sessionSnapshot: _sessionSnapshot,
            );
          },
    );

    final result = await service.fetchCampusCard();
    final cachedResult = await service.readLatestCachedCampusCard();

    expect(result.status, CampusCardQueryStatus.unexpectedError);
    expect(result.snapshot, isNull);
    expect(
      (await AcademicCredentialsService.instance.getStatus()).oaAccount,
      '20260002',
    );
    expect(cachedResult, isNull);
  });

  test('查询过程中清除 OA 密码时不会重新写入校园卡缓存', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final service = _buildService(
      gateway: _FakeCampusCardGateway(),
      campusReachable: true,
      refreshOaLogin:
          ({
            bool forceRefresh = false,
            bool requireCampusNetwork = true,
          }) async {
            await AcademicCredentialsService.instance.clearSecret(
              AcademicCredentialSecret.oaPassword,
            );
            await AcademicCredentialsService.instance.saveOaLoginSession(
              _sessionSnapshot,
            );
            return AcademicLoginValidationResult(
              status: AcademicLoginValidationStatus.success,
              message: 'OA 登录校验通过',
              detail: '已刷新 OA 会话',
              checkedAt: DateTime(2026, 4, 30),
              entranceUri: _oaEntranceUri,
              finalUri: _oaEntranceUri,
              sessionSnapshot: _sessionSnapshot,
            );
          },
    );

    final result = await service.fetchCampusCard();
    final cachedResult = await service.readLatestCachedCampusCard();

    expect(result.status, CampusCardQueryStatus.unexpectedError);
    expect(result.snapshot, isNull);
    expect(cachedResult, isNull);
  });
}

CampusCardService _buildService({
  required _FakeCampusCardGateway gateway,
  required bool campusReachable,
  CampusCardOaLoginRefresher? refreshOaLogin,
}) {
  return CampusCardService(
    gateway: gateway,
    refreshOaLogin: refreshOaLogin,
    campusNetworkStatusService: CampusNetworkStatusService(
      probeUri: Uri.parse('https://tygl.sspu.edu.cn/'),
      probe: (probeUri, timeout) async => CampusNetworkProbeResult(
        reachable: campusReachable,
        detail: campusReachable ? '校园网可达' : '校园网不可达',
        statusCode: campusReachable ? 200 : null,
      ),
    ),
  );
}

class _FakeCampusCardGateway implements CampusCardGateway {
  _FakeCampusCardGateway({
    this.requireAuthFirst = false,
    CampusCardHttpSnapshot? entryPage,
    CampusCardHttpSnapshot? homePage,
    CampusCardHttpSnapshot? transactionPage,
    CampusCardHttpSnapshot? queryPage,
  }) : entryPage = entryPage ?? _cardSnapshot(_balanceHtml),
       homePage = homePage ?? _cardSnapshot(_balanceHtml),
       transactionPage =
           transactionPage ??
           CampusCardHttpSnapshot(
             finalUri: CampusCardService.defaultTransactionIndexUri,
             statusCode: 200,
             body: _transactionHtml,
           ),
       queryPage = queryPage ?? _cardSnapshot(_transactionHtml);

  final bool requireAuthFirst;
  final CampusCardHttpSnapshot entryPage;
  final CampusCardHttpSnapshot homePage;
  final CampusCardHttpSnapshot transactionPage;
  final CampusCardHttpSnapshot queryPage;
  final List<Map<String, String>> resetCookieHeaders = [];
  int openCount = 0;
  Map<String, String>? submittedFields;

  @override
  Future<void> resetSession(Map<String, String> cookieHeadersByHost) async {
    resetCookieHeaders.add(cookieHeadersByHost);
  }

  @override
  Future<CampusCardHttpSnapshot> openEntryPage(
    Uri entranceUri,
    Duration timeout,
  ) async {
    openCount++;
    if (requireAuthFirst && openCount == 1) return _casSnapshot;
    return entryPage;
  }

  @override
  Future<CampusCardHttpSnapshot> fetchPage(
    Uri pageUri,
    Duration timeout,
  ) async {
    if (pageUri.path.contains('/myepay/')) return homePage;
    if (pageUri.path.contains('/consume/')) return transactionPage;
    return CampusCardHttpSnapshot(
      finalUri: pageUri,
      statusCode: 404,
      body: 'not found',
    );
  }

  @override
  Future<CampusCardHttpSnapshot> queryTransactions({
    required Uri queryUri,
    required Map<String, String> fields,
    required Duration timeout,
  }) async {
    submittedFields = fields;
    return queryPage;
  }
}

CampusCardHttpSnapshot _cardSnapshot(String body) {
  return CampusCardHttpSnapshot(
    finalUri: Uri.parse('https://card.sspu.edu.cn/epay/'),
    statusCode: 200,
    body: body,
  );
}

final CampusCardHttpSnapshot _casSnapshot = CampusCardHttpSnapshot(
  finalUri: Uri.parse('https://id.sspu.edu.cn/cas/login'),
  statusCode: 200,
  body: '<html><title>登录 - 上海第二工业大学</title></html>',
);

final AcademicLoginSessionSnapshot _sessionSnapshot =
    AcademicLoginSessionSnapshot(
      cookieHeadersByHost: const {
        'oa.sspu.edu.cn': 'OA=fake-oa-session',
        'id.sspu.edu.cn': 'CASTGC=fake-cas-session',
      },
      authenticatedAt: DateTime(2026, 4, 30),
      entranceUri: _oaEntranceUri,
      finalUri: _oaEntranceUri,
    );

AcademicLoginValidationResult _loginSuccessResult() {
  return AcademicLoginValidationResult(
    status: AcademicLoginValidationStatus.success,
    message: 'OA 登录校验通过',
    detail: '已刷新 OA 会话',
    checkedAt: DateTime(2026, 4, 30),
    entranceUri: _oaEntranceUri,
    finalUri: _oaEntranceUri,
    sessionSnapshot: _sessionSnapshot,
  );
}

final Uri _oaEntranceUri = Uri.parse(
  'https://oa.sspu.edu.cn//interface/Entrance.jsp?id=xykxt',
);

const String _balanceHtml = '''
<html>
  <body>
    <table>
      <tr><td>账户余额</td><td>23.45 元</td></tr>
      <tr><td>卡状态</td><td>正常</td></tr>
    </table>
  </body>
</html>
''';

const String _transactionHtml = '''
<html>
  <head><meta name="_csrf" content="csrf-token" /></head>
  <body>
    <table>
      <tr><th>时间</th><th>类型</th><th>商户</th><th>金额</th><th>余额</th></tr>
      <tr><td>2026-04-29 12:10</td><td>消费</td><td>一食堂</td><td>-12.50</td><td>23.45</td></tr>
    </table>
  </body>
</html>
''';
