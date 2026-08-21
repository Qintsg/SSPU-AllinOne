# 功能设计文档（Features）

> 工大聚合 SSPU-AllinOne · 全部功能的需求 / 实现 / 关联 / 约束的单一真源
>
> 设计语言见 [`DESIGN.md`](../../DESIGN.md) 与 `docs/design/`（[foundations](../design/foundations/README.md)、[components](../design/components/README.md)）；本目录只描述**做什么、怎么做、彼此如何关联**，不重复设计 token。

---

## 1. 这是什么

本目录是工大聚合所有功能的**结构化设计档案**，按「全局总览 → 模块总览 → 单功能细文档」三层组织，目标是可维护、可扩展、可追溯到代码与 Issue。

数据原则与全局约束（全本地、只读查询、凭据进系统安全存储）适用于每一个功能，详见各模块约束与 [`overview/domains.md`](overview/domains.md)。

## 2. 三层文档体系

| 层级 | 文件 | 职责 |
| --- | --- | --- |
| ① 全局总览 | 本 `README.md` | 入口、模块地图、文档约定、状态图例、索引 |
| ② 模块总览 | 各模块 `README.md` | 业务域职责、功能清单、内部依赖、相关 Issue |
| ③ 单功能细文档 | 各模块 `<feature>.md` | 元信息 → 需求 → 交互 → 实现 → 关联 → 约束 → 演进 |

跨模块视图集中在 [`overview/`](overview/)：功能矩阵、业务域依赖、演进路线。

## 3. 模块地图

| 模块 | 目录 | 范围 |
| --- | --- | --- |
| 平台基础 | [`platform/`](platform/README.md) | 导航壳、主页、设置、安全隐私、存储同步、通知、自动刷新、更新、主题、i18n、校历（通用） |
| 教务 | [`academic/`](academic/README.md) | 登录凭据 + EAMS（个人信息/日历/成绩/过程化/考试/开课/空闲教室/培养计划）+ 活动（体育打卡/第二课堂） |
| 校园生活 | [`campus-life/`](campus-life/README.md) | 校园卡余额与明细、消费统计与可视化 |
| 资讯 | [`info/`](info/README.md) | 多源新闻聚合、消息中心、微信公众号文章 |
| 邮箱 | [`email/`](email/README.md) | 收件箱与阅读、撰写发送 |
| 常用操作 | [`quick-operations/`](quick-operations/README.md) | 快捷跳转（含 App 深链）、常用/规则文档查询 |
| 校园网 | [`network/`](network/README.md) | 网络状态检测（门禁）、网络诊断、VPN 一键连接（仅桌面，本地插件） |
| AI 助手 | [`ai/`](ai/README.md) | 助手对话（BYOK）、模型与数据边界、本地数据 MCP 暴露（仅桌面） |

## 4. 状态图例

| 徽标 | 含义 |
| --- | --- |
| **已实现** | 代码已落地并可用 |
| **部分实现** | 主流程可用，仍有 Issue 待完善 |
| **设计中** | 需求/解析已就绪或在排期，UI/前端待补 |
| **占位** | 仅建骨架，需求待用户描述 |

## 5. 文档约定

- **正文简体中文，文件名英文 kebab-case**（如 `grade.md`），与 `docs/design/` 命名一致。
- 新增功能：复制 [`_templates/feature.md`](_templates/feature.md) → 填入所属模块目录 → 在该模块 `README.md` 与 [`overview/feature-matrix.md`](overview/feature-matrix.md) 登记。
- 新增模块：复制 [`_templates/module.md`](_templates/module.md) 为模块 `README.md`，并在本文件「模块地图」登记。
- 交叉引用统一用相对路径 Markdown 链接；功能 ID 形如 `<module>.<feature>`。
- 每篇细文档头部维护状态徽标，便于矩阵聚合。

## 6. 与代码 / Issue 的关系

- 每篇细文档的「主要代码」列指向 `lib/` 下的实现，改代码时同步更新文档。
- 「关联 Issue」列回链 GitHub Issue，路线演进见 [`overview/roadmap.md`](overview/roadmap.md)。
- 本目录是**设计意图**的真源；代码是**落地结果**，两者出现分歧时以最近一次评审为准并就地修正。
