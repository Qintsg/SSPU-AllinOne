# 动效 Motion

清源动效追求 **干净、快速、功能性**——动画是为了传达状态变化，不是装饰。

## 时长

| 场景 | 时长 | 缓动 |
|---|---|---|
| 微交互（按钮 hover、复选框勾选） | `120ms` | `cubic-bezier(0.33,0,0.2,1)` |
| 页面内展开/收起（折叠面板、抽屉） | `200ms` | `cubic-bezier(0.33,0,0.2,1)` |
| 页面切换（路由转场） | `320ms` | `cubic-bezier(0.33,0,0.2,1)` |
| 加载占位符脉动 | `1500ms` | `ease-in-out` infinite |

## Flutter 映射

```dart
class YhDuration {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
}

class YhCurves {
  static const standard = Cubic(0.33, 0.0, 0.2, 1.0);
}
```

## 原则

- **优先用 opacity / transform**；避免 width / height 动画（触发重排）。
- 按钮 pressed 状态：`transform: scale(var(--pressed-scale))` + `120ms`，默认 `interaction.pressedScale = 0.98`，不用 translate 下沉（太重）。
- 页面转场：淡入 + 轻微上移 `translateY(8px → 0)`，不用左右滑（校园工具不是社交 App）。
- 骨架屏脉动：`opacity 0.5 ↔ 1` + `1500ms ease-in-out infinite`，背景用 `--c-muted`。
- 系统请求减少动态时，位移与缩放动画归零；必要反馈只保留不超过 `120ms` 的透明度变化。
