/*
 * 学校邮箱服务测试 — 校验凭据读取、协议边界、发信与账号规范化
 * @Project : SSPU-AllinOne
 * @File : email_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

import 'dart:async';
import 'dart:io';

import 'package:enough_mail/enough_mail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/academic_credentials.dart';
import 'package:sspu_allinone/models/email_mailbox.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/email_service.dart';
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

  test('IMAP 列表与附件使用分段读取条件', () {
    expect(
      EnoughMailGateway.imapSummaryFetchCriteria,
      contains('BODYSTRUCTURE'),
    );
    expect(
      EnoughMailGateway.imapSummaryFetchCriteria,
      isNot(contains('BODY.PEEK[]')),
    );
    expect(EnoughMailGateway.imapPartFetchCriteria('2.1'), '(BODY.PEEK[2.1])');
    expect(
      () => EnoughMailGateway.imapPartFetchCriteria('2] BODY.PEEK[]'),
      throwsFormatException,
    );
  });

  test('100 封邮件的本地主题正文搜索在一秒内完成', () {
    final messages = List<EmailMessageSnapshot>.generate(
      100,
      (index) => EmailMessageSnapshot(
        id: 'IMAP:$index',
        subject: index == 42 ? '目标主题' : '普通通知 $index',
        senderName: '测试发件人',
        senderAddress: 'sender$index@example.com',
        preview: '第 $index 封邮件摘要',
        body: index == 73 ? '正文包含目标关键词' : '普通正文 $index',
      ),
    );

    final stopwatch = Stopwatch()..start();
    final matches = EmailService.filterLocalMessages(messages, ' 目标 ');
    stopwatch.stop();

    expect(matches.map((message) => message.id), ['IMAP:42', 'IMAP:73']);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
  });

  test('邮箱自动刷新设置默认关闭并可持久化间隔', () async {
    final service = EmailService(gateway: _FakeEmailGateway());

    expect(await service.isAutoRefreshEnabled(), isFalse);
    expect(
      await service.getAutoRefreshIntervalMinutes(),
      EmailService.defaultAutoRefreshIntervalMinutes,
    );

    await service.setAutoRefreshEnabled(true);
    await service.setAutoRefreshIntervalMinutes(60);

    expect(await service.isAutoRefreshEnabled(), isTrue);
    expect(await service.getAutoRefreshIntervalMinutes(), 60);
  });

  test('停止获取后收信不读取凭据也不访问邮箱网关', () async {
    final gateway = _FakeEmailGateway();
    final service = EmailService(
      gateway: gateway,
      isFetchEnabled: () async => false,
    );

    final result = await service.fetchMessages(protocol: EmailProtocol.imap);

    expect(result.status, EmailQueryStatus.fetchDisabled);
    expect(result.message, '邮箱已停止获取');
    expect(gateway.fetchImapCount, 0);
    expect(gateway.fetchPopCount, 0);
    expect(gateway.lastAccount, isNull);
  });

  test('停止获取后不校验收信协议登录', () async {
    final gateway = _FakeEmailGateway();
    final service = EmailService(
      gateway: gateway,
      isFetchEnabled: () async => false,
    );

    final result = await service.validateLogin(EmailProtocol.imap);

    expect(result.status, EmailQueryStatus.fetchDisabled);
    expect(gateway.validateImapCount, 0);
    expect(gateway.validatePopCount, 0);
    expect(gateway.lastAccount, isNull);
  });

  test('未保存学工号时不访问邮箱协议网关', () async {
    final gateway = _FakeEmailGateway();
    final service = EmailService(gateway: gateway);

    final result = await service.fetchMessages(protocol: EmailProtocol.imap);

    expect(result.status, EmailQueryStatus.missingEmailAccount);
    expect(gateway.fetchImapCount, 0);
  });

  test('未保存邮箱密码时停止只读收信', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
    );
    final gateway = _FakeEmailGateway();
    final service = EmailService(gateway: gateway);

    final result = await service.fetchMessages(protocol: EmailProtocol.pop);

    expect(result.status, EmailQueryStatus.missingEmailPassword);
    expect(gateway.fetchPopCount, 0);
  });

  test('IMAP 只读收信会由学工号派生邮箱账号并返回邮件快照', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final gateway = _FakeEmailGateway(messages: [_mailSnapshot]);
    final service = EmailService(gateway: gateway);

    final result = await service.fetchMessages(protocol: EmailProtocol.imap);

    expect(result.status, EmailQueryStatus.success);
    expect(gateway.fetchImapCount, 1);
    expect(gateway.lastAccount, '20260001@sspu.edu.cn');
    expect(result.snapshot?.messages.single.subject, '教务通知');
  });

  test('邮箱读取成功写入协议缓存且失败不会覆盖最近缓存', () async {
    final receivedAt = DateTime(2026, 5, 1, 8, 30);
    final mailSnapshot = EmailMessageSnapshot(
      id: 'IMAP:1',
      subject: '教务通知',
      senderName: '教务处',
      senderAddress: 'notice@sspu.edu.cn',
      preview: '请查看最新通知。',
      body: '请查看最新通知。',
      receivedAt: receivedAt,
    );
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final service = EmailService(
      gateway: _FakeEmailGateway(messages: [mailSnapshot]),
    );

    final result = await service.fetchMessages(protocol: EmailProtocol.imap);
    final cachedResult = await service.readLatestCachedMessages(
      EmailProtocol.imap,
    );

    expect(result.status, EmailQueryStatus.success);
    expect(cachedResult?.snapshot?.messages.single.subject, '教务通知');
    final cachedReceivedAt = cachedResult?.snapshot?.messages.single.receivedAt;
    expect(cachedReceivedAt?.isUtc, isFalse);
    expect(cachedReceivedAt?.isAtSameMomentAs(receivedAt), isTrue);

    final failedService = EmailService(
      gateway: _FakeEmailGateway(error: const SocketException('offline')),
    );
    final failedResult = await failedService.fetchMessages(
      protocol: EmailProtocol.imap,
    );
    final cachedAfterFailure = await failedService.readLatestCachedMessages(
      EmailProtocol.imap,
    );

    expect(failedResult.status, EmailQueryStatus.networkError);
    expect(cachedAfterFailure?.snapshot?.messages.single.subject, '教务通知');
  });

  test('邮箱缓存持久化不写入明文邮箱账号', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final service = EmailService(
      gateway: _FakeEmailGateway(messages: [_mailSnapshot]),
    );

    await service.fetchMessages(protocol: EmailProtocol.imap);
    final storedPayload = (await StorageService.getAllData(
      '${StorageKeys.emailMailboxCacheCollection}_imap',
    )).values.single;
    final cachedResult = await service.readLatestCachedMessages(
      EmailProtocol.imap,
    );

    expect(storedPayload.toString(), isNot(contains('20260001@sspu.edu.cn')));
    expect(storedPayload.toString(), isNot(contains('20260001')));
    expect(cachedResult?.snapshot?.account, isEmpty);
    expect(cachedResult?.snapshot?.messages.single.subject, '教务通知');
  });

  test('邮箱读取过程中清除邮箱密码时不会重新写入邮箱缓存', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final service = EmailService(
      gateway: _FakeEmailGateway(
        messages: [_mailSnapshot],
        beforeReturn: () => AcademicCredentialsService.instance.clearSecret(
          AcademicCredentialSecret.emailPassword,
        ),
      ),
    );

    final result = await service.fetchMessages(protocol: EmailProtocol.imap);
    final cachedResult = await service.readLatestCachedMessages(
      EmailProtocol.imap,
    );

    expect(result.status, EmailQueryStatus.unexpectedError);
    expect(result.snapshot, isNull);
    expect(cachedResult, isNull);
  });

  test('SMTP 不允许收信但允许用户主动发信', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final gateway = _FakeEmailGateway();
    final service = EmailService(gateway: gateway);

    final fetchResult = await service.fetchMessages(
      protocol: EmailProtocol.smtp,
    );
    final validationResult = await service.validateLogin(EmailProtocol.smtp);
    final sendResult = await service.sendMessage(
      const EmailComposeRequest(
        to: ['student@example.com'],
        cc: ['teacher@example.com'],
        subject: '测试主题',
        body: '测试正文',
      ),
    );

    expect(fetchResult.status, EmailQueryStatus.loginRejected);
    expect(validationResult.status, EmailQueryStatus.success);
    expect(sendResult.status, EmailQueryStatus.success);
    expect(gateway.validateSmtpCount, 1);
    expect(gateway.sendSmtpCount, 1);
    expect(gateway.fetchImapCount + gateway.fetchPopCount, 0);
    expect(gateway.lastAccount, '20260001@sspu.edu.cn');
    expect(gateway.lastComposeRequest?.recipientCount, 2);
  });

  test('SMTP 通过校验后把附件原样交给 MIME 网关', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final directory = await Directory.systemTemp.createTemp(
      'email-attachment-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}课表.pdf');
    await file.writeAsBytes(const [1, 2, 3, 4]);
    final gateway = _FakeEmailGateway();
    final service = EmailService(gateway: gateway);
    final attachment = EmailAttachmentRequest(
      path: file.path,
      fileName: '课表.pdf',
      mediaType: 'application/pdf',
      size: 4,
    );

    final result = await service.sendMessage(
      EmailComposeRequest(
        to: const ['student@example.com'],
        subject: '附件邮件',
        body: '请查收附件。',
        attachments: [attachment],
      ),
    );

    expect(result.status, EmailQueryStatus.success);
    expect(gateway.sendSmtpCount, 1);
    expect(gateway.lastComposeRequest?.attachments, [same(attachment)]);
  });

  test('SMTP 发信输入不完整时不访问协议网关', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final gateway = _FakeEmailGateway();
    final service = EmailService(gateway: gateway);

    final result = await service.sendMessage(
      const EmailComposeRequest(
        to: ['invalid-address'],
        subject: '测试主题',
        body: '测试正文',
      ),
    );

    expect(result.status, EmailQueryStatus.invalidInput);
    expect(gateway.sendSmtpCount, 0);
  });

  test('SMTP 发信不会把收件人或正文写入普通缓存', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final service = EmailService(gateway: _FakeEmailGateway());

    final result = await service.sendMessage(
      const EmailComposeRequest(
        to: ['recipient@example.com'],
        subject: '敏感主题',
        body: '敏感正文',
      ),
    );
    final imapCache = await StorageService.getAllData(
      '${StorageKeys.emailMailboxCacheCollection}_imap',
    );
    final popCache = await StorageService.getAllData(
      '${StorageKeys.emailMailboxCacheCollection}_pop',
    );
    final smtpCache = await StorageService.getAllData(
      '${StorageKeys.emailMailboxCacheCollection}_smtp',
    );
    final storedState = '$imapCache $popCache $smtpCache';

    expect(result.status, EmailQueryStatus.success);
    expect(storedState.toString(), isNot(contains('recipient@example.com')));
    expect(storedState.toString(), isNot(contains('敏感主题')));
    expect(storedState.toString(), isNot(contains('敏感正文')));
  });

  test('SMTP 发信网络或超时失败时返回安全网络错误', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final request = const EmailComposeRequest(
      to: ['recipient@example.com'],
      subject: '敏感主题',
      body: '敏感正文',
    );

    for (final error in <Object>[
      const SocketException('offline'),
      TimeoutException('timeout'),
    ]) {
      final service = EmailService(gateway: _FakeEmailGateway(error: error));

      final result = await service.sendMessage(request);

      expect(result.status, EmailQueryStatus.networkError);
      expect(
        '${result.message} ${result.detail}',
        isNot(contains('recipient')),
      );
      expect('${result.message} ${result.detail}', isNot(contains('敏感主题')));
      expect('${result.message} ${result.detail}', isNot(contains('敏感正文')));
    }
  });

  test('SMTP 服务端拒绝发信时返回登录拒绝且不回显输入', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final service = EmailService(
      gateway: _FakeEmailGateway(
        error: SmtpException.message(
          SmtpClient(EmailService.defaultDomain),
          'raw recipient@example.com 敏感正文',
        ),
      ),
    );

    final result = await service.sendMessage(
      const EmailComposeRequest(
        to: ['recipient@example.com'],
        subject: '敏感主题',
        body: '敏感正文',
      ),
    );

    expect(result.status, EmailQueryStatus.loginRejected);
    expect('${result.message} ${result.detail}', isNot(contains('recipient')));
    expect('${result.message} ${result.detail}', isNot(contains('敏感主题')));
    expect('${result.message} ${result.detail}', isNot(contains('敏感正文')));
  });

  test('IMAP 已读状态通过高级网关回写服务器', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final gateway = _AdvancedFakeEmailGateway();
    final service = EmailService(gateway: gateway);
    final result = await service.markMessageAsRead(
      _mailSnapshot.copyWith(serverUid: '42', isRead: false),
    );

    expect(result.status, EmailQueryStatus.success);
    expect(gateway.markSeenCount, 1);
    expect(gateway.lastServerUid, '42');
  });

  test('IMAP 附件下载按服务器 UID 与 MIME part 透传', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final gateway = _AdvancedFakeEmailGateway();
    final service = EmailService(gateway: gateway);
    const attachment = EmailAttachmentSnapshot(
      id: '2.1',
      fileName: '课表.pdf',
      mediaType: 'application/pdf',
    );
    final result = await service.downloadAttachment(
      _mailSnapshot.copyWith(serverUid: '42'),
      attachment,
    );

    expect(result.isSuccess, isTrue);
    expect(result.download?.fileName, '课表.pdf');
    expect(result.download?.bytes, [1, 2, 3]);
    expect(gateway.lastFetchId, '2.1');
  });

  test('停止邮箱获取后不会回写已读或下载附件', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final gateway = _AdvancedFakeEmailGateway();
    final service = EmailService(
      gateway: gateway,
      isFetchEnabled: () async => false,
    );
    final readResult = await service.markMessageAsRead(
      _mailSnapshot.copyWith(serverUid: '42', isRead: false),
    );
    final downloadResult = await service.downloadAttachment(
      _mailSnapshot.copyWith(serverUid: '42'),
      const EmailAttachmentSnapshot(
        id: '2.1',
        fileName: '课表.pdf',
        mediaType: 'application/pdf',
      ),
    );

    expect(readResult.status, EmailQueryStatus.fetchDisabled);
    expect(downloadResult.status, EmailQueryStatus.fetchDisabled);
    expect(gateway.markSeenCount, 0);
    expect(gateway.lastFetchId, isNull);
  });

  test('SMTP 附件校验拒绝过多、丢失和超大文件', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final gateway = _FakeEmailGateway();
    final service = EmailService(gateway: gateway);
    final tooMany = List.generate(
      EmailService.maxAttachmentCount + 1,
      (index) =>
          EmailAttachmentRequest(path: 'missing-$index', fileName: '附件$index'),
    );
    final tooManyResult = await service.sendMessage(
      EmailComposeRequest(
        to: const ['recipient@example.com'],
        subject: '主题',
        body: '正文',
        attachments: tooMany,
      ),
    );
    final missingResult = await service.sendMessage(
      const EmailComposeRequest(
        to: ['recipient@example.com'],
        subject: '主题',
        body: '正文',
        attachments: [
          EmailAttachmentRequest(path: 'missing', fileName: '不存在.txt'),
        ],
      ),
    );
    final directory = await Directory.systemTemp.createTemp('email-test-');
    addTearDown(() => directory.delete(recursive: true));
    final hugeFile = File('${directory.path}${Platform.pathSeparator}huge.bin');
    final randomAccess = await hugeFile.open(mode: FileMode.write);
    await randomAccess.truncate(EmailService.maxAttachmentBytes + 1);
    await randomAccess.close();
    final hugeResult = await service.sendMessage(
      EmailComposeRequest(
        to: const ['recipient@example.com'],
        subject: '主题',
        body: '正文',
        attachments: [
          EmailAttachmentRequest(path: hugeFile.path, fileName: 'huge.bin'),
        ],
      ),
    );

    expect(tooManyResult.message, '附件过多');
    expect(missingResult.message, '附件不可用');
    expect(hugeResult.message, '附件总大小过大');
    expect(gateway.sendSmtpCount, 0);
  });

  test('扩大查询范围会合并既有缓存并保留新旧邮件', () async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      emailPassword: 'mail-pass',
    );
    final first = EmailService(
      gateway: _FakeEmailGateway(messages: [_mailSnapshot]),
    );
    await first.fetchMessages(protocol: EmailProtocol.imap, messageCount: 1);
    const older = EmailMessageSnapshot(
      id: 'IMAP:2',
      subject: '更早邮件',
      senderName: '教务处',
      senderAddress: 'notice@sspu.edu.cn',
      preview: '更早内容',
      body: '更早内容',
    );
    final second = EmailService(gateway: _FakeEmailGateway(messages: [older]));
    final result = await second.fetchMessages(
      protocol: EmailProtocol.imap,
      messageCount: 2,
    );

    expect(
      result.snapshot?.messages.map((message) => message.id),
      containsAll(['IMAP:1', 'IMAP:2']),
    );
  });
}

class _FakeEmailGateway implements EmailGateway {
  _FakeEmailGateway({this.messages = const [], this.error, this.beforeReturn});

  final List<EmailMessageSnapshot> messages;
  final Object? error;
  final Future<void> Function()? beforeReturn;
  int fetchImapCount = 0;
  int fetchPopCount = 0;
  int validateImapCount = 0;
  int validatePopCount = 0;
  int validateSmtpCount = 0;
  int sendSmtpCount = 0;
  String? lastAccount;
  EmailComposeRequest? lastComposeRequest;

  @override
  Future<List<EmailMessageSnapshot>> fetchImapMessages({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required int messageCount,
    required Duration timeout,
  }) async {
    fetchImapCount++;
    lastAccount = account;
    final error = this.error;
    if (error != null) throw error;
    await beforeReturn?.call();
    return messages;
  }

  @override
  Future<List<EmailMessageSnapshot>> fetchPopMessages({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required int messageCount,
    required Duration timeout,
  }) async {
    fetchPopCount++;
    lastAccount = account;
    final error = this.error;
    if (error != null) throw error;
    await beforeReturn?.call();
    return messages;
  }

  @override
  Future<void> validateImapLogin({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required Duration timeout,
  }) async {
    validateImapCount++;
    lastAccount = account;
  }

  @override
  Future<void> validatePopLogin({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required Duration timeout,
  }) async {
    validatePopCount++;
    lastAccount = account;
  }

  @override
  Future<void> validateSmtpLogin({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required Duration timeout,
  }) async {
    validateSmtpCount++;
    lastAccount = account;
  }

  @override
  Future<void> sendSmtpMessage({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required EmailComposeRequest request,
    required Duration timeout,
  }) async {
    sendSmtpCount++;
    lastAccount = account;
    lastComposeRequest = request;
    final error = this.error;
    if (error != null) throw error;
    await beforeReturn?.call();
  }
}

class _AdvancedFakeEmailGateway extends _FakeEmailGateway
    implements AdvancedEmailGateway {
  int markSeenCount = 0;
  String? lastServerUid;
  String? lastFetchId;

  @override
  Future<void> markImapMessageSeen({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required String serverUid,
    required Duration timeout,
  }) async {
    markSeenCount++;
    lastServerUid = serverUid;
  }

  @override
  Future<EmailAttachmentDownload?> fetchImapAttachment({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required String serverUid,
    required String fetchId,
    required String fileName,
    required String mediaType,
    required Duration timeout,
  }) async {
    lastServerUid = serverUid;
    lastFetchId = fetchId;
    return EmailAttachmentDownload(
      fileName: fileName,
      mediaType: mediaType,
      bytes: const [1, 2, 3],
    );
  }
}

const EmailMessageSnapshot _mailSnapshot = EmailMessageSnapshot(
  id: 'IMAP:1',
  subject: '教务通知',
  senderName: '教务处',
  senderAddress: 'notice@sspu.edu.cn',
  preview: '请查看最新通知。',
  body: '请查看最新通知。',
);
