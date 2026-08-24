# 清源组件工作台参考稿 v09 评审记录

日期：2026-08-17  
分支：`feature/design-language-spec`  
状态：冻结，取代 v08 作为组件工作台验收基线

## 修订范围

v09 只将组件组标题的编号列从固定 24px 改为按编号内容自适应；编号与标题之间仍保持 8px 间距。控件尺寸、卡片尺寸、页面列数和业务状态均未改变。

## 自评审

两位编号实际只需要自身字宽。固定 24px 轨道在窄屏中形成约 10px 的无意义空隙，使标题与说明看起来像与编号脱节，也浪费了中文说明的可用行宽。内容自适应后，编号仍是明确的扫描锚点，标题与说明更紧密地组成一个语义组；360px 下三组标题均获得相同节奏，768px 及以上的列布局不受影响。

该调整回应“卡片内部避免大片空白、优化排版”的要求，没有删除信息、缩小触控目标或改变操作顺序。

## 浏览器核验

```powershell
uv run --with playwright python scripts/design/verify_design_prototype.py `
  --output build/design-review-components-workbench-v09 `
  --surface-prefix components.
```

结果：48/48 张真实 Chromium 参考截图通过。人工复核操作页 360×800 亮暗主题：编号、标题和说明形成紧凑稳定的层级，无重叠、换行或横向溢出；按钮和其他控件保持 v08 冻结尺寸。

冻结截图目录：`build/design-review-components-workbench-v09`。Flutter 逐图验收阈值保持 SSIM ≥ 0.90。
