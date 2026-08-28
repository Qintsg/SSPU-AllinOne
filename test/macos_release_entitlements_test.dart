/*
 * macOS Release entitlement 配置回归测试
 * @Project : SSPU-AllinOne
 * @File : macos_release_entitlements_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-26
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unsigned macOS 本地 entitlements 剥离受限权限', () {
    final unsignedEntitlements = File(
      'macos/Runner/Release-unsigned.entitlements',
    ).readAsStringSync();

    // 本地 ad-hoc 构建使用空 entitlements，避免 AMFI 拒绝启动。
    expect(unsignedEntitlements, isNot(contains('com.apple.security.')));
    expect(unsignedEntitlements, isNot(contains('keychain-access-groups')));
  });

  test('macOS Release 使用无 entitlement 的 ad-hoc 签名', () {
    final releaseWorkflow = File(
      '.github/workflows/release.yml',
    ).readAsStringSync();

    expect(releaseWorkflow, contains('使用无 entitlement 的 ad-hoc 签名 macOS App Bundle'));
    expect(releaseWorkflow, contains('codesign --force --deep --sign -'));
    expect(releaseWorkflow, contains('codesign --verify --deep --strict --verbose=2'));
    expect(releaseWorkflow, contains('仍包含受限 entitlement'));
    expect(releaseWorkflow, contains('ditto "\$macos_app_bundle"'));
    expect(releaseWorkflow, isNot(contains('Developer ID Application')));
    expect(releaseWorkflow, isNot(contains('xcrun notarytool submit')));
    expect(releaseWorkflow, isNot(contains('xcrun stapler staple')));
    expect(releaseWorkflow, isNot(contains('MACOS_SIGNING_CERTIFICATE_BASE64')));
    expect(
      releaseWorkflow,
      contains(
        'dist/SSPU-AllinOne-v\${{ needs.prepare.outputs.version }}-macos-universal.dmg',
      ),
    );
  });

  test('macOS DMG 卷名保持在 appdmg 长度限制内', () {
    final releaseWorkflow = File(
      '.github/workflows/release.yml',
    ).readAsStringSync();

    expect(
      releaseWorkflow,
      isNot(
        contains('"title": "SSPU-AllinOne v\${APP_VERSION} (\${APP_BUILD})"'),
      ),
    );
    expect(releaseWorkflow, contains('DMG_TITLE="SSPU-AIO v\${APP_VERSION}"'));
    expect(releaseWorkflow, contains('if [ "\${#DMG_TITLE}" -gt 27 ]; then'));
    expect(releaseWorkflow, contains('"title": "\${DMG_TITLE}"'));

    const currentPublicVersion = '0.4.0-beta';
    expect('SSPU-AIO v$currentPublicVersion'.length, lessThanOrEqualTo(27));
  });
}
