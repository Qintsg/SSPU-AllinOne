# 清源组件工作台参考稿 v07 评审记录

日期：2026-08-17  
分支：`feature/design-language-spec`  
状态：冻结，取代 v06 作为组件工作台验收基线

## 设计计划

- 色彩：保持清源既有品牌青、品牌浅底、结构深蓝、纸面白与夜间墨色，不新增装饰色。
- 字体：继续使用 MiSans；标题承担页面识别，正文负责说明，数字与状态使用紧凑数据节奏。
- 布局：360 为单列，768 为双列，1200 与 1600 为三列；页面边距分别保持 16、16、24、24dp。
- 标志性表达：校园信息始终以“事实、来源、时间、下一步”组织，反馈组件不伪装成内容卡片。
- 动效：本次不增加环境动画；交互仍继承清源的按压、焦点与减少动态契约。

## 自评审

v06 的即时反馈示例复用了内容容器的 16px 通用内边距，使 Banner 和 Toast 看起来像两张额外卡片，也造成反馈卡存在无意义的纵向空白。这与“短时反馈应快速扫读、行动靠近结果”的任务不符。

v07 将 Banner 改为接近 Flutter 契约的 14px 水平、12/13px 垂直内边距；Toast 改为 16px 水平、8px 垂直内边距，同时保留撤销按钮 48dp 命中区。调整后反馈层级更紧凑，按钮与消息仍在同一视线内，亮暗主题均保持足够对比。没有引入渐变、大色块或额外装饰，视觉识别继续来自清源的校园证据结构，而不是通用仪表盘样式。

为符合单文件规模约束，工作台布局规则已拆至 `_component-reference-layout.css`，控件规则继续保留在 `_component-reference.css`；加载顺序已在参考宿主页显式声明。

## 浏览器核验

```powershell
uv run --with playwright python scripts/design/verify_design_prototype.py `
  --output build/design-review-components-workbench-v07 `
  --surface-prefix components.
```

结果：48/48 张真实 Chromium 参考截图通过。人工复核了反馈页在 360×800 与 768×900 下的亮暗主题：无横向溢出、无截断，单/双列切换正确，Banner、Toast 和骨架屏之间均为 8dp 节奏，Toast 撤销操作仍满足 48dp 命中区。

冻结截图目录：`build/design-review-components-workbench-v07`。Flutter 逐图验收阈值保持 SSIM ≥ 0.90。
