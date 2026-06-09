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
import 'package:sspu_allinone/services/authenticated_data_cache_service.dart';
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
    expect(gateway.submittedFields?['tabNo'], '1');
    expect(gateway.submittedFields?['pager.offset'], '0');
    expect(gateway.submittedFields?['_tradedirect'], 'on');
    expect(gateway.submittedFields?['_csrf'], 'csrf-token');
    expect(gateway.submittedRefererUri?.path, '/epay/consume/index');
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

  test('真实 epay XML zone 合并列能解析交易号和点号时间', () async {
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
<?xml version="1.0" encoding="UTF-8"?><zones><zone name="zone_show_box_1"><![CDATA[
<table>
  <thead>
    <tr>
      <td>创建时间</td><td>名称&nbsp;&nbsp;|&nbsp;&nbsp;交易号</td><td>对方</td>
      <td>金额&nbsp;&nbsp;|&nbsp;&nbsp;明细</td><td>付款方式</td><td>状态</td><td>操作</td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><div>2026.06.09</div><div class="span_2">114527</div></td>
      <td><a>完美校园翼支付充值</a><div>交易号：T20260609114527</div></td>
      <td>一卡通</td><td>200.00</td><td>现金</td><td>交易成功</td><td>详情</td>
    </tr>
    <tr>
      <td><div>2026.06.09</div><div class="span_2">112953</div></td>
      <td><a>POS消费</a><div>交易号：T20260609112953</div></td>
      <td>一食堂</td><td>12.00</td><td>现金</td><td>交易成功</td><td>详情</td>
    </tr>
  </tbody>
</table>
]]></zone></zones>
''',
      ),
    );
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchCampusCard(
      requireCampusNetwork: false,
      queryTransactions: true,
    );

    expect(result.status, CampusCardQueryStatus.success);
    final records = result.snapshot!.records;
    expect(records.length, 2);
    expect(records.first.occurredAt, '2026-06-09 11:45:27');
    expect(records.first.title, '完美校园翼支付充值');
    expect(records.first.transactionId, 'T20260609114527');
    expect(records.first.amount, 200);
    expect(records.last.title, 'POS消费');
    expect(records.last.amount, -12);
  });

  test('从 epay 首页查看所有交易记录入口发现真实交易页并携带 referer', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final transactionUri = Uri.parse(
      'https://card.sspu.edu.cn/epay/trans/allRecords',
    );
    final queryUri = Uri.parse(
      'https://card.sspu.edu.cn/epay/trans/queryRecords',
    );
    final gateway = _FakeCampusCardGateway(
      entryPage: _cardSnapshot('''
<html><body>
  <table><tr><td>账户余额</td><td>23.45 元</td></tr></table>
  <a href="/epay/trans/allRecords">查看所有交易记录</a>
</body></html>
'''),
      homePage: _cardSnapshot('''
<html><body>
  <a data-url="/epay/trans/allRecords">查看所有交易记录</a>
</body></html>
'''),
      transactionPagesByUri: {
        transactionUri: CampusCardHttpSnapshot(
          finalUri: transactionUri,
          statusCode: 200,
          body: '''
<html><head><meta name="_csrf" content="real-csrf" /></head><body>
  <form id="transparam" action="/epay/trans/queryRecords">
    <input name="tabNo" value="1" />
    <input name="pager.offset" value="0" />
  </form>
</body></html>
''',
        ),
      },
      queryPagesByPageNo: {
        1: CampusCardHttpSnapshot(
          finalUri: queryUri,
          statusCode: 200,
          body: _transactionQueryTable([
            _TransactionFixtureRow(
              date: '2026-06-09 12:47',
              title: 'POS消费',
              transactionId: 'T202606090001',
              counterparty: '一食堂',
              amount: '12.50',
              detail: '午餐',
              paymentMethod: '校园卡',
              status: '交易成功',
            ),
          ]),
        ),
      },
    );
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchCampusCard(
      requireCampusNetwork: false,
      syncAllTransactions: true,
    );

    expect(result.status, CampusCardQueryStatus.success);
    expect(gateway.fetchedPageUris, contains(transactionUri));
    expect(gateway.submittedQueryUris.single, queryUri);
    expect(gateway.submittedRefererUris.single, transactionUri);
    expect(gateway.submittedFieldsList.single['_csrf'], 'real-csrf');
    expect(result.snapshot?.records.single.transactionId, 'T202606090001');
  });

  test('首次全量同步会翻取所有交易记录页直到短页并加密缓存', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final gateway = _FakeCampusCardGateway(
      queryPagesByPageNo: {
        1: _transactionQueryPage(
          List.generate(
            10,
            (index) => _TransactionFixtureRow.expense(index + 1),
          ),
        ),
        2: _transactionQueryPage(
          List.generate(
            10,
            (index) => _TransactionFixtureRow.expense(index + 11),
          ),
        ),
        3: _transactionQueryPage([
          _TransactionFixtureRow.income(21, title: '补助'),
        ]),
      },
    );
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchCampusCard(
      requireCampusNetwork: false,
      syncAllTransactions: true,
    );
    final cachedResult = await service.readLatestCachedCampusCard();

    expect(result.status, CampusCardQueryStatus.success);
    expect(gateway.submittedFieldsList.map((fields) => fields['pageNo']), [
      '1',
      '2',
      '3',
    ]);
    expect(gateway.submittedFieldsList.map((fields) => fields['pager.offset']), [
      '0',
      '10',
      '20',
    ]);
    expect(result.snapshot?.records.length, 21);
    expect(result.snapshot?.transactionPageCount, 3);
    expect(result.snapshot?.records.first.amount, -1);
    expect(result.snapshot?.records.last.amount, 21);
    expect(cachedResult?.snapshot?.records.length, 21);
    expect(
      await StorageService.getCollectionCount(
        StorageKeys.campusCardCacheCollection,
      ),
      0,
    );
  });

  test('已有全量缓存后只访问已知页数并合并旧交易记录', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final cachedSnapshot = CampusCardSnapshot(
      balance: 30,
      status: '正常',
      fetchedAt: DateTime(2026, 6, 8, 8),
      sourceUri: Uri.parse('https://card.sspu.edu.cn/epay/consume/query'),
      transactionPageCount: 3,
      records: List.unmodifiable(
        List.generate(
          30,
          (index) => CampusCardTransactionRecord(
            occurredAt: '2026-05-${(index + 1).toString().padLeft(2, '0')} 08:00',
            amount: -(index + 1).toDouble(),
            title: '旧交易 ${index + 1}',
            transactionId: 'OLD${index + 1}',
            counterparty: '旧窗口',
            direction: 'expense',
            rawCells: const [],
          ),
        ),
      ),
    );
    await AuthenticatedDataCacheService.saveLatest(
      collection: StorageKeys.campusCardCacheCollection,
      accountKey: '20260001',
      fetchedAt: cachedSnapshot.fetchedAt,
      data: cachedSnapshot.toJson(),
    );
    final gateway = _FakeCampusCardGateway(
      queryPagesByPageNo: {
        1: _transactionQueryPage([
          _TransactionFixtureRow.income(100, title: '补助'),
        ]),
        2: _transactionQueryPage(const []),
        3: _transactionQueryPage(const []),
      },
    );
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchCampusCard(
      requireCampusNetwork: false,
      syncAllTransactions: true,
    );

    expect(result.status, CampusCardQueryStatus.success);
    expect(gateway.submittedFieldsList.map((fields) => fields['pageNo']), [
      '1',
      '2',
      '3',
    ]);
    expect(result.snapshot?.transactionPageCount, 3);
    expect(result.snapshot?.records.length, 31);
    expect(
      result.snapshot?.records.any((record) => record.transactionId == 'OLD30'),
      isTrue,
    );
    expect(result.snapshot?.records.first.title, '补助');
  });

  test('全量同步解析不到新记录时保留旧加密缓存记录和页数', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    await AcademicCredentialsService.instance.saveOaLoginSession(
      _sessionSnapshot,
    );
    final cachedSnapshot = CampusCardSnapshot(
      balance: 30,
      status: '正常',
      fetchedAt: DateTime(2026, 6, 8, 8),
      sourceUri: Uri.parse('https://card.sspu.edu.cn/epay/consume/query'),
      transactionPageCount: 2,
      records: const [
        CampusCardTransactionRecord(
          occurredAt: '2026-06-08 08:00',
          amount: -3,
          title: '旧交易',
          transactionId: 'OLD1',
          direction: 'expense',
          rawCells: [],
        ),
      ],
    );
    await AuthenticatedDataCacheService.saveLatest(
      collection: StorageKeys.campusCardCacheCollection,
      accountKey: '20260001',
      fetchedAt: cachedSnapshot.fetchedAt,
      data: cachedSnapshot.toJson(),
    );
    final gateway = _FakeCampusCardGateway(
      queryPagesByPageNo: {
        1: CampusCardHttpSnapshot(
          finalUri: CampusCardService.defaultTransactionQueryUri,
          statusCode: 200,
          body: '<ajax-response><![CDATA[<div>暂无数据</div>]]></ajax-response>',
        ),
        2: CampusCardHttpSnapshot(
          finalUri: CampusCardService.defaultTransactionQueryUri,
          statusCode: 200,
          body: '<ajax-response><![CDATA[<div>暂无数据</div>]]></ajax-response>',
        ),
      },
    );
    final service = _buildService(gateway: gateway, campusReachable: true);

    final result = await service.fetchCampusCard(
      requireCampusNetwork: false,
      syncAllTransactions: true,
    );

    expect(result.status, CampusCardQueryStatus.success);
    expect(result.snapshot?.transactionPageCount, 2);
    expect(result.snapshot?.records.single.transactionId, 'OLD1');
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
    Map<Uri, CampusCardHttpSnapshot> transactionPagesByUri = const {},
    Map<int, CampusCardHttpSnapshot> queryPagesByPageNo = const {},
  }) : entryPage = entryPage ?? _cardSnapshot(_balanceHtml),
       homePage = homePage ?? _cardSnapshot(_balanceHtml),
       transactionPage =
           transactionPage ??
           CampusCardHttpSnapshot(
             finalUri: CampusCardService.defaultTransactionIndexUri,
             statusCode: 200,
             body: _transactionHtml,
           ),
       queryPage = queryPage ?? _cardSnapshot(_transactionHtml),
       transactionPagesByUri = transactionPagesByUri,
       queryPagesByPageNo = queryPagesByPageNo;

  final bool requireAuthFirst;
  final CampusCardHttpSnapshot entryPage;
  final CampusCardHttpSnapshot homePage;
  final CampusCardHttpSnapshot transactionPage;
  final CampusCardHttpSnapshot queryPage;
  final Map<Uri, CampusCardHttpSnapshot> transactionPagesByUri;
  final Map<int, CampusCardHttpSnapshot> queryPagesByPageNo;
  final List<Map<String, String>> resetCookieHeaders = [];
  final List<Uri> fetchedPageUris = [];
  final List<Uri> submittedQueryUris = [];
  final List<Map<String, String>> submittedFieldsList = [];
  final List<Uri?> submittedRefererUris = [];
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
    fetchedPageUris.add(pageUri);
    final transactionPageByUri = transactionPagesByUri[pageUri];
    if (transactionPageByUri != null) return transactionPageByUri;
    if (pageUri.path.contains('/myepay/')) return homePage;
    if (pageUri.path.contains('/consume/') ||
        pageUri.path.contains('/trans/')) {
      return transactionPage;
    }
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
    Uri? refererUri,
  }) async {
    submittedFields = fields;
    submittedRefererUri = refererUri;
    submittedFieldsList.add(Map<String, String>.from(fields));
    submittedRefererUris.add(refererUri);
    submittedQueryUris.add(queryUri);
    final pageNo = int.tryParse(fields['pageNo'] ?? '') ?? 1;
    return queryPagesByPageNo[pageNo] ?? queryPage;
  }

  Uri? submittedRefererUri;
}

CampusCardHttpSnapshot _cardSnapshot(String body) {
  return CampusCardHttpSnapshot(
    finalUri: Uri.parse('https://card.sspu.edu.cn/epay/'),
    statusCode: 200,
    body: body,
  );
}

CampusCardHttpSnapshot _transactionQueryPage(
  List<_TransactionFixtureRow> rows,
) {
  return CampusCardHttpSnapshot(
    finalUri: CampusCardService.defaultTransactionQueryUri,
    statusCode: 200,
    body: _transactionQueryTable(rows),
  );
}

String _transactionQueryTable(List<_TransactionFixtureRow> rows) {
  final bodyRows = rows.map((row) => '''
  <tr>
    <td>${row.date}</td><td>${row.title}</td><td>${row.transactionId}</td>
    <td>${row.counterparty}</td><td>${row.amount}</td><td>${row.detail}</td>
    <td>${row.paymentMethod}</td><td>${row.status}</td><td>详情</td>
  </tr>
''').join();
  return '''
<ajax-response><![CDATA[
<table>
  <tr><th>创建时间</th><th>名称</th><th>交易号</th><th>对方</th><th>金额</th><th>明细</th><th>付款方式</th><th>状态</th><th>操作</th></tr>
$bodyRows
</table>
]]></ajax-response>
''';
}

class _TransactionFixtureRow {
  const _TransactionFixtureRow({
    required this.date,
    required this.title,
    required this.transactionId,
    required this.counterparty,
    required this.amount,
    required this.detail,
    required this.paymentMethod,
    required this.status,
  });

  factory _TransactionFixtureRow.expense(int index, {String title = 'POS消费'}) {
    final day = ((index - 1) % 28) + 1;
    return _TransactionFixtureRow(
      date: '2026-06-${day.toString().padLeft(2, '0')} 12:00',
      title: title,
      transactionId: 'EXP${index.toString().padLeft(4, '0')}',
      counterparty: '窗口 $index',
      amount: index.toStringAsFixed(2),
      detail: '消费',
      paymentMethod: '校园卡',
      status: '交易成功',
    );
  }

  factory _TransactionFixtureRow.income(int index, {String title = '充值'}) {
    final day = ((index - 1) % 28) + 1;
    return _TransactionFixtureRow(
      date: '2026-06-${day.toString().padLeft(2, '0')} 08:00',
      title: title,
      transactionId: 'INC${index.toString().padLeft(4, '0')}',
      counterparty: '一卡通',
      amount: index.toStringAsFixed(2),
      detail: title,
      paymentMethod: '现金',
      status: '交易成功',
    );
  }

  final String date;
  final String title;
  final String transactionId;
  final String counterparty;
  final String amount;
  final String detail;
  final String paymentMethod;
  final String status;
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
