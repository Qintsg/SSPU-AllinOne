# 页面模式 Patterns

页面模式描述多个清源组件如何共同完成一项用户任务。模式不复制组件视觉值，也不持有业务状态。

## 首批模式

- [`responsive-shell.md`](./responsive-shell.md)：移动底栏、桌面导航轨与窗口框架。
- [`home-dashboard.md`](./home-dashboard.md)：首页今日学程时间轨与只读业务概览。
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
