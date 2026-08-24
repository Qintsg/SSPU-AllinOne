# 教务详情恢复账本评审 v01

<!--
  教务详情恢复账本的实现前自评审记录
  @Project : SSPU-AllinOne
  @File : 2026-08-19-academic-detail-recovery-ledger-v01.md
  @Author : Qintsg
  @Date : 2026-08-19
-->

日期：2026-08-19  
分支：`feature/design-language-spec`  
状态：已实现并完成 Windows 候选复核；以候选截图、交互协同和人工审查验收，跳过 SSIM。

## 证据与结论

- Windows 360×800 `academic.exam-detail/error/light` 候选中，状态内容约为 72dp 符号、两行标题与说明、48dp 按钮，却被居中堆叠为约 323dp 高的卡片；大量边框内区域没有传达状态或帮助恢复。
- 1200×900 content 候选已证明筛选账本、指标和时间轴能按内容收束；恢复状态应遵循同一密度原则，不能回退成居中海报。
- 采用 [`academic-detail-recovery-ledger-v01.md`](../patterns/academic-detail-recovery-ledger-v01.md)：左锚定图标与事实，宽屏将唯一操作并入同一阅读行，窄屏只让操作自然落行。

## 操作与异常路径检查

- 加载期间没有可误触的重试；返回、页面标题与筛选路径保持可达。
- 空状态的“重新读取”和错误状态的“检查后重试”继续调用原回调；不增加联网、二次确认或新的设置项。
- `RetainedRefreshController` 的单飞、旧内容保留、凭据换代隔离和 operation-locked 禁用均不改动。
- Tab / Shift+Tab 顺序遵循页面内容、状态说明、唯一动作；按钮保持最小 48dp 触控目标与可见焦点。
- `disableAnimations` 时不进入尺寸过渡；暗色保持现有对比度与服务色语义。

## 实施后核验要求

1. 为考试详情的 360px error、360px empty 和 1200px error 添加紧凑高度及动作可用性回归。
2. 运行教务回归、静态分析、48 张考试详情候选采集与 Windows Debug 构建。
3. 人工抽检四档视口、亮暗、loading/empty/error/stale/operation-locked，确认没有横向溢出、无意义大空卡或动作遮挡。

## 实施后核验

- 共享状态卡移除旧的最小高度约束与居中海报编排；360px 使用 `spacing.s` 内边距，加载状态改为活动环—说明的同行账本，空/错误状态改为符号—事实—唯一动作的连续阅读顺序。768px 起动作与事实同行；所有距离、半径和尺寸继续由清源 token 推导。
- 新增“考试详情窄屏错误状态紧凑呈现恢复账本且可重试”回归，固定 360×800、1× DPR；状态卡高度小于 240dp，动作不小于 48dp，并实际调用原有重试回调。
- Windows 重新采集考试详情 6 态 × 四档 × 亮暗共 48 张候选。人工抽检 360px loading、empty、error，768px 暗色 error，1200px 亮色 error 和 1600px 暗色 operation-locked：恢复卡均按内容结束，说明未裁切，操作没有遮挡；陈旧和锁定状态继续保留有效记录与横幅。
