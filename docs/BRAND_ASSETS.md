# 品牌资产与图标生成

## 源文件

- 系统应用图标源图：`assets/brand/app-icon_outer-white-transparent.png`
- 系统应用图标 SVG 备份：`assets/brand/app-icon_outer-white-transparent.svg`
- 应用内徽章源图：`assets/brand/badge_outer-white-transparent.png`
- 应用内徽章 SVG 备份：`assets/brand/badge_outer-white-transparent.svg`

系统应用图标使用圆角方形版本，覆盖 Windows 任务栏、安装器、卸载入口、Android Launcher、iOS / macOS AppIcon、Web favicon / PWA icon 和 Linux Release 打包图标。应用内首页、锁屏页、关于页和文档预览使用圆形徽章版本。

## 生成命令

```powershell
python scripts/assets/generate_brand_icons.py
```

脚本依赖 Pillow；本地如缺少依赖，可先执行 `python -m pip install Pillow`。

脚本会根据 `assets/brand` 源图重新生成：

- `assets/images/logo.png`
- `assets/images/app_icon.png`
- `assets/images/app_icon.ico`
- `windows/runner/resources/app_icon.ico`
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png`（Android 8+ adaptive icon 前景，108dp 画布内使用 72dp 安全区）
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png`
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png`
- `web/favicon.png`
- `web/icons/*.png`
- `docs/pictures/logo/logo.png`
- `docs/pictures/logo/logo.svg`
- `docs/pictures/logo/ico-preview.png`

## 校验建议

1. 运行 `python scripts/assets/generate_brand_icons.py` 后确认 `git diff` 只包含预期平台图标与文档变更。
2. 使用 ImageMagick 或 Pillow 检查各平台尺寸是否匹配 `Contents.json`、Android mipmap 和 Web manifest。
3. Windows 本地构建后检查窗口左上角、任务栏、安装器和卸载入口图标。
4. Web 构建后检查 favicon、Apple touch icon 和 manifest icon。
5. Android / iOS / macOS 若当前机器无法构建，至少完成资源尺寸和透明通道静态检查。
