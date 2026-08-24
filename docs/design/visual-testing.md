# 清源五平台视觉验收

本规范把视觉验收定义为“确定性截图矩阵 + 自动完整性检查 + 人工逐屏评审”。Android、iOS、Windows、macOS、Linux 分别执行；Flutter Web 不在本轮范围。自 2026-08-17 起跳过 SSIM，不再用单一像素相似度替代对排版密度、操作协同、异常恢复和平台适配的判断。

## 固定环境

- Flutter 3.44.0、MiSans、`zh_CN`、`Asia/Shanghai`。
- 固定时钟 `2026-07-18T09:30:00+08:00`，关闭动画并启用 `qingyuan-sanitized-v1` 脱敏 fixture。
- 视口固定为 `360x800`、`768x900`、`1200x900`、`1600x1000`，每档同时采集 light / dark。
- 文件名固定为 `<surface>--<state>--<theme>--<width>x<height>.png`；`surface` 与 `state` 必须来自 [`visual-manifest.json`](./resources/visual-manifest.json)。

## 验收重点与外部区域

- CI 必须为每个平台生成清单注册的全部截图，严格校验文件名、数量、物理尺寸与 sidecar 边界；缺图、错尺寸或越界立即失败。
- 人工评审逐屏检查信息层级、内容密度、首屏滚动、断行、溢出、触控目标、焦点、遮挡、亮暗对比和平台习惯，不以平台平均或抽样替代失败页面。
- 应用工具栏、弹层、错误反馈和恢复动作始终属于清源自绘区域；系统认证、真实网页和 PDF 正文通过同名 `<image>.regions.json` sidecar 标明，便于评审时区分应用责任边界。
- `visual-manifest.json` 通过 `externalRegionStates` 逐区域声明允许生成 sidecar 的页面状态；清源自绘的 loading、empty、error、认证说明和降级反馈不能因为位于 WebView/PDF/系统认证流程中而跳过评审。
- 外部确认态不为被清源 Dialog 覆盖的 PDF/WebView 正文生成矩形 sidecar，避免把自绘弹层误归为外部内容。

发布门禁还必须通过对应页面的行为测试，重点验证重复操作互斥、旧请求隔离、系统返回、取消、失败后上下文保留和原地恢复；设计稿未列出的插件异常、外部应用拒绝、权限变化与部分完成状态一经发现，必须先加入参考清单和行为契约，不能以“没有设计稿”为由跳过。

```json
{
  "externalRegions": [
    {"id": "document", "x": 0, "y": 56, "width": 1200, "height": 844}
  ]
}
```

坐标使用截图物理像素。sidecar 只标注外部内容责任边界，不参与数值相似度计算。

## 五平台 Flutter 候选采集

候选图由真实 Flutter 渲染树生成，不复用 HTML 原型截图。Android 与 iOS 必须分别由 Android Emulator 和 iOS Simulator 的 `integration_test` runner 渲染，截图字节通过 Flutter 设备测试通道回传 CI 主机；禁止用 `debugDefaultTargetPlatformOverride` 伪装移动平台。Windows、macOS、Linux 分别在同系统桌面 runner 上采集。五个平台均加载 MiSans 与 `YhIcons` 底层字体，并输出 `visual-manifest.json` 注册的 194 个页面/状态组合、四档视口与亮暗主题矩阵；每个平台必须恰好得到 1552 张 PNG。候选上传前还会校验文件名、PNG 物理尺寸和外部区域 sidecar 边界。桌面 Widget 测试必须同时把根测试视图与页面 `MediaQuery` 固定为目标视口，避免根 Navigator/Overlay 回落到默认 800×600：

```bash
flutter test test/visual/qingyuan_visual_capture_test.dart \
  --dart-define=QINGYUAN_VISUAL_CAPTURE=true \
  --dart-define=QINGYUAN_VISUAL_PLATFORM=windows \
  --timeout 300s
```

移动端 runner 使用独立入口（示例中的 `<device-id>` 由 CI 启动的模拟器提供）：

```bash
flutter test -d <device-id> integration_test/qingyuan_visual_capture_test.dart \
  --dart-define=QINGYUAN_VISUAL_CAPTURE=true \
  --dart-define=QINGYUAN_VISUAL_DEVICE_CAPTURE=true \
  --dart-define=QINGYUAN_VISUAL_PLATFORM=android \
  --timeout 300s
```

输出位于 `build/visual/<platform>`。CI 在完整性校验后上传每个平台的全部候选图，供逐屏评审；候选图不能反向覆盖或替代已冻结的设计参考。

首页显示项关闭后的稿外密度场景另由 [`home_density_visual_capture_test.dart`](../../test/visual/home_density_visual_capture_test.dart) 采集，覆盖 360×800 与 1200×900、亮暗主题以及全部/单项/全关闭三种配置；该补充矩阵不改变主 manifest 数量，但必须通过布局、字体、无滚动和截图尺寸检查。

## 五平台原生能力冒烟

视觉候选只证明 Flutter 自绘树可渲染，不能替代真实插件和平台生命周期验证。每个平台在采集视觉矩阵前运行 [`qingyuan_platform_smoke_test.dart`](../../integration_test/qingyuan_platform_smoke_test.dart)，使用无网络、可重复的数据覆盖：

- 临时目录与安全存储的可逆读写；Linux runner 没有桌面密钥环时允许明确的 `PlatformException` 降级，但不允许插件未注册。
- 系统认证能力探测；Linux 必须返回不支持，其他平台必须完成插件调用或安全降级。
- `pdfrx` 打开并释放确定性单页 PDF。
- WebView 打开 `data:` 文档、刷新、进入次页、返回和释放；Linux 按产品能力契约走不支持降级。
- Windows、macOS、Linux 的窗口状态读取。

```powershell
flutter test -d windows integration_test/qingyuan_platform_smoke_test.dart `
  --timeout 180s
```

Windows 已在本机真实 runner 通过。Android、iOS、macOS、Linux 必须由各自 CI runner 执行；任一平台的插件未注册、打开失败、返回失败、资源释放异常或非预期降级都会阻断该平台视觉采集和发布构建。冒烟只使用临时数据并在结束时清理，不读取真实校园账户、网页或文档。

## 全量设计参考候选

浏览器原型会先采集应用壳中的高保真主流程，再用同一清源 token 和 [`reference-catalog.json`](./resources/reference-catalog.json) 补齐所有次级页面、八态与经确认的交互场景态。输出同样严格覆盖 194 × 4 × 2 = 1552 张，并生成 `reference-index.json`，记录设计系统版本、固定 fixture 和每张图片的 SHA-256：

```powershell
python scripts/design/verify_design_prototype.py --output build/design-review
```

索引状态固定为 `design-review-candidate`。它证明参考稿完整且可复现，不等于产品确认，也不能未经评审直接成为实现依据。

## 参考冻结纪律

实现只能依据已确认、已冻结的设计参考。页面实现不理想时不得用重录候选图绕过评审；若视觉意图改变，必须先修改设计文档、原型、清单和版本，经自评审冻结后再修改 Flutter。
