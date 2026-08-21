# 首页密度与视口填充 v01 自评审

<!--
  首页密度参考稿的自评审记录
  @Project : SSPU-AllinOne
  @File : 2026-08-21-home-dashboard-density-v01.md
  @Author : Qintsg
  @Date : 2026-08-21
-->

## 评审对象

`docs/design/patterns/home-dashboard-density-v01.md`。

## 评审结论

采用。三档桌面视口的底部集中空白与卡片集中空白被拆为均匀节奏留白；紧凑端路径不变；不新增 token、组件或动画时长；不触碰业务契约。

## 评审要点

1. **视口填充是否破坏 360×800 无滚动**：否。弹性编排只在 `allowScrolling == false && !compact` 分支启用，紧凑端仍走 `_homeCompactPrimaryHeight` 固定高度。
2. **时间轨弹性间隔在条目极少时是否失衡**：可接受。弹性间隔带最小高度（`spacing.s`/`spacing.m`），条目为空时 hero 与说明文本之间仍保持最小节奏，不会出现单条巨大留白。
3. **概览列 Spacer 均布在卡数变化时是否跳变**：可接受。卡数变化触发既有 `AnimatedSize` 收束动画；均布间隔上限 `spacing.xl2`，超出后顶部对齐，避免极端拉伸。
4. **是否需要新增 token**：否。全部复用 `spacing`、`layout.divider`、`motion` 现有值。

## 实施后核验表

| 检查项 | 预期 | 实际 |
| --- | --- | --- |
| 768×900 / 1200×900 / 1600×1000 content 亮暗截图无底部集中空白 | 通过 | 通过：两列封顶垂直居中，剩余高度化为上下均等边距 |
| 360×800 无横向溢出且不滚动 | 通过 | 通过 |
| flutter analyze | 无问题 | 通过 |
| 全量 flutter test | 通过 | 通过：722 通过 + 1556 视觉跳过 |
| 设计门禁（design system / stylesheets / platform ci） | 通过 | 通过 |
| 视觉产物校验 | 通过 | 通过：1544 PNG + 144 sidecar |