# 清源 Design System（DESIGN.md）

> 版本：v0.4.0 · 工大聚合 SSPU-AllinOne 前端重写 · 设计语言总纲
>
> 本文件取代旧版 Fluent 2 设计系统规范（旧规范已整体废弃，不再保留）。
> 完整规范、组件与样例见 [`docs/design/`](docs/design/README.md)。

---

## 1. 这是什么

**清源（Qīngyuán）** 是工大聚合本次前端重写所采用的设计系统。它不是一套页面，而是一套**组件系统**：

- **机器令牌是唯一真源**——`docs/design/resources/tokens.json` 定义视觉值，文档、样例 CSS 与 Flutter 主题由它生成或校验。
- **自建组件库**——不沿用、不继承、不重皮仓库历史的 Fluent 2 实现；Flutter 原生 widget 仅作不可见的机械骨架（手势 / 焦点 / 输入法 / 滚动 / 无障碍）。
- **token 驱动**——颜色、字号、间距、圆角、阴影、动效全部来自语义令牌，代码中**零裸值**；亮 / 暗双主题集中切换。
- **一套五端**——Android、iOS、Windows、macOS、Linux 五个发布平台共享语义、组件契约与信息层级；布局密度、导航形态和输入反馈按窗口与输入方式适配。Flutter Web 不属于本轮视觉与构建验收范围。

> 背景：工大聚合是面向上海第二工业大学师生的校园综合服务应用，数据全本地、不上云。清源承接「校园信息聚合 + 教务 / 课表 / 资讯 / 邮箱 / 财务 / 体育 / 第二课堂 + AI 助手」的产品形态，并为未来业务增长预留扩展。

---

## 2. 四条原则

| # | 原则 | 含义 | 落地要点 |
|---|------|------|----------|
| 01 | **聚而不杂** | 聚合是核心 | 清晰信息分层 + 稳定的业务域分类色 + 充分留白；一屏一个重点 |
| 02 | **本地为信** | 数据只在本地 | 用实体表面、克制材质、明确「本地」标识传达可信，不靠花哨渐变 |
| 03 | **墨蓝为骨，青雾点睛** | 结构与行动分工 | 学院墨蓝做结构 / 图表，青雾做行动；行动色一屏至多两次 |
| 04 | **一套五端** | 跨端一致 | Android、iOS、Windows、macOS、Linux 使用同一套语义 token 与组件接口；断点、密度、鼠标/触控/键盘反馈允许适配；Web 本轮不验收 |

---

## 3. 令牌速览

完整定义见 [`docs/design/foundations/`](docs/design/foundations/README.md)。

| 类别 | 关键值（Light） | 说明 |
|------|----------------|------|
| 行动色 · 青雾（响应色） | `--brand-strong #478384` / `--brand #6FA3A4` / `--brand-tint #E9F0F0` / `--brand-ink #356263` | 深支扛白字填充（AA Large 4.3:1），亮支做点缀 |
| 结构色 · 墨蓝 | `--structural #14304D` | 沉浸头图 / 图表 / AI 助手 |
| 中性（暖灰） | `--bg #F7F6F5` `--surface #FFFFFF` `--fg #1C1B1A` `--border #D1CEC9` | 占 70–90% 像素 |
| 状态 | success `#1F8F57` · warn `#B26A12` · danger `#C23B33` | 仅表达状态语义 |
| 业务域（可生长） | 教务 `#3D7EA6` · 课表 `#6B5B95` · 资讯 `#C97D4A` · 邮箱 `#5C8C6E` · 财务 `#B85C6A` · 体育 `#8A6B3D` · 二课堂 `#6A8C5C` · 快捷 `#7A7A8C` | 已登记域使用稳定语义色；新增域通过评审扩展 token，不在运行时散列 |
| 字体 | `MiSans`（display+body）· 数字走等宽 mono | 沿用仓库已内置字体 |
| 圆角 | 控件 `10` · 输入 `12` · 卡片 `16` · 磁贴 `18` · 抽屉 `24` | 比 Fluent 更柔 |
| 阴影 | `e1` 卡片 / `e2` 浮起 / `e3` 抽屉 | 整体压低 |
| 动效 | `120 / 200 / 320ms` · `cubic-bezier(.33,0,.2,1)` | 状态、展开、路由三档；减少动态时收敛为零时长或淡入 |

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

- 组件可视化入口是 [`components/samples/`](docs/design/components/samples/) 下的逐组件亮/暗样例。
- 页面级可视化入口是 [`patterns/samples/app-shell.html`](docs/design/patterns/samples/app-shell.html)，覆盖七个主目的地；首个实现纵向切片仍是“导航壳 + 首页今日学程时间轨”。

---

## 6. Flutter 落地边界

- 迁移期允许现有 `FluentApp` 继续作为应用宿主，并通过 theme extension 注入 `YhTheme`；这不代表清源组件可以继承 Fluent 视觉控件。
- 清源组件可使用 `Focus`、`Actions`、`Shortcuts`、`MouseRegion`、`GestureDetector`、`Semantics`、`EditableText`、`CustomPaint` 等机械原语。
- 清源组件不得使用 Material / Cupertino / Fluent 的成品视觉控件来代替自身契约；图标统一经过清源图标门面，不直接使用 `Icons.*`。
- 旧页面与清源页面可按路由并存；完成一条纵向切片并通过回归后再迁移下一批，不建立两套业务状态。

---

## 7. 视觉签名

清源把“校园时间”作为唯一重点视觉签名：课程节次、待办、考试和刷新状态沿**今日学程时间轨**组织。墨蓝承担时间与结构，青雾只标记当前行动；其它页面保持安静，避免把渐变大卡、玻璃材质或无业务含义的装饰当作品牌。

---

## 8. 取代与废弃

- 旧 Fluent 2 设计系统（通信蓝 `#0F6CBD`、锐角、acrylic）整体废弃，仓库不保留其设计系统规范副本（如需可从 git 历史恢复）。
- 当前已发布实现仍基于 Fluent；清源在完成基础层、核心组件和首页纵向切片后按页面迁移。迁移完成前不删除兼容层。

变更记录见 [`docs/design/CHANGELOG.md`](docs/design/CHANGELOG.md)。
