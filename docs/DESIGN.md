# SSPU-AllinOne 设计文档

> 版本：v0.2.5-alpha | 最后更新：2026-05-18

---

## 1. 项目概述

### 1.1 项目定位

SSPU-AllinOne 是面向上海第二工业大学（SSPU）师生的校园综合服务应用。目标是将分散在多个官网、微信公众号、教务系统中的校园信息和服务聚合到一个客户端中，提供统一、高效的使用体验。

### 1.2 核心原则

- **数据本地化**：所有用户数据仅保留在设备本地，不上传至任何云端服务
- **全平台覆盖**：基于 Flutter 构建，支持 Android、iOS、macOS、Linux、Windows、Web 六大平台
- **Fluent 2 设计语言**：采用 Fluent 2 令牌、主题扩展与响应式导航，提供现代、一致的视觉体验

### 1.3 技术选型

| 层级 | 技术 | 版本约束 | 说明 |
|------|------|----------|------|
| 框架 | Flutter | >= 3.44.0 | 跨平台 UI 框架 |
| 语言 | Dart | ^3.12.0 | 随 Flutter SDK 绑定 |
| UI 体系 | `fluent_ui` + `fluentui_system_icons` | `fluent_ui ^4.15.1` / `fluentui_system_icons ^1.1.273` / 项目内 `lib/design/` | Flutter 框架承载运行时，可见 Fluent 控件与系统图标来自外部 Fluent 包，项目内保留语义 facade、兼容 token 与业务组合组件 |
| 本地存储 | shared_preferences / path_provider | ^2.5.3 / ^2.1.5 | 键值迁移与平台应用目录解析 |
| 加密 | crypto / flutter_secure_storage | ^3.0.6 / ^8.1.0 | 应用锁密码哈希与可解密凭据安全存储 |
| 系统认证 | local_auth | ^3.0.1 | 可选系统快速验证，作为应用锁密码的本机认证辅助入口 |
| 网络请求 | dio | ^5.8.0+1 | 官网与公众号平台 HTTP 抓取 |
| 本地打开 | open_filex | ^4.7.0 | 应用内更新校验通过后打开安装器、安装包或所在文件夹 |
| 邮箱协议 | enough_mail | ^2.1.7 | 学校邮箱 IMAP / POP 只读收信、SMTP 登录校验与用户主动发信 |
| PDF 查看 / 解析 | pdfrx / pdfrx_engine | ^2.4.3 / ^0.4.2 | 校历原始 PDF 应用内查看与 PDF 文本抽取 |
| 桌面集成 | window_manager / tray_manager | ^0.5.1 / ^0.5.3 | 桌面窗口控制、macOS 原生红绿灯按钮与系统托盘 |
| Windows WebView | flutter_inappwebview | ^6.1.5 | 文章页与公众号平台登录页 |
| 应用信息 | package_info_plus | ^10.1.0 | 运行时版本号与构建号读取 |
| 代码规范 | flutter_lints | ^6.0.0 | Dart 推荐 lint 规则集 |

---

## 2. 应用架构

### 2.1 整体结构

```
┌─────────────────────────────────────────────────────────────┐
│                          main.dart                           │
│ WebView2 / Storage / Tray / Notification / AutoRefresh 初始化 │
├─────────────────────────────────────────────────────────────┤
│                         SSPUApp                              │
│          协议确认 / 密码保护 / 窗口关闭拦截 / 托盘监听        │
├─────────────────────────────────────────────────────────────┤
│                         AppShell                             │
│       Fluent Adaptive Navigation + Bottom Navigation         │
├─────────────┬─────────────┬─────────────┬─────────────┬─────────────┬─────┤
│  HomePage   │ AcademicPage│ CourseSchedule │  InfoPage   │QuickLinks   │ ... │
│  最新消息    │ 教务摘要页   │ 独立课程表页    │ 官网/微信聚合 │ YAML 快捷跳转 │     │
├─────────────┴─────────────┴─────────────┴─────────────┴─────────────┴─────┤
│ Services: Password / MessageState / CampusNetwork / Wxmp /  │
│ InfoRefresh / AutoRefresh / Notification / Storage / AppInfo│
└─────────────────────────────────────────────────────────────┘
```

### 2.2 分层说明

| 层级 | 目录 | 职责 |
|------|------|------|
| 入口层 | `lib/main.dart` | 平台能力初始化、Flutter 应用入口与主题配置、协议确认 / 密码 / 托盘生命周期 |
| 导航层 | `lib/app.dart` | Fluent 主题下的自适应导航、移动端底部导航、页面切换容器 |
| 页面层 | `lib/pages/` | 主页、教务、信息中心、设置、关于、登录 WebView 等页面 |
| 组件层 | `lib/widgets/`、`lib/design/components/` | Fluent surface、设置分区、消息项、频道列表、响应式布局等可复用 UI |
| 控制层 | `lib/controllers/` | 复杂分区状态协调，当前主要用于微信推文设置 |
| 服务层 | `lib/services/` | 状态持久化、抓取、自动刷新、通知、退出、应用信息等 |
| 模型 / 工具层 | `lib/models/`、`lib/utils/` | 消息模型、渠道配置、时间/匹配/WebView 环境工具 |

### 2.3 启动流程

```
应用启动
  │
  ▼
WidgetsFlutterBinding.ensureInitialized()
  │
  ▼
平台能力初始化
  ├── Windows: WebView2 环境
  └── 桌面端 windowManager + TrayService
  │
  ▼
runApp(SSPUApp)
  │
_initApp()
  ├── StorageService.init()
  ├── 检查当前协议确认状态
  ├── 检查密码是否已设置
  └── 后台启动 NotificationService / AutoRefreshService
  │
  ├── 未同意当前协议 ──▶ 完整法律与隐私说明确认弹窗
  ├── 未设密码 ─────▶ AppShell（主界面）
  └── 已设密码 ─────▶ LockPage（锁定页）
                           │
                           ▼
                     PasswordService.verifyPassword()
                           │
                     ├── 正确 ──▶ AppShell
                     └── 错误 ──▶ 抖动动画 + 重试
```

---

## 3. 导航系统

### 3.1 Fluent 视觉下的自适应导航结构

应用在紧凑宽度保留移动端底部 Fluent 导航，在中等、扩展和大屏宽度使用外部 `fluent_ui` `NavigationView` / `NavigationPane`，保持桌面、平板与移动端的导航层级一致。

| 导航项 | 图标 | 位置 | 对应页面 |
|--------|------|------|----------|
| 主页 | `FluentIcons.home` | 主区域 | `HomePage` |
| 教务中心 | `FluentIcons.education` | 主区域 | `AcademicPage` |
| 课程表 | `FluentIcons.calendar` | 主区域 | `CourseSchedulePage` |
| 信息中心 | `FluentIcons.info` / `FluentIcons.infoSolid` | 主区域 | `InfoPage` |
| 学校邮箱 | `FluentIcons.mail` | 主区域 | `EmailPage` |
| 快速跳转 | `FluentIcons.link` | 主区域 | `QuickLinksPage` |
| 设置 | `FluentIcons.settings` | 次级区域 | `SettingsPage`（含关于分区） |

应用桌面 / 平板侧边导航在“设置”上方显示校园网 / VPN 状态徽标，启动后自动检测一次，点击徽标可重新检测。当前默认通过只读访问 `https://tygl.sspu.edu.cn/` 判断校园受限资源是否可达。“关于”不再作为一级导航项，版本、许可证、隐私说明和第三方依赖信息并入设置页关于分区。

### 3.2 显示模式

桌面布局按响应式 window size class 切换导航形态，移动端使用底部导航栏：

- **Compact**（< 600px）：底部 Fluent 导航
- **Medium**（600–840px）：`NavigationPane` compact 模式
- **Expanded**（840–1200px）：`NavigationPane` compact 模式
- **Large / Extra large**（>= 1200px）：`NavigationPane` expanded 模式

### 3.3 页面切换动画

所有主页面切换使用统一主题下的导航容器选中状态切换；手机底部导航通过 `KeyedSubtree` 强制刷新当前页，保持切换后的内容状态与动画一致。

### 3.4 Fluent 2 surface 与微动效

主导航页面统一使用 Fluent surface 与共享设计 token 承载核心内容区。组件集中处理浅色 / 深色背景、描边、圆角、阴影、悬停高亮和按压缩放反馈，避免页面各自硬编码视觉状态。页面入场动画继续使用 `flutter_animate` 的淡入与轻微纵向位移，并通过共享 motion token 对多张卡片做错峰入场。

---

## 4. 页面设计

### 4.1 主页（HomePage）

**文件**：`lib/pages/home_page.dart`

**当前状态**：已实现

**已实现功能**：
- 校园仪表盘顶部概览
- 今日课程、学籍信息、校园卡余额、体育考勤、第二课堂、最新消息、邮箱摘要和快速跳转磁贴
- 首页磁贴显隐设置，学籍信息和校园卡余额沿用既有显隐键，其它磁贴使用独立显隐键
- 最新消息本地读取与排序，点击消息后标记已读并打开内嵌 WebView
- 校园卡余额手动刷新使用统一 3 秒短反馈，静默刷新失败保留旧缓存

**UI 结构**：
- `FluentPage.scrollable` 作为页面容器
- `FluentPageHeader` 显示页面标题
- `FluentContentWidth` 封顶内容宽度，顶部 `FluentMaterialSurface` 承载校园概览
- 业务磁贴使用 `FluentDashboardTile` 的五态结构：未配置、加载、就绪、降级、失败
- 桌面端多列 dashboard 网格，移动端单列紧凑磁贴

### 4.2 教务中心（AcademicPage）

**文件**：`lib/pages/academic_page.dart`

**当前状态**：已接入多套真实只读教务服务

**当前状态说明**：已接入体育部考勤、第二课堂学分和本专科教务摘要三类只读服务。受限服务查询前统一执行校园网 / VPN 前置检测，不可达时不提交密码、不刷新 OA 会话；教学评价等写入型功能保持关闭。

**UI Refresh 2026 行为**：教务中心使用宽屏两栏 / 中屏双列 / 窄屏单列布局，三类业务卡片通过业务域强调色、图标容器和指标行统一视觉层级。卡片自动刷新、静默刷新失败保留旧内容、手动刷新成功 / 失败 3 秒短反馈由 `CardAutoRefreshController` 统一管理。

### 4.2.1 课程表页面（CourseSchedulePage）

**文件**：`lib/pages/course_schedule_page.dart`

**当前状态**：已实现独立课程表页

**已实现能力**：作为主导航独立页面展示当前学期课表，复用本专科教务自动刷新配置，并在凭据、校园网 / VPN 或课表不可用时显示明确状态。页面仅展示课程名称、时间、地点、教师和周次，不提供选课、退课、调课等写入入口。

**UI 结构**：宽 / 中屏使用周网格视图，窄屏使用今日 + 单日切换视图。网格内置教务处作息时间节次，课程块按课程名稳定分配课程色板颜色，当前日 / 当前节次高亮，冲突课程并排显示。

课程表页标题命令区提供“校历”入口，进入独立校历页。命令区使用可换行布局，移动端窄屏时“返回 / 校历 / 刷新课表”按钮可自动换行，避免标题栏溢出。

### 4.2.2 校历页面（AcademicCalendarPage）

**文件**：`lib/pages/academic_calendar_page.dart`

**当前状态**：已实现教务处校历缓存、结构化解析和原始 PDF 查看。

**数据来源**：校历服务访问 `https://jwc.sspu.edu.cn/xl/list.htm`，该入口无需校园网 / VPN。列表解析仅处理 2021 年及以后的可识别学年，详情页按 PDF 播放器、正文 PDF 链接、正文图片的优先级提取资源。

**缓存策略**：结构化结果写入统一 `StorageService` 集合，key 为学年起始年份；桌面端和移动端会将 PDF 与抽取文本保存到 `.sspu-aio/academic_calendars/pdf/` 与 `.sspu-aio/academic_calendars/text/`。Web 端无法写本地文件时仅保留 URL 与结构化缓存。进入校历页、课程表相关学期定位或设置页读取生效学期时，会优先读取本地缓存，缺少当前学年或 7/8 月临近下一学年时自动抓取。解析版本变化或旧缓存过期时会刷新并覆盖同学年缓存。

**结构化结果**：秋季 / 春季学期按官网文本中的开始日期推导 17 周范围，夏季学期按 PDF 文本中的实际教学段日期生成不连续教学段，支持 2+3 或 3+2 等不同结构。仅对文本明确给出日期的内容生成日期标签，例如运动会停课日；“另行通知”类节假日说明只保留原文，不推断具体日期。

**失败回退**：列表、详情、PDF 下载或文本解析失败不会阻断应用启动、课程表页或设置页。有旧缓存时继续使用旧缓存并标记可能过期；无结构化数据时页面仍展示标题、详情链接、PDF 或图片资源，并提供“提交 issue”反馈入口。

### 4.3 信息中心（InfoPage）

**文件**：`lib/pages/info_page.dart`

**当前状态**：核心页面已实现

**已实现能力**：
- 官网 / 职能部门 / 教学单位 / 微信推文聚合
- 搜索、来源类型、来源名称、分类、未读筛选
- 分页浏览、全部标已读
- 官网消息刷新与微信推文刷新
- 刷新进度条与单例刷新状态保持
- 本地缓存持久化与已读状态管理
- 设置页仅展示已接入抓取链路的渠道；微信服务号历史枚举仅用于旧缓存兼容，不作为可开启入口

**UI 结构**：桌面 / 平板端将全部标为已读、刷新官网消息和刷新微信推文放入“信息中心”标题行命令区，筛选区升级为可折叠面板并展示 active filter chips；消息列表和空状态使用独立 surface，减少非内容区域占高。分页器支持键盘左右翻页。

**移动端适配**：Compact 宽度下使用搜索优先的单行图标操作区，次级筛选收进 Fluent 底部抽屉，页面主体保留当前筛选摘要；分页固定为上一页 / 当前页状态 / 下一页单行结构，优先保证消息列表首屏可视高度。

### 4.4 快速跳转（QuickLinksPage）

**文件**：`lib/pages/quick_links_page.dart`

**当前状态**：已实现

**已实现能力**：
- 从 `assets/config/quick_links.yaml` 读取分组链接
- 支持快捷入口名称、URL 与校园服务意图搜索
- 支持常用入口标记，首页仪表盘优先展示常用入口
- 桌面端支持 `Ctrl+K` / `Meta+K` 聚焦搜索
- 按设备宽度响应式布局磁贴
- 根据名称自动推断图标与强调色
- 点击后通过默认浏览器打开外部链接

**UI 结构**：搜索框和最佳匹配入口合并为一个操作 surface；链接磁贴使用可点击 Fluent surface，悬停时显示强调色边框、柔和背景和阴影提升。

### 4.4.1 学校邮箱（EmailPage）

**文件**：`lib/pages/email_page.dart`

**当前状态**：已实现只读收信、协议校验与 SMTP 主动发信

**已实现能力**：使用学工号派生学校邮箱账号，通过 IMAP / POP 只读读取最近邮件，并通过 SMTP 校验登录状态和用户主动发送普通文本邮件。页面展示标题、发件人、时间、正文摘要和正文快照；发信表单支持 To / Cc / Bcc / 主题 / 正文，不提供附件、草稿、自动发送、后台重试、回复、转发、删除、移动、标记已读或修改文件夹入口。

**UI 结构**：宽屏左侧放账户说明、撰写面板和协议操作，右侧使用列表 + 详情双栏；窄屏按说明、撰写、协议、列表顺序纵向堆叠并进入详情页。撰写面板使用紧凑表单和内联结果，发送成功或失败同时显示自动收回的小型反馈。邮件行展示发件人锚点、时间、未读状态和正文摘要。

### 4.5 设置页（SettingsPage）

**文件**：`lib/pages/settings_page.dart`

**当前状态**：已实现多分区设置页

**功能模块**：

#### 4.5.1 常规设置

- **关闭按钮行为**：支持每次询问 / 最小化到托盘 / 直接退出
- **消息推送总开关**：控制自动刷新后的桌面通知
- **勿扰时段**：设置开始/结束时间，通知服务按时间窗静默

#### 4.5.2 学期设置

提供全局学期设置，作为课表、成绩、考试、第二课堂等后续详情页的统一默认查询上下文。用户只选择 `YYYY-YYYY 学年 + 秋季 / 春季 / 夏季学期`，当前日期所在学期和周数由官网校历缓存优先、内置校历兜底按周一自动计算，不再暴露手动周数输入。若用户选择非当前日期所在学期，设置页仍展示当前日期实际学期状态，并单独显示“查询使用”的所选学期。内置日期定位覆盖 2023-2024 至 2026-2027 学年；2023 年以前官网已知学期保留为可选择项，但会提示暂无日期定位，供后续课程表等功能按“不可定位”状态降级。夏季学期视为一个长学期，教学段逐年内置或解析，允许 3+2 或 2+3 等不同结构，中间非教学区间显示为暑假；其它未落在教学段或夏季长范围内的区间显示为寒假。

#### 4.5.3 自动刷新设置

集中配置校园网 / VPN 状态检测、体育查询、校园卡余额、学校邮箱、第二课堂学分和本专科教务的自动刷新开关与间隔。默认不自动访问受限服务，关闭后仍可在对应页面手动刷新；职能部门、教学单位、微信推文保留快捷入口跳转到对应设置面板。

#### 4.5.4 安全设置

- **密码保护**：支持启用、移除、修改密码、立即上锁和系统快速验证兜底提示
- **教务凭据**：保存学工号、OA 密码、体育部查询密码和邮箱密码；学校邮箱账号固定由学工号派生
- **数据清理**：支持清理信息中心缓存或清除所有本地数据

#### 4.5.5 首页显示设置

常规分区提供首页磁贴显隐控制：今日课程、学籍信息、校园卡余额、体育考勤、第二课堂、最新消息、邮箱摘要和快速跳转。全部隐藏时首页显示空状态并引导回设置页。

#### 4.5.6 消息推送设置

- **职能部门**：按渠道分组展示开关、刷新间隔、分类开关
- **教学单位**：按学院 / 中心分组管理抓取与筛选
- **微信推文**：公众号平台认证、刷新配置、SSPU 微信矩阵关注与单号开关

### 4.6 关于页（AboutPage）

**文件**：`lib/pages/about_page.dart`

**当前状态**：作为设置页关于分区实现

**已实现能力**：
- 运行时读取 `PackageInfo` 展示版本号
- 展示作者与许可证
- 提供 GitHub 仓库与完整法律与隐私说明入口
- 展示当前项目许可证和主要第三方组件列表

### 4.7 锁定页（LockPage）

**文件**：`lib/pages/lock_page.dart`

**当前状态**：已完整实现

**设计参考**：1Password 锁定页面

**功能细节**：

| 特性 | 实现方式 |
|------|----------|
| 密码输入 | `TextField(obscureText: true)`，按平台保留标准文本输入行为 |
| 自动聚焦 | `WidgetsBinding.addPostFrameCallback` 延迟请求焦点 |
| 回车提交 | `onSubmitted` 回调直接触发验证 |
| 错误提示 | 密码框下方红色文本 |
| 抖动动画 | `TweenSequence` 5段水平偏移，500ms，`easeInOut` 曲线 |
| 加载状态 | 验证中按钮显示 `CircularProgressIndicator` 并禁用 |
| 错误恢复 | 密码错误后自动清空输入、重新聚焦 |
| 主题适配 | 根据 `Theme.of(context).colorScheme` 调整文字和状态色 |
| 系统快速验证 | 若用户启用且当前设备支持，进入锁定页后优先请求系统认证；失败、取消、超时或不可用时回到手动密码 |

**抖动动画序列**：

```
  0 → -10 → +10 → -10 → +10 → 0
  (权重: 1 : 2 : 2 : 2 : 1)
```

---

## 5. 密码保护系统

### 5.1 架构设计

密码保护系统由三个组件协同工作：

```
PasswordService（核心服务）
      │
      ├──▶ LockPage（验证入口）
      │
      ├──▶ SettingsPage（管理入口）
      │
      └──▶ SystemAuthService（可选系统认证封装）
```

### 5.2 PasswordService

**文件**：`lib/services/password_service.dart`

**存储机制**：
- 后端：native 平台使用统一 JSON 状态文件，Web 平台使用 `shared_preferences` 浏览器存储保存同一份 JSON 状态；浏览器存储不可用时退回内存态保证启动
- 键名：`app_password_hash`
- 系统快速验证配置键名：`app_quick_auth_enabled`
- 存储格式：SHA-256 哈希字符串（64 位十六进制）

**安全设计**：
- 明文密码不落盘，仅存储哈希值
- 加盐哈希：`sspu_aio_salt_$<password>_$end`
- 哈希算法：SHA-256（来自 `crypto` 包）
- 系统快速验证只保存本地布尔开关，不保存、读取或记录 PIN、Face ID、Touch ID、生物识别模板等原始认证数据
- 修改密码和移除密码保护会同步清除 `app_quick_auth_enabled`，避免旧密码上下文下的快速验证配置继续生效

**API 接口**：

| 方法 | 签名 | 说明 |
|------|------|------|
| `isPasswordSet` | `static Future<bool>` | 检查是否已设置密码 |
| `setPassword` | `static Future<void> (String)` | 设置新密码 |
| `verifyPassword` | `static Future<bool> (String)` | 验证密码是否正确 |
| `removePassword` | `static Future<void>` | 移除密码保护 |
| `isQuickAuthEnabled` | `static Future<bool>` | 检查系统快速验证开关 |
| `setQuickAuthEnabled` | `static Future<void> (bool)` | 设置系统快速验证开关 |
| `clearQuickAuth` | `static Future<void>` | 清除系统快速验证配置 |

### 5.3 SystemAuthService

**文件**：`lib/services/system_auth_service.dart`

**平台支持**：
- Android / iOS / macOS / Windows：通过 `local_auth` 调用系统认证能力
- Linux / Web：直接返回不可用，不调用插件，设置入口隐藏且锁定页保留手动密码

**认证策略**：
- 不使用 `biometricOnly: true`，允许 Windows 和移动端按系统策略使用 PIN、密码或生物识别
- 启用 quick auth 前必须先输入当前应用密码，再成功完成一次系统认证
- 锁定页在 quick auth 启用且设备可用时自动优先请求系统认证，同时保留密码输入框和“解锁”按钮
- 系统认证失败、取消、超时或插件不可用时不清空密码、不退出应用，只提示用户使用手动密码

### 5.4 AcademicCredentialsService

**文件**：`lib/services/academic_credentials_service.dart`

**存储机制**：
- 后端：`flutter_secure_storage`，按平台委托系统安全存储能力
- Android：启用 `EncryptedSharedPreferences`
- iOS / macOS：使用系统 Keychain；macOS Runner 配置 `keychain-access-groups`
- Windows / Linux / Web：使用插件对应平台实现；Linux 打包需提供 `libsecret` 运行依赖

**安全设计**：
- 教务凭据需要后续解密登录外部网站，因此不能使用不可逆哈希
- 设置页只回填学工号，OA 密码、体育部查询密码和邮箱密码输入框始终为空
- 页面展示每个密码字段是否已保存，并提示数据加密存储在本地、不上传至云端
- 不使用 `readAll` / `deleteAll` 批量接口，清理时逐项删除已知键，保持 Windows 兼容性

**API 接口**：

| 方法 | 签名 | 说明 |
|------|------|------|
| `getStatus` | `Future<AcademicCredentialsStatus>` | 获取学工号和各密码填写状态 |
| `saveCredentials` | `Future<void> ({required String oaAccount, String? oaPassword, String? sportsQueryPassword, String? emailPassword})` | 保存账号和本次填写的密码，空密码不覆盖旧值 |
| `readSecret` | `Future<String?> (AcademicCredentialSecret)` | 读取指定密码原文 |
| `clearSecret` | `Future<void> (AcademicCredentialSecret)` | 清除指定密码字段 |
| `clearAll` | `Future<void>` | 清除全部教务凭据 |

### 5.5 密码操作流程

#### 设置密码

```
用户点击开关(开启)
  │
  ▼
ContentDialog: 输入密码 + 确认密码
  │
  ├── 密码为空 → 错误提示
  ├── 两次不一致 → 错误提示
  └── 通过验证 → PasswordService.setPassword() → 成功提示
```

#### 修改密码

```
用户点击"修改密码"
  │
  ▼
ContentDialog: 旧密码 + 新密码 + 确认新密码
  │
  ├── 旧密码验证失败 → 错误提示
  ├── 新密码为空 → 错误提示
  ├── 两次不一致 → 错误提示
  └── 全部通过 → PasswordService.setPassword() → 清除 quick auth → 成功提示
```

#### 移除密码

```
用户点击开关(关闭)
  │
  ▼
ContentDialog: 输入当前密码
  │
  ├── 验证失败 → 错误提示
  └── 验证通过 → PasswordService.removePassword() → 清除 quick auth → 成功提示
```

#### 启用系统快速验证

```
用户点击“系统快速验证”开关
  │
  ▼
检查密码保护已开启且 SystemAuthService.isAvailable() 为 true
  │
  ▼
ContentDialog: 输入当前密码
  │
  ├── 密码错误 / 取消 → 不启用
  └── 密码正确 → local_auth 系统认证
                      │
                      ├── 认证成功 → app_quick_auth_enabled = true
                      └── 失败 / 取消 / 超时 / 不可用 → app_quick_auth_enabled 清除，保留手动密码
```

#### 锁定页解锁

```
进入 LockPage
  │
  ├── quick auth 未启用或不可用 → 显示手动密码
  └── quick auth 已启用且可用 → 自动请求系统认证
                                  │
                                  ├── 成功 → AppShell
                                  └── 失败 / 取消 / 超时 → 手动密码仍可用
```

---

## 6. 主题系统

### 6.1 配置方式

在 `main.dart` 的 Flutter 应用入口中统一接入 `AppTheme.build(Brightness.light)` / `AppTheme.build(Brightness.dark)`：

| 属性 | 值 | 说明 |
|------|------|------|
| `theme` | `AppTheme.build(Brightness.light)` | 浅色 Fluent 2 主题 |
| `darkTheme` | `AppTheme.build(Brightness.dark)` | 深色 Fluent 2 主题 |
| `themeMode` | `ThemeMode.system` | 自动跟随系统设置 |
| `fontFamily` | `MiSans` | 全局字体 |
| `colorScheme` | `ColorScheme.fromSeed` | 统一品牌色与状态色 |

### 6.2 主题适配要求

- 所有页面的文字颜色、背景色必须通过 `Theme.of(context)` 与 `ColorScheme` 获取
- 半透明效果使用 `.withValues(alpha: x)` 方法
- 不硬编码颜色值（白色/黑色除外的主题依赖色）
- 主页面优先使用 Fluent surface、`SectionCard` 和共享间距 / 圆角 token，统一浅色 / 深色背景、描边、阴影、图标容器和标题说明布局
- 阴影与交互动效通过 `AppShapes`、`AppSpacing` 和 `AppMotion` token 获取；禁止在页面中新增零散硬编码阴影和缓动

---

## 7. 国际化

### 7.1 当前状态

- 已使用 Flutter 内置本地化委托和 `supportedLocales` 保留中文界面基础能力
- 当前界面文字使用硬编码中文
- 后续可接入 Flutter 国际化方案实现多语言切换

---

## 8. 目录结构

核心目录包括 `lib/main.dart`、`lib/app.dart`、`lib/controllers/`、`lib/models/`、`lib/pages/`、`lib/services/`、`lib/theme/`、`lib/utils/` 和 `lib/widgets/`。页面、服务和模型按功能继续拆分，超长文件默认继续解耦。

---

## 9. 后续路线

长期路线包括信息中心抓取源扩充、主页可配置摘要面板、快速跳转用户自定义与排序、多语言支持、数据导出 / 备份，以及安装器与签名公证完善。当前版本不在界面中暴露未接入渠道，未完成能力只保留在路线说明中。

---

## 10. 安全设计约束

1. **应用锁密码不以明文存储**：始终使用 SHA-256 哈希
2. **加盐防御**：防止彩虹表攻击
3. **可解密凭据使用系统安全存储**：教务凭据不写入统一 JSON 状态文件，按平台使用 Keychain / Keystore / Credential Locker / libsecret 等能力
4. **系统快速验证不保存原始认证数据**：仅保存本地布尔配置，真实认证由操作系统和 `local_auth` 完成
5. **状态文件本地化**：桌面端保存在用户目录，移动端保存在系统分配的应用支持目录
6. **网络请求仅用于内容抓取**：当前版本会访问学校官网与微信公众平台，不上传用户业务数据到自建服务
7. **认证材料最小暴露**：公众号平台 Cookie / Token 仅保存在本地状态文件，不进入仓库
8. **调试日志脱敏**：HTTP Debug 日志仅输出 scheme、host 和 path，不输出 query、fragment 或 userInfo
9. **发布签名不入库**：Android release keystore 通过本地文件或 CI Secrets 注入
10. **无敏感信息调试日志**：密码、教务凭据与微信认证敏感字段不输出到控制台
11. **协议版本确认**：首次启动弹窗在同一篇文档中展示免责声明、用户协议、隐私协议、开源许可证与第三方协议说明，当前确认状态使用 `agreement_20260612_email_smtp_send_accepted` 保存，旧版协议键仅作为历史状态保留；Windows Inno Setup 安装器使用同一份法律资产展示安装阶段许可页
