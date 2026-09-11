# 后台自动刷新

> 子模块：[系统能力](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.system.auto-refresh` |
| 状态 | 已实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/auto_refresh_service*.dart`、`info_refresh_service.dart`；`lib/controllers/card_auto_refresh_controller.dart` |

## 1. 需求

按统一的校园数据间隔在后台自动刷新教务、体育、第二课堂、校园卡和邮箱，并在页面层协调刷新与反馈。官网与公众号消息仍由消息刷新调度器统一驱动。

## 2. 实现

- `auto_refresh_service`（init/timers/fetch 拆分）：统一调度各功能的自动刷新定时器；`info_refresh_service` 编排资讯抓取。
- `card_auto_refresh_controller`：卡片级刷新协调与反馈。
- 教务、体育、第二课堂、校园卡和邮箱保留独立开关，但刷新间隔由 `DataAutoRefreshPreferences` 统一持有；写入后通知已挂载页面立即重启定时器。旧版来源间隔会在首次读取时迁移，存在冲突时选择最长间隔，避免升级后意外提高请求频率。
- 官网与公众号消息渠道默认开启；消息渠道的显示、抓取条数和刷新策略仍在对应来源分区管理。

## 3. 关联

- 被依赖：各域查询功能（教务/校园卡/邮箱/资讯）与 [主页仪表盘](../shell/home-dashboard.md) 卡片刷新。
- 关联：[设置中心](../shell/settings.md)（自动刷新分区）。

## 4. 约束

- 校园数据使用一个共享间隔，并由页面级聚合按钮合并并发，避免重复请求和高频骚扰站点。
- 后台刷新受平台后台执行限制；不阻塞 UI。

## 5. 待办与演进

- [x] 清源刷新反馈、单飞保护、缓存保留与卡片协调。
- [x] 与 #187 的模块级“停止获取”总开关联动。
