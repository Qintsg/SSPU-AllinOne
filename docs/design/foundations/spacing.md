# 间距 Spacing

清源使用 **4 基点间距阶**，覆盖组件内边距、外边距、栅格间隙。

## 间距阶

| Token | 值 | 用途 |
|---|---|---|
| `--sp-xs` | `4px` | icon 与文字间隙、chip 内边距 |
| `--sp-s` | `8px` | 列表行内边距、表单字段垂直间隙 |
| `--sp-m` | `12px` | 卡片内边距、按钮内边距 |
| `--sp-l` | `16px` | 卡片间隙、段落垂直间距 |
| `--sp-xl` | `24px` | section 间隙、页面内边距（移动） |
| `--sp-2xl` | `32px` | 页面内边距（桌面）、大模块间距 |
| `--sp-3xl` | `48px` | 首屏顶部留白、特殊分区 |

## Flutter 映射

```dart
class YhSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xl2 = 32.0;
  static const xl3 = 48.0;
}
```

## 原则

- 组件间距 **优先 l (16) / xl (24)**，避免零散的 14 / 20。
- 移动端页面边距默认 `xl (24)`；桌面端 `2xl (32)`。
- 栅格列间隙默认 `l (16)`。
