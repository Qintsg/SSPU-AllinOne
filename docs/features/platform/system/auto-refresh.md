# 后台自动刷新

> 子模块：[系统能力](README.md)　·　状态：**已实现**（前端重构中）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.system.auto-refresh` |
| 状态 | 已实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/auto_refresh_service*.dart`、`info_refresh_service.dart`；`lib/controllers/card_auto_refresh_controller.dart` |

## 1. 需求

按各功能配置的间隔在后台自动刷新数据（教务/校园卡/邮箱/资讯等），并在卡片层协调刷新与反馈。

## 2. 实现

- `auto_refresh_service`（init/timers/fetch 拆分）：统一调度各功能的自动刷新定时器；`info_refresh_service` 编排资讯抓取。
- `card_auto_refresh_controller`：卡片级刷新协调与反馈。
- 各功能各自的开关/间隔/条数配置（教务、校园卡、邮箱、资讯频道）由各自服务持有，本服务统一驱动。

## 3. 关联

- 被依赖：各域查询功能（教务/校园卡/邮箱/资讯）与 [主页仪表盘](../shell/home-dashboard.md) 卡片刷新。
- 关联：[设置中心](../shell/settings.md)（自动刷新分区）。

## 4. 约束

- 刷新频率受各功能间隔约束、合并并发，避免高频骚扰站点。
- 后台刷新受平台后台执行限制；不阻塞 UI。

## 5. 待办与演进

- [ ] 前端重构后的刷新反馈与卡片协调。
