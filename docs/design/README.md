# 清源设计系统

清源是工大聚合前端重写的设计契约。它服务上海第二工业大学师生的跨端校园信息聚合场景，以“聚而不杂、本地为信、墨蓝为骨、青雾点睛”为核心原则。

## 阅读顺序

1. [`../../DESIGN.md`](../../DESIGN.md)：方向、边界、迁移策略与视觉签名。
2. [`resources/tokens.json`](./resources/tokens.json)：唯一机器真源。
3. [`foundations/`](./foundations/README.md)：颜色、字体、间距、阴影与动效语义。
4. [`components/`](./components/README.md)：44 个组件契约与交互样例。
5. [`patterns/`](./patterns/README.md)：组件如何组成页面和跨端壳层。
6. [`domain/`](./domain/README.md)：校园领域信息如何映射到组件。

## 当前阶段

- v0.3 冻结基础契约，并建立 JSON、CSS、Flutter 与文档的一致性校验。
- Flutter 实现先与既有 Fluent 页面并存，再以首页纵向切片验证清源。
- 完成一条切片的视觉、无障碍、响应式与回归验证后，才迁移下一批页面。

## 变更流程

1. 说明要解决的真实界面问题和受影响语义。
2. 先修改 `resources/tokens.json`，再同步生成物或镜像值。
3. 更新受影响的基础、组件、模式或领域文档。
4. 运行设计契约校验、Flutter 分析和相关测试。
5. 在 [`CHANGELOG.md`](./CHANGELOG.md) 记录破坏性或视觉可感知变化。
