# 应用更新检测

> 子模块：[系统能力](README.md)　·　状态：**已实现**（前端重构中）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.system.app-update` |
| 状态 | 已实现 |
| 平台 | 全平台（本地安装入口依平台而定） |
| 关联 Issue | — |
| 主要代码 | `lib/services/app_update_service.dart`、`app_update_models.dart`、`app_update_parsing.dart`、`app_info_service.dart`、`app_display_name_service.dart` |

## 1. 需求

按正式版/测试版渠道查询 GitHub Release，发现新版本并（在支持平台）提供本地下载与安装入口。

## 2. 实现

- 查询 GitHub Release；资产元数据优先读 `manifest.json` 的 SHA-256，回退 `SHA256SUMS.txt`，再回退 API `digest`。
- 支持本地安装入口的平台下载推荐资产到系统默认应用数据目录下的 `update_downloads/<tag>/`，**SHA-256 校验通过**才显示「打开安装入口」。
- 按平台选择资产：Windows installer（区分 x64/arm64）、macOS DMG、Linux AppImage/deb/rpm/portable、Android APK；portable 仅打开文件夹提示手动替换。

## 3. 关联

- 关联：[设置中心](../shell/settings.md)（更新分区）、[本地存储](storage-sync.md)（下载目录）。
- 平台差异：见 `docs/RELEASE.md` 与 `docs/USAGE.md`。

## 4. 约束

- 下载资产必须 SHA-256 校验通过才提供安装入口；不自动解压/覆盖/静默安装。
- 仅查询与下载，不强制更新。

## 5. 待办与演进

- [ ] 前端重构后的更新卡片与渠道切换。
