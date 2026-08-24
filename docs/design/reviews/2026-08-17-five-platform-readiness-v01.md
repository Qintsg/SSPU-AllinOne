# 清源五平台交付就绪审计 v01

日期：2026-08-17  
分支：`feature/design-language-spec`  
状态：Windows 本机与 Linux 容器验收通过；Android Debug 构建通过，Android 运行时/iOS/macOS 等待真实 runner 结果  
视觉政策：后续跳过 SSIM，保留确定性截图矩阵、完整性门禁与人工逐屏评审

## 已冻结范围

- Flutter Web 明确排除；发布范围为 Android、iOS、Windows、macOS、Linux。
- 设计清单覆盖 44 个清源组件、51 个 surface、187 个页面/状态组合，以及四档视口和亮暗主题。
- 每个平台候选矩阵固定为 `187 × 4 × 2 = 1496` 张 PNG，并附 144 份允许的外部区域 sidecar。
- 页面可见实现统一经 `lib/design/qingyuan/qingyuan_ui.dart` 使用主题、图标、宿主、导航、弹层、反馈和 `Yh*` 组件；静态门禁拒绝业务层导入内部实现。
- 运行时不依赖 `fluent_ui`、Material/Cupertino/Fluent 成品视觉控件或 `Icons.*`；`fluentui_system_icons` 只作为 `YhIcons` 的不可见实现细节。

## 本机已验证

| 项目 | 环境 | 结果 |
| --- | --- | --- |
| CI 校验器测试 | Python | 48/48 通过（含五平台 CI 矩阵回归） |
| 设计系统完整契约 | Python | 通过 |
| Flutter 静态分析 | Flutter 3.44.0 / Dart 3.12.0 | 无问题 |
| Flutter 全量测试 | Flutter 3.44.0 | 695 项通过；1496 个需显式采集环境的截图用例跳过 |
| Windows 原生能力冒烟 | Windows 真实 runner | 5/5 通过；认证不可用降级与窗口关闭保护可逆切换已实际调用 |
| Windows Release | Flutter 3.44.0 | 生成 `build/windows/x64/runner/Release/sspu_allinone.exe` |
| HTML 设计参考 | Chromium | `build/design-review-v42-no-ssim`：1496 PNG + 144 sidecar，浏览器交互与布局门禁通过 |
| Windows 视觉候选 | Flutter 3.44.0 | `build/visual/windows`：1496 PNG + 144 sidecar；根 Overlay 使用真实目标视口，清单、尺寸和边界通过 |
| GitHub Actions 语法 | `actionlint` | 通过 |
| 五平台 CI 静态矩阵 | Python | 构建与视觉候选 job 均严格包含 Android、iOS、Windows、macOS、Linux，明确排除 Web |
| 工作树差异格式 | `git diff --check` | 通过 |

Windows v34 曾完成 1376/1376 的历史 SSIM 验证。该结果只作为既有 Windows 证据保留；按最新决定，Flutter 3.44.0 候选及后续五平台任务均不再计算 SSIM，也不在 CI 生成差异结果目录。

任务型模态框复审还修复了关闭确认组件与 `YhDialog` 的重复安全边距：360 宽度下取消、最小化和退出重新获得 280dp 整行宽度，错误与操作锁定状态仍保留选择和恢复路径。

## 五平台状态

| 平台 | CI 构建 | 原生 smoke | 1496 张采集与完整性 | 当前判定 |
| --- | --- | --- | --- | --- |
| Android | 本机 Flutter 3.44 容器 Debug APK 通过 | 无 KVM 软件 AVD 实际执行 4/5；WebView 生命周期超时 | 未运行可信视觉矩阵 | 构建通过；运行时/视觉验收等待 CI runner |
| iOS | 已配置 | 已配置 iOS Simulator | 已配置真实设备测试通道 | 等待 CI runner |
| Windows | 已配置且本机 Release 通过 | 本机 5/5 通过 | 本机完整性通过 | 本平台通过 |
| macOS | 已配置 | 已配置 macOS runner | 已配置桌面 runner | 等待 CI runner |
| Linux | 本机 Ubuntu Flutter 3.44 容器 Debug 通过 | 本机 `xvfb` Linux runner 5/5 通过 | 本机容器 1496 PNG + 144 sidecar 通过 | Linux 平台通过；GitHub CI 仍待执行 |

CI 对每个平台继续执行真实平台构建、原生插件生命周期冒烟、1496 张候选采集、文件名/数量/尺寸/sidecar 边界校验和候选上传。发布评审应逐屏关注首屏是否需要滚动、卡片与按钮是否过大、信息密度、断行与溢出、键鼠/触控协同、焦点、亮暗对比、异常恢复和减少动态行为。

## v02 本机证据补充（2026-08-18）

- 设计原型浏览器验证器已拆分为 CLI、核心契约和领域状态采集三个模块；原命令保持兼容，并重新完成 1496 张参考图与 144 份 sidecar 生成。
- 微信扫码登录补充候选认证事务回归：候选 Cookie 已写入、后续读取为空且校验失败时，必须恢复原连接；该路径已有 Widget 回归测试。
- Windows Release 与 5 项原生 smoke 均基于当前 Flutter 代码再次通过；Windows 候选目录仍严格为 1496 PNG + 144 sidecar。
- Linux 使用与 CI 相同的 Ubuntu 依赖清单和 `xvfb` desktop runner 完成 Debug 构建、5 项原生 smoke、1496 PNG 和 144 sidecar；该证据不替代 GitHub Actions 自身的运行记录。
- Android 使用 Flutter 3.44 容器完成 `flutter build apk --debug`；容器可安装 AVD 但没有 KVM，软件模拟器结果只能作为诊断，不能替代可信 Android Emulator/真实设备视觉采集。
- 后续实际启动了 Android 15 x86_64 AVD（软件 TCG，无 KVM）：安全存储、系统认证、PDF 和窗口状态 4 项通过，Headless WebView data URL 生命周期在 30 秒内未完成而失败；因此没有生成或接纳 Android 视觉候选。
- 本文中的“已配置”仅证明 CI 工作流和静态矩阵门禁存在；除 Windows/Linux 已列出的真实 runner 证据外，不构成平台执行结果。

## 尚未完成的外部证据

- 当前没有可运行这组未提交混合改动的远端 PR，因此 Android 可信 Emulator、iOS、macOS 的 CI 结果尚不存在；Linux 已有本机容器 runner 证据，Android 已有容器构建和无 KVM 诊断证据，但均没有 GitHub Actions 记录。
- 不能用 Windows、Linux 或 Android 容器构建替代 Android Emulator、iOS、macOS 的插件行为或截图。
- 无人值守 runner 不主动弹出可用设备的系统认证对话框，也不执行会关闭 runner 的窗口动作；真实认证成功/用户拒绝和最终关闭按钮仍需各平台人工发布冒烟。
- 在 Android Emulator、iOS、macOS 对应 runner 的构建、原生 smoke、候选完整性与人工逐屏评审均通过前，只能表述为“清源前端代码与 Windows/Linux 验收就绪，Android 构建已验证”，不能表述为“五平台最终发布验收完成”。

## v03 当前批次补充（2026-08-18）

- 首页可配置概览密度与教务总览紧凑指标已完成设计稿、自评审、Flutter 实现和稿外视觉核验；补充首页 12 张 Flutter 密度截图，教务总览 Windows 四档亮暗 80/80 通过。
- 当前 Chromium 参考目录 `build/design-review-v44-no-ssim` 已重新通过 1496 张生成；Windows 与 Linux 当前目录均为 1496 PNG + 144 sidecar，并通过完整性校验。
- 当前 Flutter 全量回归为 699 项通过，`flutter analyze` 无问题；Python 门禁 48/48、`actionlint` 和差异格式检查通过。
- Windows Release、Windows smoke 5/5、Linux Flutter 3.44.0 Debug、Linux smoke 5/5 均基于本批代码再次通过；Android Flutter 3.44.0 容器 Debug APK 也已构建成功。
- Android 可信 Emulator 视觉与 WebView smoke、iOS/macOS 对应 runner 仍是外部证据缺口，未将容器或 Windows/Linux 结果替代这些平台。

## v04 当前清单重采集（2026-08-19）

- 视觉清单已从 187 扩展至 193 个页面/状态组合；单平台目标随之更新为 `193 × 4 × 2 = 1544` 张 PNG，外部区域 sidecar 仍为 144 份。
- Windows 本机已用最新 Flutter 代码重新生成完整候选：1544/1544 截图采集通过，`validate_visual_artifacts.py` 确认文件名、物理尺寸、清单覆盖与 sidecar 边界全部有效；该矩阵已在邮件提交坞与首页问候短语改动后重新生成。
- 同一工作树内的 `flutter test --reporter compact` 为 711 项通过、1556 项未启用采集环境的视觉用例跳过；`flutter analyze`、设计契约和差异格式检查通过。
- 同一源码已完成 Windows Release 构建；随后在真实 Windows runner 重跑平台烟测 5/5，通过安全存储可逆读写、系统认证安全降级、PDF 生命周期、WebView 打开/刷新/返回和窗口状态读取。
- 当前 Windows 主机的 Android Debug 构建在 Flutter 工具链定位 Android SDK 前失败；`flutter doctor -v`、SDK 路径检查与 Android Studio 检查均确认 SDK 未安装，且本机 `android/local.properties` 指向 Linux 容器路径。保留的 APK 早于本批源码，不能作为当前证据。
- Linux 已使用 Flutter 3.44.0 一次性容器和 CI 同款原生依赖完成当前源码的 Debug 构建、真实 Linux runner 烟测 5/5 与 1544/1544 候选采集；`validate_visual_artifacts.py` 已确认 Linux sidecar、尺寸和清单覆盖有效。容器中的 Xvfb 采用显式生命周期启动，避免 Debian `xvfb-run` 在 Docker PID 1 下的就绪信号等待缺陷。
- Android、iOS、macOS 仍没有对应真实 runner 的最新 1544 张矩阵；Android 本机还缺少 SDK，因此五平台最终验收依旧未完成。

## v05 校园卡空记录恢复条与构建证据（2026-08-19）

- 校园卡详情的本地筛选空状态完成“左锚定、内容高恢复条”设计与实现。Windows 与 Linux 均重新采集该 surface 的 56 张（7 状态 × 4 视口 × 亮暗）候选，并分别通过各自完整目录的 `1544` 张 PNG 与 `144` 份 sidecar 校验；其它未改变 surface 保留原候选。
- Windows 当前源码再次完成 Release 构建；全量 `flutter test` 现为 713 项通过、1556 项未启用采集环境的视觉用例跳过，`flutter analyze`、设计系统、样式与清单门禁均通过。
- Android 当前源码在 Flutter 3.44.0 容器完成 `flutter build apk --debug`，生成 `build/app/outputs/flutter-apk/app-debug.apk`。本机仍无 Android SDK，且该 APK 构建不替代可信 Emulator 的插件 smoke 或视觉矩阵。
- Linux 当前源码在 Flutter 3.44.0 容器完成 Debug 构建、显式 Xvfb 下真实 Linux runner 的 5/5 原生 smoke，并更新校园卡详情候选。容器结束后已在 Windows 主机重新执行 `flutter pub get`，确认容器路径没有残留到宿主 `.dart_tool` 或生成插件注册表。
- iOS、macOS 与 Android 可信 Emulator 的当前构建、原生 smoke、完整视觉候选和逐屏人工评审仍需对应 CI runner；因此五平台最终验收依旧未完成。

## v06 校园卡终端错误恢复条（2026-08-19）

- 校园卡详情在“无有效快照且只读请求失败”的终端 error 状态移除居中高空卡：360px 的警告图标与标题同行，768px 起为左锚定、内容高的失败说明与双行动恢复条；重试原操作、凭据失效禁用、返回首页与不展示不可信余额/交易记录的契约不变。
- Windows 与 Linux 均重采集该 surface 全部 56 张状态候选，并分别通过完整目录 `1544` 张 PNG、`144` 份 sidecar 的校验。Linux 本批再次完成 Flutter 3.44.0 Debug 构建与真实 runner smoke 5/5；Windows 端已完成对应候选重采集，Release 重建待本批最终源码冻结后执行。
- 测试辅助函数同步固定为 1× DPR 与物理视口，确保“360×800”布局断言确实在 360×800，而不是 Flutter 测试默认 2400×1800 view 下运行；这是一项测试准确性修正，不改变生产 UI。
- Android 当前 APK 的最近构建早于本小批终端错误布局；iOS、macOS、Android 可信 Emulator 和 Windows 当前 Release 仍需在本批最终源码冻结后刷新。五平台最终验收依旧未完成。
