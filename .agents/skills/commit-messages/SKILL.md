---
name: commit-messages
description: Use when writing git commit messages in SSPU-AllinOne. Covers the required format, allowed types, and scope conventions.
---

# Commit Messages

Format: `type(scope): 中文摘要`

## Allowed Types

| type | Use |
|------|-----|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `style` | Formatting (no logic change) |
| `refactor` | Code restructuring |
| `test` | Tests |
| `chore` | Maintenance |
| `ci` | CI config |
| `build` | Build system |
| `perf` | Performance |
| `deps` | Dependencies |

## Scope

Lowercase, short description of affected area:

```
feat(wechat): 添加公众号订阅基础框架
fix(macos): 修复 Runner 构建路径错误
docs(readme): 更新构建说明
ci(actions): 添加 CodeQL 扫描
deps(flutter): 升级到 3.44.0
```

## Rules

- Summary MUST contain Chinese characters
- Use `type(scope): 中文摘要` format
- Keep summary concise (1 sentence)
- Scope is optional but recommended

## Linking Issues

In commit body or PR body:

- `Closes #123` — auto-close issue on merge
- `Fixes #123` — same as Closes
- `Resolves #123` — same as Closes
- `Refs #123` — reference without closing

## Examples

```
feat(auth): 添加微信扫码登录

fix(ios): 修复竖屏模式下导航栏缺失

docs(changelog): 更新 v1.0.0 变更记录

refactor(service): 提取通用刷新逻辑到基类

test(academic): 补充教务页面单元测试
```
