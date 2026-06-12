/*
 * Release 工作流配置回归测试
 * @Project : SSPU-AllinOne
 * @File : release_workflow_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GitHub Release Tag 指向当前 workflow 提交而不是默认分支', () {
    final releaseWorkflow = File(
      '.github/workflows/release.yml',
    ).readAsStringSync();
    final publishStep = RegExp(
      r'softprops/action-gh-release@b4309332981a82ec1c5618f44dd2e27cc8bfbfda[\s\S]*?files: dist/\*',
    ).firstMatch(releaseWorkflow)?.group(0);

    expect(publishStep, isNotNull);
    expect(
      publishStep,
      contains('tag_name: \${{ needs.prepare.outputs.tag }}'),
    );
    expect(publishStep, contains('target_commitish: \${{ github.sha }}'));
  });

  test('Windows arm64 Release 使用 arm64 JDK 避免 jni 链接混架构', () {
    final releaseWorkflow = File(
      '.github/workflows/release.yml',
    ).readAsStringSync();
    final windowsArm64Job = RegExp(
      r'build-windows-arm64:[\s\S]*?(?=\n  build-macos:)',
    ).firstMatch(releaseWorkflow)?.group(0);

    expect(windowsArm64Job, isNotNull);
    expect(windowsArm64Job, contains('runs-on: windows-11-arm'));
    expect(windowsArm64Job, contains('actions/setup-java@v5.2.0'));
    expect(windowsArm64Job, contains("java-version: '21'"));
    expect(windowsArm64Job, contains('architecture: arm64'));
    expect(windowsArm64Job, isNot(contains('architecture: x64')));
  });
}
