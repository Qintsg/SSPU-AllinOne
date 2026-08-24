# 设置恢复状态密度 v03

## 自评审

- [x] 三个页面全部覆盖 360×800、768×900、1200×900、1600×1000 和亮暗主题。
- [x] data/privacy 的 content/loading/error 共 24 张均使用同一三行任务账本。
- [x] update 与 wechat 的 initial/loading/content/error 共 64 张状态语义互不混用。
- [x] 1200/1600 的任务卡按内容高度收束，删除原先卡片下半部大片无任务空白。
- [x] 360/768 保持自然滚动；按钮不拉满任务行，主动作仍满足 48dp。
- [x] loading 保留页面与输入，禁用重复动作；update 主动作同步显示“检查中”。
- [x] error 保留完成结果并在原行提供查看、重试、重新认证或重新校验。
- [x] content 动作均使用用户可理解的具体动词，没有通用“打开”占位。
- [x] 更新结果作为账本内摘要出现，不新增重复卡片或无关装饰。
- [x] 微信 initial 与其他状态共享标题、来源和主要动作位置，切换时不产生结构跳跃。
- [x] 视觉特征来自“可恢复的本机任务账本”，没有采用通用仪表盘或大数字装饰。

## 迭代记录

- v01 只收紧 loading/error 卡片，但 initial 仍有过大空白，未冻结。
- v02 收紧 initial，却仍使用通用“打开”动作，未冻结。
- v03 补齐真实行项目、动作和更新结果后冻结。

Flutter 实现必须在本记录冻结后开始；后续若调整卡片、按钮、设置项、状态文案或恢复行为，需要新设计版本和新评审记录。

## Flutter 实现验收

- Windows 数据与隐私：`build/visual/windows-settings-recovery-data-v04`，24/24 逐图通过，最低 SSIM `0.943977797`；报告位于 `build/visual-results/windows-settings-recovery-data-v04/report.json`。
- Windows 应用更新：`build/visual/windows-settings-recovery-update-v04`，32/32 逐图通过，最低 SSIM `0.941961427`；报告位于 `build/visual-results/windows-settings-recovery-update-v04/report.json`。
- Windows 微信认证：`build/visual/windows-settings-recovery-wechat-v04`，32/32 逐图通过，最低 SSIM `0.940990486`；报告位于 `build/visual-results/windows-settings-recovery-wechat-v04/report.json`。
- 360×800 的横幅、任务行、动作按钮和底部导航已人工复核：状态文本不再占用过高空间，任务动作仍保持 48dp 目标，最后一行可通过自然滚动到达。
- 相关 31 项页面行为测试通过，覆盖初始、加载、失败、恢复、重复操作互斥和旧请求隔离；应用更新新增 360 宽度账本回归断言。
