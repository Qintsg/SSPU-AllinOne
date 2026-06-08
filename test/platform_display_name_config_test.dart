/*
 * 平台显示名配置测试 — 校验各平台用户可见名称本地化入口
 * @Project : SSPU-AllinOne
 * @File : platform_display_name_config_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-06
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

Map<String, Object?> _readJson(String path) {
  return jsonDecode(_read(path)) as Map<String, Object?>;
}

void main() {
  test('Android Launcher 名称使用资源本地化', () {
    expect(
      _read('android/app/src/main/AndroidManifest.xml'),
      contains('android:label="@string/app_name"'),
    );
    expect(
      _read('android/app/src/main/res/values/strings.xml'),
      contains('<string name="app_name">SSPU-AllinOne</string>'),
    );
    expect(
      _read('android/app/src/main/res/values-zh/strings.xml'),
      contains('<string name="app_name">工大聚合</string>'),
    );
    expect(
      _read('android/app/build.gradle.kts'),
      contains('applicationId = "cn.qintsg.sspu_allinone"'),
    );
  });

  test('Apple InfoPlist 字符串包含英文 fallback 与中文显示名', () {
    for (final platform in ['ios', 'macos']) {
      final plist = _read('$platform/Runner/Info.plist');
      final project = _read('$platform/Runner.xcodeproj/project.pbxproj');

      expect(plist, contains('SSPU-AllinOne'));
      expect(
        plist,
        contains('Use system authentication to quickly unlock SSPU-AllinOne'),
      );
      expect(project, contains('InfoPlist.strings in Resources'));
      expect(project, contains('zh-Hans.lproj/InfoPlist.strings'));
      expect(project, contains('zh-Hant.lproj/InfoPlist.strings'));

      expect(
        _read('$platform/Runner/en.lproj/InfoPlist.strings'),
        contains('"CFBundleDisplayName" = "SSPU-AllinOne";'),
      );
      expect(
        _read('$platform/Runner/zh-Hans.lproj/InfoPlist.strings'),
        contains('"CFBundleDisplayName" = "工大聚合";'),
      );
      expect(
        _read('$platform/Runner/zh-Hant.lproj/InfoPlist.strings'),
        contains('"CFBundleDisplayName" = "工大聚合";'),
      );
    }
  });

  test('Windows 和 Linux 原生入口按语言环境显示应用名', () {
    expect(
      _read('windows/runner/main.cpp'),
      contains('GetUserDefaultUILanguage'),
    );
    expect(
      _read('windows/runner/main.cpp'),
      contains(r'L"\u5de5\u5927\u805a\u5408"'),
    );
    expect(
      _read('lib/main.dart'),
      contains('windowManager.setTitle(AppDisplayName.currentPlatformName)'),
    );
    expect(
      _read('windows/runner/Runner.rc'),
      contains('VALUE "ProductName", "工大聚合"'),
    );

    for (final script in [
      '.github/installer/windows-x64.iss',
      '.github/installer/windows-arm64.iss',
    ]) {
      final content = _read(script);
      expect(content, contains('AppName={code:GetAppDisplayName}'));
      expect(
        content,
        contains('UninstallDisplayName={code:GetAppDisplayName}'),
      );
      expect(content, contains("Result := '工大聚合'"));
      expect(content, contains(r'DefaultDirName={autopf}\{#AppTechnicalName}'));
      expect(
        content,
        isNot(contains(r'DefaultDirName={autopf}\{code:GetAppDisplayName}')),
      );
      expect(content, contains('OutputBaseFilename=SSPU-AllinOne-v'));
      expect(content, contains('UsePreviousPrivileges=yes'));
      expect(content, contains('Select install scope / 选择安装范围'));
      expect(content, contains('Install for &me only / 仅为当前用户安装'));
    }

    final linuxRunner = _read('linux/runner/my_application.cc');
    expect(linuxRunner, contains('g_get_language_names'));
    expect(linuxRunner, contains('"工大聚合"'));

    final releaseWorkflow = _read('.github/workflows/release.yml');
    final linuxReleaseAssetsAction = _read(
      '.github/actions/package-linux-release-assets/action.yml',
    );
    expect(
      releaseWorkflow,
      contains('./.github/actions/package-linux-release-assets'),
    );
    expect(linuxReleaseAssetsAction, contains('Name=SSPU-AllinOne'));
    expect(linuxReleaseAssetsAction, contains('Name[zh_CN]=工大聚合'));
    expect(
      linuxReleaseAssetsAction,
      contains(r'SSPU-AllinOne-v${RELEASE_VERSION}'),
    );
  });

  test('Web title 与 manifest 支持中英文显示名', () {
    final englishManifest = _readJson('web/manifest.json');
    final chineseManifest = _readJson('web/manifest.zh.json');
    final indexHtml = _read('web/index.html');

    expect(englishManifest['name'], 'SSPU-AllinOne');
    expect(englishManifest['short_name'], 'SSPU-AllinOne');
    expect(chineseManifest['name'], '工大聚合');
    expect(chineseManifest['short_name'], '工大聚合');
    expect(indexHtml, contains('navigator.languages'));
    expect(indexHtml, contains("manifest.zh.json"));
    expect(indexHtml, contains("isChinese ? '工大聚合' : 'SSPU-AllinOne'"));
  });
}
