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
  test('unsigned macOS release 使用空 entitlements 剥离受限权限', () {
    final unsignedEntitlements = File(
      'macos/Runner/Release-unsigned.entitlements',
    ).readAsStringSync();

    // unsigned DMG 使用空 entitlements 剥离沙盒与钥匙串权限，避免 AMFI 拒绝启动。
    expect(unsignedEntitlements, isNot(contains('com.apple.security.')));
    expect(unsignedEntitlements, isNot(contains('keychain-access-groups')));
  });

  test('macOS Release 使用 ad-hoc 自签名替代官方签名与公证', () {
    final releaseWorkflow = File(
      '.github/workflows/release.yml',
    ).readAsStringSync();

    expect(
      releaseWorkflow,
      contains('使用 ad-hoc 自签名（未配置官方 Developer ID 签名与公证）'),
    );
    expect(releaseWorkflow, contains('codesign --force --deep --sign -'));
    expect(releaseWorkflow, isNot(contains('xcrun notarytool submit')));
    expect(releaseWorkflow, isNot(contains('xcrun stapler staple')));
    expect(releaseWorkflow, isNot(contains('Developer ID Application')));
    expect(
      releaseWorkflow,
      contains(
        'dist/SSPU-AllinOne-v\${{ needs.prepare.outputs.version }}-macos-arm64.dmg',
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

    const currentPublicVersion = '0.2.8-alpha';
    expect('SSPU-AIO v$currentPublicVersion'.length, lessThanOrEqualTo(27));
  });
}
