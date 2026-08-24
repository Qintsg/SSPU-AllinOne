# 邮件撰写连续表单与提交坞评审 v01

<!--
  邮件撰写连续表单与提交坞的设计自评审与实现前冻结记录
  @Project : SSPU-AllinOne
  @File : 2026-08-19-mail-compose-action-dock-v01.md
  @Author : Qintsg
  @Date : 2026-08-19
-->

日期：2026-08-19  
分支：`feature/design-language-spec`  
范围：`mail.compose` 的 initial/content/loading/error 四态及其四档亮暗视口  
结论：**通过，冻结后进入 Flutter 实现**

## 审查证据

- `build/visual/windows/mail.compose--content--light--360x800.png`：页面标题与卡内标题均为“撰写邮件”，而收件人至正文已超过首屏，发送操作仅出现在滚动末尾。
- `build/visual/windows/mail.compose--content--light--1600x1000.png`：桌面表单、双列地址字段及底部操作组均已按内容收束，不适合为移动问题新增全宽固定条。
- 既有 `EmailComposePanel` 只承载表单展示；发送互斥、地址解析、结果反馈和关闭状态都由 `EmailPage` 协调，适合将紧凑端提交坞放在页面框架层。

## 决定与边界

- 采用 [`mail-compose-action-dock-v01.md`](../patterns/mail-compose-action-dock-v01.md) 的连续表单与紧凑端提交坞。
- 删除卡内重复标题及冗余关闭图标；取消仍由清楚命名的次级按钮完成，发送仍为唯一主操作。
- 固定坞仅显示于撰写态的紧凑断点；宽屏不变，避免以解决窄屏问题为由增加桌面横向空白。
- 不修改 SMTP 服务、请求模型、地址格式、缓存、自动刷新、失败文案、路由或任何设置项。

## 实现后核验要求

1. 在 360/768 中验证提交坞始终位于内容滚动区外，且不会遮挡字段或底部导航。
2. 验证 1200/1600 没有提交坞，表单继续使用既有双列地址字段和内容高度。
3. 覆盖取消、发送、发送中禁用、错误保留、键盘焦点与语义。
4. 通过定向 Flutter 测试、`flutter analyze`、设计门禁和四档亮暗候选截图；按当前政策不计算 SSIM。

## 实现后核验

| 项目 | 结果 |
| --- | --- |
| Flutter 行为回归 | `test/email_page_test.dart` 18/18 通过；新增紧凑端滚动后提交坞可见、取消不发送，以及发送中字段与两个行动共同锁定。 |
| Flutter 候选 | `build/visual/windows-mail-compose-action-dock-v01`：32 张，覆盖 initial/content/loading/error、四档视口与亮暗主题。 |
| 人工逐屏审视 | 360×800 正文可继续滚动而取消/发送始终位于底部导航上方；768×900 无固定坞且表单与操作完整同屏；1200/1600 维持双列地址字段、内容高度和右下行动组。 |
| 异常恢复 | error 态在表单内保留失败反馈和输入上下文，提交坞不遮挡提示；loading 态的取消、发送和全部输入均禁用。 |
| 全量回归 | `flutter test --reporter compact`：711 项通过、1,556 个未启用采集环境的视觉用例按预期跳过。 |
| 静态与差异门禁 | `flutter analyze --no-fatal-infos`、清源设计契约、拆分样式表契约及 `git diff --check` 均通过。 |

本批没有引入新的服务调用、状态或设置项。固定坞只改变紧凑端既有操作的可达位置；正常动效沿用页面既有状态切换，减少动态时不额外运行位置过渡，避免表单输入期间的视觉跳动。
