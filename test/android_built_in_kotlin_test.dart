/*
 * Android Built-in Kotlin 迁移配置回归测试
 * @Project : SSPU-AllinOne
 * @File : android_built_in_kotlin_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('app 模块不再直接应用 Kotlin Gradle Plugin', () {
    final appGradle = _read('android/app/build.gradle.kts');

    expect(appGradle, isNot(contains('id("kotlin-android")')));
    expect(appGradle, isNot(contains('id("org.jetbrains.kotlin.android")')));
    expect(appGradle, isNot(contains('kotlinOptions')));
    expect(appGradle, contains('compilerOptions'));
    expect(appGradle, contains('JvmTarget.JVM_17'));
  });

  test('Flutter migrator 的临时 Built-in Kotlin 兼容开关已显式启用', () {
    final gradleProperties = _read('android/gradle.properties');

    expect(gradleProperties, contains('android.builtInKotlin=true'));
    expect(gradleProperties, contains('android.newDsl=true'));
    expect(gradleProperties, isNot(contains('android.builtInKotlin=false')));
    expect(gradleProperties, isNot(contains('android.newDsl=false')));
  });
}
