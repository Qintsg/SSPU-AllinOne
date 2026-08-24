# 资讯（Info）

> 业务域：`info`　·　所属：[功能总览](../README.md)

## 1. 模块职责

聚合校内外公开信息并提供统一阅读：配置驱动的多源抓取、统一消息中心（聚合/已读/筛选/搜索）、固定校内公众号文章。

## 2. 功能清单

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| 多源新闻聚合 | 部分实现 | — | [`news-aggregation.md`](news-aggregation.md) |
| 消息中心 | 部分实现 | #188 | [`message-center.md`](message-center.md) |
| 微信公众号文章 | 部分实现 | — | [`wechat-articles.md`](wechat-articles.md) |

## 3. 信息架构（三级标签）

- tag1 来源类型（`MessageSourceType`）→ tag2 来源名称（`MessageSourceName`）→ tag3 内容分类（`MessageCategory`）。
- **微信推文仅两级**：tag1 + tag2（公众号名），无 tag3。
- 频道(channel)开关 + 子分类开关 + 自动刷新间隔/抓取条数（默认值后续可调）+ 已读集合。

## 3.1 功能关系

- **多源新闻聚合** + **微信公众号文章** 产出统一 `MessageItem` → **消息中心** 聚合展示。
- 阅读统一走**内置 WebView**（+ 外部浏览器按钮 + 下载型 URL 特别处理）。

## 4. 模块级约束

- 数据源为公开网页/公众号，只读抓取；单源失败降级、不阻断整体。
- **通知投递归 [platform/通知与提醒](../platform/system/notifications.md)**；info 只产消息并声明通知意愿（含单公众号）。
- 抓取走统一 HTTP 服务并尊重频道自动刷新节流；敏感登录态进安全存储、不入日志。

## 5. 相关 Issue

#188（优化消息推送并添加课程/考试提醒——通知投递侧）。
