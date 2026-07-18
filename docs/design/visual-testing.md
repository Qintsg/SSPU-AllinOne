# 清源五平台视觉验收

本规范把视觉验收定义为逐张截图的发布门禁。Android、iOS、Windows、macOS、Linux 分别执行；Flutter Web 不在本轮范围。任何平台、视口、主题、页面或状态失败，都不能被其他截图的平均分抵消。

## 固定环境

- Flutter 3.44.0、MiSans、`zh_CN`、`Asia/Shanghai`。
- 固定时钟 `2026-07-18T09:30:00+08:00`，关闭动画并启用 `qingyuan-sanitized-v1` 脱敏 fixture。
- 视口固定为 `360x800`、`768x900`、`1200x900`、`1600x1000`，每档同时采集 light / dark。
- 文件名固定为 `<surface>--<state>--<theme>--<width>x<height>.png`；`surface` 与 `state` 必须来自 [`visual-manifest.json`](./resources/visual-manifest.json)。

## 阈值与外部区域

- 应用自绘区域：SSIM `>= 0.99`。
- 系统认证、真实网页、PDF 正文等外部区域：SSIM `>= 0.95`。
- 外部区域不得扩大到应用工具栏、弹层或错误反馈。一个截图存在外部区域时，在基准图旁增加同名 sidecar：`<image>.regions.json`。

```json
{
  "externalRegions": [
    {"id": "document", "x": 0, "y": 56, "width": 1200, "height": 844}
  ]
}
```

坐标使用截图物理像素。比较器会从应用区域计算中排除这些矩形，并逐个按 0.95 独立判定。

## 比较命令

每个平台 runner 在生成实际截图后执行：

```powershell
dart run tool/visual_compare.dart `
  --baseline test/visual/baselines/windows `
  --actual build/visual/windows `
  --output build/visual-results/windows `
  --manifest docs/design/resources/visual-manifest.json `
  --platform windows
```

失败目录包含 `report.json`，并在 `failures/<截图名>/` 下保存 `baseline.png`、`actual.png`、`diff.png`。CI 必须连同实际截图目录一起上传，保证失败可定位。

## 五平台 Flutter 候选采集

候选图由真实 Flutter 渲染树生成，不复用 HTML 原型截图。CI 在 Android、iOS、Windows、macOS、Linux 五个平台标签下分别锁定目标平台，加载 MiSans 与 `YhIcons` 底层字体，并输出六类 44 组件面板以及快捷入口、法律、关于、WebView 错误页的四档视口、亮暗主题矩阵：

```bash
flutter test test/visual/qingyuan_visual_capture_test.dart \
  --dart-define=QINGYUAN_VISUAL_CAPTURE=true \
  --dart-define=QINGYUAN_VISUAL_PLATFORM=windows \
  --timeout 300s
```

输出位于 `build/visual/<platform>`。这些文件是待设计确认的候选图，不得直接作为新基线覆盖 SSIM 失败；确认后的冻结基线才进入 `test/visual/baselines/<platform>`。

## 基线纪律

基线只能由已确认、已冻结的设计参考生成。页面实现失败时不得用重录基线绕过门禁。若视觉意图改变，必须先修改设计文档、原型、清单和版本，再在独立变更中更新基线。
