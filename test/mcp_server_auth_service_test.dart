import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/services/mcp_server_auth_service.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('API key can be generated, verified, rotated, and deleted', () async {
    final auth = McpServerAuthService.instance;
    expect((await auth.status()).hasKey, isFalse);

    final first = await auth.generate();
    expect(first, hasLength(43));
    expect(await auth.verify(first), isTrue);
    expect(await auth.verify('$first-wrong'), isFalse);
    expect((await auth.status()).createdAt, isNotNull);

    final second = await auth.rotate();
    expect(second, isNot(first));
    expect(await auth.verify(first), isFalse);
    expect(await auth.verify(second), isTrue);

    await auth.disable();
    expect((await auth.status()).hasKey, isFalse);
    expect(await auth.verify(second), isFalse);
  });
}
