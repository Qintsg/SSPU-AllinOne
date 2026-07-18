# 组件库 · Components

清源设计系统的组件层契约——每个组件给出解剖(anatomy)、状态、变体、token 映射、Flutter API、Do&Don't，并配一个亮/暗双主题的可交互样例。

> 行动色（响应色）：**`#478384`**（青雾深支）。所有视觉值走 token，不硬编码。

## 六大类 44 个组件

> 分类以总纲 [`DESIGN.md`](../../../DESIGN.md) 为准。

### 操作类 Actions（10）
**Button** · **IconButton** · **FAB** · **Segmented** · **Chip** · **Switch** · **Checkbox** · **Radio** · **Slider** · **Stepper**

### 输入类 Inputs（6）
**TextField** · **Search** · **Textarea** · **Select** · **DatePicker** · **OTP**

### 容器与反馈 Containers & Feedback（9）
**Card** · **Tile** · **ListItem** · **Accordion** · **Banner** · **Toast** · **Dialog** · **Skeleton** · **EmptyState**

### 导航类 Navigation（5）
**AppBar** · **BottomNav** · **NavRail** · **Tabs** · **Pagination**

### 数据展示类 Data Display（8）
**Badge** · **StatusPill** · **Avatar** · **MetricCard** · **Progress** · **Ring** · **FeedItem** · **SourceBadge**

### 校园域组件 Domain-specific（6）
**TodayCard** · **CourseBlock** · **AIMessage** · **BalanceModule** · **QuickLink** · **AttendanceItem**

## 阅读指南

1. **先读模板** [`_template.md`](./_template.md) — 了解每份组件规格的结构。
2. **看示范全规格** [`button.md`](./button.md) — 质量基线在此。
3. **打开可交互样例** [`samples/button.html`](./samples/button.html) — 真实视觉 + 全状态 + 亮/暗切换。
4. **按类浏览** — 每个组件都遵循模板结构，方便 agent 逐个实现。

## 样例约定（重要）

所有 `samples/*.html` 共享样式与脚本，自己只写组件标记；视觉值必须与机器真源 `../resources/tokens.json` 一致：

- [`samples/_qingyuan.css`](./samples/_qingyuan.css) — token（#478384）+ 全组件基础类 + 页面骨架，亮/暗双主题。
- [`samples/_qingyuan.js`](./samples/_qingyuan.js) — 主题切换（持久化 + 跟随系统）+ 通用交互（switch/check/radio/seg/chip/tab/stepper）。

样例文件头部固定两行引用，**禁止内联硬编码 hex**。全局换色先改 `tokens.json`，再生成或同步 `_qingyuan.css`：

```html
<link rel="stylesheet" href="_qingyuan.css" />
<!-- …组件标记… -->
<script src="_qingyuan.js"></script>
```

## 落地映射

所有组件走 **自建组件库** 策略（不继承 Material/Cupertino，原生 widget 仅作机械骨架）：

| 清源组件 | Flutter 实现骨架 | 说明 |
|---|---|---|
| `YhButton` | `FocusableActionDetector` + `GestureDetector` + 自绘容器 | 不继承 Material/Cupertino/Fluent 视觉控件 |
| `YhTextField` | `EditableText` + 自绘外壳 | 不用 Material `TextField` |
| `YhCard` | `Container` + token | 无依赖 |
| `YhAppBar` | 仅用布局槽位 | 视觉全自绘 |
| ... | ... | 设计系统即真源 |

迁移期主题通过 `YhTheme extends ThemeExtension<YhTheme>` 注入现有宿主，并由 `BuildContext` 扩展读取。组件不直接依赖宿主是 Fluent 还是未来的纯 Flutter 壳。

图标统一使用 `YhIcons` 门面。规格中的 `Icons.*` 旧示例在实现前必须替换，不构成允许直接依赖 Material 图标的例外。

---

**进度**：44 份规格与样例已建立；v0.3 开始先冻结基础契约，再按依赖顺序实现核心组件与首页纵向切片。
