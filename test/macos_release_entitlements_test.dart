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

  test('macOS DMG 打包前以 Release-unsigned.entitlements 剥离残留 entitlement', () {
    final releaseWorkflow = File(
      '.github/workflows/release.yml',
    ).readAsStringSync();

    // unsigned DMG 路径必须显式使用 Release-unsigned.entitlements 剥离权限。
    final unsignedEntitlementRef = releaseWorkflow.indexOf(
      'Release-unsigned.entitlements',
    );
    final adHocSigningIndex = releaseWorkflow.indexOf(
      'codesign --force --deep --sign -',
    );
    final entitlementCheckIndex = releaseWorkflow.indexOf(
      'unsigned macOS 产物不得携带',
    );

    expect(unsignedEntitlementRef, greaterThanOrEqualTo(0));
    expect(adHocSigningIndex, greaterThanOrEqualTo(0));
    expect(entitlementCheckIndex, greaterThan(adHocSigningIndex));
  });
}
