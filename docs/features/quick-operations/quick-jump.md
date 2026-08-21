# 快捷跳转

> 模块：[常用操作](README.md)　·　状态：**部分实现**（配置/搜索层已实现，前端重构 + 新增 App 深链与平台可见性）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `quick-operations.quick-jump` |
| 状态 | 部分实现 |
| 平台 | 全平台（条目按平台可见性过滤） |
| 关联 Issue | #280 |
| 主要代码 | `lib/services/quick_links_config_service.dart`、`quick_links_search_service.dart` |

## 1. 需求

以配置驱动方式提供校园站点、办事入口与常用 App 的快捷跳转；支持移动端 App 深链，并按平台/安装情况过滤可见条目。

**验收要点**
- 配置分组展示跳转条目，支持关键词搜索。
- App 类条目作为**独立条目**呈现（如「学习通（APP）」「学习通（网页）」「学习通（OA）」分列）。
- **无对应 App 的平台或未安装时，App 条目直接隐藏**（不回退、不报错）。

## 2. 配置模型（沿用并扩展 `quick_links.yaml`）

```yaml
site_groups:
  - category: 学习平台
    items:
      - name: 学习通（APP）
        kind: app          # web | app | oa
        url: <App 深链/scheme>
        appId: <包名/Bundle ID 或 scheme，用于安装检测>
        platforms: [android, ios]   # 适用平台白名单；省略=全平台
        icon: <可选>
      - name: 学习通（网页）
        kind: web
        url: https://...
      - name: 学习通（OA）
        kind: oa
        url: <OA 入口>
```

- 新增字段：`kind`（web/app/oa）、`platforms`（适用平台白名单）、`appId`（App 安装检测）。
- 现有 `category`/`name`/`url`/`icon` 保持兼容。

## 3. 实现

### 3.1 条目可见性

- 按当前平台与 `platforms` 白名单过滤；`kind: app` 条目额外做**安装检测**，未安装即隐藏。
- 隐藏而非禁用：用户只看到当前可用的入口。

### 3.2 跳转行为

| kind | 行为 |
| --- | --- |
| `web` | 内置 WebView 打开（带外部浏览器按钮），下载型 URL 交系统/外部（复用 [info 处理](../info/message-center.md)） |
| `app` | 移动端唤起目标 App 深链（#280 学习通）；唤起失败按隐藏前提不应出现 |
| `oa` | 经 OA 会话进入入口（依赖 [登录与凭据](../academic/auth-credentials.md)） |

### 3.3 搜索

- `quick_links_search_service`：在可见条目的名称/分类内本地搜索。

## 4. 关联

- 依赖：跳转配置（`quick_links.yaml`）；`oa` 类依赖 [登录与凭据](../academic/auth-credentials.md)；`web` 类复用 [info 的 WebView/下载处理](../info/message-center.md)。
- 关联：[文档查询](document-query.md)（同模块，办事入口与文档互补）。

## 5. 约束

- 仅做跳转与指引，不代理第三方登录态（`oa` 仅复用本校会话）。
- 外链来源需可信、明确；App 深链仅在确有 App 的平台呈现。
- 平台差异：桌面通常无 App 条目；移动端按安装情况过滤。

## 6. 待办与演进

- [ ] 配置模型扩展 `kind`/`platforms`/`appId`。
- [ ] App 安装检测与条目隐藏；移动端 App 深链（#280）。
- [ ] `oa` 类入口经 OA 会话跳转。
- [ ] `web` 类复用 info 的内置 WebView 与下载型 URL 处理。
