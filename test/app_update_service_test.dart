/*
 * 应用更新服务测试 — 校验版本比较、Release 解析与资产选择
 * @Project : SSPU-AllinOne
 * @File : app_update_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/services/app_update_service.dart';

void main() {
  group('comparePublicVersions', () {
    test('按数字段和渠道顺序比较公开版本', () {
      expect(comparePublicVersions('1.0.1', '1.0.0'), greaterThan(0));
      expect(
        comparePublicVersions('1.0.0-beta', '1.0.0-alpha'),
        greaterThan(0),
      );
      expect(comparePublicVersions('1.0.0', '1.0.0-rc'), greaterThan(0));
      expect(comparePublicVersions('1.0.0+3', '1.0.0+1'), 0);
      expect(comparePublicVersions('1.0.0.1-hotfix', '1.0.0'), greaterThan(0));
    });
  });

  test('AppReleaseInfo 从 GitHub Release JSON 提取公开版本与资产', () {
    final release = AppReleaseInfo.fromJson({
      'name': 'SSPU-AllinOne v1.2.0-beta',
      'tag_name': 'v1.2.0-beta',
      'prerelease': true,
      'html_url':
          'https://github.com/Qintsg/SSPU-AllinOne/releases/tag/v1.2.0-beta',
      'published_at': '2026-05-18T00:00:00Z',
      'assets': [
        {
          'name': 'SSPU-AllinOne-v1.2.0-beta-windows-x64-installer.exe',
          'browser_download_url': 'https://example.com/installer.exe',
          'size': 10485760,
        },
      ],
    });

    expect(release.version, '1.2.0-beta');
    expect(release.prerelease, isTrue);
    expect(release.assets.single.displaySize, '10.0 MB');
  });
}
