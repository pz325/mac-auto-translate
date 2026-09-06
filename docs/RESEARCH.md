# 调研摘要

调研日期：2026-09-05。

## 产品与源码

### Easydict

- 原生 macOS 词典/翻译工具，支持输入翻译、划词、OCR、全局与窗口内快捷键、多翻译服务、自动识别语言。
- 有主窗口、浮窗、迷你窗口三类表面，说明翻译工具需要按使用场景控制信息密度。
- 其工程指南采用 feature-oriented 目录、SwiftUI 新界面、单元测试和完整本地化。
- 对本项目的启发：保留极简输入浮窗，把复杂 provider/prompt 设置放在菜单栏设置窗口；快捷键与翻译引擎解耦。

### Transly

- 纯 macOS 菜单栏翻译工具，使用浮动 HUD；项目明确拆分 Hotkey、Translation、Settings、Design 等模块。
- 使用 Carbon `RegisterEventHotKey` 处理普通全局组合键，避免仅为 `⇧⌘6` 请求辅助功能权限。
- 对本项目的启发：panel 与主翻译视图复用、协调器持有长生命周期组件、快捷键适配器不进入核心库。

### Bob / PopClip 集成

- Bob 的 PopClip 集成体现了“选中文本—点图标—立即翻译”的低交互成本。
- 本项目首版不做跨应用取词，因此不申请 Accessibility/Screen Recording；用输入浮窗把权限面降到最低。

## 平台与协议

- Swift Package Manager 的 product 可以是 library 或 executable，适合从同一代码库产出核心库、App、HTTP 服务和 MCP Server。
- OpenAI 使用 Responses API `POST /v1/responses`，把系统规则放入 `instructions`，原文放入 `input`，并设置 `store: false`。
- Anthropic 兼容层使用 `POST /v1/messages`、`x-api-key` 与 `anthropic-version`。
- Kimi Code 官方文档确认 Anthropic 兼容 Base URL 为 `https://api.kimi.com/coding/`，endpoint 为 `/v1/messages`。
- MCP stdio 使用 UTF-8 JSON-RPC，每条消息以换行分隔，stdout 只能输出协议消息。

## AI coding Markdown

参考 SwiftAgents 和 Easydict 的 `AGENTS.md`，本项目生成了根目录 `AGENTS.md`。针对 macOS 13 和 SwiftPM 做了调整，重点是：核心库边界、Swift concurrency、无第三方依赖、敏感信息保护、单元测试、release 前检查。

## 参考资料

- https://github.com/tisfeng/Easydict
- https://github.com/tisfeng/Easydict/blob/dev/AGENTS.md
- https://github.com/vlr-code/transly
- https://github.com/twostraws/SwiftAgents
- https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html
- https://developers.openai.com/api/reference/cli/resources/responses/methods/create
- https://platform.claude.com/docs/en/api/overview
- https://www.kimi.com/code/docs/
- https://modelcontextprotocol.io/specification/draft/basic/transports
