# 校园卡查询规则探索

本文记录 issue #114 实现前对校园卡查询系统的只读探索结果，后续维护校园卡余额、状态和交易记录查询时以本文为约束。

## 入口与认证

- OA 校园卡入口为 `https://oa.sspu.edu.cn//interface/Entrance.jsp?id=xykxt`。
- 未认证访问 OA 入口时，会先跳转到 `https://oa.sspu.edu.cn/sso/login.jsp`，再跳转到 `https://id.sspu.edu.cn/cas/login`。
- OA 入口返回的门户页会通过脚本跳转到 `https://card.sspu.edu.cn?sysadmin=...`，随后由业务站点继续跳转到 `http://card.sspu.edu.cn/epay/`。
- 未认证访问校园卡业务入口时，会跳转到 CAS，`service` 为 `http://card.sspu.edu.cn/epay/j_spring_cas_security_check`。
- OA 入口中的 `{base64}Ly9pbnRlcmZhY2UvRW50cmFuY2UuanNwP2lkPXh5a3h0` 解码后为 `//interface/Entrance.jsp?id=xykxt`。
- 实现中复用已保存的 OA/CAS Cookie 会话；若会话失效，则调用现有 OA 登录校验刷新会话后重试校园卡入口。

## 页面与接口线索

- 已确认 `card.sspu.edu.cn/epay/` 和 `/epay/j_spring_cas_security_check` 属于校园卡 CAS 业务链路。
- 当前真实链路会从 `http://card.sspu.edu.cn/epay/...` 301 到 `https://card.sspu.edu.cn/epay/...`；业务页面与交易查询应使用 HTTPS，避免停在 301 空响应。
- 未认证请求无法确认业务页 DOM 结构；未认证访问任意候选业务路径都会先进入 CAS，因此不能仅凭跳转判断路径真实存在。
- 同类 `epay` 系统常见只读候选路径包括：
  - 余额 / 个人页：`/epay/myepay/index`
  - 交易记录页：`/epay/consume/index`
  - 交易查询接口：`/epay/consume/query`
- 交易查询接口在同类系统中可能返回 XML / CDATA 包裹的 HTML 表格，应用同时支持普通 HTML 和 XML / CDATA 表格解析。
- 已在真实登录态下确认当前交易记录表列包括 `创建时间`、`名称`、`交易号`、`对方`、`金额`、`明细`、`付款方式`、`状态`、`操作`；首页最近交易表可能缺少 `付款方式` 列。
- 已确认真实查询页使用 `AjaxAnywhere`，接口返回 `<zones><zone name="zone_show_box_1"><![CDATA[...]]></zone></zones>`；交易表可能把 `名称 | 交易号` 合并在同一列、把 `金额 | 明细` 合并在同一列，日期可能是 `yyyy.MM.dd` 加六位时间。
- `状态 / 操作` 是交易表列表列，不得被当作账户“卡状态”键值行；卡状态只能从明确的 `卡状态` / `账户状态` 字段解析。
- 交易查询接口需保留 `_csrf`、`pageNo`、`tabNo`、`pager.offset`、`starttime`、`endtime`、`timetype`、`tradename`、`_tradedirect` 等只读查询字段；真实默认页签为 `tabNo=1`，每页偏移为 `(pageNo - 1) * 10`。
- 详情页默认“最近”查询沿用交易页表单默认日期窗口；用户点击“最近”时清空输入框但请求层仍使用页面默认值。手动日期范围才覆盖 `starttime` / `endtime`。

## 刷新与展示策略

- 首页“校园卡余额”卡片默认不自动读取，避免进入主页即访问需要 OA 登录与校园网 / VPN 的受限服务。
- 卡片标题行展示上次刷新时间、刷新按钮、“交易记录查询”和右侧详情箭头。
- 首页“学籍信息”和“校园卡余额”在宽屏下左右排布；任一开关关闭时另一张卡片自适应占满宽度，窄屏下纵向堆叠。
- 设置页常规设置可分别隐藏“学籍信息卡片”和“校园卡余额卡片”，默认均显示。
- 设置页“自动刷新设置”可开启校园卡余额自动刷新并选择刷新间隔；开启后进入主页会主动读取一次。
- 每次读取前必须先执行校园网 / VPN 前置检测，检测不可达时不打开校园卡入口、不刷新 OA 会话。
- 首页成功态只展示账户余额；当页面明确返回的卡状态不是“正常 / 有效 / 可用”时，首页同步展示黄色短文本状态，不展示最近交易列表。
- 详情页展示账户概览和交易记录筛选 / 列表 / 分页。进入详情页后会自动查询系统默认最近交易；“最近”清空日期，“近7天 / 近30天”自动填入日期范围。

## 只读边界

- 当前能力只允许访问 OA/CAS 登录链路、校园卡余额页、交易记录页和交易记录查询接口。
- 不执行充值、支付、二维码付款、挂失、解挂、修改限额、提交订单、确认交易等任何写入或状态变更操作。
- 实现中将交易查询限制在明确的 `/epay/consume/query` 候选路径，禁止主动探测支付、充值或订单接口。
- UI、日志和文档不得展示 OA 密码、Cookie、CAS Ticket 或其它可直接复用的身份值。

## 未确认风险

- 登录后的实际业务页 DOM 结构、余额字段文案、卡状态字段和交易记录列顺序仍需在真实登录态下持续验证。
- `/epay/myepay/index`、`/epay/consume/index`、`/epay/consume/query` 是同类系统候选路径，SSPU 是否长期稳定支持需要后续真实环境确认。
- 若页面结构变化导致无法解析，应用应返回“页面结构异常”，不得伪造余额、状态或空成功结果。
