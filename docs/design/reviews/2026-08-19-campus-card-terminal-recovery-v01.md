# 校园卡终端错误恢复条评审 v01

日期：2026-08-19  
分支：`feature/design-language-spec`  
状态：已实现并完成 Windows/Linux 本机核验

## 评审范围

评审 [校园卡终端错误恢复条 v01](../patterns/campus-card-terminal-recovery-v01.md)。范围限定为没有可恢复记录的校园卡详情错误，筛选空结果与保留旧记录的部分失败不在本批范围。

## 评审结论

- [x] 360 标题与图标同行，避免“记录”孤立换行；说明、重试和返回仍在单个连续任务面中。
- [x] 768 起将双行动与失败说明收束在内容高横向恢复条内，宽屏左锚定而非居中漂浮。
- [x] 重试和返回的业务语义、可用性、焦点顺序与 48dp 目标不变；凭据失效仍只允许返回首页。
- [x] 终端错误不展示不可信余额、日期或交易记录，也不会与本地筛选“清除筛选”混淆。
- [x] 方案只复用清源已有 card/button/token，未增加服务、设置项、图标包或视觉主题分支。

## 实施约束

1. 只替换 `CampusCardDetailPage` 终端 `error` 的展示布局；不得波及 stale、partial-error、operation-locked、validation-error 或普通 empty。
2. 当双行动横向不足时必须自然换行，不能缩小触控目标或让返回动作消失。
3. 实现后需要重新采集 Windows/Linux 该 surface 的 56 张候选，并运行终端错误、凭据失效和路由返回回归。

## 实现与核验

- `home_campus_card_detail_layout.dart` 已以 `_CampusCardTerminalErrorRecoveryPanel` 替换居中 `YhEmptyState`。360px 将警告图标与标题同行，说明与两个恢复行动在下方连续排列；768px 起使用左锚定的图标—说明—行动恢复条。
- 原始失败原因、只读查询/同步重试动词、凭据失效时的重试禁用、返回首页、无有效余额/交易记录，以及既有单飞和路由契约均未改动。
- 校园卡详情布局回归现明确固定 1× DPR 与物理视口，避免 Flutter test 默认 2400×1800 view 误测为 360×800；新增终端错误标题单行、内容高度、左缘对齐和双行动 48dp 断言。校园卡详情与首页定向回归 57 项、`flutter analyze --no-fatal-infos` 均通过。
- Windows 与 Linux 均重新生成校园卡详情 56 张候选，并人工复核 error 的四档亮暗代表图；两端各自的全量候选目录均通过 `1544` 张 PNG 与 `144` 份 sidecar 完整性校验。Linux 还在真实 runner 完成 Debug 构建与原生 smoke 5/5。
