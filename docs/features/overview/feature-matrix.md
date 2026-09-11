# 功能矩阵（Feature Matrix）

> 功能 × 状态 × 平台 × Issue 的全局聚合表。新增功能时同步登记此表。状态图例见 [功能总览](../README.md#4-状态图例)。

| 模块 | 功能 | 状态 | 平台 | Issue | 文档 |
| --- | --- | --- | --- | --- | --- |
| 平台·壳层 | 导航与响应式壳层 | 已实现 | 全平台 | #298 | [↗](../platform/shell/navigation-shell.md) |
| 平台·壳层 | 主页仪表盘与卡片 | 已实现 | 全平台 | #187 | [↗](../platform/shell/home-dashboard.md) |
| 平台·壳层 | 设置中心 | 已实现 | 全平台 | #187 | [↗](../platform/shell/settings.md) |
| 平台·系统 | 安全锁屏与隐私 | 已实现 | 全平台 | — | [↗](../platform/system/security-privacy.md) |
| 平台·系统 | 本地存储与同步 | 部分实现 | 全平台 | #194 | [↗](../platform/system/storage-sync.md) |
| 平台·系统 | 通知与提醒 | 部分实现（本地链路/权限状态已实现；真实设备待验收） | 全平台 | #188 | [↗](../platform/system/notifications.md) |
| 平台·系统 | 后台自动刷新 | 已实现 | 全平台 | — | [↗](../platform/system/auto-refresh.md) |
| 平台·系统 | 应用更新检测 | 已实现 | 全平台 | — | [↗](../platform/system/app-update.md) |
| 平台·系统 | 发布与 macOS 首次启动 | 部分实现（CI 门禁已补；Runner 实机待验收） | macOS | #327 | [↗](../platform/system/release.md) |
| 平台·个性化 | 主题与深色模式 | 已实现 | 全平台 | #168（已关闭） | [↗](../platform/personalization/theme.md) |
| 平台·个性化 | 国际化基础设施 | 设计中 | 全平台 | #192 | [↗](../platform/personalization/i18n.md) |
| 平台·通用 | 校历 | 已实现 | 全平台 | — | [↗](../platform/academic-calendar.md) |
| 教务 | 登录与凭据 | 已实现 | 全平台 | — | [↗](../academic/auth-credentials.md) |
| 教务·EAMS | EAMS 基座 | 已实现 | 全平台 | — | [↗](../academic/eams/foundation.md) |
| 教务·EAMS | 个人信息 | 已实现 | 全平台 | — | [↗](../academic/eams/profile.md) |
| 教务·EAMS | 日历（课程+考试） | 本地实现与自动化测试完成；系统日历实机验收待补 | 全平台 | #175 | [↗](../academic/eams/calendar.md) |
| 教务·EAMS | 成绩查询 | 已实现 | 全平台 | #177（已关闭） | [↗](../academic/eams/grade.md) |
| 教务·EAMS | 过程化成绩 | 已实现 | 全平台 | #177（已关闭） | [↗](../academic/eams/grade-process.md) |
| 教务·EAMS | 考试安排 | 已实现 | 全平台 | #178（已关闭） | [↗](../academic/eams/exam-schedule.md) |
| 教务·EAMS | 开课查询 | 部分实现 | 全平台 | #179（不再计划独立页面） | [↗](../academic/eams/course-offerings.md) |
| 教务·EAMS | 空闲教室查询 | 已实现 | 全平台 | #176 | [↗](../academic/eams/free-classrooms.md) |
| 教务·EAMS | 培养计划 | 已实现 | 全平台 | #174 | [↗](../academic/eams/program-plan.md) |
| 教务·活动 | 体育打卡考勤 | 已实现 | 全平台 | — | [↗](../academic/activity/sports-attendance.md) |
| 教务·活动 | 第二课堂学生报告 | 已实现 | 全平台 | — | [↗](../academic/activity/student-report.md) |
| 校园生活 | 校园卡余额与明细 | 已实现 | 全平台 | #187（仅关联显隐/获取设置） | [↗](../campus-life/campus-card.md) |
| 校园生活 | 消费统计与可视化 | 已实现（本地趋势 + 自定义窗口 + 日/周/月聚合） | 全平台 | — | [↗](../campus-life/consumption-analytics.md) |
| 资讯 | 多源新闻聚合 | 已实现 | 全平台 | — | [↗](../info/news-aggregation.md) |
| 资讯 | 消息中心 | 部分实现 | 全平台 | #188 | [↗](../info/message-center.md) |
| 资讯 | 微信公众号文章 | 部分实现 | 全平台 | — | [↗](../info/wechat-articles.md) |
| 邮箱 | 收件箱与阅读 | 已实现 | 全平台 | — | [↗](../email/inbox.md) |
| 邮箱 | 撰写发送 | 已实现 | 全平台 | — | [↗](../email/compose.md) |
| 常用操作 | 快捷跳转 | 已实现（App 深链、内嵌 WebView、OA 会话复用） | 全平台（条目按平台/安装状态过滤） | #280（已实现） | [↗](../quick-operations/quick-jump.md) |
| 常用操作 | 文档查询 | 设计中 | 全平台 | #131 | [↗](../quick-operations/document-query.md) |
| 校园网 | 校园网状态检测（门禁） | 部分实现 | 全平台 | — | [↗](../network/network-status.md) |
| 校园网 | 网络诊断与测速 | 设计中 | 全平台 | — | [↗](../network/network-diagnostics.md) |
| 校园网 | VPN 一键连接 | 不再计划 | 仅桌面（Win/macOS/Linux） | #169（不再计划） | [↗](../network/vpn-connect.md) |
| 校园网 | 本地插件机制（应用内不可见） | 不再计划 | 仅桌面（Win/macOS/Linux） | #169（不再计划） | [↗](../network/plugin-host.md) |
| AI 助手 | AI 助手对话 | 设计中 | 全平台 | — | [↗](../ai/ai-assistant.md) |
| AI 助手 | 模型与数据边界 | 设计中 | 全平台 | — | [↗](../ai/model-data-boundary.md) |
| AI 助手 | 本地数据 MCP 暴露 | 已实现（桌面；跨设备与第二客户端验收待补） | 仅桌面（Win/macOS/Linux） | — | [↗](../ai/mcp-server.md) |
