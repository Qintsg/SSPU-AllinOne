# Toast 轻提示

> 操作后的瞬时反馈——浮于底部/顶部，短暂出现后自动消失。"已签到""已复制""已保存"。

## 概述

- **用途**：非阻断的瞬时操作反馈。
- **变体**：dark（中性深色，默认）/ brand（青雾）/ success（成功）。
- **关键状态**：enter（滑入）/ visible（~2s）/ exit（淡出）。

---

## 解剖 Anatomy

```
        ╭───────────────────────╮
        │ ✓  已签到成功          │  ← 图标 + 文本，胶囊 + 阴影
        ╰───────────────────────╯
        浮于内容之上，2 秒后自动淡出
```

**必需元素**：胶囊容器（圆角 10 + `shadow-2`）、文本。**可选**：前置状态图标、撤销链接。

---

## 变体 Variants

| 变体 | 底色 | 用途 |
|---|---|---|
| **dark** | `#2A2E33`（两主题一致）+ 白字 | 中性反馈（默认） |
| **brand** | `--brand-strong` + `--on-brand` | 与品牌行动关联的反馈 |
| **success** | `--success` + 白字 | 明确成功 |

---

## 状态 States

| 阶段 | 行为 |
|---|---|
| **enter** | 从边缘滑入 + 淡入（~200ms） |
| **visible** | 停留 ~2s（带撤销可延长） |
| **exit** | 淡出移除 |

> 与 Banner 区别：**Toast 瞬时自动消失、不可常驻**；持续提示用 Banner。

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| dark 底 | `toastBg` | `#2A2E33` | `#2A2E33` |
| `--brand-strong` | brandStrong | `#478384` | `#5C9A9B` |
| `--success` | success | `#1F8F57` | `#28C26B` |
| `--shadow-2` | elevation2 | `0 4 12 / 12%` | `0 4 12 / 50%` |

---

## Flutter API

```dart
YhToast.show(context, '已签到成功', kind: YhToastKind.success, duration: const Duration(seconds: 2));
YhToast.show(context, '链接已复制');
```

---

## Do & Don't

### ✅ Do
- 文案短（≤ 12 字），动词 + 结果（"已复制""已保存"）。
- 同一时刻只显示一个 Toast（排队，不堆叠）。
- 关键不可逆操作配"撤销"。

### ❌ Don't
- 用 Toast 承载需用户决策的内容（那是 Dialog）。
- 持续展示不消失（应改 Banner）。

---

## 可交互样例

[`samples/toast.html`](./samples/toast.html) — 三变体；点按钮触发滑入。

## 无障碍 Accessibility

- `Semantics(liveRegion:true)` 让读屏播报；停留时长足够阅读（短文 ≥ 2s）。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
