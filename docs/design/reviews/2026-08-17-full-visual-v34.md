# 清源全量视觉参考 v34 与 Windows 验收记录

日期：2026-08-17  
分支：`feature/design-language-spec`  
状态：Windows 冻结通过；取代 v33；其他四平台等待真实 CI runner

## 本版设计与门禁变化

v34 在 v33 的页面、状态、四档视口和亮暗主题布局基础上，纳入已评审的设计 token 别名修订。教务排序的选中阴影与键盘焦点、第二课堂规则明细动效重新由 `tokens.json` 的现行语义变量驱动；没有增删页面按钮、卡片、设置项或业务行动。

参考稿加载链新增独立静态门禁：从 HTML 的 `link` 递归遍历 CSS `@import`，校验拆分样式可达性与所有 `var(--token)` 定义。五平台视觉任务在采集前新增原生能力 smoke，覆盖临时目录、安全存储、系统认证、PDF、WebView 与桌面窗口生命周期。

## 自评审与冻结

- token 修订只恢复总纲已有的品牌焦点、一级阴影和标准动效曲线，没有引入裸值或局部视觉分叉。
- 四档视口、亮暗主题、48dp 目标、键鼠/触控协同和减少动态契约保持不变。
- 未修改 fixture、时钟、阈值或外部区域；没有通过重录 Flutter 图规避参考差异。
- 完整 Chromium 原型核验通过后才采集 Flutter 候选，符合“设计稿 → 自评审 → 冻结 → 实现 → 验收”的顺序。

## 全量视觉结果

- 设计参考：`build/design-review-v34`，1376 张 PNG、104 份外部区域 sidecar，索引 1376 项。
- Windows 候选：`build/visual/windows-full-v34`，由本机 Flutter 3.44.6 采集 1376 张 PNG、104 份 sidecar；清单、尺寸和边界校验通过。
- 对比报告：`build/visual-results/windows-full-v34/report.json`。
- 结果：1376/1376 张逐图通过。
- 最低应用区：`settings.licenses--external-cancelled--light--1200x900.png`，SSIM 0.900283576。
- 最低外部区：`external.webview--operation-locked--dark--360x800.png` 的 `document`，SSIM 0.933079587。

阈值保持每张 SSIM ≥ 0.90，没有按平台平均或全局平均放行，也没有扩大外部区域。

为核对 CI 锁定版本，另用独立 Flutter 3.44.0 / Dart 3.12.0 工具链生成 `build/visual/windows-full-v34-flutter-3.44.0`：1376 张 PNG、104 份 sidecar 全部通过清单、尺寸和边界校验。按后续验收决定，本轮跳过这套候选的重复 SSIM 计算；因此上面的 SSIM 数值只对应 Flutter 3.44.6 候选，不将其冒充为 3.44.0 像素评分。

## 工程与原生能力门禁

- `actionlint .github/workflows/ci.yml`：通过。
- GitHub 治理校验：通过。
- 清源设计系统校验器：36/36；拆分样式校验器：3/3；两份静态契约均通过。
- `flutter analyze`：无问题。
- `flutter test --timeout 300s`：680 项通过。
- Windows 原生能力 smoke：5/5，通过 WebView 打开、刷新、后退和幂等释放等真实 runner 生命周期。
- `flutter build windows --release`：通过，产物为 `build/windows/x64/runner/Release/sspu_allinone.exe`。
- 上述 analyze、680 项测试、Windows smoke、Release 与 1376 张候选采集均在独立 Flutter 3.44.0 工具链再次通过；依赖锁未变化。

Android、iOS、macOS、Linux 必须在对应真实 CI runner 继续执行构建、原生 smoke 和 1376 张视觉矩阵。Windows v34 只能证明本平台，不构成五平台最终完成声明。
