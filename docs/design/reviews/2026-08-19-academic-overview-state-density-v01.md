# 教务总览恢复状态密度评审 v01

<!--
  教务总览恢复状态密度的实现前自评审记录
  @Project : SSPU-AllinOne
  @File : 2026-08-19-academic-overview-state-density-v01.md
  @Author : Qintsg
  @Date : 2026-08-19
-->

日期：2026-08-19  
分支：`feature/design-language-spec`  
状态：实现前冻结；采用人工多尺寸与操作协同核验，跳过 SSIM。

## 问题证据

- Windows 1200×900 `academic.overview/credentials-required` 候选显示少量认证说明与一个行动，但外层卡片几乎占满页面内容宽度并被 `popoverWidth` 最小高度拉高。
- 同一状态下详细数据源仍是有效的诊断与恢复上下文；大空卡令两个连续分区显得互不相关。
- 窄屏 partial-error 与 operation-locked 已证明状态横幅可以在不牺牲恢复文案的情况下保持紧凑；无内容状态应遵循同样的内容高度原则，但保留单独的主行动分组。

## 评审结论

采用 [`academic-overview-state-density-v01.md`](../patterns/academic-overview-state-density-v01.md) 的左锚定、自然内容高度恢复面板。否决删除卡片和仅缩小大卡两种方案，避免损失行动层级或保留无意义宽边界。

## 协同与稿外情形检查

- 凭据不足、服务错误、无数据、首次读取、后台恢复与协同刷新都保留明确动作或实时反馈；不以空白替代失败说明。
- 凭据不足状态的账户连接、错误状态的重试、空状态的学期调整仍只调用既有回调；不会新增校园服务请求。
- 操作锁定的 `liveRegion`、重复刷新与详情导航禁用、详细数据源的焦点转移/焦点归还不变。
- 宽屏面板的自然结束不是内容缺失：它后面的背景和详细来源标题有真实阅读关系，不新增装饰卡片。

## 实施后核验要求

1. 添加 1200px 凭据不足状态的面板宽度与自然高度回归，并保留现有回调行为测试。
2. 运行教务回归、静态分析和原型浏览器门禁。
3. 重新采集总览 80 张 Windows 候选；人工检查四档亮暗的无内容状态及 360px operation-locked。

## 实施后核验

- 新增 1200px 凭据不足状态回归：面板宽度从旧版 1104dp 收束为不超过 `layout.formContentWidth` 的 560dp，真实内容高度为 295dp，账户连接行动仍可用。
- `flutter test test/academic_page_test.dart` 的 60 项教务回归，以及全量 `flutter test` 的 719 项回归均通过（1,556 项视觉采集用例按开关跳过）；`flutter analyze --no-fatal-infos`、设计系统与样式门禁通过。
- 浏览器原型与 Windows Flutter 候选均重新生成 `academic.overview` 的 80 张四档亮暗截图；抽检 1200px 凭据不足、768px loading 与 360px error 后确认恢复说明、唯一行动和详细来源连续可达。
- Windows Release 基于当前源码构建成功；`1544` 张全量 Windows 候选与 `144` 份 sidecar 通过文件名、尺寸和边界完整性校验。本批按当前项目政策跳过 SSIM，未用重录候选替代设计评审。
