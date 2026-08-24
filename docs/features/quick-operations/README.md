# 常用操作（Quick Operations）

> 业务域：`quick-operations`　·　所属：[功能总览](../README.md)
>
> 原 `quick-links` 模块更名扩展：快捷跳转 + 常用/规则等文档查询。

## 1. 模块职责

聚合常用的跳转入口与文档查询：校园站点/办事入口/常用 App 的快捷跳转（含移动端 App 深链），以及常用文档、办事流程说明与规章制度（规则）的汇总查询。

## 2. 功能清单

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| 快捷跳转 | 部分实现 | #280 | [`quick-jump.md`](quick-jump.md) |
| 文档查询 | 设计中 | #131 | [`document-query.md`](document-query.md) |

## 3. 内部依赖

- 跳转配置与文档汇总均为**内置 YAML 配置**驱动，随版维护。
- `web` 类跳转与文档预览复用 [info 的内置 WebView 与下载型 URL 处理](../info/message-center.md)；`oa` 类跳转依赖 [登录与凭据](../academic/auth-credentials.md)；收藏/置顶依赖 [本地存储](../platform/system/storage-sync.md)。

## 4. 模块级约束

- 仅做跳转与文档指引，**不代理第三方登录态**（`oa` 仅复用本校会话）。
- App 深链拆为独立条目；**无对应 App 的平台或未安装时直接隐藏**该条目。
- 下载型 URL 交系统/外部处理；数据全本地（含收藏/置顶），来源需可信、明确。

## 5. 相关 Issue

#280（移动端学习通 App 跳转）、#131（常用办事流程与文档汇总）。
