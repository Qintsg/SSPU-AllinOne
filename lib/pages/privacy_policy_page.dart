/*
 * 隐私协议页面 — 展示本地数据、凭据、网络访问与用户控制说明
 * @Project : SSPU-AllinOne
 * @File : privacy_policy_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-15
 */

import '../design/fluent_ui.dart';

import '../theme/app_spacing.dart';

/// 隐私协议全文。
/// 本协议与当前应用的数据落盘、外部服务访问和清理能力保持同步。
const String kPrivacyPolicyText = '''
工大聚合（SSPU-AllinOne）隐私协议

开发者：Qintsg
最后更新日期：2026年5月15日

请在使用本软件前仔细阅读本协议。本协议说明工大聚合（SSPU-AllinOne）如何在您的设备上处理数据、访问外部服务，以及您可以如何管理本地数据。

一、适用范围

1. 本协议适用于工大聚合（SSPU-AllinOne）应用本身。

2. 本软件未获得上海第二工业大学（SSPU）、微信、微信公众平台及其关联方的任何官方授权、认可或背书。

3. 本软件访问的学校系统、腾讯企业邮箱、微信公众平台、系统浏览器组件、操作系统安全存储等第三方或系统能力，由相应服务提供方或系统提供方负责；您在这些服务中的账号、数据和行为同时受其规则约束。

二、数据处理原则

1. 本软件以本地处理为主。开发者不会主动收集、上传、出售或共享您的个人信息、登录凭据、业务数据、消息缓存、课程与成绩相关信息。

2. 本软件不提供开发者自建云端同步服务。当前版本没有将用户业务数据上传至开发者服务器的功能。

3. 本软件仅在完成功能所需时访问外部服务，并尽量保持只读查询边界；涉及外部网站登录、会话刷新、邮件协议登录或微信公众平台认证时，会按对应服务的页面或协议要求提交必要的账号、密码、Cookie、Token 或会话材料。

三、本地存储的数据

1. 桌面端应用数据默认保存在 `~/.sspu-aio/`；Android / iOS 保存在系统分配的应用支持目录下的 `.sspu-aio/`；Web 端使用浏览器提供的本地存储能力。

2. `app_state.json` 用于保存应用设置、密码保护哈希、系统快速验证开关、消息缓存、已读状态、关注列表、自动刷新设置、登录会话快照等状态数据。

3. `wxmp_config.toml` 用于保存微信公众号平台高级配置、Cookie、Token 及相关抓取参数。设置页提供内置编辑器和认证清除入口。

4. Windows 版本会在统一数据目录下创建 `webview2/`，用于 Edge WebView2 运行态、站点数据和浏览器组件缓存。

5. 学工号、OA 密码、体育部查询密码、邮箱密码和 OA 登录会话等可解密凭据保存于系统安全存储，不写入 `app_state.json`。

6. 应用锁密码不以明文保存，仅保存加盐后的 SHA-256 哈希。系统快速验证仅保存本地布尔开关，不保存、读取或记录系统 PIN、Face ID、Touch ID、生物识别模板等原始认证数据。

四、网络访问范围

1. 本软件会访问学校官网、教务相关页面、OA / CAS、校园卡、体育部查询系统、学工报表系统、学校邮箱 IMAP / POP / SMTP 服务、微信公众平台及您配置的微信公众号内容来源。

2. 网络访问用于读取消息、课程、成绩、考试、培养计划、校园卡余额、第二课堂学分、体育考勤、学校邮箱邮件和微信公众号文章等信息。

3. 本软件不主动执行选课、退课、教学评价、付款、发信、发布文章、修改外部账号资料等写入型操作；但外部服务自身的登录、会话刷新、访问日志、风控校验和 Cookie 更新可能由对应服务记录或处理。

4. HTTP 调试日志仅输出 scheme、host 和 path，不输出 query、fragment、userInfo、密码、Cookie、Token 或其他敏感认证字段。

五、系统权限与平台能力

1. 网络访问用于连接学校系统、邮箱协议服务、微信公众平台和网页内容来源。

2. 本地文件能力用于保存应用配置、缓存、WebView2 运行态和微信公众号平台配置文件。

3. 系统安全存储用于保存后续登录外部网站时必须可解密读取的凭据。

4. 系统快速验证用于在启用应用锁后辅助解锁。真实认证过程由操作系统完成，本软件只接收成功、失败、取消或不可用等结果。

5. 桌面端窗口、托盘和通知能力用于关闭行为管理、后台保留入口和本地系统通知。

六、用户控制与数据清理

1. 您可以在设置页清理信息中心缓存，该操作不会影响登录信息、设置和关注列表。

2. 您可以在设置页清除所有本地数据。该操作会清除应用状态、登录信息、设置、缓存和本软件管理的系统安全存储凭据，并退出应用。

3. 您可以在设置页的教务凭据区域单独清除 OA 密码、体育部查询密码或邮箱密码。

4. 您可以在设置页的微信公众号平台区域清除认证信息，或编辑 `wxmp_config.toml` 移除 Cookie、Token 和高级抓取参数。

5. 若需要手动重建本地状态，可在退出应用后备份并删除 `~/.sspu-aio/` 或移动端系统应用支持目录下的 `.sspu-aio/`。系统安全存储中的凭据建议优先通过应用内入口清除。

七、未成年人使用

本软件面向具备独立判断能力的校园用户。未成年人使用本软件前，应在监护人同意和指导下阅读本协议，并谨慎保存和使用账号凭据。

八、协议变更

开发者可能随软件更新调整本协议。修改后的协议将在软件更新或首次展示时生效。继续使用本软件即表示您接受修改后的协议。

九、联系与反馈

如对本协议或本软件的数据处理方式有疑问，请通过项目仓库提供的反馈渠道联系开发者。
''';

/// 隐私协议页面。
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentPage.scrollable(
      header: const FluentPageHeader(title: Text('隐私协议')),
      padding: AppSpacing.regularPagePadding,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: FluentCard(
              padding: EdgeInsets.zero,
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: SelectableText(
                  kPrivacyPolicyText.trim(),
                  style: FluentTheme.of(context).typography.body,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
