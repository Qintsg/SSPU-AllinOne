/*
 * GitHub 安全扫描工作流回归测试
 * @Project : SSPU-AllinOne
 * @File : github_security_workflow_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readWorkflow(String fileName) {
  return File('.github/workflows/$fileName').readAsStringSync();
}

void main() {
  test('高级 CodeQL 覆盖 Actions、C/C++、Python 与 Ruby 配置', () {
    final workflow = _readWorkflow('codeql.yml');

    expect(workflow, contains('name: CodeQL Analysis'));
    expect(workflow, contains('security-events: write'));
    expect(workflow, contains('github/codeql-action/init@'));
    expect(workflow, contains('github/codeql-action/analyze@'));
    expect(workflow, contains('language: actions'));
    expect(workflow, contains('language: python'));
    expect(workflow, contains('language: ruby'));
    expect(workflow, contains('languages: c-cpp'));
    expect(workflow, contains('build-mode: none'));
    expect(workflow, contains("category: '/language:c-cpp'"));
    expect(workflow, isNot(contains('language: dart')));
  });

  test('Flutter 覆盖率 workflow 上传 lcov artifact', () {
    final workflow = _readWorkflow('code-coverage.yml');

    expect(workflow, contains('name: Code Coverage'));
    expect(workflow, contains('flutter test --coverage'));
    expect(workflow, contains('actions/upload-artifact@'));
    expect(workflow, contains('name: flutter-coverage-lcov'));
    expect(workflow, contains('path: coverage/lcov.info'));
    expect(workflow, contains("if-no-files-found: error"));
  });

  test('Secret Scanning workflow 使用全历史 Gitleaks 扫描', () {
    final workflow = _readWorkflow('secret-scanning.yml');

    expect(workflow, contains('name: Secret Scanning'));
    expect(workflow, contains('fetch-depth: 0'));
    expect(workflow, contains('gitleaks/gitleaks-action@'));
    expect(workflow, contains('GITLEAKS_ENABLE_COMMENTS'));
    expect(workflow, contains('GITLEAKS_ENABLE_UPLOAD_ARTIFACT'));
    expect(workflow, contains('schedule:'));
  });

  test('CI quality-gate 显式整合 Dart 与 Flutter 门禁', () {
    final workflow = _readWorkflow('ci.yml');

    expect(workflow, contains('name: Dart / Flutter Quality Gate'));
    expect(workflow, contains('Dart Format（仅检查 PR 变更的 Dart 文件）'));
    expect(workflow, contains('Flutter Analyze（Dart 静态分析）'));
    expect(workflow, contains('Flutter Test（Dart / Widget 测试）'));
  });
}
