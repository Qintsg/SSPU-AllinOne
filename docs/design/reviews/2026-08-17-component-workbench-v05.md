# 清源组件工作台参考稿 v05 评审记录

日期：2026-08-17  
分支：`feature/design-language-spec`  
状态：冻结，取代 v04 作为组件工作台验收基线

## 修订范围

v05 是不改变信息架构的密度修订，只处理 v04 自评审中发现的三个细节：

- 纵向字段不再继承横向 `flex-basis`，学期、日期、OTP 和错误输入按真实内容高度收口；768px 双列不再出现高空白输入框。
- Chip 保留完整 48dp 命中区，但可见胶囊收为 32dp，兼顾触控与视觉密度。
- 环形进度按真实 82% 连续绘制，不再用四段边框近似；紧凑空状态同步 32dp 图标和 16dp 内边距。

这些改动直接回应“大卡片、大空白、大按钮框”的问题，没有删除辅助文本，也没有缩小可操作区域。

## 浏览器核验

```powershell
uv run --with playwright python scripts/design/verify_design_prototype.py `
  --output build/design-review-components-workbench-v05 `
  --surface-prefix components.
```

结果：48/48 张参考截图通过真实 Chromium 门禁。

复审确认：

- 360px 单列、768px 双列、1200px/1600px 三列均无横向溢出。
- 纵向输入卡按内容收口，最后一张卡可滚动到达。
- Chip 视觉胶囊缩小后，按钮边界仍保持至少 48×48dp。
- 环形进度、暗色对比、键盘焦点、方向键协同和减少动态全部通过。
- 页面未新增无效卡片、装饰按钮或大面积占位空白。

冻结截图目录：`build/design-review-components-workbench-v05`。Flutter 组件工作台以此目录逐图执行 SSIM ≥ 0.90 验收。
