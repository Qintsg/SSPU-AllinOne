# 清源设计系统

清源是工大聚合前端重写的设计契约。它服务上海第二工业大学师生的跨端校园信息聚合场景，以“聚而不杂、本地为信、墨蓝为骨、青雾点睛”为核心原则。

## 阅读顺序

1. [`../../DESIGN.md`](../../DESIGN.md)：方向、边界、迁移策略与视觉签名。
2. [`resources/tokens.json`](./resources/tokens.json)：唯一机器真源。
3. [`foundations/`](./foundations/README.md)：颜色、字体、间距、阴影与动效语义。
4. [`components/`](./components/README.md)：44 个组件契约与交互样例。
5. [`patterns/`](./patterns/README.md)：组件如何组成页面和跨端壳层。
   首页可配置密度参考：[`home-dashboard-density-v05.md`](./patterns/home-dashboard-density-v05.md)。
   教务总览紧凑指标参考：[`academic-overview-density-v02.md`](./patterns/academic-overview-density-v02.md)。
6. [`domain/`](./domain/README.md)：校园领域信息如何映射到组件。
7. [`visual-testing.md`](./visual-testing.md)：五平台截图矩阵、外部区域标注、完整性门禁与人工视觉评审。

## 当前阶段

- v0.4.0 冻结全量页面状态与严格视口尺寸，并建立 JSON、CSS、Flutter、文档与页面原型的一致性校验；后续视觉候选采用自动完整性门禁与人工逐屏评审，不再计算 SSIM。
- 七个主目的地、详情边界和关键状态均已进入页面设计范围；[`patterns/samples/app-shell.html`](./patterns/samples/app-shell.html) 是统一视觉核验入口。
- Flutter 运行时已切换为纯清源组件；当前候选截图仅用于逐屏评审，未确认前不得反向覆盖已冻结参考。
- Flutter 页面与业务组件统一从 `lib/design/qingyuan/qingyuan_ui.dart` 访问宿主、主题、路由、弹层、反馈、图标与 `Yh*` 组件；业务代码不得直接导入清源内部实现文件。
- 完成一条切片的视觉、无障碍、响应式与回归验证后，才迁移下一批页面。

## 变更流程

1. 说明要解决的真实界面问题和受影响语义。
2. 先修改 `resources/tokens.json`，再同步生成物或镜像值。
3. 更新受影响的基础、组件、模式或领域文档。
4. 运行设计契约校验、Flutter 分析和相关测试。
5. 在 [`CHANGELOG.md`](./CHANGELOG.md) 记录破坏性或视觉可感知变化。

本地校验：

```powershell
python scripts/ci/test_validate_design_system.py
python scripts/ci/validate_design_system.py
flutter test test/visual_compare_test.dart
```

页面级浏览器核验的锁定依赖、Chromium 安装与执行命令见 [`../../scripts/design/README.md`](../../scripts/design/README.md)；CI 使用同一命令并保存四档视口截图。
