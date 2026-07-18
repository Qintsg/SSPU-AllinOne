# 阴影与高度 Elevation

清源使用 **低强度、暖调阴影**（oklch 灰 + 低 alpha），避免 Material / Fluent 的多层高光。

## 阴影阶

| Token | 值 | 用途 |
|---|---|---|
| `--e0` | `none` | 扁平表面（tile / inline card） |
| `--e1` | `0 1px 2px rgba(20,48,77,0.08)` | 悬浮卡片 hover |
| `--e2` | `0 2px 8px rgba(20,48,77,0.12)` | 下拉菜单、弹出层 |
| `--e3` | `0 4px 16px rgba(20,48,77,0.16)` | 对话框、抽屉 |
| `--e4` | `0 8px 32px rgba(20,48,77,0.2)` | 模态遮罩（极少用） |

暗色主题时，阴影改用 `rgba(0,0,0,0.4/0.5/0.6)` 避免不可见。

## Flutter 映射

```dart
class YhElevation {
  static const e0 = BoxShadow(color: Colors.transparent);
  static const e1 = BoxShadow(
    color: Color(0x14143041), // rgba(20,48,77,0.08)
    blurRadius: 2,
    offset: Offset(0, 1),
  );
  static const e2 = BoxShadow(
    color: Color(0x1F143041),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  // e3 / e4 同理
}
```

## 原则

- **默认扁平 e0**；hover 才加 e1；弹出层 e2。
- 不叠加多层阴影（Fluent acrylic 那套）——一个元素一个阴影值。
- 桌面端列表行 hover 可用 `background + e1`，移动端不加阴影（点击态用 pressed 背景）。
