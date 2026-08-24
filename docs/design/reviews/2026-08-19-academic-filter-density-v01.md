# 教务详情筛选账本密度评审 v01

<!--
  清源教务详情筛选账本密度的设计自评审与实现前冻结记录
  @Project : SSPU-AllinOne
  @File : 2026-08-19-academic-filter-density-v01.md
  @Author : Qintsg
  @Date : 2026-08-19
-->

日期：2026-08-19  
分支：`feature/design-language-spec`  
验收：跳过 SSIM；按截图完整性、人工逐屏审查、操作协同与异常恢复核验。

## 审查证据

- `build/visual/state-density-v01/academic.grade-process--content--light--1200x900.png`：一个学年学期选择器被包在整行卡片中，右侧为无信息空白。
- `build/visual/state-density-v01/academic.grade-detail--empty--light--1200x900.png`：学期选择与过程化成绩入口仅占筛选卡左侧，状态卡已收束后该空白更加明显。
- `build/visual/state-density-v01/academic.exam-detail--error--dark--1600x1000.png`：三项筛选本身构成真实依赖组，应保留同组边界，但不应延伸到整页。
- 当前课程表的四档原型审查未发现同类可操作卡片空白，本批不扩展到课表。

## 评审结论

- 采用 [`academic-filter-density-v01.md`](../patterns/academic-filter-density-v01.md) 的按字段数量收束方案。
- 不删除筛选、刷新、过程化成绩入口或任何错误恢复动作；变化只调整外层容器宽度及单字段宽屏边框。
- 三项考试筛选必须保持年、学期、考试类型的可见顺序；课程成绩的次级入口紧贴学期选择；过程化成绩单字段宽屏去框。
- 本评审冻结后，Flutter 实现不得改动请求参数、默认选择、业务数据或路由契约。

## 实施后核验要求

1. 教务详情相关回归和 `flutter analyze` 通过。
2. 采集三类详情的四档亮暗候选图，确认筛选容器不会横向拉满或截断控件。
3. 逐图检查 loading/empty/error/operation-locked 仍保留筛选、焦点和恢复路径。

## 实施后核验

| 项目 | 结果 |
| --- | --- |
| 教务详情回归 | `flutter test test/academic_page_test.dart`，56 项通过 |
| 视觉候选 | `build/visual/academic-filter-density-v01`，144 张：课程成绩/过程化成绩 96、考试安排 48 |
| 人工抽检 | 课程成绩 empty 1200、过程化成绩 content 1200、考试 error 1600 暗色与考试 empty 360 均确认筛选区按真实字段收束，单字段去框、窄屏完整保留分组 |

候选图中三种详情的 loading、empty、error、stale 与 operation-locked 均可采集。筛选项的可用性、默认值、重试、单飞锁和返回路径保持原状。
