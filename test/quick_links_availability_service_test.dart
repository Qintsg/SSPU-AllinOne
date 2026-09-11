import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/services/quick_links_availability_service.dart';
import 'package:sspu_allinone/services/quick_links_config_service.dart';

void main() {
  const groups = <QuickLinkGroupConfig>[
    QuickLinkGroupConfig(
      category: '学习平台',
      items: [
        QuickLinkItemConfig(
          name: '学习通（APP）',
          url: 'chaoxing://',
          kind: QuickLinkKind.app,
          platforms: {QuickLinkPlatform.android, QuickLinkPlatform.ios},
        ),
        QuickLinkItemConfig(name: '学习通（网页）', url: 'https://i.chaoxing.com/'),
      ],
    ),
  ];

  test('App 条目仅在支持平台且已安装时可见', () async {
    var detectionCount = 0;
    final desktopGroups = await QuickLinksAvailabilityService.filterGroups(
      groups,
      platform: QuickLinkPlatform.windows,
      canLaunch: (_) async {
        detectionCount += 1;
        return true;
      },
    );

    expect(desktopGroups.single.items.single.name, '学习通（网页）');
    expect(detectionCount, 0);

    final unavailableGroups = await QuickLinksAvailabilityService.filterGroups(
      groups,
      platform: QuickLinkPlatform.android,
      canLaunch: (_) async {
        detectionCount += 1;
        return false;
      },
    );

    expect(unavailableGroups.single.items.single.name, '学习通（网页）');
    expect(detectionCount, 1);

    final availableGroups = await QuickLinksAvailabilityService.filterGroups(
      groups,
      platform: QuickLinkPlatform.ios,
      canLaunch: (uri) async {
        detectionCount += 1;
        return uri.scheme == 'chaoxing';
      },
    );

    expect(availableGroups.single.items.map((item) => item.name), [
      '学习通（APP）',
      '学习通（网页）',
    ]);
    expect(detectionCount, 2);
  });

  test('安装检测失败时只隐藏 App 条目而不阻断网页入口', () async {
    final filteredGroups = await QuickLinksAvailabilityService.filterGroups(
      groups,
      platform: QuickLinkPlatform.android,
      canLaunch: (_) async => throw Exception('plugin unavailable'),
    );

    expect(filteredGroups.single.items.single.name, '学习通（网页）');
  });
}
