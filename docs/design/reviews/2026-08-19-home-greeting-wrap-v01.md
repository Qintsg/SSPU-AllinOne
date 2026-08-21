# 首页问候语短语换行评审 v01

<!--
  首页问候语短语换行的设计自评审与实现前冻结记录
  @Project : SSPU-AllinOne
  @File : 2026-08-19-home-greeting-wrap-v01.md
  @Author : Qintsg
  @Date : 2026-08-19
-->

日期：2026-08-19  
分支：`feature/design-language-spec`  
范围：`home.dashboard` 的四档视口、亮暗主题与八个状态  
结论：**通过，冻结后进入 Flutter 实现**

## 审查证据

- 最新 Windows 候选 `home.dashboard--content--light--360x800.png` 中，问候“早上好，先看清今天。”在刷新按钮旁被渲染为“早上好，先看清今 / 天。”。
- 同一候选没有横向溢出或首页滚动，问题仅是中文孤字削弱了首屏阅读质量；1200/1600 的单行标题和刷新操作无需改变。
- 当前标题与刷新在同一 Row，直接缩小标题或刷新会损害等级或触控目标，不能接受。

## 决定与边界

- 采用 [`home-greeting-wrap-v01.md`](../patterns/home-greeting-wrap-v01.md) 的短语级换行。
- 原型先用两个 `nowrap` 文字片段验证小视口断句，Flutter 随后使用相同的语义短语结构；完整可访问名称保持原文。
- 不调整日期、刷新、状态药丸、首页时间轨、概览、行动坞、数据请求或断点预算。
- 本评审冻结后，仅允许修正问候标题的展示结构、测试和原型；不得借机修改业务内容。

## 实现后核验要求

1. 360、390、768、1200、1600 的亮暗候选中确认短语换行与单行恢复均正确。
2. 覆盖标题语义、刷新 48dp 目标、首页无滚动和所有首页状态。
3. 通过首页定向测试、原型核验、`flutter analyze`、设计门禁与候选截图；按当前政策不计算 SSIM。

## 实现后核验

| 项目 | 结果 |
| --- | --- |
| 原型核验 | `verify_design_prototype.py --surface-prefix home.dashboard`：64 张首页原型候选通过；首页密度交互矩阵 6/6 通过。 |
| Flutter 行为回归 | `test/home_page_test.dart test/home_dashboard_density_test.dart`：57/57 通过，新增 360px 短语边界、完整语义和既有无滚动断言。 |
| Flutter 候选 | `build/visual/windows-home-greeting-wrap-v01`：64 张，覆盖首页八态、四档视口与亮暗主题。 |
| 人工逐屏审视 | 360×800 的 content/loading 与亮暗主题均显示完整的“早上好，/先看清今天。”；768、1200、1600 恢复为单行，刷新目标、时间轨、概览和行动坞不变。 |
| 全量验证 | 更新后的 Windows 完整矩阵 1544/1544 与 144 份 sidecar 通过产物校验；`flutter test --reporter compact` 为 711 项通过、1556 项视觉采集用例按预期跳过；`flutter analyze`、设计门禁和差异格式检查通过。 |

实现增加独立的展示短语组件，不影响问候原文、日期、刷新状态、数据、导航或首页动效；父 `Semantics` 保留单一完整标题供读屏器朗读。
