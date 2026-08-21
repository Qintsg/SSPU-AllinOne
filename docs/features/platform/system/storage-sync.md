# 本地存储与同步

> 子模块：[系统能力](README.md)　·　状态：**部分实现**（本地存储已实现，WebDAV 同步设计中）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.system.storage-sync` |
| 状态 | 部分实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | #194 |
| 主要代码 | `lib/services/storage_service.dart`、`storage_keys.dart`、`app_data_directory_service.dart`、`authenticated_data_cache_service.dart` |

## 1. 需求

统一本地数据存储，并提供**可选的加密 WebDAV 同步**（#194），让多设备共享设置/配置/缓存。

**验收要点**
- 所有数据落**系统默认应用数据目录**（`path_provider`，不再用 `~/.sspu-aio`）。
- WebDAV 同步：端到端加密；**同步设置/配置/业务缓存，凭据不同步**；手动触发，冲突保留较新。

## 2. 本地存储（已实现）

- `StorageService` + `storage_keys`：统一状态文件（`app_state.json`）与键约定。
- `app_data_directory_service`：解析系统默认应用数据目录。
- `authenticated_data_cache_service`：按账号隔离的业务缓存（教务/校园卡/邮箱/消息等）。
- 凭据/Token/Key 不进此处，走系统安全存储（见 [安全锁屏与隐私](security-privacy.md)）。

## 3. 加密 WebDAV 同步（#194，设计中）

- **范围**：设置项、各功能配置（如 `wxmp_config.toml`、卡片显隐/排序、自动刷新）、业务缓存；**凭据不同步**（仍仅在本机安全存储）。
- **加密**：端到端加密（用户口令派生密钥），WebDAV 服务端只存密文。
- **触发**：手动同步（上传/下载）；**冲突**保留较新一方（按时间戳），必要时提示。
- **配置**：WebDAV 端点/账号/口令在设置「数据管理」分区；WebDAV 凭据本身进安全存储。

## 4. 关联

- 被依赖：几乎所有功能（设置/配置/缓存读写）；[校历](../academic-calendar.md)（PDF/文本缓存）、[消息中心](../../info/message-center.md)、[校园卡](../../campus-life/campus-card.md) 等缓存。
- 依赖：[安全锁屏与隐私](security-privacy.md)（WebDAV 凭据与加密密钥安全存储）、[设置中心](../shell/settings.md)。

## 5. 约束

- 数据全本地优先；同步为**可选、默认关闭**。
- **凭据不出本机**：WebDAV 同步不包含教务/邮箱等业务凭据。
- 同步内容端到端加密；明文与密钥不进日志。

## 6. 待办与演进

- [ ] 加密 WebDAV 同步（范围/加密/冲突/配置）（#194）。
- [ ] 同步内容清单与脱敏校验。
