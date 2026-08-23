# 清源页面原型浏览器核验

核验脚本使用 Playwright 自带 Chromium，不依赖本机 Edge 或 Chrome。首次运行先安装锁定依赖和浏览器：

```powershell
python -m pip install --disable-pip-version-check --only-binary=:all: --require-hashes -r .github/requirements/design-prototype.txt
python -m playwright install chromium
```

随后执行：

```powershell
python scripts/design/verify_design_prototype.py --output build/design-review
```

脚本覆盖 360、768、1200、1600px，检查七个主目的地、详情与外部内容边界、页面交互、亮暗主题、键盘焦点、48px 目标、减少动态、横向溢出和控制台错误。它根据视觉清单和全状态参考目录补齐全部 194 个页面/状态组合，最终输出 1552 张核验截图及带 SHA-256 的 `reference-index.json`。CI 使用同一依赖、浏览器和命令。

首页设置项关闭后的稿外密度由以下命令单独核验，覆盖全部、单项和全关闭三种配置：

```powershell
python scripts/design/check_home_density_interactions.py
```

本地调整单一批次时可使用 `--surface-prefix settings.about` 只核验匹配的参考界面；CI 和最终冻结仍必须省略该参数以生成全部 1552 张。

Flutter 候选中，Android/iOS 使用 `integration_test/qingyuan_visual_capture_test.dart` 在对应模拟器上渲染并回传截图；桌面三端使用各自 CI runner 上的 widget 视觉采集。
