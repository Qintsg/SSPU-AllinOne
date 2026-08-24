# 平台基础（Platform）

> 业务域：`platform`　·　所属：[功能总览](../README.md)

## 1. 模块职责

承载跨功能的应用壳层与系统能力，是其余业务域的共享基座。按三个子组组织，外加一项通用能力（校历）。

## 2. 子模块与功能

### 壳层 [`shell/`](shell/README.md)

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| 导航与响应式壳层 | 已实现 | #298 | [`shell/navigation-shell.md`](shell/navigation-shell.md) |
| 主页仪表盘与卡片 | 部分实现 | #187 | [`shell/home-dashboard.md`](shell/home-dashboard.md) |
| 设置中心 | 已实现 | #187 | [`shell/settings.md`](shell/settings.md) |

### 系统能力 [`system/`](system/README.md)

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| 安全锁屏与隐私 | 已实现 | — | [`system/security-privacy.md`](system/security-privacy.md) |
| 本地存储与同步 | 部分实现 | #194 | [`system/storage-sync.md`](system/storage-sync.md) |
| 通知与提醒 | 部分实现 | #188 | [`system/notifications.md`](system/notifications.md) |
| 后台自动刷新 | 已实现 | — | [`system/auto-refresh.md`](system/auto-refresh.md) |
| 应用更新检测 | 已实现 | — | [`system/app-update.md`](system/app-update.md) |

### 个性化 [`personalization/`](personalization/README.md)

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| 主题与深色模式 | 部分实现 | #168 | [`personalization/theme.md`](personalization/theme.md) |
| 国际化基础设施 | 设计中 | #192 | [`personalization/i18n.md`](personalization/i18n.md) |

### 通用能力

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| 校历（无需登录，供全局学期/周次计算） | 部分实现 | — | [`academic-calendar.md`](academic-calendar.md) |

## 3. 内部依赖

- 主页 / 设置 / 通知依赖导航壳层的路由与目的地。
- 几乎所有业务功能依赖：安全凭据存储、本地存储、自动刷新、通知。
- **校历**为通用学期/周次基座，被教务课表/考试/过程化成绩/空闲教室等依赖（无需登录）。

## 4. 模块级约束

- 数据全本地（系统默认应用数据目录）；凭据进系统安全存储；不再使用 `~/.sspu-aio`。
- UI 严格走设计系统门面，禁裸值（[`DESIGN.md`](../../../DESIGN.md)）。

## 5. 相关 Issue

#298（前端重构）、#187（卡片/模块显隐）、#188（推送提醒）、#168（主题）、#192（i18n）、#194（WebDAV 同步）、#189（小组件）。
