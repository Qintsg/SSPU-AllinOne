# 关于页视觉与外部操作验收 v22

## 自评审

- [x] loading、content、error、external-confirmation、external-cancelled、external-error、operation-locked 七态完整覆盖。
- [x] 四档视口和亮暗主题共 56 张均保留标题、构建信息、法律/许可入口和返回路径。
- [x] 外部确认默认安全焦点、Tab 循环、Escape 取消、触发器焦点归还和打开互斥均已通过既有设计门禁。
- [x] 取消后的 Toast 在截图前清理；外部确认交互后恢复鼠标输入模式，静态图没有残留键盘焦点环。
- [x] 外部打开失败与操作锁定保留当前构建信息，不用空白页或通用错误卡替换有效内容。

## Flutter 实现验收

- 冻结参考：`build/design-review-settings-about-v22`，56 张。
- Windows 候选：`build/visual/windows-settings-about-v07`，56/56 逐图通过。
- 最低 SSIM `0.902140417`，对应 `settings.about--external-confirmation--light--360x800.png`。
- 对比报告：`build/visual-results/windows-settings-about-v07-vs-design-v22/report.json`。
