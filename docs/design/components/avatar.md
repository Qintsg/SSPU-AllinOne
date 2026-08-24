# Avatar 头像

> 用户/实体的视觉标识——头像图或文字回退（姓氏首字）。三尺寸，圆形。

## 概述

- **用途**：用户头像、机构标识、列表前导。
- **变体**：image（图片）/ initial（文字回退）/ fill（青雾实心文字）。尺寸 sm / md / lg。
- **关键状态**：静态；可叠 Badge 红点。

---

## 解剖 Anatomy

```
 ◯饶    ◯王    ◯李
 sm 30  md 40  lg 56
 圆形 · 图片 cover / 文字回退居中
```

**必需元素**：圆形容器；图片（`object-fit:cover`）或文字回退（姓氏/首字母）。

---

## 变体 Variants

| 变体 | 视觉 | 用途 |
|---|---|---|
| **initial** | `--brand-tint` 底 + `--brand-ink` 字 | 无头像图时的默认回退 |
| **fill** | `--brand-strong` 实心 + 白字 | 需更强存在感（当前用户） |
| **image** | 裁切填充图片 | 有头像图 |

---

## 状态 States

静态。加载失败回退到 initial；可与 Badge 组合显示在线点/未读。

---

## Token 映射

| 设计 token | 亮色 | 暗色 |
|---|---|---|
| `--brand-tint` / `--brand-ink` | `#E9F0F0` / `#356263` | `#1E3233` / `#A8CFCF` |
| `--brand-strong` / `--on-brand` | `#478384` / `#FFFFFF` | `#5C9A9B` / `#0A0D12` |

尺寸：sm 30 / md 40 / lg 56；圆角 50%。

---

## Flutter API

```dart
class YhAvatar extends StatelessWidget {
  const YhAvatar({super.key, this.imageUrl, this.text, this.size = YhAvatarSize.md, this.fill = false});
  // imageUrl 优先；失败或为空回退到 text 首字。
}
```

```dart
YhAvatar(text: '饶', size: YhAvatarSize.lg);
YhAvatar(imageUrl: url, text: '王');   // 加载失败回退 '王'
```

---

## Do & Don't

### ✅ Do
- 无图时用姓氏/首字母回退，底色用 brand-tint。
- 列表内统一尺寸，左缘对齐。

### ❌ Don't
- 回退用随机彩色底（清源统一青雾系，保持克制）。
- 头像挤压变形（务必 `cover` 裁切）。

---

## 可交互样例

[`samples/avatar.html`](./samples/avatar.html) — 三尺寸 + 回退 + 叠 Badge。

## 无障碍 Accessibility

- 有意义头像 `Semantics(label:'$name 的头像')`；纯装饰回退可 `excludeSemantics`。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
