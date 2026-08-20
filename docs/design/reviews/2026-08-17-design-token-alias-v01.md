# 清源设计 token 别名修订 v01

日期：2026-08-17  
分支：`feature/design-language-spec`  
状态：设计意图复核并冻结；纳入下一版全量参考

## 设计计划

- 色彩：继续使用 `brand`、`brandInk`、`surface` 与既有明暗主题，不增加局部颜色或页面裸值。
- 字体与间距：保持 MiSans、现有字阶和密度，本次不改变内容层级、卡片尺寸或响应式断点。
- 交互：教务排序选中态使用一阶阴影，键盘焦点使用品牌色、统一焦点环宽度和间距；第二课堂规则明细使用基础时长与标准曲线。
- 标志性表达：状态变化继续由“结构边界 + 品牌焦点 + 短促位移”表达，不增加装饰性动画。

## 自评审

拆分样式校验发现参考 CSS 仍引用 `--shadow-e1`、`--focus-ring`、`--focus`、`--focus-offset` 和 `--curve-standard`，这些别名已不在 `tokens.json` 生成的语义变量中。浏览器会静默丢弃对应声明，导致参考稿缺少排序层级、键盘焦点或规则明细动效，且旧校验器没有遍历 HTML `link` 与 CSS `@import` 加载链。

本次修订只把旧别名映射回已有机器真源：

- `--shadow-e1` → `--shadow-1`
- `--focus-ring` → `--focus-ring-width`
- `--focus` → `--brand`
- `--focus-offset` → `--focus-ring-gap`
- `--curve-standard` → `--curve`

复核结论：这些声明恢复了设计总纲原有的层级、焦点和减少动态契约，没有增删按钮、卡片、设置项或业务行为，也没有引入与清源主题无关的通用装饰。四档视口和亮暗主题均沿用同一语义 token，因此冻结为 v01。

## 参考与 Flutter 验收

- 教务总览参考：`build/design-review-academic-token-alias-v01`；Windows 定向结果 80/80 逐图通过，最低应用区 SSIM 0.903527260。
- 第二课堂规则参考：`build/design-review-student-report-rules-token-alias-v01`；Windows 定向结果 16/16 逐图通过，最低应用区 SSIM 0.901557113。
- 阈值保持每张 SSIM ≥ 0.90；未扩大外部区域，未用 Flutter 实际图覆盖设计参考。

## 新增静态门禁

`validate_design_stylesheets.py` 从每个参考 HTML 出发遍历 `link` 与 `@import`，拒绝不可达拆分 CSS 和未定义的 `var(--token)`。只有运行时注入的 `--academic-accent`、`--component-progress`、`--domain`、`--rule-progress` 作为显式白名单保留；校验器单元测试覆盖有效链、缺失引用和未定义 token。
