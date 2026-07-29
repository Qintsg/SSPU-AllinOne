# 次级任务页框架

`YhTaskPage` 统一承载设置、更新、认证等次级任务的页面层级，不属于 44 个原子组件清单。

## 页面契约

- 顶栏保持返回、上下文眉题、确定性来源和最多一个“更多操作”。
- 正文依次展示场景眉题、任务标题、必要说明、一个主要行动、来源条和任务内容。
- compact 使用 `16dp` 页面边距并把主要行动铺满；medium 以上使用流式 `4vw` 边距，限制在 `24–48dp`。
- 需要在紧凑端连续排列“筛选—指标—原始证据”的账本页可显式选择 `YhTaskPageRhythm.relaxedCompact`；默认节奏不得随单页视觉调整而改变。
- 阅读与表单正文默认居中并限制为 `layout.pageContentWidth`，避免 1600px 视口出现超长阅读行。
- 数据表、任务账本等结构化面板可使用 `YhTaskPageWidth.fluid` 占满流式页面区；长文本仍由行内内容约束控制阅读长度。
- 页面内容可滚动，来源与主要行动不能因为 loading、empty 或 error 状态消失。
- `更多操作` 必须提供来源信息和可关闭抽屉；不得成为无行为的视觉占位。
- 从“更多操作”进入对话框或下一任务时，先关闭抽屉并把稳定焦点归还页首触发器；取消对话框后仍回到该触发器。
- 互斥操作期间可传入 `canPop: false`，同时禁用顶栏返回和系统返回；操作结束后必须恢复。

## Flutter 接口

```dart
YhTaskPage(
  title: '外观',
  kicker: '设置',
  summary: '跟随系统、亮色和暗色即时生效，并保持相同信息层级。',
  source: '本机外观设置',
  sourceSymbol: '设',
  primaryActionLabel: '应用主题',
  onPrimaryAction: applyTheme,
  body: appearancePanel,
)
```

页面只传语义内容与回调；间距、圆角、断点、排版和来源条视觉均由清源 token 决定。
