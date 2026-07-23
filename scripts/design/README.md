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

脚本覆盖 360、768、1200、1600px，检查七个主目的地、详情与外部内容边界、页面交互、亮暗主题、键盘焦点、48px 目标、减少动态、横向溢出和控制台错误。它根据视觉清单和全状态参考目录补齐全部 123 个页面/状态组合，最终输出 984 张核验截图及带 SHA-256 的 `reference-index.json`。CI 使用同一依赖、浏览器和命令。
