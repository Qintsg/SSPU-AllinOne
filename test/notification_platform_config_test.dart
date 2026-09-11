import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android 声明定时通知与重启恢复能力', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
      ),
    );
    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver',
      ),
    );
    expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
    expect(manifest, contains('android.intent.action.MY_PACKAGE_REPLACED'));
  });

  test('Android 为通知插件启用 Java API 脱糖', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('isCoreLibraryDesugaringEnabled = true'));
    expect(
      gradle,
      contains(
        'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")',
      ),
    );
  });
}
