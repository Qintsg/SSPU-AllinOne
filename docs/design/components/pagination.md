# Pagination 分页

> 长列表的翻页控制——上一页 / 页码 / 下一页，当前页青雾实心。桌面表格、搜索结果常用。

## 概述

- **用途**：分页浏览长数据集（成绩列表、搜索结果、表格）。
- **变体**：full（首尾 + 页码 + 省略号，默认）/ simple（仅上下页 + "第 x / n 页"）。
- **关键状态**：页码 rest / active；上下页到边界 disabled。

---

## 解剖 Anatomy

```
‹   1   2   3  …  12   ›
        ▣ active：青雾实心
首尾按钮到边界禁用
```

**必需元素**：上一页 / 下一页按钮、页码按钮（36×36，等宽数字）；页多时用省略号收纳。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **页码 rest** | 描边 + `--fg` |
| **页码 hover** | 边框 + 字转青雾 |
| **页码 active** | `--brand-strong` 实心 + 白字 |
| **prev/next disabled** | 不透明度 40%（到首/末页） |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | brandStrong（active） | `#478384` | `#5C9A9B` |
| `--on-brand` | onBrand | `#FFFFFF` | `#0A0D12` |
| `--border` | border | `#D1CEC9` | `#353A3F` |
| `--surface` | surface | `#FFFFFF` | `#1E2226` |

---

## Flutter API

```dart
class YhPagination extends StatelessWidget {
  const YhPagination({super.key, required this.page, required this.pageCount, required this.onChanged});
  // 自动计算省略号窗口（首页、末页、当前 ±1）。
}
```

```dart
YhPagination(page: p, pageCount: 12, onChanged: (n)=>load(n));
```

---

## Do & Don't

### ✅ Do
- 页多时用省略号只显示首/末 + 当前邻近页。
- 移动端优先用 simple（上下页 + 页码文本）或无限滚动。
- 等宽数字，页码切换不跳动。

### ❌ Don't
- 一次铺开几十个页码按钮。
- 当前页不高亮（用户迷失）。

---

## 可交互样例

[`samples/pagination.html`](./samples/pagination.html) — 点页码切换 active。

## 无障碍 Accessibility

- `Semantics(button:true, label:'第 N 页', selected: 当前)`；上下页带"上一页/下一页"标签，到边界 `enabled:false`。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
