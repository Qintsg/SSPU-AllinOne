# 消息中心

> 模块：[资讯](README.md)　·　状态：**部分实现**（聚合、筛选、搜索、阅读、下载交接与通知生产链路已完成；真实设备通知验证待补）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `info.message-center` |
| 状态 | 部分实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | #188（提醒，通知投递归 platform） |
| 主要代码 | `lib/services/message_state_service*.dart`、`info_refresh_service.dart`；`lib/models/message_item.dart`、`channel_config*.dart` |

## 1. 需求

将多源 `MessageItem` 聚合为统一消息中心：列表浏览、已读未读、按频道/分类筛选、本地搜索、未读红点/计数，并提供文章阅读入口。

**验收要点**
- 多源汇聚为统一列表（按时间/时间戳排序），本地已读/未读与未读计数。
- 按 tag2 来源、tag3 分类筛选；频道与子分类开关生效。
- 本地缓存消息标题搜索。
- 阅读统一走内置 WebView，下载型 URL 特别处理。
- 通知**只声明可通知项与单源意愿**，投递归 [通知与提醒](../platform/system/notifications.md)。

## 2. 交互与界面

- 统一消息列表：来源/分类标签、标题、时间、已读未读标识；未读红点/计数在入口与导航呈现。
- 筛选：按频道(tag2)/分类(tag3)；搜索框在已缓存标题内匹配。
- 阅读：点击进入**内置 WebView** 打开原文，带「用外部浏览器打开」按钮。
- 界面使用清源搜索、筛选抽屉、消息列表与 WebView 页面；本文档同时约束数据语义与可用动作。

## 3. 实现

### 3.1 聚合与状态（沿用现有）

- `MessageStateService`（单例）：已读 ID 集合（本地持久化）、`markAsRead`/`markAllAsRead`/`countUnread`、持久化消息列表。
- **频道/分类开关**：`isChannelEnabled`/`isCategoryEnabled`；自动刷新间隔与手动/自动抓取条数（默认值后续可调）。
- `info_refresh_service` 按频道编排抓取与合并。

### 3.2 筛选与搜索

- 筛选：按 tag2 来源、tag3 分类，结合频道/子分类开关过滤。
- **本地搜索**：对已缓存消息标题匹配（离线可用）。

### 3.3 文章阅读（仅内置 WebView）

- 统一用**内置 WebView** 打开 `MessageItem.url`，提供「用外部浏览器打开」按钮；不做正文解析阅读器。
- **下载型 URL 处理**：检测指向 PDF/doc/压缩包等的链接（`content-disposition` / 扩展名 / MIME）→ **交系统下载或外部应用打开**，不在 WebView 内卡住。

### 3.4 通知边界

- 消息中心**产出消息**并声明「可通知项」与单源（含单公众号）通知意愿；**实际投递、勿扰时段、全局开关归** [通知与提醒](../platform/system/notifications.md)（#188）。

## 4. 关联

- 依赖：[多源新闻聚合](news-aggregation.md)、[微信公众号文章](wechat-articles.md)（消息来源）；[本地存储](../platform/system/storage-sync.md)；[后台自动刷新](../platform/system/auto-refresh.md)。
- 被依赖：[通知与提醒](../platform/system/notifications.md)（消费消息与通知意愿）；[主页仪表盘](../platform/shell/home-dashboard.md)（未读/最新卡片）。

## 5. 约束

- 已读状态、消息列表本地持久化（系统默认应用数据目录）；不上云。
- 阅读经内置 WebView，下载型 URL 交系统/外部处理，避免在 WebView 内异常。
- 普通消息通知开关由设置中心独立管理；本模块只提供消息与单公众号通知意愿，实际投递由通知服务统一执行。

## 6. 待办与演进

- [x] 统一聚合列表、已读未读状态与本地持久化。
- [x] 频道/分类筛选与本地标题、摘要、来源搜索。
- [x] 内置 WebView 阅读与外部浏览器入口。
- [x] WebView 捕获下载请求并交系统浏览器/下载应用处理；打开失败保留可恢复错误提示。
- [x] 与 [通知与提醒](../platform/system/notifications.md) 对接通知意愿（#188）；真实设备投递仍需验证。
- [ ] 抓取条数/间隔默认值复核调整。
