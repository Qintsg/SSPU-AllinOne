# Quickstart: 校园工作台响应式收敛验证

## 自动化验证

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --no-fatal-infos
flutter test
flutter build windows --debug
python scripts/ci/validate_spec_kit.py
```

预期：全部命令退出码为 0；Widget 测试在窄屏、平板和桌面尺寸均没有渲染异常。

## Windows Debug 手工回归

1. 运行 `flutter run -d windows --debug`。
2. 依次打开教务、课表、信息、邮箱、跳转、AI 服务和设置。
3. 将窗口调整到约 360×800、768×900、1200×900；检查无黄色溢出条和控制台渲染异常。
4. 教务核对五项身份字段、已获学分、下一场考试及删除项；课表核对时间轴和跨节次课程块。
5. 信息执行全渠道刷新和分页；邮箱分别滚动列表与长正文并确认无远端内容加载。
6. 检查快速跳转换行、AI 双栏等高、端口旁服务按钮和左下角设置入口。

## 验收证据

- 保存自动化命令摘要和 Windows Debug 控制台是否出现 rendering exception。
- 若发现 `BOTTOM OVERFLOW`，记录页面、窗口尺寸和 widget 路径，修复后重新执行对应场景。

## 失败基线

- 教务协同刷新部分失败时，成绩缓存曾串行等待考试学期解析，导致顶部“已获学分”在考试初始化缓慢或失败时保持为 `0`；回归测试现固定为各来源并行加载，并验证失败来源不覆盖其他来源的最后有效缓存。
- 旧课表桌面路径依赖固定网格和不可滚动的剩余高度，在 1084×706 窗口中无法访问第 13 节并触发底部溢出；回归测试现验证单节时间轴、跨节课程块的位置和完整纵向可滚动性。
- AI 服务宽屏双栏最初使用 `IntrinsicHeight` 包裹含 `LayoutBuilder` 的授权卡，真实布局抛出 intrinsic dimension 异常；现改为基于 Qingyuan 控件与间距令牌计算的等高区域，并覆盖 1200×900 双栏和 360×800 单栏。

## 2026-09-12 最终结果

- `dart format --output=none --set-exit-if-changed lib test integration_test`：487 个文件，0 个变更。
- `flutter analyze --no-fatal-infos`：No issues found。
- `flutter test --no-pub -r compact`：835 通过、1572 个平台条件跳过、0 失败。
- 重点响应式与行为测试组合：166 通过、0 失败。
- `python scripts/ci/validate_design_system.py`：通过。
- `python scripts/ci/test_validate_design_system.py`：38 通过。
- `python scripts/ci/validate_spec_kit.py` 与 `python scripts/ci/validate_github_governance.py`：通过。
- 视觉采集：教务、课表、信息、邮箱、跳转、AI 服务、设置共 7 个入口，覆盖 360×800、768×900、1200×900、1600×1000 与明暗主题；关键 content 截图人工核对无溢出。
- `flutter build windows --debug`：成功生成 `build/windows/x64/runner/Debug/sspu_all_in_one.exe`。
- `flutter run -d windows --debug`：成功启动并持续观察 30 秒；无 `RenderFlex overflow`、`IntrinsicHeight/LayoutBuilder` 或其他 rendering exception。校园 VPN 探测失败属于当前网络环境，体育系统直连返回 HTTP 200。
