# 页面模式 Patterns

页面模式描述多个清源组件如何共同完成一项用户任务。模式不复制组件视觉值，也不持有业务状态。

## 首批模式

- [`responsive-shell.md`](./responsive-shell.md)：移动底栏、桌面导航轨与窗口框架。
- [`home-dashboard.md`](./home-dashboard.md)：首页今日学程时间轨与只读业务概览。
- [`home-dashboard-density-v05.md`](./home-dashboard-density-v05.md)：首页可配置服务关闭后的收束规则。
- [`home-greeting-wrap-v01.md`](./home-greeting-wrap-v01.md)：首页问候语的紧凑端短语换行规则。
- [`course-schedule-day-rail-v01.md`](./course-schedule-day-rail-v01.md)：课程表紧凑端完整七日日期带与可达性规则。
- [`campus-card-empty-recovery-v01.md`](./campus-card-empty-recovery-v01.md)：校园卡详情本地筛选无结果的紧凑恢复条。
- [`campus-card-terminal-recovery-v01.md`](./campus-card-terminal-recovery-v01.md)：校园卡详情无本地快照时的终端错误恢复条。
- [`academic-overview-density-v02.md`](./academic-overview-density-v02.md)：教务总览紧凑指标账本。
- [`academic-overview-flow-v03.md`](./academic-overview-flow-v03.md)：教务总览的连续学程流、自然高度卡片与窄屏标题规则。
- [`academic-overview-state-density-v01.md`](./academic-overview-state-density-v01.md)：教务总览初始、空、凭据和失败恢复面板的内容高度规则。
- [`academic-filter-density-v01.md`](./academic-filter-density-v01.md)：教务详情筛选账本的宽度与单字段规则。
- [`task-state-density-v01.md`](./task-state-density-v01.md)：快捷入口与教务详情的加载、空和错误状态收束规则。
- [`academic-detail-recovery-ledger-v01.md`](./academic-detail-recovery-ledger-v01.md)：教务详情加载、空与错误状态的紧凑恢复账本。
- [`information-feed.md`](./information-feed.md)：校园资讯流的内容、筛选与响应式阅读规则。
- [`information-feed-state-width-v03.md`](./information-feed-state-width-v03.md)：校园资讯无内容状态的窄恢复列与断点规则。
- [`mail-compose-action-dock-v01.md`](./mail-compose-action-dock-v01.md)：邮件撰写连续表单与紧凑端固定提交坞。
- [`about-legal-reading-density-v01.md`](./about-legal-reading-density-v01.md)：关于构建账本与法律阅读列的内容高度、可读宽度和恢复规则。
- [`appearance-choice-density-v01.md`](./appearance-choice-density-v01.md)：外观主题选择线的内容高度、互斥操作与断点规则。
- [`academic-calendar-evidence-rail-v01.md`](./academic-calendar-evidence-rail-v01.md)：校历宽屏证据栏与独立 PDF 阅读区的高度规则。
- [`open-source-license-density-v01.md`](./open-source-license-density-v01.md)：开源许可矩阵与移动项目卡的宽度和恢复规则。
- [`application-map.md`](./application-map.md)：七个主目的地、详情边界和完整页面级验收契约。
- [`states-and-flows.md`](./states-and-flows.md)：六态语法、认证、详情、外部边界和数据清除流程。
- [`samples/app-shell.html`](./samples/app-shell.html)：覆盖七个主目的地的亮暗、响应式可交互原型。

## 约束

- 页面一屏一个信息重点，主行动至多一个。
- 同一目的地与业务状态在不同断点保持一致，只改变编排和密度。
- 加载、空、未配置、过期缓存、失败必须是显式状态。
- 模式只依赖组件公开接口，不跨过组件 seam 读取实现细节。

## 完成边界

v0.3 页面设计已覆盖全应用主导航、主页面、详情边界和关键状态；Flutter 迁移进度单独记录，不以页面设计完成冒充实现完成。
