# 清源全量视觉参考 v33 与 Windows 验收记录

日期：2026-08-17  
分支：`feature/design-language-spec`  
状态：Windows 冻结通过；取代 v32；其他四平台等待真实 CI runner

## 本版设计变化

v33 在 v32 的组件工作台 v09 基础上纳入校园资讯空错状态 v03。资讯 `initial/loading/empty/error` 不再使用固定 352px 大空卡：360 改为约 240px 紧凑纵向卡，768 及以上改为约 192px 的“图标—说明—行动”横向任务条。状态文案、恢复路径、业务 fixture 和外部区域定义均未改变。

## 设计与实现验收

- 资讯 v03 浏览器参考：48/48 通过。
- 资讯 v03 Windows Flutter：48/48 通过，最低 SSIM 0.953443276。
- 资讯布局行为测试：8/8 通过；新增 360/1200 状态密度与行动位置回归。
- 全量参考：`build/design-review-v33`，1376 张 PNG、104 个外部区域 sidecar，索引 1376 项。
- 全量 Windows 候选：`build/visual/windows-full-v33`，1376 张 PNG、104 个 sidecar。

## Windows 全量逐图结果

```powershell
dart run tool/visual_compare.dart `
  --baseline build/design-review-v33 `
  --actual build/visual/windows-full-v33 `
  --output build/visual-results/windows-full-v33 `
  --manifest docs/design/resources/visual-manifest.json `
  --platform windows
```

结果：1376/1376 张逐图通过。最低应用区仍为 `settings.licenses--external-cancelled--light--1200x900.png`，SSIM 0.900283576；最低外部区仍为 `external.webview--operation-locked--dark--360x800.png` 的 `document` 区域，SSIM 0.933079587。阈值保持 0.90，未扩大外部区域。

## 工程门禁

- `flutter analyze`：无问题。
- `flutter test --timeout 300s`：680 项通过。
- 清源设计系统契约：此前同工作树版本已通过。
- `flutter build windows --release`：通过，产物为 `build/windows/x64/runner/Release/sspu_allinone.exe`。

Android、iOS、macOS、Linux 仍必须由对应真实 runner 完成构建、集成冒烟和 1376 张视觉矩阵；Windows 结果不能替代其他平台。
