import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/email_mailbox.dart';
import 'package:sspu_allinone/models/message_item.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/authenticated_data_cache_service.dart';
import 'package:sspu_allinone/services/email_service.dart';
import 'package:sspu_allinone/services/message_state_service.dart';
import 'package:sspu_allinone/services/mcp_snapshot_adapters.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  test('message snapshot exposes only searchable title metadata', () async {
    await MessageStateService.instance.saveMessages([
      const MessageItem(
        id: 'internal-message-id',
        title: '奖学金申请通知',
        summary: '请在截止日期前提交申请材料。',
        date: '2026-09-11',
        url: 'https://example.edu/path?token=secret',
        sourceType: MessageSourceType.schoolWebsite,
        sourceName: MessageSourceName.studentAffairs,
        category: MessageCategory.studentNotice,
      ),
    ]);

    final result = await McpSnapshotAdapters().messages({'query': '奖学金'});
    final item =
        (result.data?['items'] as List<dynamic>).single as Map<String, dynamic>;
    expect(item['title'], '奖学金申请通知');
    expect(item['sourceName'], '学生处');
    expect(item, isNot(contains('id')));
    expect(item, isNot(contains('url')));
    expect(item.toString(), isNot(contains('secret')));
  });

  test(
    'email snapshot omits body, server UID, endpoint, and attachment names',
    () async {
      const account = '20260001@sspu.edu.cn';
      await AcademicCredentialsService.instance.saveCredentials(
        oaAccount: '20260001',
      );
      final fetchedAt = DateTime.now();
      final snapshot = EmailMailboxSnapshot(
        protocol: EmailProtocol.imap,
        account: account,
        fetchedAt: fetchedAt,
        endpoint: EmailService.defaultImapEndpoint,
        messages: [
          EmailMessageSnapshot(
            id: 'raw-message-id',
            subject: '课程调整',
            senderName: '教务处',
            senderAddress: 'jwc@sspu.edu.cn',
            preview: '明天第一节课调整教室。',
            body: '完整正文不应通过 MCP search_email 返回。',
            receivedAt: fetchedAt,
            serverUid: '99123',
            attachments: const [
              EmailAttachmentSnapshot(
                id: 'attachment-id',
                fileName: '敏感附件.pdf',
                mediaType: 'application/pdf',
              ),
            ],
          ),
        ],
      );
      await AuthenticatedDataCacheService.saveLatest(
        collection: '${StorageKeys.emailMailboxCacheCollection}_imap',
        accountKey: account,
        fetchedAt: fetchedAt,
        data: snapshot.toJson(),
      );

      final result = await McpSnapshotAdapters().email({'query': '课程'});
      final item =
          (result.data?['items'] as List<dynamic>).single
              as Map<String, dynamic>;
      expect(item['subject'], '课程调整');
      expect(item['hasAttachments'], isTrue);
      expect(item['messageId'], isNot('raw-message-id'));
      final encoded = item.toString();
      expect(encoded, isNot(contains('完整正文')));
      expect(encoded, isNot(contains('99123')));
      expect(encoded, isNot(contains('敏感附件.pdf')));
      expect(encoded, isNot(contains('imap.exmail.qq.com')));
      expect(encoded, isNot(contains(account)));
    },
  );
}
