# 系统能力（System）

> 子模块：`platform/system`　·　所属：[平台基础](../README.md)

## 1. 子系统职责

跨功能的系统级基础能力：安全与隐私、本地存储与同步、通知与提醒、后台自动刷新、应用更新。被各业务功能共用。

## 2. 功能清单

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| 安全锁屏与隐私 | 已实现 | — | [`security-privacy.md`](security-privacy.md) |
| 本地存储与同步 | 部分实现 | #194 | [`storage-sync.md`](storage-sync.md) |
| 通知与提醒 | 部分实现 | #188 | [`notifications.md`](notifications.md) |
| 后台自动刷新 | 已实现 | — | [`auto-refresh.md`](auto-refresh.md) |
| 应用更新检测 | 已实现 | — | [`app-update.md`](app-update.md) |

## 3. 共性

- 数据全本地（系统默认应用数据目录）；凭据进系统安全存储。
- 通知投递、自动刷新、存储为各业务共享基座。
