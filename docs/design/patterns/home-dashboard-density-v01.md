# 首页密度与视口填充 v01

<!--
  清源首页消除底部空白与卡片集中空白的密度参考稿
  @Project : SSPU-AllinOne
  @File : home-dashboard-density-v01.md
  @Author : Qintsg
  @Date : 2026-08-21
-->

## 目标

对象是进入首页的学生。当前实现在 768×900、1200×900、1600×1000 三档桌面视口下，行动坞以下约 25%–40% 的视口是完全空白；时间轨卡片内部底部约 30% 是集中空白；右侧概览列在高度被强制拉伸后卡间间距过大。360×800 紧凑端内容刚好占满，无需滚动，本稿保持该性质不变。

本稿只调整首页首屏的垂直节奏与高度编排，不改变任何业务服务、状态文案、导航契约、概览卡内容、行动坞内容、刷新单飞或失败恢复。

## 现状证据

- `home_dashboard_view.dart`：非滚动分支用 `MediaQuery.height * homeContentHeightViewportPercent(42%)` 并 clamp 到 `homeContentMinHeight(372)`–`homeContentMaxHeight(420)` 作为主区高度，主区+行动坞之后不再占用剩余视口，导致页面底部大片空白（1600×1000 最严重）。
- `home_dashboard_primary_layout.dart`：时间轨内部 Column 顶部对齐，两段固定 `SizedBox` 间隔，卡片被外层强制高度拉伸后空白集中在卡片底部。
- `home_dashboard_content.dart`：概览列 `separatedColumn` 用 `Expanded` 拉伸每张卡，高度增大后卡内留白与卡间分隔同时变大。

## 视觉方向

- 沿用现有 token（`spacing`、`radius`、`layout.divider`、`motion`），不新增 token、不引入新组件、不改配色与字体。
- **视口填充**：非滚动分支主区高度改为“剩余视口弹性填充”——页头、主区、行动坞组成 `Column(mainAxisSize.max)`，主区 `Expanded`，行动坞保持自然高度并贴底于内容列；页面底部 padding 保持 `spacing.s/xl`。空白不再堆积在页面底部。
- **时间轨弹性节奏**：时间轨内部把 hero 与条目列表之间的两段固定间隔改为 `Expanded` 弹性间隔（保留最小高度 `spacing.s`/`spacing.m`），条目列表之后追加一段弹性尾距（最小 `spacing.m`）。卡片被拉伸时空白均匀分布为节奏留白，而不是集中在底部。
- **概览列紧凑卡+均布间隔**：`separatedColumn` 改为“卡自然高度 + 弹性均布间隔”：每张概览卡用 `ConstrainedBox(minHeight: control.regular + spacing.xs)` 保持紧凑，卡间用 `Spacer` 均布剩余高度（间隔上限 `spacing.xl2`，超出后卡列整体顶部对齐、底部留一段 `spacing.m` 说明性尾距）。卡不再被拉伸出大内白。
- **紧凑端不变**：360×800 仍走 `_homeCompactPrimaryHeight` 固定高度路径与 2 列网格，不滚动性质保持；仅当 `allowScrolling == false` 且非 compact 时启用上述弹性编排。
- **动画**：概览列收束动画（`AnimatedSize`）保持；弹性间隔随视口变化自然过渡，不新增动画时长。

```text
1200×900 / 1600×1000（改后）
┌ 页头（问候+状态行）            ┐
│ ┌ 时间轨（弹性节奏）┐ ┌ 概览列 ┐│
│ │ meta            │ │ 卡1    ││
│ │ hero            │ │  ┈均布┈ ││
│ │  ┈弹性┈         │ │ 卡2    ││
│ │ 条目1           │ │  ┈均布┈ ││
│ │ 条目2           │ │ 卡3    ││
│ │ 条目3           │ │  ┈均布┈ ││
│ │  ┈弹性尾距┈     │ │ 卡4    ││
│ └─────────────────┘ └────────┘│
│ ┌ 行动坞（自然高度）          ┐│
│ └────────────────────────────┘│
└ 剩余视口被主区吸收，无底部空白  ┘
```

## 自评审

1. **保持 percent 高度并把行动坞下移贴底**：否决。空白只是从页面底部移到行动坞上方，仍是一片集中空白。
2. **主区 Expanded 填充 + 内部固定间隔不变**：否决。时间轨与概览列的集中空白会随视口增高而更大。
3. **主区 Expanded + 时间轨弹性节奏 + 概览列紧凑卡均布间隔**：采用。空白被拆成均匀节奏留白，卡片保持紧凑，页面底部不再堆积空白；紧凑端路径完全不变，风险最低。

## 实现边界

- `home_dashboard_view.dart`：非滚动、非 compact 分支的主区 `SizedBox(height: percent.clamp(...))` 改为 `Expanded`；`Column` 保持 `mainAxisSize.max`。
- `home_dashboard_primary_layout.dart`：`_buildTimelinePanel` 内两段固定 `SizedBox` 间隔改为带最小高度的 `Expanded`（`LayoutBuilder`+`ConstrainedBox` 或 `Flexible(fit: FlexFit.tight)` 包 `ConstrainedBox`），条目列表后追加弹性尾距。
- `home_dashboard_content.dart`：`separatedColumn` 的 `Expanded(child: item)` 改为 `ConstrainedBox(minHeight)` 自然高度 + 卡间 `Spacer` 均布（间隔上限 `spacing.xl2`）。
- 不改动 `_homeCompactPrimaryHeight`、compact 网格、行动坞、状态行、页头、任何 service/model/测试夹具语义。

实施后需验证：四档视口亮暗 `home.dashboard` content 截图无底部集中空白、360×800 仍无滚动、`flutter analyze`、全量 `flutter test`、设计门禁与视觉产物校验通过。