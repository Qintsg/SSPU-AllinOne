# 间距 Spacing

清源使用 **4 基点间距阶**，覆盖组件内边距、外边距、栅格间隙。

## 间距阶

| Token | 值 | 用途 |
|---|---|---|
| `--sp-xs` | `4px` | icon 与文字间隙、chip 内边距 |
| `--sp-s` | `8px` | 列表行内边距、表单字段垂直间隙 |
| `--sp-m` | `16px` | 卡片内边距、按钮内边距、栅格间隙 |
| `--sp-l` | `24px` | section 间隙、页面内边距（移动） |
| `--sp-xl` | `32px` | 页面内边距（桌面）、大模块间距 |
| `--sp-2xl` | `48px` | 首屏顶部留白、特殊分区 |

## Flutter 映射

```dart
class YhSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
  static const xl2 = 48.0;
}
```

## 原则

- 组件间距优先 `m (16)` / `l (24)`，避免零散的 14 / 20。
- 移动端页面边距默认 `l (24)`；桌面端 `xl (32)`。
- 栅格列间隙默认 `m (16)`。
