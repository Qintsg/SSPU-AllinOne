# 变更日志

<!-- markdownlint-disable MD024 -->

本文档遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/) 规范，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [Unreleased]

### 新增

- 新增高级 CodeQL、Gitleaks 密钥扫描与 Flutter 覆盖率 workflow，并将 Dart / Flutter 质量门禁文案整合到现有 CI。
- 新增 User-Agent Policy PR workflow，阻止未写明例外原因的非标准 UA 进入运行时代码。

### 变更

- OA/CAS 与校园受限 HTTP 请求改用 `SSPU-AllinOne/{version} ({platform}; {os_version})` 应用身份 User-Agent，微信公众号和通用 WebView 保留带注释说明的浏览器 UA 例外。

### 修复

- 修正 macOS Bundle ID、RunnerTests 标识和钥匙串访问组大小写，统一使用 `cn.qintsg.sspuAllInOne`。

## [0.2.8-alpha] - 2026-06-12

### 发布

- 本版本是 `v0.3.0-beta` 前最后一个 `v0.2.x-alpha` 版本，聚焦仓库治理、发布链路、设置体验、移动端适配和若干关键页面修复；仍包含已知问题，建议作为预发布版本谨慎使用。

### 新增

- 第二课堂学分改为解析学工报表规则矩阵、总计行和“已获分数”详情，并将缓存迁移到系统安全存储，旧版普通明文缓存不再读取。
- 设置页微信矩阵新增推荐账号与公众号头像展示，支持在矩阵内直接按公众号切换关注状态，并加入“上海发布”“上海教育考试院”等入口。
- 校历页面改为直接内嵌 PDF 展示，并按首次进入或间隔超过一个月自动刷新校历文件。
- 关于分区迁入设置页底部，开源项目与许可证信息改为表格化展示。

### 变更

- 完善 CI/CD 与仓库治理门禁：普通 PR 增加标题/分支/base 校验、变更 Dart 文件格式检查、`flutter test`、GitHub 治理配置校验、Dependency Review、PR Metadata 与 Issue Triage 自动化，并补齐标签字典与文档说明。
- Release workflow 不再构建和发布 Web 静态站点，公开 Release 资产矩阵收敛到 Android、Windows、macOS 与 Linux。
- 收敛 Release workflow 复用逻辑，将 Flutter 初始化、arm64 SDK 安装、Windows portable 打包和 Linux 多格式产物整理抽成 composite actions，降低多平台发布脚本重复度。
- 收敛 PR 模板为默认通用模板与 Release 专项模板，并完善 Issue 表单的多选平台、影响模块、优先级建议、敏感信息提醒和验收字段。
- 设置页完成聚合设置体验优化：微信推文、职能部门、教学单位、安全设置、学期设置、数据管理、公众号认证与配置编辑器等区域重排，并压缩冗余说明文本。
- 学期选择逻辑调整为“当前日期所在学期”和“后续查询使用学期”分离，选择非当前学期时不再直接按寒假处理。
- 移除操作成功后的底部大横幅通知，改为内联文字或自动收回的小型反馈。
- iOS Bundle ID 标准化为 `cn.qintsg.sspuAllInOne`。

### 修复

- 合并免责声明、用户协议、隐私协议、开源许可证与第三方协议说明，改为首次启动一次确认，并让 Windows x64 / arm64 安装器在安装阶段展示同一份许可文本。
- 更换应用徽章、系统应用图标与 Web favicon，覆盖 Windows、Android、iOS、macOS、Linux 打包和应用内品牌位，并新增可复现图标生成脚本。
- 将中文语言环境下的应用显示名定为“工大聚合”，覆盖应用内标题、系统启动器/窗口标题、安装器展示名、Web title/manifest 和平台元数据，并保留 `SSPU-AllinOne` 作为英文显示名与 Release 资产命名。
- 统一本地数据目录为 `.sspu-aio`，同步状态文件、微信公众号配置、Windows WebView2 运行态目录、隐私协议、设置页文案和相关测试，避免新运行继续创建旧目录。
- 将 Windows x64 / arm64 Inno Setup 安装器改为双模式安装，全新安装默认当前用户范围，并保留用户显式选择所有用户安装的能力；安装器现在会检测既有安装，升级时沿用原范围和路径，同版本重装先调用卸载器并让用户选择是否保留 `.sspu-aio/` 应用数据。
- 修复第二课堂详情解析失败时覆盖旧缓存的问题；主矩阵可展示带 warning 的临时结果，但不会写掉上一份完整安全缓存。
- 修复移动端输入法弹出时底部导航和页面重复让位、闪烁或布局错乱的问题。
- 修复 iOS 设置界面选择框弹层与系统状态栏冲突的问题。
- 修复 iOS 凭据保存时共享路由滚动状态导致的滚动崩溃。
- 修复桌面侧边栏收起或展开时菜单按钮位置和纵向对齐不一致的问题。
- 修复通用弹窗按钮与文本视觉不协调的问题，并支持点击卡片外区域取消。
- 修复 macOS Release 构建中钥匙串访问组声明缺失导致的凭据保存失败风险，并接入 #248 的 appdmg 签名、公证与装订链路。
- 修复第二课堂卡片刷新行位置、教务卡片刷新布局和课表顶部摘要在窄空间下的适配问题。

### 依赖

- Flutter 工具链基线升级到 `3.44.0`、Dart SDK 基线升级到 `3.12.0`，并同步升级可解析的 Flutter 依赖锁定项。

### 已知问题

- macOS DMG 已按 #248 走 Developer ID 签名与公证流程；签名公证后的钥匙串凭据保存能力仍需继续验证。
- 主页校园卡余额在未填写教务凭据时的提示展示仍可能存在异常。
- 部分页面在移动端输入法弹出时仍可能存在局部布局问题。
- 微信公众平台登录流程与凭证管理仍需继续优化。

## [0.2.7-alpha] - 2026-06-05

### 新增

- 新增桌面标题栏校园网 / VPN 状态入口，桌面端可在窗口框架中查看当前受限校园服务可达性，并保留主页状态提示。

### 变更

- 迁移前端到外部 `fluent_ui` / `fluentui_system_icons` 设计体系，新增项目级 Fluent 组件、语义图标 facade、主题 token 与页面导航入口，收敛旧 Material 兼容层。
- 重构主导航、首页、教务中心、课表、信息中心、邮箱、快速跳转、设置、协议、隐私、锁定和 WebView 等页面的 Fluent 控件与响应式样式。
- 更新 GitHub Actions 依赖版本，Release 与 CI 工作流统一使用 `actions/checkout@v6.0.3`。

### 修复

- 优化教务、体育考勤、校园卡、第二课堂、学校邮箱等鉴权数据缓存刷新逻辑，减少凭据或会话刷新后页面仍展示旧数据的问题。
- 补充 OA 会话预热和可复用的鉴权数据缓存服务，修复多个受限校园服务在凭据更新、Cookie 过期或刷新失败后的状态回退。
- 完善校园网状态检测结果建模、桌面标题栏展示和相关测试，降低网络不可达、检测中与失败状态的误判。

### 文档

- 更新 Fluent 2 设计迁移记录、仓库工作流约束、使用文档和长期议题计划，补充 AGENTS 仓库工作规范。

### 测试

- 补充 Fluent 可访问性、鉴权缓存、OA 会话预热、校园网状态、教务、校园卡、体育考勤、学校邮箱、第二课堂与页面刷新相关回归测试。

### 依赖

- 升级 `flutter_secure_storage` 到 `10.3.1` 并同步刷新 Flutter 依赖锁定项。

## [0.2.6-alpha] - 2026-05-18

### 新增

- 新增隐私协议页面，并在首次启动协议确认弹窗和关于页中提供入口。
- 设置页常规分区新增应用内检查更新入口，可按正式版 / 测试版渠道查询 GitHub Release 并打开当前平台推荐安装包。

### 变更

- 统一版本号、Release 分支、构建产物命名和发布 PR label 规则：公开版本不再显式包含 `+build`，stable / lts / hotfix 作为普通 Release，alpha / beta / rc 作为 Pre-release。
- 项目许可证从 MIT 切换为 Artistic License 2.0，仓库许可证文件、展示文案、应用内使用协议和当前协议确认键同步更新。
- 项目名称统一迁移为 `SSPU-AllinOne`，同步更新 Dart 包名、Android / Apple / Linux 应用身份、Windows / Linux 主程序名、Release 资产命名、前端展示文案、仓库文档链接与发布元数据。
- 首次启动确认从单一使用协议扩展为使用协议与隐私协议，并使用当前协议版本键触发既有用户重新确认。

### 修复

- 修复 Windows 构建缓存保留旧项目路径时 `flutter run -d windows` 无法重新生成 CMake 构建文件的问题；清理 `build/windows` 后会按当前目录重新配置。
- 兼容 Visual Studio 18 / MSVC 14.51 对 `<experimental/coroutine>` 的弃用阻断，避免 Windows 插件编译时因旧协程头静态断言失败。
- 修复首页、信息中心、设置页等 surface 组件在窗口约束变化时可能一闪而过的 `Cannot interpolate between finite constraints and unbounded constraints` 运行时异常。
- 将 Windows WebView2 环境改为首次打开内嵌网页时懒加载，并在退出流程中显式释放已创建环境，避免未打开 WebView 时关闭应用仍触发 Chromium 窗口类清理报错。
- 优化桌面端退出顺序：关闭应用时优先隐藏前端窗口，再在后台限时释放 WebView2、托盘和窗口管理资源，降低退出时用户可见卡顿。

### 文档

- 补充改名后的签名边界：Android 现有 keystore 可继续签名新包名产物但不构成旧包名原地升级；Apple Bundle ID 迁移后需要新的 App ID 与 provisioning profile。
- 补充隐私协议对本地状态文件、系统安全存储、WebView2 运行态、外部服务访问和用户清理方式的说明。

### 依赖

- 升级可解析到最新版本的 Flutter 依赖锁定项：`flutter_secure_storage_windows`、`json_annotation`、`url_launcher_web`、`vm_service`、`win32`。

## [0.2.5-alpha+1] - 2026-05-15

### 发布

- 本版本为过渡版本，包含大量已知缺陷，不建议下载安装；建议等待 `v0.3.x` 版本发布后再使用。

### 新增

- 侧边导航“设置”上方新增校园网 / VPN 状态徽标，默认通过访问 `tygl.sspu.edu.cn` 检测受限校园服务可达性
- 新增可替换的 `CampusNetworkStatusService`，为后续 OA、教务、校园卡、学工报表等受限查询入口提供统一前置判断
- 设置页新增“自动刷新设置”分区，支持配置校园网 / VPN 状态检测间隔、体育查询自动刷新、校园卡余额自动刷新开关与间隔，并提供职能部门、教学单位、微信推文自动刷新设置快捷入口
- 安全设置页新增本专科教务系统（OA）登录校验，复用已保存 OA 账号密码和校园网 / VPN 前置检测，区分凭据缺失、网络不可达、验证码 / MFA 和网页流程异常，并在成功后保存可复用 Cookie 会话快照
- 教务中心新增体育部课外活动考勤卡片，使用独立体育部查询密码读取早操、课外活动、次数调整、体育长廊总次数，支持右下角显示上次刷新时间、手动刷新和考勤记录二级页面
- 主页新增校园卡余额卡片，复用 OA/CAS 登录态只读查询账户余额、卡状态和最近交易记录，并提供右上角详情页入口、右下角上次刷新时间和手动刷新按钮
- 侧边导航新增“邮箱”页面，使用“学工号@sspu.edu.cn”作为固定学校邮箱账号，通过 IMAP / POP 只读读取最近邮件，并使用 SMTP 进行登录认证与连通性校验；设置页同步新增学校邮箱自动刷新开关与间隔
- 教务中心新增“第二课堂学分”卡片，复用 OA/CAS 登录态进入学工报表系统，只读读取第二课堂逐项得分明细；设置页同步新增第二课堂学分自动刷新开关与间隔
- 教务中心新增“本专科教务”摘要卡片，复用 OA/CAS 登录态只读聚合个人信息、当前课表、成绩、考试、培养计划和培养计划完成情况，并识别开课检索、空闲教室入口状态
- 侧边导航新增独立“课表”页面，复用本专科教务只读课表能力展示课程名称、时间、地点、教师和周次；设置页同步新增本专科教务自动刷新开关与间隔

### 变更

- 主导航页面接入统一 `FluentSurface` 视觉容器，完善首页、教务中心、课表、信息中心、学校邮箱和快速跳转页的 Fluent 2 阴影、描边、悬停与入场动效
- 信息中心将刷新、搜索和筛选操作集中为同一操作区，快速跳转页将搜索框和最佳匹配入口合并为统一操作 surface，降低页面操作分散感
- 设置页微信渠道仅展示已接入的微信公众号推文入口，微信服务号历史枚举保留为旧缓存兼容，不再作为可开启渠道显示
- 拆分信息中心消息来源名称枚举，保持消息模型主文件低于仓库 500 行结构上限

### 修复

- 修复 Windows WebView2 自定义用户数据目录下，微信公众平台扫码登录后 CookieManager 读取默认存储导致无法自动提取 Cookie 的问题
- 修复第二课堂学分解析对“得分 / 分数 / 认定分”列、空白类别延续和学年学期字段识别不完整的问题
- 学工报表 SSO、首页或第二课堂明细页返回登录页时，会在已保存 OA 密码的前提下自动刷新 OA/CAS 会话并重试
- Debug HTTP 日志改为只输出 scheme、host 和 path，避免查询参数、fragment 或 userInfo 中的临时凭据进入控制台

### 依赖

- 新增 `gbk_codec` 用于解码体育部查询系统 GBK / GB2312 页面
- 新增 `enough_mail` 用于学校邮箱 IMAP / POP / SMTP 协议接入

### 文档

- 新增 OA / CAS 登录规则探索记录，明确跳转链路、表单字段、RSA 密码格式、会话保存和只读边界
- 新增体育部考勤查询规则探索记录，明确学生身份登录字段、WebForms 隐藏字段、GBK 解码和只读边界
- 新增校园卡查询规则探索记录，明确 OA/CAS 跳转链路、校园卡业务入口、候选交易查询接口和只读边界
- 新增学校邮箱只读接入规则探索记录，明确腾讯企业邮箱端点、IMAP / POP 读取策略、SMTP 认证边界和敏感信息保护要求
- 新增学工报表第二课堂学分查询规则探索记录，明确 OA SSO 入口、`xgbb` 本地登录页限制、`studentxfform` 只读学分页定位策略和只读边界

## [0.2.3-alpha+2] - 2026-04-26

### 修复

- Release workflow 在打包 macOS unsigned DMG 前重新 ad-hoc 签名 `.app`，剥离 Flutter/Xcode 构建后残留的受限 entitlement

### 测试

- 补充 macOS Release workflow 回归测试，确保打包前先清理签名权限再执行 entitlement 拦截

### 文档

- 补充 macOS unsigned DMG 打包前重新 ad-hoc 签名的发布约束

### 发布

- 以 `0.2.3-alpha+2` 重新发布 alpha 构建批次，使用 `v0.2.3-alpha` Tag，并通过完整版本号区分新产物

## [0.2.3-alpha+1] - 2026-04-26

### 修复

- macOS unsigned Release 移除受限 entitlement，并在打包前校验签名状态，修复 ad-hoc 签名 DMG 被 AMFI 拒绝启动的问题

### 文档

- 补充 alpha 版本自动发布流程、Release PR 要求和失败后递增构建号重发规则

### 发布

- 尝试以 `0.2.3-alpha+1` 发布 alpha 构建批次；因 macOS DMG entitlement 校验失败，未生成 GitHub Release

## [0.2.2-alpha+4] - 2026-04-25

### 新增

- 密码保护新增可选系统快速验证：启用时需先确认当前密码并完成一次系统认证，锁定页优先尝试系统认证且保留手动密码兜底；Linux / Web 隐藏该入口

### 修复

- macOS 启动阶段托盘初始化失败时降级为无托盘模式，避免托盘异常中断主窗口启动导致应用无法打开
- macOS 托盘图标路径补充 App.framework 与 Resources 下的 Flutter assets 候选路径，并保留跨平台回退路径

### 发布

- 以 `0.2.2-alpha+4` 重新发布 alpha hotfix 构建批次，使用 `v0.2.2-alpha` Tag，并通过完整版本号区分新产物

## [0.2.2-alpha+3] - 2026-04-24

### 修复

- Android release 构建将 `compileSdk` 提升到至少 34，修复 `flutter_secure_storage` 依赖链中的 AndroidX AAR metadata 要求 API 34 以上导致 APK 构建失败的问题
- Android release 构建补充 Tink 编译期注解类的 R8 `dontwarn` 规则，修复 release shrink 阶段因缺少注解类而中断的问题

### 发布

- 以 `0.2.2-alpha+3` 重新发布 alpha 构建批次，使用 `v0.2.2-alpha` Tag，并通过完整版本号区分新产物

## [0.2.2-alpha+2] - 2026-04-24

### 修复

- Release 工作流的 Linux x64 / arm64 构建依赖补齐 `libsecret-1-dev`，修复 `flutter_secure_storage_linux` 在 CMake 阶段找不到 `libsecret-1>=0.18.4` 导致 Linux 产物构建失败的问题

### 发布

- 以 `0.2.2-alpha+2` 重新发布 alpha 构建批次，使用 `v0.2.2-alpha` Tag，并通过完整版本号区分新产物

## [0.2.2-alpha] - 2026-04-24

### 新增

- 微信推文认证卡片新增“打开配置文件所在文件夹”入口，并保留使用系统默认应用打开 `wxmp_config.toml`
- 快速跳转页新增搜索框，支持名称 / URL 精确匹配、模糊匹配和校园服务意图匹配，并可直接打开最佳匹配结果
- 安全设置页新增教务凭据本地保存入口，支持学工号、OA 密码、体育部查询密码和邮箱密码的加密存储与填写状态提示

### 变更

- 移除设置页中的 VS Code 专用配置文件入口，统一改为使用系统默认文件管理器打开配置目录
- 同步 Release PR 发布说明章节校验规则，确保工作流可从 PR 正文生成规范化的 `release-notes.md`

### 修复

- 修复 Android 启动前等待本地状态目录、通知和自动刷新初始化导致首帧无法渲染、界面纯白的问题
- 修复微信公众号平台认证信息提取与配置文件编辑流程，避免无效认证状态影响刷新链路
- 优化配置入口异常提示和相关测试命名，降低配置文件打开失败时的排查成本
- 修复 Windows arm64 Release 构建中 JDK 架构与 Flutter Windows toolchain 不一致导致 `jni` 插件链接失败的问题

## [0.2.1-alpha] - 2026-04-23

### 修复

- 恢复 Android `applicationName` 注入，重新启用 Flutter 默认插件注册链路，修复安装后启动黑屏的问题
- 回退错误的 Android 自适应启动图标资源引用，恢复应用图标显示，避免系统回退到默认安卓图标

## [0.2.0-alpha] - 2026-04-23

### 新增

- 快速跳转改为读取仓库内 YAML 配置，支持后续维护分组、链接和可选自定义图标
- 微信公众号平台支持本地 `wxmp_config.toml` 高级配置文件，并在设置页提供打开与重新加载入口
- 信息中心官网刷新增加进度反馈与分渠道增量合并，刷新过程中保留当前列表并逐步显示已解析的新内容
- 新增“信息网页接入请求”Issue 模板，便于统一收集学院 / 部门官网名称、栏目列表页 URL、解析结构与验收标准
- 接通信息中心自动刷新与推送配置，支持官网渠道和微信公众号分别设置刷新间隔，并在设置变更后即时重载定时器
- 消息推送设置页新增一键全开、一键全关操作，支持职能部门、教学单位和微信推文分区快速切换
- README 与使用文档补充各平台 Release 产物位置、分发方式与 Android 本地签名说明
- Release 工作流新增 Windows arm64 安装器与 Linux x64/arm64 的 `.deb` 安装包产物
- Windows arm64 / Linux arm64 公开发布矩阵提升为与 x64 同级，自动进入正式 Release 资产清单
- 新增 `docs/RELEASE.md`，统一版本来源、Tag 规则、资产命名、平台矩阵、Release Notes 模板与发布门槛
- 新增发布说明提取与元数据生成脚本，自动产出 `release-notes.md`、`manifest.json` 与 `SHA256SUMS.txt`
- 新增 Release 申请 Issue 模板与复合 action，统一发布版本解析和 Release 元数据生成

### 变更

- Android 构建链升级到 Gradle 9.4.1，并同步将 Android Gradle Plugin 调整到兼容的 8.13.2
- Android release 构建改为优先读取本地 `key.properties` 中的签名配置，缺失时回退到 debug 签名
- 关于页版本号改为运行时读取应用包信息，README 徽章改为直接从 `pubspec.yaml` 动态取值
- 完善设置页“微信推文消息获取”操作逻辑，补齐公众号平台刷新设置、认证入口与 SSPU 微信矩阵展示
- 将用户设置、认证信息、文章缓存和 WebView2 运行态统一收敛到 `~/.sspu-all-in/`
- 将微信推文高级配置文件入口合并到公众号平台认证卡片，扫码登录成功后自动更新 `wxmp_config.toml`
- 删除设置页微信推文中的独立搜索公众号卡片和已关注公众号卡片，关注入口收敛到 SSPU 微信矩阵
- 信息中心刷新进度改为服务层状态，切换页面后仍会保留官网消息和微信推文刷新进度
- 微信推文默认刷新条数调整为 10，并按 SSPU 微信矩阵中的公众号开关过滤抓取范围
- 完善设置页“消息推送（官网）”操作逻辑，将职能部门 / 教学部门渠道调整为分组级刷新设置、网站总开关和内容分类按钮
- 删除微信读书接入方式，统一改为通过公众号平台获取微信公众号文章，并在信息中心未完成认证时禁用对应刷新按钮
- 将信息公开网“最新公开信息”在应用内显示为“公开信息”，并将渠道设置调整为一级列表直接操作开关、刷新间隔和子分类开关
- 学校官网接入“学校新闻 / 通知公告 / 校内活动”三个栏目，其中校内活动改用官网动态接口解析
- 教务处接入“教学动态 / 学生专栏 / 教师专栏”三个栏目，并进入文章页读取精确发布时间
- 将信息技术中心单一分类显示为“消息”
- 将体育部分类显示为“通知公告 / 部门动态”
- 体育部进入文章页读取精确发布时间，并将保卫处分类显示为“动态/通知 / 宣教专栏”
- 将校区建设办统一显示为“基建处”，并改为解析“建设要闻 / 通知公告”列表页
- 新闻网改为解析“综合新闻”列表页并支持翻页
- 学生处改为解析“学工要闻 / 通知公告”列表页，并校正通知分类显示名称
- 计算机与信息工程学院改为聚合解析“工作动态 / 教师工作 / 学生工作”多个子栏目
- 智能制造与控制工程学院改为聚合解析“学院动态 / 教学科研 / 通知公告”列表页
- 资源与环境工程学院改为聚合解析“新闻资讯 / 通知公告 / 科研与服务 / 党建思政”列表页
- 能源与材料学院改为聚合解析“新闻资讯 / 通知与公告 / 育人园地 / 科学研究”列表页
- 经济与管理学院改为聚合解析“学院动态 / 通知公告 / 育人园地 / 党群引领”列表页
- 语言与文化传播学院改为聚合解析“新闻动态 / 学院公告 / 学生活动 / 讲座信息”列表页
- 数理与统计学院改为聚合解析“学院新闻 / 学院公告 / 学术动态 / 育人园地”列表页，并进入文章页读取精确发布时间
- 职业技术教师教育学院改为聚合解析“新闻动态 / 通知公告”列表页
- 国际教育中心改为聚合解析“新闻 / 公告”列表页
- 继续教育学院改为聚合解析“学院新闻 / 学院公告”列表页
- 职业技术学院改为聚合解析“学院新闻 / 学院公告”列表页
- 马克思主义学院改为聚合解析“学院新闻 / 通知公告 / 学术科研 / 教育教学”列表页
- 新增工程训练与创新教育中心来源，并解析“中心动态 / 通知公告”两个栏目
- 新增后勤服务中心、外国留学生事务办公室、国际交流处、招生办、人事处、科研处、校工会、党委组织部、党委统战部、党委办公室、校团委、资产与实验管理处来源，研究生处改为解析指定“动态”列表页，并补齐快速跳转入口
- 集成电路学院、智能医学与健康工程学院、艺术与设计学院、创新创业教育中心、图书馆、艺术教育中心改为解析用户指定栏目列表页，并补齐对应分类筛选

### 修复

- 收敛 Android 侧静态检查噪声，补齐启动图标自适应资源，并将 `AndroidManifest.xml` 中的类引用改为确定值
- 微信公众号刷新按页获取每个公众号的推文直到达到条数上限或遇到已存文章，并为桌面端退出步骤增加超时兜底
- 微信公众号刷新前增加公众号平台认证有效性校验，避免失效 Cookie / Token 继续进入刷新链路
- 放宽设置页刷新文章个数输入框宽度，修复三类消息推送设置页数字显示不全的问题
- 微信推文手动刷新支持逐公众号合并新内容并更新进度条，同时将按钮文案调整为“刷新最新微信推文”
- 设置页在窄屏设备改用顶部下拉切换分区，避免固定左侧导航挤压内容导致移动端出框
- 优化微信公众平台认证状态检测，增加脱敏调试日志和认证状态诊断，避免无效 Token 被误判为可用
- 将 macOS Flutter Debug / Release xcconfig wrapper 纳入版本控制，修复新检出后 `flutter run -d macos` 找不到 Flutter 配置文件的问题
- 过滤官网解析中的 `javascript:` 等无效链接，并为 WebView 增加非法 URL 兜底页，避免点击消息时崩溃
- 将自动打标中的 `release` 标签更名为 `release-files`，避免仓库治理 / 安装器 / Release 配置类 PR 在合并时误触发发布工作流
- 调整 `develop` / `main` 同步策略：移除导致历史持续分叉的线性历史要求，并明确同步 PR 必须使用 merge commit
- 统一桌面端退出流程，修复 Windows 点击关闭后选择“退出应用”时窗口未响应、退出失败的问题
- 为移动端竖屏手机切换到底部导航，并为窄屏保留顶栏入口，修复低 DPI 竖屏下导航栏缺失的问题
- 为 Linux Release 显式补齐并校验主程序可执行权限，同时补充压缩包解压与 `chmod +x` 使用说明
- 收窄“刷新官网消息”的手动刷新范围，避免微信公众号抓取串入官网刷新链路导致信息中心长时间卡在加载状态
- 为 macOS Debug / Release entitlements 补充 `com.apple.security.network.client`，修复官网刷新与内嵌 WebView 页面统一空白的问题
- 统一版本解析保留内部 `+build` 并产出不含构建号的公开版本，修复 Tag 与资产命名不一致、Web / Linux / Android 公开产物不符合发布规则的问题
- 修复最新 Release workflow 中 Windows arm64 / Linux arm64 依赖 `subosito/flutter-action` 获取不存在的 stable arm64 bundle 而失败的问题，改为从官方 `flutter/flutter` 仓库检出指定 tag 并在 runner 本机预缓存 SDK

## [0.1.5-alpha] - 2026-04-21

### 新增

- Release 新增 Windows x64 / arm64 安装器、Android arm32 / arm64 / x64 APK、iOS arm64 未签名应用包、macOS universal DMG、Linux x64 / arm64 压缩包、Web JavaScript / WebAssembly 压缩包
- Issue 模板升级为表单式模板，补充平台、环境、复现、日志、验收标准等必填信息
- 补充分支命名规范与目标分支约定，明确 `main` / `develop` 的回合并要求

### 变更

- Flutter 工具链升级到 `3.41.7`，Dart SDK 基线升级到 `3.11.5`
- `window_manager` 升级到 `0.5.1`，同步刷新锁文件与桌面插件注册产物
- GitHub Actions 依赖升级到当前最新稳定标签（`actions/checkout@v6.0.2`、`upload-artifact@v7.0.1`、`download-artifact@v8.0.1` 等）
- PR CI 精简为 `flutter analyze`，草稿 PR 仅保留自动标签工作流
- GitHub Actions 官方 action 升级到 Node.js 24 runtime 兼容版本，消除 Node.js 20 deprecation warning
- 删除 CodeQL PR 安全扫描工作流
- 移除 PR 阶段跨平台 build check，平台构建集中到 Release 工作流
- PR 模板补充风险、回滚、验证记录、发布说明与回合并检查项
- PR 模板补充标准 Release Notes 章节，带 `release` 标签的 PR merge 后直接作为 GitHub Release 正文来源
- Labeler 标签拆分为 `ci`、`release`、`governance`、`dependencies` 等更细粒度规则
- Dependabot 默认向 `develop` 提交分组升级 PR，减少依赖更新噪音并贴合分支流转
- Issue 配置关闭空白提单入口，并补充文档导向链接
- PR CI 调整为仅执行 `flutter analyze`，并对带 `release` 标签的 PR 追加发布分支与发布说明模板校验
- Release 工作流改为从 `pubspec.yaml` 读取版本号，统一生成 Android/Windows/macOS/Linux/Web 公开资产与校验文件
- Release 工作流新增 Windows arm64、Linux arm64 正式构建与打包步骤，删除独立实验性架构发布分叉
- 预发布 Release 的目标分支约束调整为对应发布通道，并同步到 CI、Release workflow 与仓库模板
- 依赖升级：`package_info_plus` 升级到 `10.1.0`，并同步刷新锁文件中的 `package_info_plus_platform_interface` 与 `win32`
- `Build & Release` 工作流新增 `workflow_dispatch` 手动触发入口，支持显式传入目标分支与 Release Notes

### 修复

- 修复 Release 工作流中的 macOS DMG 打包路径错误，改为自动发现真实 `.app` 产物
- 修复 Windows 安装器编译依赖宿主机缺失中文语言文件导致的发布失败
- 修复 Windows arm64 Release 安装器脚本中的 Inno Setup 架构标识，恢复为当前编译器支持的 `arm64`
- 修复 Windows arm64 Release workflow 对 Flutter 输出目录的硬编码假设，改为构建后自动定位主程序目录并传入 Inno Setup
- 暂时收敛未验证的 Windows arm64 / Linux arm64 桌面发布矩阵，避免 Release 因官方 Flutter SDK 架构解析失败而整体中断
- 修复 macOS Runner 的 Xcode 配置引用错误，恢复 Flutter 生成配置与 CocoaPods 支持文件的正确加载，解决 `flutter build macos` 编译失败问题
- 修复 Android 启动阶段调用桌面插件导致黑屏闪退的问题，并同步 Android / iOS / macOS / Linux / Web 的应用名称与图标资源

---

## [0.0.1-alpha] - 2026-04-18

### 新增

- 初始化 Flutter 项目，支持 Android / iOS / macOS / Linux / Windows / Web 全平台
- 项目基础结构与配置
- MIT 许可证
- README.md 项目文档
- CLAUDE.md 代理工作规范
- docs/ 文档目录（API.md、CHANGELOG.md）
- .gitignore 版本控制忽略规则
- Fluent 2 设计风格前端页面驾架（主页、教务中心、信息中心、快速跳转、设置）
- NavigationView 侧边栏导航 + EntrancePageTransition 页面切换动画
- 密码保护功能（SHA-256 哈希本地存储，设置/修改/移除）
- 1Password 风格锁定页（抨动动画、自动聚焦）
- 深色/浅色主题自动跟随系统
