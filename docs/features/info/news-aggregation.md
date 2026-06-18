# 多源新闻聚合

> 模块：[资讯](README.md)　·　状态：**部分实现**（抓取/解析层已实现，前端重构）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `info.news-aggregation` |
| 状态 | 部分实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/college_news_service*.dart`、`jwc/itc/security/sports/construction/campus/sspu_news_service.dart`、`sspu_official_service.dart`、`web_content_service.dart`；`lib/models/message_item.dart`、`channel_config*.dart` |

## 1. 需求

以**配置驱动**方式抓取校内多源网页新闻，统一解析为 `MessageItem`，供 [消息中心](message-center.md) 聚合展示。

**验收要点**
- 覆盖 20+ 教学单位/部门首页与专用源（教务/信息办/保卫/体育/基建/新闻网/学校官网等）。
- 单源解析失败需降级（不影响其它源），不崩溃。
- 抓取走统一 HTTP 服务并尊重频道自动刷新间隔/条数。

## 2. 数据来源与配置（沿用现有，内置配置驱动）

- **通用学院源**：`CollegeNewsService` + `CollegeConfig`，按 CMS 模板分类解析：
  - 模板 A（标准 `ul` 列表）、B（`news_list` 图文卡片）、C（swiper 轮播）、D（自定义结构）。
  - 每个单位用一条 `CollegeConfig` 声明 `baseUrl` / 模板 / 选择器 / 日期格式 / 来源名(tag2) / 分类(tag3)。
- **专用源服务**：教务(jwc)、信息办(itc)、保卫(security)、体育(sports)、基建(construction)、新闻网(campus)、学校官网(sspu/sspu_official) 等各自服务。
- **新增/改版维护**：学校站点改版时，**改配置表或对应专用源解析即可**，随版发布（本期不做远程下发）。

## 3. 实现

### 3.1 抓取流程

```
频道(channel) → 源配置/专用源 → HTTP 抓取列表页 → 模板解析(标题/日期/链接) → MessageItem(去重 by id=URL 哈希)
```

- 列表项解析出标题、日期（含短日期补年、斜杠/拼合等格式）、详情 URL；`id` 为 URL 哈希用于已读跟踪。
- `knownMessageIds` 支持增量（已知则可跳过）；`maxCount` 限制条数。
- 正文不在此解析（阅读统一走内置 WebView，见 [消息中心](message-center.md)）。

### 3.2 三级标签产出

- tag1 来源类型（`MessageSourceType`：学校官网 / 微信推文 / 服务号）。
- tag2 来源名称（`MessageSourceName`：各单位/部门）。
- tag3 内容分类（`MessageCategory`：~100 个栏目；公众号源除外，见 [公众号](wechat-articles.md) 仅两级）。

## 4. 关联

- 被依赖：[消息中心](message-center.md)（消费 `MessageItem`）。
- 依赖：统一 `HttpService`；[后台自动刷新](../platform/system/auto-refresh.md)（按频道间隔触发）。

## 5. 约束

- 数据源为公开网页，只读抓取；单源失败降级、不阻断整体。
- 抓取频率受频道自动刷新间隔/条数约束，避免对站点造成压力。
- 解析仅取列表元数据，不在抓取层缓存正文。

## 6. 待办与演进

- [ ] 随前端重构对接消息中心展示。
- [ ] 站点改版时维护对应 `CollegeConfig`/专用源解析。
- [ ] **后续**：源配置远程下发（如需免发版修复改版）。
