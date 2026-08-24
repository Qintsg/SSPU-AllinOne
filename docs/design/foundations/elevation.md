# 阴影与高度 Elevation

清源使用 **低强度、暖调阴影**（oklch 灰 + 低 alpha），避免 Material / Fluent 的多层高光。

## 阴影阶

| Token | 值 | 用途 |
|---|---|---|
| `--e0` | `none` | 扁平表面（tile / inline card） |
| `--e1` | `0 1px 3px rgba(0,0,0,0.08)` | 悬浮卡片 hover |
| `--e2` | `0 4px 12px rgba(0,0,0,0.12)` | 下拉菜单、弹出层 |
| `--e3` | `0 8px 28px rgba(0,0,0,0.16)` | 对话框、抽屉 |

暗色主题时，阴影改用 `rgba(0,0,0,0.4/0.5/0.6)` 避免不可见。

## Flutter 映射

```dart
class YhElevation {
  static const e0 = BoxShadow(color: Colors.transparent);
  static const e1 = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 3,
    offset: Offset(0, 1),
  );
  static const e2 = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
  // e3 同理
}
```

## 原则

- **默认扁平 e0**；hover 才加 e1；弹出层 e2。
- 不叠加多层阴影（Fluent acrylic 那套）——一个元素一个阴影值。
- 桌面端列表行 hover 可用 `background + e1`，移动端不加阴影（点击态用 pressed 背景）。
