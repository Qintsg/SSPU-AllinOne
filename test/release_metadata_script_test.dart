/*
 * Release 元数据脚本回归测试
 * @Project : SSPU-AllinOne
 * @File : release_metadata_script_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Release metadata 接受签名 macOS DMG 资产', () async {
    final tempDir = await Directory.systemTemp.createTemp('release-metadata-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    for (final assetName in _expectedAssetNames) {
      await File(
        '${tempDir.path}${Platform.pathSeparator}$assetName',
      ).writeAsString('fixture:$assetName');
    }

    final result = await Process.run('python', [
      'scripts/release/generate_release_metadata.py',
      '--asset-dir',
      tempDir.path,
      '--version',
      '1.2.0',
      '--pubspec-version',
      '1.2.0+7',
      '--channel',
      'stable',
      '--build-number',
      '7',
      '--tag',
      'v1.2.0',
      '--release-date',
      '2026-06-12T00:00:00Z',
      '--flutter-version',
      '3.44.0',
      '--dart-version',
      '3.12.0',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

    final manifest =
        jsonDecode(
              await File(
                '${tempDir.path}${Platform.pathSeparator}manifest.json',
              ).readAsString(),
            )
            as Map<String, Object?>;
    final platforms = manifest['platforms']! as List<Object?>;
    final macosEntry = platforms.cast<Map<String, Object?>>().singleWhere(
      (entry) => entry['platform'] == 'macos',
    );

    expect(macosEntry['arch'], 'universal');
    expect(macosEntry['kind'], 'dmg');
    expect(macosEntry['filename'], 'SSPU-AllinOne-v1.2.0-macos-universal.dmg');
  });
}

const _expectedAssetNames = [
  'SSPU-AllinOne-v1.2.0-android-universal.apk',
  'SSPU-AllinOne-v1.2.0-windows-x64-installer.exe',
  'SSPU-AllinOne-v1.2.0-windows-x64-portable.zip',
  'SSPU-AllinOne-v1.2.0-windows-arm64-installer.exe',
  'SSPU-AllinOne-v1.2.0-windows-arm64-portable.zip',
  'SSPU-AllinOne-v1.2.0-macos-universal.dmg',
  'SSPU-AllinOne-v1.2.0-linux-x64-appimage.AppImage',
  'SSPU-AllinOne-v1.2.0-linux-x64-deb.deb',
  'SSPU-AllinOne-v1.2.0-linux-x64-rpm.rpm',
  'SSPU-AllinOne-v1.2.0-linux-x64-portable.tar.gz',
  'SSPU-AllinOne-v1.2.0-linux-arm64-appimage.AppImage',
  'SSPU-AllinOne-v1.2.0-linux-arm64-deb.deb',
  'SSPU-AllinOne-v1.2.0-linux-arm64-rpm.rpm',
  'SSPU-AllinOne-v1.2.0-linux-arm64-portable.tar.gz',
];
