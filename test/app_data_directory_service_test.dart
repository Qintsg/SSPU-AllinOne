/*
 * 应用数据目录服务测试 — 校验统一本地数据目录命名
 * @Project : SSPU-AllinOne
 * @File : app_data_directory_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-06
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/services/app_data_directory_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/services/wxmp_config_service.dart';

void main() {
  late Directory homeDirectory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    homeDirectory = await Directory.systemTemp.createTemp(
      'app_data_directory_home_',
    );
    AppDataDirectoryService.debugSetDirectoryForTesting(null);
  });

  tearDown(() async {
    AppDataDirectoryService.debugSetDirectoryForTesting(null);
    StorageService.debugSetStateFilePathForTesting(null);
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    WxmpConfigService.instance.debugSetConfigPathForTesting(null);
    SharedPreferences.setMockInitialValues({});
    if (await homeDirectory.exists()) {
      await homeDirectory.delete(recursive: true);
    }
  });

  test('统一目录名为 .sspu-aio 且默认根目录不再包含旧名称', () async {
    final rootPath = await AppDataDirectoryService.getRootDirectoryPath();

    expect(AppDataDirectoryService.directoryName, '.sspu-aio');
    expect(rootPath, endsWith('${Platform.pathSeparator}.sspu-aio'));
    expect(rootPath, isNot(contains('.sspu-all-in')));
    expect(rootPath, isNot(contains('.sspu-all-in-one')));
  });

  test('状态文件和微信公众号配置文件使用统一数据目录', () async {
    final rootDirectory = Directory(
      '${homeDirectory.path}${Platform.pathSeparator}.sspu-aio',
    );
    AppDataDirectoryService.debugSetDirectoryForTesting(rootDirectory.path);

    await StorageService.init();
    await StorageService.setString('sample', 'value');
    await WxmpConfigService.instance.ensureConfigFile();

    expect(
      await StorageService.getStateFilePath(),
      '${rootDirectory.path}${Platform.pathSeparator}app_state.json',
    );
    expect(
      await WxmpConfigService.instance.getConfigPath(),
      '${rootDirectory.path}${Platform.pathSeparator}wxmp_config.toml',
    );
    expect(
      await File(
        '${rootDirectory.path}${Platform.pathSeparator}app_state.json',
      ).exists(),
      isTrue,
    );
    expect(
      await File(
        '${rootDirectory.path}${Platform.pathSeparator}wxmp_config.toml',
      ).exists(),
      isTrue,
    );
  });

  test('清除所有数据时只删除当前统一数据目录', () async {
    final rootDirectory = Directory(
      '${homeDirectory.path}${Platform.pathSeparator}.sspu-aio',
    );
    final legacyDirectory = Directory(
      '${homeDirectory.path}${Platform.pathSeparator}.sspu-all-in',
    );
    AppDataDirectoryService.debugSetDirectoryForTesting(rootDirectory.path);

    await legacyDirectory.create(recursive: true);
    await File(
      '${legacyDirectory.path}${Platform.pathSeparator}legacy.txt',
    ).writeAsString('legacy backup');
    await StorageService.init();
    await StorageService.setString('sample', 'value');

    await StorageService.clearAll();

    expect(await rootDirectory.exists(), isFalse);
    expect(await legacyDirectory.exists(), isTrue);
    expect(
      await File(
        '${legacyDirectory.path}${Platform.pathSeparator}legacy.txt',
      ).readAsString(),
      'legacy backup',
    );
  });

  test('Web 状态后端保持 SharedPreferences 路径不变', () async {
    StorageService.debugUseSharedPreferencesStorageForTesting(true);

    await StorageService.init();
    await StorageService.setString('sample', 'value');

    expect(
      await StorageService.getStateFilePath(),
      'SharedPreferences:sspu_app_state_json',
    );
    expect(await StorageService.getString('sample'), 'value');
  });

  test('默认微信公众号配置注释展示新目录', () {
    final toml = WxmpConfig.defaults().toToml();

    expect(toml, contains('~/.sspu-aio/'));
    expect(toml, isNot(contains('.sspu-all-in')));
    expect(toml, isNot(contains('.sspu-all-in-one')));
  });
}
