# SSPU-AllinOne（工大聚合）使用文档

> 本文档面向开发者，说明项目在开发状态下的环境准备、运行、测试、构建与调试方式。

---

## 1. 环境准备

### 1.1 必需工具

| 工具 | 最低版本 | 说明 |
|------|----------|------|
| Flutter SDK | 3.41.7 | 框架主体，包含 Dart SDK |
| Dart SDK | 3.11.5 | 随 Flutter SDK 一同安装 |
| Git | 2.x | 版本控制 |

### 1.2 平台开发工具

根据目标平台安装对应工具链：

| 平台 | 所需工具 |
|------|----------|
| Android | Android Studio + Android SDK |
| iOS | Xcode（仅 macOS） |
| macOS | Xcode + CocoaPods（仅 macOS） |
| Linux | clang、cmake、ninja-build、pkg-config、libgtk-3-dev |
| Windows | Visual Studio 2022（含"使用 C++ 的桌面开发"工作负载） |
| Web | Chrome 浏览器（推荐） |

### 1.3 验证环境

```bash
# 检查 Flutter 环境是否就绪
flutter doctor

# 期望输出：所有目标平台显示 ✓
```

---

## 2. 获取项目

```bash
# 克隆仓库
git clone https://github.com/Qintsg/SSPU-AllinOne.git
cd SSPU-AllinOne
```

---

## 3. 依赖安装

```bash
# 获取所有 Dart/Flutter 依赖
flutter pub get
```

依赖列表（见 `pubspec.yaml`）：

| 包名 | 用途 |
|------|------|
| Flutter SDK | 跨平台运行时、渲染基础设施与图标 |
| `shared_preferences` | 本地键值对存储 |
| `path_provider` | 平台应用支持目录解析 |
| `crypto` | SHA-256 哈希 |
| `flutter_secure_storage` | 系统安全存储，用于保存可解密教务凭据 |
| `local_auth` | 可选系统快速验证，用于密码保护开启后的本机认证解锁 |
| `url_launcher` | 打开外部链接，例如 GitHub Release 页面 |
| `open_filex` | 打开本地安装器、安装包或文件夹入口 |
| `dio` | HTTP 请求与应用内更新下载 |
| `gbk_codec` | GBK / GB2312 解码，用于体育部查询系统旧版页面 |
| `enough_mail` | IMAP / POP / SMTP 邮箱协议客户端，用于学校邮箱只读收信和登录校验 |
| `pdfrx` | 应用内 PDF 查看，用于校历原始 PDF 预览 |
| `pdfrx_engine` | PDF 文本抽取，用于教务处校历结构化解析 |
| `flutter_lints` | 代码规范（dev） |

---

## 4. 运行项目

### 4.1 列出可用设备

```bash
flutter devices
```

### 4.2 运行（调试模式）

```bash
# 使用默认设备
flutter run

# 指定平台
flutter run -d chrome          # Web
flutter run -d windows         # Windows 桌面
flutter run -d macos           # macOS 桌面
flutter run -d linux           # Linux 桌面

# 指定 Android/iOS 设备（使用 flutter devices 获取设备 ID）
flutter run -d <device_id>
```

### 4.3 热重载与热重启

在调试模式运行时：

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| 热重载 | `r` | 保留状态，更新 UI 代码 |
| 热重启 | `R` | 重置状态，重新构建 |
| 退出 | `q` | 停止调试运行 |

### 4.4 VS Code 调试

1. 安装 Flutter 扩展（`Dart-Code.flutter`）
2. 打开项目根目录
3. 按 `F5` 或点击"运行和调试" → "Dart & Flutter"
4. 选择目标设备运行

---

## 5. 代码分析

```bash
# 运行静态分析（lint + 类型检查）
flutter analyze
```

规则配置见项目根目录的 `analysis_options.yaml`，基于 `flutter_lints` 推荐规则集。

期望输出：

```
Analyzing sspu_allinone...
No issues found!
```

---

## 6. 测试

### 6.1 运行全部测试

```bash
flutter test
```

### 6.2 运行指定测试文件

```bash
flutter test test/widget_test.dart
```

### 6.3 当前测试覆盖

| 测试文件 | 类型 | 覆盖范围 |
|----------|------|----------|
| `test/academic_eams_service_test.dart` | 单元测试 | 本专科教务只读服务、开课检索、空闲教室查询 |
| `test/academic_page_test.dart` | Widget 测试 | 教务中心卡片、二级页面与本专科教务摘要入口 |
| `test/course_schedule_page_test.dart` | Widget 测试 | 独立课程表页面状态与自动刷新 |
| `test/widget_test.dart` | 冒烟测试 | SSPUApp 可正常构建 |

> 测试体系仍在继续补充，后续会进一步扩展集成测试与更多异常分支覆盖。

### 6.4 查看测试覆盖率

```bash
flutter test --coverage
# 生成 coverage/lcov.info

# 使用 lcov 工具生成 HTML 报告（需安装 lcov）
# genhtml coverage/lcov.info -o coverage/html
```

---

## 6.5 本专科教务 / OA 登录校验调试

安全设置页的“教务凭据”区域提供“验证 OA 登录”按钮，用于只读检查已保存的 OA 账号密码是否可完成学校 OA / CAS 登录。校验前会先执行校园网 / VPN 前置检测；成功后仅保存可复用 Cookie 会话快照，不保存一次性 CAS Ticket。

CAS 要求图形验证码、MFA / 安全验证或页面结构变化时，应用会给出明确状态提示，不会尝试绕过交互验证。登录规则探索记录见 [OA_LOGIN_RULES.md](OA_LOGIN_RULES.md)。

## 6.6 体育部课外活动考勤调试

教务中心页提供体育部查询系统的课外活动考勤卡片，展示总次数和早操、课外活动、次数调整、体育长廊四类明细。默认不自动访问体育部系统；可手动刷新，也可在设置页开启“体育查询自动刷新”。

每次读取前都会重新执行校园网 / VPN 前置检测，使用独立体育部查询密码，不复用 OA 密码。登录与解析规则探索记录见 [SPORTS_ATTENDANCE_RULES.md](SPORTS_ATTENDANCE_RULES.md)。

## 6.7 校园卡余额与交易记录调试

主页提供“校园卡余额”卡片，标题行包含上次刷新时间、刷新按钮和交易记录入口；成功态只展示余额，卡状态仅在异常时显示短提示。详情页进入后会自动查询系统默认最近交易，并支持“最近 / 近7天 / 近30天”或手动日期范围只读查询。默认不自动访问校园卡系统；可手动刷新，也可在设置页开启“校园卡余额自动刷新”。

校园卡链路复用 OA/CAS 会话，每次读取前都会执行校园网 / VPN 前置检测，不提供充值、支付或其它写入入口。登录与解析规则探索记录见 [CAMPUS_CARD_RULES.md](CAMPUS_CARD_RULES.md)。

## 6.8 学校邮箱只读收信调试

侧边导航提供“学校邮箱”页面，用于校验邮箱协议登录状态，并通过 IMAP 或 POP 读取最近邮件。邮箱账号固定由学工号派生为 `学工号@sspu.edu.cn`，邮箱密码独立于 OA 密码。

页面仅展示标题、发件人、时间、正文摘要和正文快照；SMTP 仅用于认证校验，不提供发送、回复、转发、删除、移动或标记已读入口。登录与协议规则探索记录见 [EMAIL_RULES.md](EMAIL_RULES.md)。

## 6.9 学工报表第二课堂学分调试

教务中心页提供“第二课堂学分”卡片，通过学工报表系统只读读取第二课堂规则矩阵、总计和“已获积分”详情。卡片展示总已获分数、总必修积分、总体通过情况、详情记录数、上次刷新，以及社会实践、报告与讲座、校园文化活动、创新创业活动四类“已获分数 / 所需分数”摘要；通过为绿色，未通过为红色。详情页展示总计概览、已获积分详情表和规则矩阵。第二课堂缓存写入系统安全存储，旧版普通明文缓存会被清除后等待重新拉取。

学工报表链路复用 OA/CAS 会话，每次读取前都会执行校园网 / VPN 前置检测；若入口、SSO、首页或第二课堂明细页返回登录页，且本地已保存 OA 密码，会先刷新一次 OA/CAS 会话再重试。本地验证码登录页不会被提交。登录与解析规则探索记录见 [STUDENT_REPORT_RULES.md](STUDENT_REPORT_RULES.md)。

## 6.10 本专科教务只读摘要与独立课程表调试

教务中心页新增“本专科教务”摘要卡片，独立“课表”页面展示当前学期课表。两者共用 EAMS 只读服务与自动刷新配置，默认不自动访问本专科教务系统。

本专科教务固定使用 `https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw` 入口并复用 OA/CAS 会话，业务站点使用 Firefox UA。页面仅展示个人基本信息、课表、成绩、考试、培养计划和入口状态，不提供选课、退课、调课、教学评价、确认、提交申请、预约教室或任何写入入口。

课程表页标题命令区提供“校历”入口，可查看教务处 2021 年以后的校历缓存、结构化学期范围、夏季教学段、特殊日期说明和原始 PDF。校历来源为 `https://jwc.sspu.edu.cn/xl/list.htm`，无需校园网 / VPN；应用优先读取本地缓存，缺少当前学年或 7/8 月临近下一学年时自动抓取。桌面端和移动端会将 PDF 与抽取文本保存到 `.sspu-aio/academic_calendars/pdf/` 和 `.sspu-aio/academic_calendars/text/`，Web 端降级为 URL 查看和结构化缓存。

设置页提供“学期设置”分区，可统一选择当前全局学期。周数由校历缓存优先、内置官网校历兜底按周一自动计算；夏季学期按逐年教学段定位，中间非教学区间显示为暑假，其它空档显示为寒假。当前日期或所选学期超出可定位范围时，应用会提示暂无日期定位，后续课表、成绩、考试等详情页应按不可定位状态降级处理。该设置是后续详情页复用的默认上下文，不会在当前版本中改变 EAMS 只读查询范围。

## 6.11 应用内更新入口

设置页常规分区提供“应用更新”卡片，可按正式版 / 测试版渠道查询 GitHub Release。发现新版本后，应用会优先读取 `manifest.json` 中的资产元数据和 SHA-256 校验值，失败时回退 `SHA256SUMS.txt`，再回退 GitHub API `digest` 字段。

支持本地安装入口的平台会在应用内下载推荐安装资产到 `.sspu-aio/update_downloads/<tag>/`，下载完成后必须通过 SHA-256 校验才显示“打开安装入口”。Windows 会严格区分 x64 / arm64 并优先选择 installer；macOS 选择 DMG；Linux 优先 AppImage，再选择 deb / rpm / portable；Android 选择 APK。portable 压缩包只会打开所在文件夹并提示手动替换，应用不会自动解压、覆盖或静默安装。

取消下载、下载失败或校验失败时，应用会删除半成品，避免用户误用。Web / iOS 等不支持本地安装的平台仅显示清晰提示，并保留“打开 Release”按钮供用户前往 GitHub Release 页面。

## 7. 构建发布包

发布版本号、Tag、GitHub Release 资产命名、Release Notes 模板与平台清单，统一以 [docs/RELEASE.md](RELEASE.md) 为准。
公开 Release 仍然通过带 `release` 标签的 PR merge 自动触发，版本号只读取 `pubspec.yaml`。

### 7.0 应用显示名与技术标识

- 中文语言环境下，应用显示名为“工大聚合”。
- 英文语言环境下，应用显示名为 `SSPU-AllinOne`。
- `pubspec.yaml` 包名、Android `applicationId`、Apple Bundle ID、Windows / Linux 可执行文件名、仓库名和 GitHub Release 资产文件名仍保持既有技术标识，不随显示名本地化变化。

### 7.1 Android

```bash
# 调试 APK
flutter build apk --debug

# 发布 APK
flutter build apk --release

# App Bundle（Google Play 推荐）
flutter build appbundle --release
```

签名说明：

- 仓库通过 `android/key.properties` 读取本地 Android release 签名配置
- 可参考 `android/key.properties.example` 填写签名信息
- 当前工作区已生成本机自签名 keystore：`android/app/sspu-release.jks`
- 当前 Android `applicationId` 为 `cn.qintsg.sspu_allinone`。仅修改展示名称不需要重新生成签名；本次包名迁移后，Android 会将新版识别为另一款应用。现有 keystore 可继续签名新包名产物，但不能作为旧包名应用的原地升级链路。
- `key.properties` 与 `.jks` 默认被 `.gitignore` 忽略，不会进入仓库
- GitHub Actions 可通过 `ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD` 四个 Secrets 在运行时写入签名配置
- 系统快速验证依赖 `local_auth`，Android Runner 使用 `FlutterFragmentActivity` 并声明 `android.permission.USE_BIOMETRIC`；仍保留密码输入作为兜底路径

输出路径：

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

发布后使用：

- `app-release.apk` 可直接安装到 Android 设备
- `app-release.aab` 用于应用商店上传，不适合本地直接安装
- GitHub Release 默认公开发布 `SSPU-AllinOne-v{version}-android-universal.apk`

### 7.2 iOS

```bash
# 需在 macOS 上运行
flutter build ios --release
```

iOS Bundle ID 已迁移为 `cn.qintsg.sspuAllinOne`。Bundle ID 变化后，需要在 Apple Developer 账号中准备新的 App ID，并重新生成匹配的 provisioning profile；证书本身不因显示名称变化而重取，但 profile 必须覆盖新的 Bundle ID。

iOS 系统快速验证通过 `local_auth` 调用系统能力，`Info.plist` 已配置 `NSFaceIDUsageDescription`。启用该功能仍需先开启应用密码保护并输入当前密码确认。

### 7.3 Web

```bash
flutter build web --release
```

输出路径：`build/web/`

Web 不支持 `local_auth`，系统快速验证入口会隐藏或显示不可用提示，用户仍使用手动密码解锁。Web 端也不访问本地文件目录，应用状态会保存到浏览器提供的 `shared_preferences` Web 存储；若浏览器存储不可用，则退回本次会话内存态以保证启动可用。

可使用任意静态文件服务器预览：

```bash
cd build/web
python -m http.server 8080
# 访问 http://localhost:8080
```

### 7.4 Windows 桌面

```bash
flutter build windows --release
```

输出路径：

- `build/windows/x64/runner/Release/`
- `build/windows/arm64/runner/Release/`

发布后使用：

- 需要连同整个 `Release/` 目录一起分发，不能只拷贝单个 `.exe`
- 启动入口为 `sspu_allinone.exe`
- GitHub Release 默认同时提供 x64 / arm64 的 installer 与 portable 产物
- Windows installer 使用 Inno Setup 双模式安装：全新安装默认选择“仅当前用户”，安装到当前用户程序目录且不需要管理员权限；用户显式选择“所有用户”或使用 `/ALLUSERS` 时安装到系统 Program Files 并按需触发 UAC。升级已存在安装时会先检测既有安装版本，版本不同时进入升级安装并沿用既有安装范围和目录，不再让用户重新选择路径。
- Windows installer 检测到已安装相同版本时，会询问是否重新安装；确认后先调用既有卸载器，卸载器会询问是否保留用户目录下的 `.sspu-aio/` 应用数据，完成卸载后再回到全新安装流程并重新显示当前用户 / 所有用户安装范围选择。静默同版本重装需显式传入 `/SSPUREINSTALL=1`，此时默认保留应用数据。
- Windows installer 的应用显示名可按系统语言显示为“工大聚合”或 `SSPU-AllinOne`，但默认安装目录固定使用英文技术名 `SSPU-AllinOne`，避免不同语言环境生成不同安装路径。
- 安装目录只保存应用程序文件；应用状态、微信公众号配置和 Windows WebView2 运行态仍保存在用户数据目录 `~/.sspu-aio/` 或移动端系统应用支持目录下的 `.sspu-aio/`。

### 7.5 macOS 桌面

```bash
# 需在 macOS 上运行
flutter build macos --release
```

输出路径：`build/macos/Build/Products/Release/`

发布后使用：

- 分发生成的 `.app` 包
- 若未做 Apple 签名与公证，首次运行可能需要在系统安全设置中手动允许
- 当前 GitHub Release 默认产出未签名 DMG：`SSPU-AllinOne-v{version}-macos-universal-unsigned.dmg`
- macOS 系统快速验证通过 `local_auth` 调用系统能力，`Info.plist` 已配置 `NSFaceIDUsageDescription`

### 7.6 Linux 桌面

```bash
flutter build linux --release
```

输出路径：

- `build/linux/x64/release/bundle/`
- `build/linux/arm64/release/bundle/`

若使用 Release 压缩包运行，建议使用 `tar` 解压以保留 Unix 可执行权限：

```bash
tar -xzf sspu-allinone-linux-x64.tar.gz
cd sspu-allinone-linux-x64
./sspu_allinone
```

如果使用图形化解压工具后出现 `Permission denied`，请补一次可执行权限：

```bash
chmod +x sspu_allinone
./sspu_allinone
```

若通过 GitHub Release 工作流发布，当前还会额外生成：

- `SSPU-AllinOne-v{version}-linux-x64-appimage.AppImage`
- `SSPU-AllinOne-v{version}-linux-x64-deb.deb`
- `SSPU-AllinOne-v{version}-linux-x64-rpm.rpm`
- `SSPU-AllinOne-v{version}-linux-x64-portable.tar.gz`
- `SSPU-AllinOne-v{version}-linux-arm64-appimage.AppImage`
- `SSPU-AllinOne-v{version}-linux-arm64-deb.deb`
- `SSPU-AllinOne-v{version}-linux-arm64-rpm.rpm`
- `SSPU-AllinOne-v{version}-linux-arm64-portable.tar.gz`

Linux 当前没有 `local_auth` 官方实现，系统快速验证入口会隐藏，用户仍使用手动密码解锁。

面向 Debian / Ubuntu 及其衍生发行版，可直接使用：

```bash
sudo apt install ./SSPU-AllinOne-v{version}-linux-x64-deb.deb
```

---

## 8. 常用开发命令

| 命令 | 用途 |
|------|------|
| `flutter pub get` | 安装依赖 |
| `flutter pub upgrade --major-versions` | 升级依赖约束到最新主版本 |
| `flutter pub outdated` | 检查过期依赖 |
| `flutter analyze` | 静态代码分析 |
| `flutter test` | 运行测试 |
| `flutter clean` | 清理构建缓存 |
| `flutter pub cache repair` | 修复依赖缓存 |
| `flutter doctor` | 检查开发环境 |
| `flutter devices` | 列出可用设备 |

---

## 9. 项目目录结构

```
SSPU-AllinOne/
├── lib/                         # Dart 源码
│   ├── main.dart                # 应用入口
│   ├── app.dart                 # 导航骨架
│   ├── pages/                   # 页面
│   │   ├── home_page.dart       # 主页
│   │   ├── academic_page.dart   # 教务中心
│   │   ├── info_page.dart       # 信息中心
│   │   ├── quick_links_page.dart# 快速跳转
│   │   ├── settings_page.dart   # 设置
│   │   └── lock_page.dart       # 锁定页
│   └── services/                # 服务层
│       └── password_service.dart# 密码管理
├── test/                        # 测试文件
│   └── widget_test.dart         # 冒烟测试
├── android/                     # Android 平台配置
├── ios/                         # iOS 平台配置
├── macos/                       # macOS 平台配置
├── linux/                       # Linux 平台配置
├── windows/                     # Windows 平台配置
├── web/                         # Web 平台配置
├── docs/                        # 项目文档
│   ├── API.md                   # API 文档
│   ├── CHANGELOG.md             # 变更日志
│   ├── DESIGN.md                # 设计文档
│   └── USAGE.md                 # 使用文档（本文件）
├── .github/                     # GitHub 配置
│   ├── workflows/                 # CI 与 Release 工作流
│   ├── ISSUE_TEMPLATE/            # Issue 模板
│   └── PULL_REQUEST_TEMPLATE/     # PR 模板
├── LICENSE                      # Artistic License 2.0 许可证
├── pubspec.yaml                 # 项目配置与依赖
├── pubspec.lock                 # 依赖锁定文件
└── analysis_options.yaml        # 静态分析配置
```

---

## 10. 故障排查

### 10.1 依赖安装失败

```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### 10.2 平台编译错误

```bash
# 确认平台工具链已安装
flutter doctor -v

# 重新生成平台配置文件（慎用，会覆盖自定义配置）
# flutter create .
```

### 10.3 Windows CMake 缓存路径错误

如果项目目录改名后运行 `flutter run -d windows`，并出现 `CMakeCache.txt directory ... is different` 或 `source ... does not match`，说明 `build/windows` 中仍保留旧源码路径缓存。删除可再生缓存后重新构建即可：

```bash
rm -rf build/windows
flutter pub get
flutter run -d windows
```

### 10.4 Fluent 2 组件编译问题

确认 Flutter SDK 版本满足 `pubspec.yaml` 的最低要求，并避免重新引入已移除的外部 Fluent UI 依赖：

```bash
flutter --version
flutter analyze
```

### 10.5 Android release 构建失败

若 `flutter build apk --release` 提示缺少签名配置，请检查：

- `android/key.properties` 是否存在
- `storeFile` 是否指向实际存在的 keystore 文件
- `storePassword` / `keyPassword` / `keyAlias` 是否与 keystore 一致

### 10.6 本地状态文件异常

桌面端会将用户设置、认证信息、消息缓存和 WebView2 运行态写入 `~/.sspu-aio/`；Android / iOS 会写入系统分配的应用支持目录下的 `.sspu-aio/`。设置页提供 `wxmp_config.toml` 内置编辑器，移动端可直接在应用内修改公众号平台认证配置。全局学期设置写入统一状态文件，教务凭据使用系统安全存储单独保存，不写入 `app_state.json`，安全设置页只显示学工号和密码填写状态。若状态文件损坏或需要重建本地状态，可先退出应用，备份后删除对应目录中的文件，再重新启动应用。

常用文件：

- `app_state.json`：应用设置、全局学期设置、消息缓存、已读状态、关注列表；系统快速验证只保存 `app_quick_auth_enabled` 布尔配置，不保存任何 PIN、生物识别或系统认证原始数据
- `wxmp_config.toml`：微信公众号平台认证与高级抓取参数
- `webview2/`：Windows WebView2 用户数据目录
- 系统安全存储：学工号、OA 密码、体育部查询密码和邮箱密码；Linux 打包运行时需提供 `libsecret` 相关依赖

### 10.7 法律与隐私说明及数据清理

首次启动、协议版本更新或用户尚未确认当前协议时，会展示“法律与隐私说明”确认弹窗。该弹窗在同一篇文档中合并展示免责声明、用户协议、隐私协议、开源许可证与第三方协议说明；一次点击“同意全部协议并继续”即确认全部内容，拒绝同意会退出应用入口。

Windows x64 / arm64 Inno Setup 安装器会在安装阶段展示同一份中文法律与隐私说明并要求确认。Android、iOS、macOS、Linux、Web 以及 portable / 压缩包等当前没有由仓库统一控制的安装前 GUI 或 CLI 确认页，因此以首次启动确认作为兜底。

关于页提供“法律与隐私说明”入口，可随时查看本地状态文件、系统安全存储、WebView2 运行态、外部服务访问、用户清理方式、开源许可证和主要第三方组件说明。协议正文同时提供中文与英文资产，便于后续 i18n 扩展。

协议确认状态使用 `agreement_20260607_artistic20_combined_accepted` 保存；旧版 `agreement_20260515_artistic20_accepted`、`agreement_20260515_accepted` 与 `eula_accepted` 仅保留为历史状态，不作为当前协议确认依据。已确认旧协议的用户需要重新确认当前完整法律与隐私说明。

隐私说明中的清理入口与设置页保持一致：安全设置可清理信息中心缓存、清除全部本地数据，教务凭据区域可单独清除 OA 密码、体育部查询密码和邮箱密码，微信公众号平台区域可清除认证信息或编辑 `wxmp_config.toml`。

---

## 11. 注意事项

1. **不要提交 `.env` 文件**：项目 `.gitignore` 已配置忽略环境变量文件
2. **不要修改 `pubspec.lock`**：除非执行了 `flutter pub get/upgrade`
3. **Windows 开发**：确保以管理员身份运行 Visual Studio Installer 安装 C++ 工作负载
4. **Web 调试**：推荐使用 Chrome，其他浏览器可能存在兼容性差异
5. **用户数据存储位置**：桌面端位于 `~/.sspu-aio/`，移动端位于系统分配的应用支持目录下的 `.sspu-aio/`，包括密码哈希、设置项、消息缓存、微信公众号认证配置和 WebView2 运行态；教务凭据另存于系统安全存储
6. **协议入口**：首次启动会展示完整法律与隐私说明，关于页可随时查看免责声明、用户协议、隐私协议、开源许可证与第三方协议说明
