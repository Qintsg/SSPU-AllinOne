# EmptyState 空状态

> 列表/搜索/收件箱为空时的友好占位——图标 + 标题 + 说明 + 可选行动，把"什么都没有"变成有指引的一屏。

## 概述

- **用途**：无数据 / 搜索无结果 / 首次使用引导 / 出错重试。
- **变体**：empty（暂无数据）/ no-result（搜索无果）/ first-use（引导创建）/ error（加载失败）。
- **关键状态**：static（可带行动按钮）。

---

## 解剖 Anatomy

```
            ▣              ← 图标徽（brand-tint 底 + 青雾图标）56×56
        暂无消息            ← 标题 b（--fg）
   新通知会出现在这里        ← 说明 p（--muted，≤2 行）
        [去订阅]            ← 行动按钮（可选）
```

**必需元素**：图标徽、标题。**可选**：说明、行动按钮。整体居中。

---

## 变体 Variants

| 变体 | 图标 / 文案侧重 | 行动 |
|---|---|---|
| **empty** | 空盒 / 铃铛 · "暂无数据" | 可省 |
| **no-result** | 放大镜 · "没有找到相关结果" | "清除筛选" |
| **first-use** | 加号 / 引导图 · "还没有内容" | "立即创建"（primary） |
| **error** | 警示 · "加载失败" | "重试" |

---

## 状态 States

静态展示。`first-use`/`error` 通常带行动按钮（primary）；`empty`/`no-result` 多为纯提示。

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-tint` | brandTint（图标底） | `#E9F0F0` | `#1E3233` |
| `--brand-strong` | brandStrong（图标） | `#478384` | `#5C9A9B` |
| `--fg` / `--muted` | fg / muted | `#1C1B1A` / `#6B6964` | `#E8E6E3` / `#9A9893` |

---

## Flutter API

```dart
class YhEmptyState extends StatelessWidget {
  const YhEmptyState({super.key, required this.icon, required this.title, this.message, this.action});
}
```

```dart
YhEmptyState(icon: YhIcons.notification, title: '暂无消息', message: '新通知会出现在这里');
YhEmptyState(icon: YhIcons.search, title: '没有找到相关结果', message: '换个关键词试试', action: YhButton(label: '清除筛选', variant: YhButtonVariant.text));
```

---

## Do & Don't

### ✅ Do
- 文案给出"接下来能做什么"，而非只说"空"。
- 图标用线性单色，配 brand-tint 底，克制。
- first-use/error 给明确行动按钮。

### ❌ Don't
- 用手绘小人/夸张插画（AI slop）。
- 文案消极（"你还没有任何东西"）——给指引而非指责。

---

## 可交互样例

[`samples/empty-state.html`](./samples/empty-state.html) — 暂无数据 / 搜索无果 / 引导创建。

## 无障碍 Accessibility

- 标题作为区域 `Semantics(header:true)`；图标 `excludeSemantics`（装饰性）；行动按钮可达。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
