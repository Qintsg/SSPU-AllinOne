# Data Model: 校园服务能力收敛

## ModulePreference

- `moduleId`: 稳定模块标识。
- `visible`: 首页卡片或摘要是否显示。
- `fetchEnabled`: 是否允许该模块访问远端校园服务。
- `order`: 首页摘要顺序；同一列表中唯一且连续。
- 状态转换：显示开关只改变布局；获取从开启变为关闭时，取消对应自动刷新和提醒计划。

## ProgramPlan

- `modules`: 培养模块列表。
- `courses`: 课程要求列表。
- `requiredCredits` / `earnedCredits`: 总要求与已完成学分。
- 校验：缺失字段保留未知状态，不推测学分或完成结论；来源只读。

## FreeClassroomQuery / FreeClassroomResult

- 查询：校区、日期、节次及可选教学楼。
- 结果：教室名称、教学楼、容量等来源可提供字段。
- 状态：等待条件 → 查询中 → 内容/空结果/登录失效/网络失败。
- 校验：开始条件必须完整有效；结果不包含预约动作。

## ReminderPlan

- `notificationId`: 稳定本地通知标识。
- `sourceType`: course / exam / message。
- `sourceId`: 来源事件稳定标识。
- `scheduledAt`: 带本地时区语义的投递时间。
- `title` / `body`: 隐私最小化通知文案。
- 状态：候选 → 已调度 → 已取消/已投递；同一来源和时刻只允许一个有效计划。

## EmailMessage / EmailAttachment

- 邮件：UID、主题、发件人、收件人、时间、正文摘要/正文、已读状态。
- 附件：文件名、媒体类型、大小、内容定位、本地路径与下载状态。
- 分页：按邮箱和账户维护最近 N 封窗口，合并时按 UID 去重，上限 100。
- 已读：本地打开后向支持 IMAP 标志的网关提交；失败不得伪造远端成功。
- 发送校验：附件必须存在、可读且满足大小约束；一次发送只提交一次。

## AcademicAgendaEntry

- `kind`: course / exam。
- `sourceId`: 课程或考试稳定标识。
- `title`, `startsAt`, `endsAt`, `location`, `description`。
- 校验：缺少可确定时间的记录不生成提醒或日历事件；本周/整学期视图共享同一事件集合。

## NotificationPermissionState

- `granted` / `denied` / `notRequired` / `unsupported` / `unknown`。
- 来源：当前平台系统通知适配器；查询异常只能降级为 `unknown`。
- 约束：`denied` 时不得保留已登记的教务提醒计划；`unknown` 不得被展示为已授权。

## CalendarExport

- `calendarName`: 导出日历名称。
- `entries`: 学术日程事件集合。
- `generatedAt`: 生成时刻。
- 校验：事件 UID 稳定；文本特殊字符正确转义；换行与行折叠符合交换格式；时间值不丢失时区语义。

## ConsumptionTrend

- `window`: all / last7Days / last30Days / custom。
- `granularity`: day / week / month。
- `points`: 时间桶、消费金额、交易数量。
- 校验：只聚合消费支出；重复记录只计一次；金额以最小货币单位计算；自定义起始日期不得晚于结束日期。

## WechatArticle

- `accountId`, `accountType`, `articleId`, `title`, `publishedAt`, `url`。
- `notificationIntent`: 来源是否允许通知。
- 去重：优先使用稳定文章身份，必要时使用规范化链接；公众号与服务号共享规则。
- 刷新状态：认证有效/失效、全成功/部分成功/失败；部分成功保留有效文章。

## VerificationEvidence

- `scope`: 功能与平台。
- `kind`: unit / widget / static / build / runner / device。
- `result`: passed / failed / pending。
- `commandOrScenario`, `observedAt`, `limitations`。
- 文档只有在相应 scope 存在足够证据时才能声明完成；设备/Runner 证据不能由不同平台的本地构建替代。
