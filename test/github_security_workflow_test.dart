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
  test('高级 CodeQL 覆盖 Actions、C/C++ 与 Python 配置', () {
    final workflow = _readWorkflow('codeql.yml');

    expect(workflow, contains('name: CodeQL Analysis'));
    expect(workflow, contains('security-events: write'));
    expect(workflow, contains('github/codeql-action/init@'));
    expect(workflow, contains('github/codeql-action/analyze@'));
    expect(workflow, contains('language: actions'));
    expect(workflow, contains('language: python'));
    expect(workflow, contains('languages: c-cpp'));
    expect(workflow, contains('build-mode: none'));
    expect(workflow, contains("category: '/language:c-cpp'"));
    expect(workflow, isNot(contains('language: dart')));
    expect(workflow, isNot(contains('language: ruby')));
  });

  test('Flutter 覆盖率 workflow 上传 lcov artifact', () {
    final workflow = _readWorkflow('code-coverage.yml');

    expect(workflow, contains('name: Code Coverage'));
    expect(
      workflow,
      contains(
        'subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2',
      ),
    );
    expect(workflow, isNot(contains('subosito/flutter-action@v2.23.0')));
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

  test('User-Agent Policy workflow 在 PR 阶段运行策略脚本', () {
    final workflow = _readWorkflow('user-agent-policy.yml');

    expect(workflow, contains('name: User-Agent Policy'));
    expect(workflow, contains('pull_request:'));
    expect(workflow, contains('contents: read'));
    expect(
      workflow,
      contains('python scripts/ci/validate_user_agent_policy.py'),
    );
  });

  test('User-Agent Policy 脚本接受当前带说明的运行时代码例外', () async {
    final result = await Process.run('python', [
      'scripts/ci/validate_user_agent_policy.py',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test('User-Agent Policy 脚本拒绝未说明的非标准 UA', () async {
    final result = await Process.run('python', [
      '-c',
      r'''
from pathlib import Path
from scripts.ci import validate_user_agent_policy as policy

samples = [
    ("standard.dart", ["'User-Agent': HttpService.userAgent,"], 0),
    ("custom.dart", ["'User-Agent': 'ExternalProbe/1.0',"], 1),
    (
        "allowed.dart",
        [
            "// UA-POLICY-ALLOW: 外部平台要求固定探测 UA，限定在兼容接口使用。",
            "'User-Agent': 'ExternalProbe/1.0',",
        ],
        0,
    ),
]

for name, lines, expected_count in samples:
    violations = []
    for index, _ in enumerate(lines):
        reason = policy.user_agent_policy_reason(lines, index)
        if reason is not None and not policy.has_policy_allow_comment(lines, index):
            violations.append(reason)
    if len(violations) != expected_count:
        raise SystemExit(f"{name}: expected {expected_count}, got {len(violations)}")
''',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
}
