# 教务总览连续学程流评审 v03

<!--
  教务总览连续学程流的实现前自评审记录
  @Project : SSPU-AllinOne
  @File : 2026-08-19-academic-overview-flow-v03.md
  @Author : Qintsg
  @Date : 2026-08-19
-->

日期：2026-08-19  
分支：`feature/design-language-spec`  
状态：实现前冻结；后续按人工多尺寸审查，不计算 SSIM。

## 审查证据

- Windows 360×800 content 候选中，“学习进度，一处看全。”在刷新按钮旁换为“学习进度，一处看 / 全。”；末尾孤字既不利于扫读，也破坏标题的节奏。
- Windows 768×900、1200×900 与 1600×1000 content 候选中，“完成度”卡因同排“学习档案”的三条任务行而等高，右侧留下大面积无内容留白。
- 候选中“查看详细数据源”与“详细数据源”标题之间存在四个 `spacing.xl2` 的人为间隔，断开了本来连续的页内跳转与目标分区。

## 结论

采用 [`academic-overview-flow-v03.md`](../patterns/academic-overview-flow-v03.md)：窄屏使用完整短标题；中宽和宽屏保持横向关系但让事实卡以自然内容高度结束；来源跳转与目标区使用单一阅读间隔。

## 协同与异常复核

- 不删除“课程成绩”“考试安排”“课表与培养进度”、刷新或详细来源入口；操作锁定时原有禁用逻辑必须继续同时禁用刷新与详情导航。
- 初始、加载、空、错误、陈旧缓存、部分失败和凭据不足继续由既有状态面板承载，不能因内容压缩隐藏失败来源或原地重试。
- 360px 继续允许业务内容自然滚动；这不是主页首屏无滚动契约。所有可操作目标、键盘焦点与语义标签保持不变。
- 动效只保留既有入场与状态反馈，并尊重减少动态；本批不增加装饰性动画。

## 实施后核验要求

1. 新增窄屏完整标题、宽屏自然高度与来源连续间隔的公共行为回归。
2. 运行教务定向测试、`flutter analyze --no-fatal-infos` 与设计原型门禁。
3. 重新采集四档亮暗教务总览 content，并抽检 partial-error 与 operation-locked，人工确认布局和协同不倒退。

## 实施后核验

| 项目 | 结果 |
| --- | --- |
| 教务回归 | `flutter test test/academic_page_test.dart`，60 项通过；新增窄屏完整标题、宽屏自然高度和连续来源分区回归。 |
| 浏览器参考 | `academic.overview` 前缀的四档亮暗 80 张参考图通过 Chromium 交互、焦点、触控目标与溢出核验。 |
| Windows 候选 | 重新采集 `academic.overview` 全部 10 个状态 × 四档视口 × 亮暗主题，共 80 张。 |
| 人工复核 | content 四档、360px partial-error / operation-locked 与 1200px credentials-required 均确认没有孤字标题、等高空卡或断裂的来源路径。 |
| 全量门禁 | `flutter test` 719 项通过、1,556 项按视觉采集开关跳过；Windows Release 构建成功；1544 张全量 Windows 候选与 144 份 sidecar 完整性校验通过。 |

本批未运行 SSIM；视觉结论来自固定截图、人审和行为回归。
