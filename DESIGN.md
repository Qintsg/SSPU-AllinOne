# 清源 Design System（DESIGN.md）

> 版本：v0.2.0 · 工大聚合 SSPU-AllinOne 前端重写 · 设计语言总纲
>
> 本文件取代旧版 Fluent 2 设计系统规范（旧规范已整体废弃，不再保留）。
> 完整规范、组件与样例见 [`docs/design/`](docs/design/README.md)。

---

## 1. 这是什么

**清源（Qīngyuán）** 是工大聚合本次前端重写所采用的设计系统。它不是一套页面，而是一套**组件系统**：

- **设计系统是唯一真源**——每个组件的视觉、状态与 token 在文档中定义，代码按文档落地。
- **自建组件库**——不沿用、不继承、不重皮仓库历史的 Fluent 2 实现；Flutter 原生 widget 仅作不可见的机械骨架（手势 / 焦点 / 输入法 / 滚动 / 无障碍）。
- **token 驱动**——颜色、字号、间距、圆角、阴影、动效全部来自语义令牌，代码中**零裸值**；亮 / 暗双主题集中切换。
- **一套六端**——同一套令牌从 360px 手机线性伸缩到桌面宽屏，不为单端做特例。

> 背景：工大聚合是面向上海第二工业大学师生的校园综合服务应用，数据全本地、不上云。清源承接「校园信息聚合 + 教务 / 课表 / 资讯 / 邮箱 / 财务 / 体育 / 第二课堂 + AI 助手」的产品形态，并为未来业务增长预留扩展。

---

## 2. 四条原则

| # | 原则 | 含义 | 落地要点 |
|---|------|------|----------|
| 01 | **聚而不杂** | 聚合是核心 | 清晰信息分层 + 稳定的业务域分类色 + 充分留白；一屏一个重点 |
| 02 | **本地为信** | 数据只在本地 | 用实体表面、克制材质、明确「本地」标识传达可信，不靠花哨渐变 |
| 03 | **墨蓝为骨，青雾点睛** | 结构与行动分工 | 学院墨蓝做结构 / 图表，青雾做行动；行动色一屏至多两次 |
| 04 | **一套六端** | 跨端一致 | 同一套 token 线性伸缩；token 直映射 Flutter `ThemeExtension` |

---

## 3. 令牌速览

完整定义见 [`docs/design/foundations/`](docs/design/foundations/README.md)。

| 类别 | 关键值（Light） | 说明 |
|------|----------------|------|
| 行动色 · 青雾（响应色） | `--brand-strong #478384` / `--brand #6FA3A4` / `--brand-tint #E9F0F0` / `--brand-ink #356263` | 深支扛白字填充（AA Large 4.3:1），亮支做点缀 |
| 结构色 · 墨蓝 | `--structural #14304D` | 沉浸头图 / 图表 / AI 助手 |
| 中性（暖灰） | `--bg #F7F6F5` `--surface #FFFFFF` `--fg #1C1B1A` `--border #D1CEC9` | 占 70–90% 像素 |
| 状态 | success `#1F8F57` · warn `#B26A12` · danger `#C23B33` | 仅表达状态语义 |
| 业务域（可生长） | 教务 `#2C63D8` · 课表 `#0E8F9A` · 资讯 `#7A52D0` · 邮箱 `#D24A7A` · 财务 `#BE8A1E` · 体育 `#E26A2C` · 二课堂 `#3E9C4F` · 快捷 `#5C6B7A` | 由 `serviceId` 哈希到色相轮，**数量不写死** |
| 字体 | `MiSans`（display+body）· 数字走等宽 mono | 沿用仓库已内置字体 |
| 圆角 | 控件 `10` · 输入 `12` · 卡片 `16` · 磁贴 `18` · 抽屉 `24` | 比 Fluent 更柔 |
| 阴影 | `e1` 卡片 / `e2` 浮起 / `e3` 抽屉 | 整体压低 |
| 动效 | `120 / 200 / 320ms` · `cubic-bezier(.33,0,.2,1)` | 进入减速、退出加速 |

---

## 4. 组件库

**六大类，44 个组件**，每个组件按统一规格成文（解剖 / 全状态 / 变体 / token 映射 / API / Flutter 骨架 / Do&Don't）。索引见 [`docs/design/components/README.md`](docs/design/components/README.md)。

| 类别 | 数量 | 代表 |
|------|------|------|
| 操作 Actions | 10 | Button · IconButton · FAB · Segmented · Chip · Switch · Checkbox · Radio · Slider · Stepper |
| 输入 Inputs | 6 | TextField · Search · Textarea · Select · DatePicker · OTP |
| 容器与反馈 Containers | 9 | Card · Tile · ListItem · Accordion · Banner · Toast · Dialog · Skeleton · EmptyState |
| 导航 Navigation | 5 | AppBar · BottomNav · NavRail · Tabs · Pagination |
| 数据展示 Data | 8 | Badge · StatusPill · Avatar · MetricCard · Progress · Ring · FeedItem · SourceBadge |
| 校园域 Domain | 6 | TodayCard · CourseBlock · AIMessage · BalanceModule · QuickLink · AttendanceItem |

---

## 5. 文档导航

```
DESIGN.md                      # ← 你在这里（总纲）
docs/design/
├─ README.md                   # 文档站索引 + 阅读指南 + 变更流程
├─ CHANGELOG.md                # 设计系统变更记录
├─ foundations/                # 基础层：色 / 字 / 距 / 影 / 动 / tokens
├─ components/                 # 组件层：索引 + 规格模板 + 逐组件全规格 + samples/
├─ patterns/                   # 模式层：页面 = 组件编排
├─ domain/                     # 校园域模块
└─ resources/                  # tokens.json（机器可读）等
```

- 可视化总览（交互式，亮/暗双主题）：设计工作区 `index.html`（组件画廊 + 旗舰组件全规格 + 落地映射）。
- 行动色对比工具：设计工作区 `color-compare.html`。

---

## 6. 取代与废弃

- 旧 Fluent 2 设计系统（通信蓝 `#0F6CBD`、锐角、acrylic）整体废弃，仓库不保留其设计系统规范副本（如需可从 git 历史恢复）。
- `docs/DESIGN.md` 等文档描述的是当前已发布版本（仍基于 Fluent）的实现现状，待清源重写落地后再同步更新，不在本次预先改写。

变更记录见 [`docs/design/CHANGELOG.md`](docs/design/CHANGELOG.md)。
