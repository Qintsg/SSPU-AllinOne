/*
 * Windows 安装器协议测试 — 校验 Inno Setup 安装阶段展示合并协议
 * @Project : SSPU-AllinOne
 * @File : windows_installer_legal_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows x64 和 arm64 安装器引用同一份合并协议文件', () {
    final x64 = File('.github/installer/windows-x64.iss').readAsStringSync();
    final arm64 = File(
      '.github/installer/windows-arm64.iss',
    ).readAsStringSync();

    const expected = r'LicenseFile={#WorkspaceDir}\assets\legal\legal_zh.txt';
    expect(x64, contains(expected));
    expect(arm64, contains(expected));
    expect(File('assets/legal/legal_zh.txt').existsSync(), isTrue);
  });
}
