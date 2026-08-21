<!--
  清源外观选择密度设计自评审与冻结记录
  @Project : SSPU-AllinOne
  @File : 2026-08-19-appearance-choice-density-v01.md
  @Author : Qintsg
  @Date : 2026-08-19
-->

# 外观选择密度评审 v01

日期：2026-08-19  
分支：`feature/design-language-spec`  
验收：跳过 SSIM；按多尺寸截图完整性、人工逐屏检查和交互协同核验。

## 审查证据

- 当前 Flutter 目标候选 `build/visual/appearance-density-audit-v01` 已生成四档、亮暗共 8 张。
- 360×800、768×900、1200×900 与 1600×1000 均显示相同问题：主题分段只使用卡片左上区域，外层卡片仍延伸到可视区底部。
- 当前候选的标题、来源条、主要动作和三项选择均清晰可见，故不调整页面层级、用词或主题行为；只删除冗余表面与最小高度。

## 决议

采用 [`appearance-choice-density-v01.md`](../patterns/appearance-choice-density-v01.md)：`YhSegmented` 成为唯一可见选择边界；正文切换为内容高度、左锚定固有宽度，外层 `YhCard` 与水平滚动容器移除。

该改动保留三项主题、回调、方向键、语义、来源抽屉、主要行动和设置摘要入口，不新增业务功能。

## 实施后核验要求

1. 增加宽屏尺寸回归，证明选择线与其正文不会填满视口。
2. 保留现有主题点击、选中语义和“应用主题”测试，并补充左右箭头切换。
3. 重新采集 360/768/1200/1600、亮暗候选，确认没有横向滚动、裁切或重复边框。
4. 通过 `flutter analyze`、设计系统/样式表门禁和 `git diff --check`。

## 冻结

本批布局与交互基线已冻结。Flutter 实现只能移除冗余约束并增加回归证据，不得更改主题设置和保存行为。

## 实施后核验

| 项目 | 结果 |
| --- | --- |
| 外观页行为回归 | `flutter test test/settings_appearance_page_test.dart`，5 项通过；覆盖主题点击、选中语义、明确键盘焦点后的左右切换、主要行动与来源抽屉。 |
| Flutter 视觉候选 | `build/visual/appearance-density-v01`，四档视口、亮暗共 8 张 PNG，文件名和物理尺寸均通过检查。 |
| 人工抽检 | 360 亮、768 暗、1200 亮、1600 暗均查看：选择线完整可见，窄屏无横向裁切，宽屏右侧留白为背景而非冗余卡片。 |
| 静态门禁 | `flutter analyze`、清源设计系统/样式表契约与 `git diff --check` 均通过。 |

本批只证明本机 Windows 目标候选；其余四个平台仍需真实 runner 验证。
