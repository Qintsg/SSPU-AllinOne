# 动效 Motion

清源动效追求 **干净、快速、功能性**——动画是为了传达状态变化，不是装饰。

## 时长

| 场景 | 时长 | 缓动 |
|---|---|---|
| 微交互（按钮 hover、复选框勾选） | `150ms` | `ease-out` |
| 页面内展开/收起（折叠面板、抽屉） | `250ms` | `cubic-bezier(0.4,0,0.2,1)` |
| 页面切换（路由转场） | `300ms` | `cubic-bezier(0.4,0,0.2,1)` |
| 加载占位符脉动 | `1500ms` | `ease-in-out` infinite |

## Flutter 映射

```dart
class YhDuration {
  static const micro = Duration(milliseconds: 150);
  static const short = Duration(milliseconds: 250);
  static const medium = Duration(milliseconds: 300);
}

class YhCurves {
  static const easeOut = Curves.easeOut;
  static const standard = Cubic(0.4, 0.0, 0.2, 1.0); // Material standard
}
```

## 原则

- **优先用 opacity / transform**；避免 width / height 动画（触发重排）。
- 按钮 pressed 状态：`transform: scale(0.97)` + `150ms`，不用 translate 下沉（太重）。
- 页面转场：淡入 + 轻微上移 `translateY(8px → 0)`，不用左右滑（校园工具不是社交 App）。
- 骨架屏脉动：`opacity 0.5 ↔ 1` + `1500ms ease-in-out infinite`，背景用 `--c-muted`。
