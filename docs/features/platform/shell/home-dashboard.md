# 主页仪表盘与卡片

> 子模块：[壳层](README.md)　·　状态：**部分实现**（前端重构 + 显隐/排序配置）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.shell.home-dashboard` |
| 状态 | 部分实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | #187、#189 |
| 主要代码 | `lib/pages/home_page.dart`、`home_*_card.dart`、`home_dashboard_widgets.dart` |

## 1. 需求

主页以卡片仪表盘聚合各域概览（学生信息、当周课程、校园卡余额、打卡、第二课堂、最新消息等），并按用户配置显隐与排序（#187）。

**验收要点**
- 卡片来自各域只读概览；加载/空/错误态明确。
- 显隐与排序由 [设置中心](settings.md) 统一配置（#187），主页按配置渲染。

## 2. 卡片来源（各域概览）

- [个人信息](../../academic/eams/profile.md)、[当周课程](../../academic/eams/calendar.md)、[考试](../../academic/eams/exam-schedule.md)、[校园卡](../../campus-life/campus-card.md)、[消费统计](../../campus-life/consumption-analytics.md)、[体育打卡](../../academic/activity/sports-attendance.md)、[第二课堂](../../academic/activity/student-report.md)、[消息中心](../../info/message-center.md) 等。

## 3. 实现

- `home_page` 按**卡片配置**（显隐 + 排序，来自设置）动态渲染清源仪表盘卡片（`home_dashboard_widgets.dart`）。
- 各卡片优先读本地缓存、再按各域刷新策略更新。
- 配置持久化于 [本地存储](../system/storage-sync.md)。

## 4. 关联

- 依赖：[导航壳层](navigation-shell.md)、[设置中心](settings.md)（#187 配置）、各域概览功能、[后台自动刷新](../system/auto-refresh.md)。
- 关联：#189 课程/考试小组件（桌面/系统小组件，后续）。

## 5. 约束

- 卡片只读概览；不在主页执行写操作。
- 显隐/排序配置本地持久化。

## 6. 待办与演进

- [ ] 卡片显隐 + 排序配置渲染（#187）。
- [ ] **后续**：课程/考试时间小组件（#189）。
