# 清源组件工作台参考稿 v08 评审记录

日期：2026-08-17  
分支：`feature/design-language-spec`  
状态：冻结，取代 v07 作为组件工作台验收基线

## 修订范围

v08 只调整普通按钮的水平内边距：从 24px 收紧到 16px，最小宽度仍为 96px、高度仍为 48px。FAB、图标按钮、卡片、标题网格和所有业务状态均未改变。

## 自评审

操作组件在 360px 下的主要与次要按钮原宽约 110px，标签本身只有四个汉字，额外宽度没有承载更多信息，还迫使图标行动和新建行动产生不必要的横向错位。16px 水平内边距与清源 Flutter 按钮契约一致，并让两枚主要行动各自稳定在约 96px；信息层级、可读性和 48dp 命中区均保持不变。调整后按钮不再显得膨胀，危险与禁用状态也仍靠语义、颜色和透明度表达，而非靠尺寸表达。

此修改没有套用新的视觉风格，也没有为提高相似度改变品牌色、字体或内容；它直接回应移动端“避免过大按钮框”的设计要求。

## 浏览器核验

```powershell
uv run --with playwright python scripts/design/verify_design_prototype.py `
  --output build/design-review-components-workbench-v08 `
  --surface-prefix components.
```

结果：48/48 张真实 Chromium 参考截图通过。人工复核操作页 360×800 亮暗主题：主要、次要、禁用和图标行动保持清晰分组，换行顺序不变，无横向溢出；所有可交互控件仍满足 48dp 命中区。

冻结截图目录：`build/design-review-components-workbench-v08`。Flutter 逐图验收阈值保持 SSIM ≥ 0.90。
