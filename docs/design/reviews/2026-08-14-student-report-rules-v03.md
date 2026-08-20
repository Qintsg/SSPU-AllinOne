# 第二课堂积分规则页 v03 自评审

## 评审范围

- 页面：`academic.student-report-rules`
- 状态：`content`、`empty`
- 主题：亮色、暗色
- 尺寸：360×800、768×900、1200×900、1600×1000
- 证据：`build/design-review-student-report-rules-v03`

## 结论

16 张参考稿全部通过浏览器结构门禁和目视评审，可以冻结并进入 Flutter 实现。

## 主要判断

- 360×800：总差额在首屏可见；类别合并为一个连续账本，没有横向滚动、重复卡框或过大间距。
- 768×900：总分、差额和类别选择不再相互挤压；左侧导航与右侧优先补齐明细形成清楚的主从关系。
- 1200×900、1600×1000：内容宽度受阅读上限约束，卡片内部没有为了填满页面而制造大片空白。
- 暗色：第二课堂色、成功色、正文和分隔线层级可辨；状态同时由文字表达，不依赖颜色。
- 空态：标题、来源、返回成绩单和恢复说明均保留；没有占满屏幕的图标或重复恢复按钮。
- 交互：类别选择为互斥语义，支持点击、Tab、Enter/Space 与方向键；初始定位第一个未完成类别。
- 动效：只在宽屏类别切换时使用一次淡入与 4dp 位移；减少动态时持续时间与位移归零。

## 冻结决定

- 冻结版本：`student-report-rules-v03`
- 冻结基线：`build/design-review-student-report-rules-v03`
- Flutter 实现必须保留真实规则、缺失字段说明和统一返回路径。
- 若实现暴露新的业务状态，先补本设计与评审记录，再修改 Flutter。

## 实现复核

- Flutter 证据：`build/visual/windows-student-report-rules-v09`
- 差异报告：`build/visual-results/student-report-rules-v09/report.json`
- 结果：16/16 逐图达到 SSIM 0.90，最低为暗色 768×900 的 `0.9015571132723125`。
- 行为测试：窄屏连续账本、767dp 断点、宽屏未完成类别优先、原位切换、空态返回、缺失字段保护、方向键与减少动态均已覆盖。
- 工程回归：`flutter analyze` 零问题，设计系统门禁通过，全量 `flutter test` 670 项通过，Windows Release 构建通过。
- 平台边界：本记录只证明 Windows；Android、iOS、macOS、Linux 由对应 CI runner 继续验证。
