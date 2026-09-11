# 发布与 macOS 首次启动

> 子模块：[系统能力](README.md)　·　状态：**部分实现**（发布链路已补齐；#327 仍待 macOS Runner 实机验收）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.system.release` |
| 状态 | CI 静态门禁与签名/公证步骤已实现；首次启动实机证据待补 |
| 平台 | macOS（发布工作流）；其余平台沿用各自发布门禁 |
| 关联 Issue | #327 |
| 主要代码 | `.github/workflows/release.yml`、`scripts/release/generate_release_metadata.py`、`macos/Runner/Release.entitlements` |

## 1. 需求

修复 macOS `0.4.0-beta` DMG 安装后首次打开被系统拦截或无法启动的问题，确保正式产物可被 Gatekeeper 接受并能完成首次启动。

## 2. 当前实现

- macOS 正式发布路径要求 Developer ID 签名、公证、staple，并检查 Gatekeeper 与 universal 架构。
- Release workflow 缺少签名、公证凭据时 fail-closed，不生成可冒充正式产物的未签名 DMG。
- 发布元数据和资产命名保持公开版本一致，避免用户下载到无法识别的产物。

## 3. 验收边界

- Windows 本地构建、静态 workflow 检查和单元测试只能证明脚本与配置契约，不能代替 macOS Runner 的签名、公证、安装、Gatekeeper 和首次启动证据。
- 在真实 macOS Runner 与干净用户目录完成验收前，状态保持“部分实现”，不得写成 #327 已关闭。

## 4. 待办

- [x] 接入签名、公证、staple、Gatekeeper 与 universal 架构门禁。
- [x] 为缺少签名材料的正式路径设置 fail-closed。
- [ ] 在 macOS Runner 下载 DMG，完成安装、首次启动与钥匙串/权限回归并记录证据。
