# 清源全量视觉参考 v32 与 Windows 验收记录

日期：2026-08-17  
分支：`feature/design-language-spec`  
状态：Windows 冻结通过；其他四平台等待真实 CI runner

## 设计汇总

v32 汇总此前已冻结的应用壳、首页、教务、课表、资讯、邮箱、快捷入口、设置、外部流程与组件工作台设计。其中组件工作台采用 v09：即时反馈收紧无效内边距，普通按钮使用 16px 水平内边距，组件组编号列按内容自适应。未修改业务 fixture、页面状态数量或外部区域定义。

## 全量参考核验

```powershell
uv run --with playwright python scripts/design/verify_design_prototype.py `
  --output build/design-review-v32
```

结果：真实 Chromium 生成并验证 1376 张 PNG 与 104 个外部区域 sidecar。`reference-index.json` 记录 `qingyuan-0.4.0`、`qingyuan-sanitized-v1`、固定时钟和全部文件 SHA-256。组件 v09 抽样截图与 v32 中同名文件的 SHA-256 完全一致。

人工抽查覆盖首页 360×800、设置 768×900、资讯错误态 1200×900、组件操作页 360×800，以及亮暗主题。未发现横向溢出、文字截断或触控目标缩小。资讯宽屏空错态的纵向密度仍可作为下一轮“先稿后码”优化候选，不在本次通过结果中隐去。

## Windows 逐图验收

```powershell
flutter test test/visual/qingyuan_visual_capture_test.dart `
  --dart-define=QINGYUAN_VISUAL_CAPTURE=true `
  --dart-define=QINGYUAN_VISUAL_PLATFORM=windows-full-v32 `
  --timeout 300s

dart run tool/visual_compare.dart `
  --baseline build/design-review-v32 `
  --actual build/visual/windows-full-v32 `
  --output build/visual-results/windows-full-v32 `
  --manifest docs/design/resources/visual-manifest.json `
  --platform windows
```

结果：1376/1376 张逐图通过，最低应用区为 `settings.licenses--external-cancelled--light--1200x900.png`，SSIM 0.900283576；最低外部区为 `external.webview--operation-locked--dark--360x800.png` 的 `document` 区域，SSIM 0.933079587。阈值始终为 0.90，未扩大外部区域。

## 工程门禁

- 清源设计系统静态契约：通过。
- `flutter analyze`：无问题。
- `flutter test --timeout 300s`：679 项通过。
- `flutter build windows --release`：通过，产物为 `build/windows/x64/runner/Release/sspu_allinone.exe`。

Android、iOS、macOS、Linux 必须由对应真实 runner 重复构建、集成冒烟与 1376 张视觉矩阵；Windows 结果不能替代其他平台。
