# 校园资讯空错状态密度 v03

日期：2026-08-17  
分支：`feature/design-language-spec`  
状态：冻结，取代 v02 中资讯 `initial/loading/empty/error` 的状态卡布局

## 设计计划

- 色彩：继续使用清源纸面白、夜间墨色、品牌青、品牌浅底和结构边界，不增加状态专属装饰色。
- 字体：继续使用 MiSans；状态标题使用 h3，原因与恢复说明使用 small，行动保持正文权重。
- 布局：360 使用约 240px 的紧凑纵向状态卡；768 及以上使用约 192px 的“图标—说明—行动”横向任务条。
- 标志性表达：状态必须同时回答“发生了什么、已有内容是否保留、下一步是什么”，行动与原因处于同一视线。
- 动效：不增加环境动画；加载环和既有减少动态契约保持不变。

## 自评审

v02 将四类状态都固定为 352px 高卡片，实际内容只占约 150–190px，宽屏出现明显的大块空白，行动也与原因说明距离过远。v03 在不删除信息的前提下压缩容器：

- 360 保持纵向阅读顺序，卡片最小高度 240px，适合单手扫读且无需页面滚动。
- 768、1200、1600 将图标置于左侧、标题与说明置于中部、恢复行动置于右侧；长文案仍保留充分宽度。
- `loading` 继续用活动环和两行说明，不出现会闪烁的整页骨架。
- `empty` 的“来源与认证设置”和 `error` 的“重试”仍分别指向正确恢复路径，所有操作保持 48dp 命中区。

本次没有把状态改成通用通知横幅：有明确恢复任务的状态仍使用边界清晰的任务条；页面辨识度继续来自校园资讯的来源、缓存与认证语义。

## 浏览器核验

```powershell
uv run --with playwright python scripts/design/verify_design_prototype.py `
  --output build/design-review-info-feed-density-v03 `
  --surface-prefix info.feed
```

结果：48/48 张真实 Chromium 参考截图通过。人工复核 `initial/loading/empty/error` 在 360×800、768×900、1200×900、1600×1000 的代表亮暗图：无横向溢出、无截断、无新增滚动，状态条显著减少无任务空白。

冻结截图目录：`build/design-review-info-feed-density-v03`。Flutter 逐图验收阈值保持 SSIM ≥ 0.90。

## Flutter 验收

- Windows 候选：`build/visual/windows-info-feed-density-v03`，48 张。
- 对比报告：`build/visual-results/windows-info-feed-density-v03/report.json`。
- 结果：48/48 逐图通过，最低 SSIM 0.953443276。
- 行为：新增 360/1200 状态布局回归；资讯布局测试 8/8 通过，搜索、来源筛选、认证设置、重试和分页契约保持不变。
