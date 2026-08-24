# 任务状态收束评审 v01

<!--
  清源任务状态收束的设计自评审与实现前冻结记录
  @Project : SSPU-AllinOne
  @File : 2026-08-19-task-state-density-v01.md
  @Author : Qintsg
  @Date : 2026-08-19
-->

日期：2026-08-19  
分支：`feature/design-language-spec`  
验收：跳过 SSIM；按截图完整性、人工逐屏审查、操作协同与异常恢复核验。

## 审查证据

- 原型当前态：资讯流和设置首页已在 360×800、768×900、1200×900、1600×1000 逐屏查看；来源筛选、底栏/导航轨、卡片宽度与滚动行为符合密度约束，本批不修改。
- Windows Flutter 候选：`links.directory--empty--light--1200x900.png` 与 `links.directory--error--light--1600x1000.png` 显示 344dp 固定高度的空/错误卡，卡内实际信息不足三行。
- Windows Flutter 候选：`academic.grade-detail--empty--light--1200x900.png` 显示固定高度状态卡；图标、说明和“重新读取”被置于大面积空白中。
- Windows Flutter 候选：`mail.message-detail--content--light--1600x1000.png` 的正文卡由实际正文和只读说明决定高度，不存在同类固定状态问题，因此排除在本批之外。

证据截图位于：

- `build/product-design-audit-2026-08-19/05-info-content-360x800.png` 至 `12-settings-general-1600x1000.png`。
- `build/visual/windows/links.directory--empty--light--1200x900.png`。
- `build/visual/windows/links.directory--error--light--1600x1000.png`。
- `build/visual/windows/academic.grade-detail--empty--light--1200x900.png`。

## 评审结论

- 采用 [`task-state-density-v01.md`](../patterns/task-state-density-v01.md) 的“左锚定任务账本”方案。
- 所有状态仍保留卡片边界、图标/活动环、来源、恢复文案和唯一动作；没有删除恢复路径，也没有以视觉理由新增伪操作。
- 宽屏卡片改为表单内容宽，紧凑端保持全宽；高度改为内容驱动。该变化改善首屏密度，同时不影响资料筛选、路由返回、单飞和 service 契约。
- 按本评审冻结后，Flutter 实现不得变更状态文案、业务状态含义和数据访问行为。

## 实施后核验要求

1. `test/quick_links_page_test.dart` 与教务详情相关测试通过。
2. 重新采集 `links.directory`、`academic.grade-detail`、`academic.exam-detail`、`academic.grade-process` 的四档、亮暗候选图。
3. 逐图确认状态卡不再有为填满窗口产生的边框空白，且按钮/焦点/滚动仍可用。
4. 通过 `flutter analyze`、设计系统静态门禁和 `git diff --check`。

## 实施后核验

| 项目 | 结果 |
| --- | --- |
| 快捷入口与教务详情回归 | `flutter test test/quick_links_page_test.dart test/academic_page_test.dart`，66 项通过 |
| Flutter 分析 | `flutter analyze` 无问题 |
| 静态门禁 | 设计系统、拆分样式表与 `git diff --check` 通过 |
| Flutter 候选 | `build/visual/state-density-v01`，176 张：快捷入口 32、课程成绩/过程化成绩 96、考试安排 48 |
| 人工抽检 | 快捷入口 empty/error 的 360 与 1200；课程成绩 empty 的 360 与 1200；考试 error 的 1600 暗色均确认卡片按内容收束，宽屏左锚定且移动端不裁切 |

视觉采集首次暴露减少动态路径的 Flutter 布局断言：零时长的 `AnimatedSize` 在异步状态替换时会在自身布局阶段重新标记布局。实现改为减少动态时直接替换、正常环境才运行 `motion.base`，随后 176 张候选全部通过；该处理符合本稿的减少动态约束，不改变状态、动作或数据契约。
