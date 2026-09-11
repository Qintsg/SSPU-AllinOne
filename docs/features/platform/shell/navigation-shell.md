# 导航与响应式壳层

> 子模块：[壳层](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.shell.navigation-shell` |
| 状态 | 已实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | #298 |
| 主要代码 | `lib/app.dart`、`app_navigation_items.dart`；`lib/widgets/responsive_layout.dart`、`desktop_window_frame.dart` |

## 1. 需求

提供跨端统一的导航与响应式布局：移动端底部导航 + 「更多」，桌面/平板侧边导航 + 桌面窗口框架。

**验收要点**
- 同一套目的地在窄屏（底部导航/更多）与宽屏（侧栏）线性适配。
- 桌面自绘窗口框架（标题栏/控制按钮）。

## 2. 实现

- `_AppDestination` 定义目的地（主页/教务/课表/信息/邮箱/跳转/设置/AI 服务/更多）。
- `responsive_layout` 按断点切换导航形态；`desktop_window_frame` 提供桌面窗口栏。
- 严格走设计系统门面（见 [`DESIGN.md`](../../../../DESIGN.md)）。

## 3. 关联

- 被依赖：[主页仪表盘](home-dashboard.md)、[设置中心](settings.md) 及所有页面。

## 4. 约束

- 一套 token 跨端线性伸缩；不为单端做特例。
- 顶层目的地保持固定，避免隐藏后失去恢复入口；#187 的显隐仅作用于首页业务卡片，联网获取由独立模块开关控制（见 [主页仪表盘](home-dashboard.md)）。

## 5. 待办与演进

- [x] 清源导航、响应式布局与桌面窗口框架（#298）。
- [x] 与 #187 首页卡片显隐及模块联网获取配置保持职责分离；顶层导航不参与隐藏。
