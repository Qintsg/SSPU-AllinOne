/*
 * 学校邮箱服务测试 — 校验凭据读取、协议边界与账号规范化
 * @Project : SSPU-AllinOne
 * @File : email_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

import 'dart:io';

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

  test('SMTP 仅允许登录校验不允许收信', () async {
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

    expect(fetchResult.status, EmailQueryStatus.loginRejected);
    expect(validationResult.status, EmailQueryStatus.success);
    expect(gateway.validateSmtpCount, 1);
    expect(gateway.fetchImapCount + gateway.fetchPopCount, 0);
  });
}

class _FakeEmailGateway implements EmailGateway {
  _FakeEmailGateway({this.messages = const [], this.error, this.beforeReturn});

  final List<EmailMessageSnapshot> messages;
  final Object? error;
  final Future<void> Function()? beforeReturn;
  int fetchImapCount = 0;
  int fetchPopCount = 0;
  int validateSmtpCount = 0;
  String? lastAccount;

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
    lastAccount = account;
  }

  @override
  Future<void> validatePopLogin({
    required EmailServerEndpoint endpoint,
    required String account,
    required String password,
    required Duration timeout,
  }) async {
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
}

const EmailMessageSnapshot _mailSnapshot = EmailMessageSnapshot(
  id: 'IMAP:1',
  subject: '教务通知',
  senderName: '教务处',
  senderAddress: 'notice@sspu.edu.cn',
  preview: '请查看最新通知。',
  body: '请查看最新通知。',
);
