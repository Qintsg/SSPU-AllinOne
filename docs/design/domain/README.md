# 校园领域映射 Domain

领域文档连接业务语言与清源组件，不承载网络请求、缓存或凭据实现。

| 领域 | 稳定语义色 | 首选展示 |
|---|---|---|
| 教务 | `service.academic` | 成绩、培养方案、考试 |
| 课表 | `service.schedule` | 今日时间轨、课程块 |
| 资讯 | `service.news` | 来源徽标、信息流 |
| 邮箱 | `service.mail` | 收件箱、未读状态 |
| 财务 | `service.finance` | 余额、消费趋势 |
| 体育 | `service.sports` | 出勤、打卡状态 |
| 第二课堂 | `service.secondclass` | 学分进度 |
| 快捷入口 | `service.quicklink` | 外部资源与文档跳转 |

## 约束

- 域色用于来源识别，不表达成功、警告或失败；状态必须使用 `color.status`。
- 新增业务域时评审语义名称与亮暗主题颜色，并更新机器 token、文档和测试。
- 用户可见文案使用真实校园任务语言，不暴露 EAMS、缓存键或网络适配器等实现术语。
