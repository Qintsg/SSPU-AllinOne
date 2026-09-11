# 壳层（Shell）

> 子模块：`platform/shell`　·　所属：[平台基础](../README.md)

## 1. 子系统职责

应用的外观骨架与统一入口：导航与响应式壳层、主页仪表盘、设置中心。是其它业务功能的承载与配置面。

## 2. 功能清单

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| 导航与响应式壳层 | 已实现 | #298 | [`navigation-shell.md`](navigation-shell.md) |
| 主页仪表盘与卡片 | 已实现 | #187 | [`home-dashboard.md`](home-dashboard.md) |
| 设置中心 | 已实现 | #187 | [`settings.md`](settings.md) |

## 3. 共性

- 壳层提供路由与目的地；主页与设置依赖之。
- 主页卡片显隐/排序在设置统一配置（#187）。
