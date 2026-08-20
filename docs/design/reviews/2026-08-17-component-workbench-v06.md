# 清源组件工作台参考稿 v06 评审记录

日期：2026-08-17  
分支：`feature/design-language-spec`  
状态：冻结，取代 v05 作为组件工作台验收基线

## 修订范围

v06 只做机械契约对齐：输入标签间距采用 6dp、学期选择使用右向进入提示、图标按钮使用 10dp 圆角；嵌套卡片和指标卡使用 1dp 分隔边界。空状态图标改为轮廓表达。信息架构、列数、卡片数量和操作均未改变。

## 自评审与核验

```powershell
uv run --with playwright python scripts/design/verify_design_prototype.py `
  --output build/design-review-components-workbench-v06 `
  --surface-prefix components.
```

结果：48/48 张参考截图通过真实 Chromium 门禁。360、768、1200、1600 的亮暗主题均无横向溢出，输入卡和反馈卡按内容收口，所有按钮仍保持 48dp 命中区，最后一张卡可滚动到达。

冻结截图目录：`build/design-review-components-workbench-v06`。Flutter 逐图验收阈值保持 SSIM ≥ 0.90。
