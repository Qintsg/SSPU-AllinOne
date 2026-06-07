/*
 * Windows 安装器协议测试 — 校验 Inno Setup 安装阶段展示合并协议
 * @Project : SSPU-AllinOne
 * @File : windows_installer_legal_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _installerScripts = [
  '.github/installer/windows-x64.iss',
  '.github/installer/windows-arm64.iss',
];

void main() {
  test('Windows x64 和 arm64 安装器引用同一份合并协议文件', () {
    const expected = r'LicenseFile={#WorkspaceDir}\assets\legal\legal_zh.txt';
    for (final script in _installerScripts) {
      expect(File(script).readAsStringSync(), contains(expected));
    }
    expect(File('assets/legal/legal_zh.txt').existsSync(), isTrue);
  });

  test('Windows x64 和 arm64 安装器默认安装目录固定使用英文技术名', () {
    final x64 = File('.github/installer/windows-x64.iss').readAsStringSync();
    final arm64 = File(
      '.github/installer/windows-arm64.iss',
    ).readAsStringSync();

    const expected = r'DefaultDirName={autopf}\{#AppTechnicalName}';
    expect(x64, contains(expected));
    expect(arm64, contains(expected));
    expect(
      x64,
      isNot(contains(r'DefaultDirName={autopf}\{code:GetAppDisplayName}')),
    );
    expect(
      arm64,
      isNot(contains(r'DefaultDirName={autopf}\{code:GetAppDisplayName}')),
    );
  });

  test('Windows 安装器升级时沿用既有安装范围和目录', () {
    for (final script in _installerScripts) {
      final content = File(script).readAsStringSync();

      expect(content, contains('UsePreviousAppDir=yes'));
      expect(content, contains('UsePreviousPrivileges=yes'));
      expect(
        content,
        contains('PrivilegesRequiredOverridesAllowed=dialog commandline'),
      );
      expect(content, contains('ExistingInstallFound'));
      expect(content, contains('ExistingInstallIsSameVersion'));
      expect(content, contains('PageID = wpSelectDir'));
      expect(content, contains('Preparing upgrade install'));
      expect(content, contains('UsePreviousPrivileges/UsePreviousAppDir'));
    }
  });

  test('Windows 安装器同版本重装先调用既有卸载程序', () {
    for (final script in _installerScripts) {
      final content = File(script).readAsStringSync();

      expect(content, contains('InitializeSetup'));
      expect(content, contains('SameVersionReinstallPrompt'));
      expect(content, contains('RunExistingUninstaller'));
      expect(
        content,
        contains(
          "RegQueryStringValue(RootKey, UninstallRegKey, 'DisplayVersion'",
        ),
      );
      expect(
        content,
        contains(
          "RegQueryStringValue(RootKey, UninstallRegKey, 'InstallLocation'",
        ),
      );
      expect(
        content,
        contains(
          "RegQueryStringValue(RootKey, UninstallRegKey, 'UninstallString'",
        ),
      );
      expect(content, contains('/SSPU_REINSTALL_CONTINUE=1'));
      expect(content, contains('RelaunchSetupAfterReinstall'));
      expect(content, contains('SSPUREINSTALL'));
    }
  });

  test('Windows 卸载器可选择是否保留应用数据目录', () {
    for (final script in _installerScripts) {
      final content = File(script).readAsStringSync();

      expect(content, contains('InitializeUninstall'));
      expect(content, contains('KeepAppDataPrompt'));
      expect(content, contains('SSPUKEEPAPPDATA'));
      expect(content, contains(r"ExpandConstant('{userprofile}\.sspu-aio')"));
      expect(content, contains('DelTree(AppDataPath, True, True, True)'));
      expect(content, contains('Keeping SSPU-AllinOne application data'));
    }
  });

  test('Windows 安装范围选择页提供中英双语关键文案', () {
    for (final script in _installerScripts) {
      final content = File(script).readAsStringSync();

      expect(content, contains('Select install scope / 选择安装范围'));
      expect(content, contains('Install for &all users / 为所有用户安装'));
      expect(content, contains('Install for &me only / 仅为当前用户安装'));
      expect(content, contains('仅安装到当前用户'));
      expect(content, contains('所有 Windows 用户'));
    }
  });

  test('Windows 安装器按架构检测对应 AppId 卸载注册表', () {
    final x64 = File('.github/installer/windows-x64.iss').readAsStringSync();
    final arm64 = File(
      '.github/installer/windows-arm64.iss',
    ).readAsStringSync();

    expect(
      x64,
      contains(
        r'Software\Microsoft\Windows\CurrentVersion\Uninstall\{3657CB2B-B935-4DE9-A7F2-FFA5E5FB1C8E}_is1',
      ),
    );
    expect(
      arm64,
      contains(
        r'Software\Microsoft\Windows\CurrentVersion\Uninstall\{F35768C5-7743-48E7-A7D0-F9923B7D1795}_is1',
      ),
    );
  });
}
