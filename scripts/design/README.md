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

脚本覆盖 360、768、1200、1600px，检查七个主目的地、邮件详情与外部网页确认边界、页面交互、亮暗主题、键盘焦点、48px 目标、减少动态、横向溢出和控制台错误，并输出核验截图。CI 使用同一依赖、浏览器和命令。
