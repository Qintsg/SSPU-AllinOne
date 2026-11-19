/*
 * 应用安全存储与 macOS 测试包的钥匙串选项
 * @Project : SSPU-AllinOne
 * @File : app_secure_storage.dart
 * @Author : Codex
 * @Date : 2026-11-19
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ad-hoc macOS 测试包使用登录钥匙串，证书签名的版本使用数据保护钥匙串。
const appSecureStorage = FlutterSecureStorage(
  mOptions: MacOsOptions(
    usesDataProtectionKeychain: !bool.fromEnvironment('SSPU_MACOS_AD_HOC'),
  ),
);
