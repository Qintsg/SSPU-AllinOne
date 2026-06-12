/*
 * 应用 User-Agent 平台信息出口 — 根据运行平台选择系统版本读取实现
 * @Project : SSPU-AllinOne
 * @File : app_user_agent_platform.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

export 'app_user_agent_platform_stub.dart'
    if (dart.library.io) 'app_user_agent_platform_io.dart';
