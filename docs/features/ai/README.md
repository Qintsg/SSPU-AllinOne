# AI 助手（AI Assistant）

> 业务域：`ai`　·　所属：[功能总览](../README.md)

## 1. 模块职责

基于用户自带模型（BYOK）的跨域智能助手：围绕校园各域**只读**数据提供问答、汇总、自然语言查询与操作引导，并在引入 AI 后保持「数据本地不上云、可控可审计」。

## 2. 功能清单

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| AI 助手对话 | 设计中 | — | [`ai-assistant.md`](ai-assistant.md) |
| 模型与数据边界 | 设计中 | — | [`model-data-boundary.md`](model-data-boundary.md) |
| 本地数据 MCP 暴露 | 设计中 | — | [`mcp-server.md`](mcp-server.md) |

## 3. 关键设计

- **模型来源**：BYOK，OpenAI 兼容端点（可对接云端代理或本地 Ollama/LM Studio/vLLM）；Key 进安全存储。
- **取数方式**：工具调用按需最小拉取（function calling），经按域授权。
- **数据边界**：默认不出域；每类只读数据出域需显式授权、最小必要、透明可审计。
- **执行边界**：可代执行只读查询；写操作（选课/发邮件等）**仅引导、不代执行**。
- **对外暴露（MCP）**：可选把本地只读数据通过 MCP（HTTP/SSE，可配端口/地址）暴露给外部客户端；默认关闭、必须 Token、复用按域授权、**仅桌面**。

## 4. 内部依赖

- [AI 助手对话](ai-assistant.md) 依赖 [模型与数据边界](model-data-boundary.md)（Provider + 授权 + 出域策略）。
- 经授权只读工具读取教务/资讯/校园卡等各域数据；UI 复用 [`ai-message` 组件](../../design/components/ai-message.md)。

## 5. 模块级约束

- 必须遵守全局**只读**原则；AI 无任何写能力。
- **数据本地优先**：默认不出域，出域边界显式、用户可控；Key/出域内容不进日志。
- 未配置模型或未授权时，能力优雅不可用，不静默出域。

## 6. 相关 Issue

暂无。
