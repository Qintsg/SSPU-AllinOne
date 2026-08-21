# 功能矩阵（Feature Matrix）

> 功能 × 状态 × 平台 × Issue 的全局聚合表。新增功能时同步登记此表。状态图例见 [功能总览](../README.md#4-状态图例)。

| 模块 | 功能 | 状态 | 平台 | Issue | 文档 |
| --- | --- | --- | --- | --- | --- |
| 平台·壳层 | 导航与响应式壳层 | 已实现 | 全平台 | #298 | [↗](../platform/shell/navigation-shell.md) |
| 平台·壳层 | 主页仪表盘与卡片 | 部分实现 | 全平台 | #187 | [↗](../platform/shell/home-dashboard.md) |
| 平台·壳层 | 设置中心 | 已实现 | 全平台 | #187 | [↗](../platform/shell/settings.md) |
| 平台·系统 | 安全锁屏与隐私 | 已实现 | 全平台 | — | [↗](../platform/system/security-privacy.md) |
| 平台·系统 | 本地存储与同步 | 部分实现 | 全平台 | #194 | [↗](../platform/system/storage-sync.md) |
| 平台·系统 | 通知与提醒 | 部分实现 | 全平台 | #188 | [↗](../platform/system/notifications.md) |
| 平台·系统 | 后台自动刷新 | 已实现 | 全平台 | — | [↗](../platform/system/auto-refresh.md) |
| 平台·系统 | 应用更新检测 | 已实现 | 全平台 | — | [↗](../platform/system/app-update.md) |
| 平台·个性化 | 主题与深色模式 | 部分实现 | 全平台 | #168 | [↗](../platform/personalization/theme.md) |
| 平台·个性化 | 国际化基础设施 | 设计中 | 全平台 | #192 | [↗](../platform/personalization/i18n.md) |
| 平台·通用 | 校历 | 部分实现 | 全平台 | — | [↗](../platform/academic-calendar.md) |
| 教务 | 登录与凭据 | 部分实现 | 全平台 | — | [↗](../academic/auth-credentials.md) |
| 教务·EAMS | EAMS 基座 | 部分实现 | 全平台 | — | [↗](../academic/eams/foundation.md) |
| 教务·EAMS | 个人信息 | 部分实现 | 全平台 | — | [↗](../academic/eams/profile.md) |
| 教务·EAMS | 日历（课程+考试） | 部分实现 | 全平台 | #175 | [↗](../academic/eams/calendar.md) |
| 教务·EAMS | 成绩查询 | 部分实现 | 全平台 | #177 | [↗](../academic/eams/grade.md) |
| 教务·EAMS | 过程化成绩 | 部分实现 | 全平台 | #177 | [↗](../academic/eams/grade-process.md) |
| 教务·EAMS | 考试安排 | 部分实现 | 全平台 | #178 | [↗](../academic/eams/exam-schedule.md) |
| 教务·EAMS | 开课查询 | 部分实现 | 全平台 | #179 | [↗](../academic/eams/course-offerings.md) |
| 教务·EAMS | 空闲教室查询 | 部分实现 | 全平台 | #176 | [↗](../academic/eams/free-classrooms.md) |
| 教务·EAMS | 培养计划 | 部分实现 | 全平台 | #174 | [↗](../academic/eams/program-plan.md) |
| 教务·活动 | 体育打卡考勤 | 部分实现 | 全平台 | — | [↗](../academic/activity/sports-attendance.md) |
| 教务·活动 | 第二课堂学生报告 | 部分实现 | 全平台 | — | [↗](../academic/activity/student-report.md) |
| 校园生活 | 校园卡余额与明细 | 部分实现 | 全平台 | #187 | [↗](../campus-life/campus-card.md) |
| 校园生活 | 消费统计与可视化 | 设计中 | 全平台 | — | [↗](../campus-life/consumption-analytics.md) |
| 资讯 | 多源新闻聚合 | 部分实现 | 全平台 | — | [↗](../info/news-aggregation.md) |
| 资讯 | 消息中心 | 部分实现 | 全平台 | #188 | [↗](../info/message-center.md) |
| 资讯 | 微信公众号文章 | 部分实现 | 全平台 | — | [↗](../info/wechat-articles.md) |
| 邮箱 | 收件箱与阅读 | 部分实现 | 全平台 | — | [↗](../email/inbox.md) |
| 邮箱 | 撰写发送 | 部分实现 | 全平台 | — | [↗](../email/compose.md) |
| 常用操作 | 快捷跳转 | 部分实现 | 全平台（条目按平台过滤） | #280 | [↗](../quick-operations/quick-jump.md) |
| 常用操作 | 文档查询 | 设计中 | 全平台 | #131 | [↗](../quick-operations/document-query.md) |
| 校园网 | 校园网状态检测（门禁） | 设计中 | 全平台 | — | [↗](../network/network-status.md) |
| 校园网 | 网络诊断与测速 | 设计中 | 全平台 | — | [↗](../network/network-diagnostics.md) |
| 校园网 | VPN 一键连接 | 设计中 | 仅桌面（Win/macOS/Linux） | #169 | [↗](../network/vpn-connect.md) |
| 校园网 | 本地插件机制（应用内不可见） | 设计中 | 仅桌面（Win/macOS/Linux） | #169 | [↗](../network/plugin-host.md) |
| AI 助手 | AI 助手对话 | 设计中 | 全平台 | — | [↗](../ai/ai-assistant.md) |
| AI 助手 | 模型与数据边界 | 设计中 | 全平台 | — | [↗](../ai/model-data-boundary.md) |
| AI 助手 | 本地数据 MCP 暴露 | 设计中 | 仅桌面（Win/macOS/Linux） | — | [↗](../ai/mcp-server.md) |
