# 清源微信公众号扫码登录 v01 评审记录

日期：2026-08-18  
分支：`feature/design-language-spec`  
状态：设计参考已评审并冻结

## 范围

- `settings.wechat-login`：`loading`、`initial`、`content`、`error`、`partial-error`、`operation-locked`、`external-confirmation`、`external-error`。
- 四档视口、亮暗主题，共 64 张设计参考。
- `initial`、`content`、`partial-error`、`operation-locked`、`external-error` 声明 `document` 外部区域，共 40 份 sidecar。

## 自评审结论

当前生产页具备紧凑工具栏和主要错误恢复，但视觉清单只覆盖认证管理页与通用 WebView，无法证明扫码页面、候选认证回滚、成功反馈和操作锁的响应式表现。

v01 采用“认证接力条”而非卡片堆叠：工具栏负责返回/刷新/外部打开，状态条只解释当前责任和恢复路径，WebView 或错误恢复面板填满剩余空间。否决通用 WebView 复用、二维码卡片化和系统浏览器登录替代三种方案。

## 冻结门禁

- Chromium 生成 64/64 张候选，并通过页面无溢出、48dp 目标与外部区域边界检查。
- `external-confirmation` 必须验证取消初焦、Tab/Shift+Tab 循环、Escape 与焦点归还。
- 360×800 亮暗主题必须无页面级滚动，状态条不得挤压网页或恢复行动。
- `operation-locked` 必须同时锁定返回、刷新和外部打开；`partial-error` 保留网页和原连接恢复说明。
- 验收完全跳过 SSIM，只使用产物完整性、交互门禁与人工逐屏复核。

上述条件通过前，本记录不得改为“已冻结”，Flutter 视觉 fixture 不得使用静态仿制页面替代生产结构。

## 冻结结论

- `build/design-review-wechat-login-v06` 已生成 64/64 张参考图；浏览器逐态验证了外部区域、确认模态、取消初焦、Tab/Shift+Tab、Escape、遮罩锁定与触发器焦点归还。
- 360×800 亮暗主题的网页区域填充至底栏上方，错误恢复行动居中且无需页面滚动；1200×900 与 1600×1000 移除了重复页头和无意义的右侧空白。
- Windows Flutter 生产候选由真实 `WxmpLoginPage` 的八态入口生成 64/64 张，并写入 40 份 `document` 外部区域 sidecar；默认生产路径仍使用 `InAppWebView`，fixture 仅替换平台正文。
- 视觉实现冻结为“工具栏 + 认证接力条 + 填充式外部区域/恢复面板”，已进入 Flutter 生产页面；实现不得退回通用 WebView 或二维码卡片套层。
- 生产页面与 fixture 共享 `WxmpLoginContentFrame`，fixture 只注入 `documentBuilder`；loading 锁定、initial 接力条、成功标题“登录已完成”、generation 旧回调丢弃和外部确认键盘协同均由生产行为测试覆盖。

## 实现复核补充

- 2026-08-18：补齐生产路径在四次读取均未获得 Cookie 时的 partial-error 说明，并区分“从未写入候选”与“曾写入候选后又读取为空”：前者明确没有写入新的认证信息，后者先恢复原连接并展示恢复结果；两种情况均保留原位重试入口。
- 回归覆盖：模拟“首次拿到候选 Cookie、后续读取为空且校验失败”的时序，断言候选写入后一定恢复原连接；同时覆盖 generation 隔离、加载锁定、外部确认焦点循环与 Escape。
- 复核证据：`flutter analyze`、全量 Flutter 测试、微信/WebView 定向测试和 Windows 四档亮暗视觉采集均通过；SSIM 按项目约定跳过。
