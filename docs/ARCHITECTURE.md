# 技术架构

## 组件图

```text
┌──────────────────────┐  ┌───────────────┐  ┌────────────────┐
│ SwiftUI/AppKit App   │  │ localhost API │  │ stdio MCP      │
│ Panel + Menu + Setup │  │ CLI daemon    │  │ Agent adapter  │
└──────────┬───────────┘  └───────┬───────┘  └───────┬────────┘
           └──────────────────────┼───────────────────┘
                                  ▼
                    ┌─────────────────────────┐
                    │ MacAutoTranslateCore    │
                    │ Language / Prompt / LLM │
                    │ Config / Session / HTTP │
                    └─────────────┬───────────┘
                                  ▼
                    OpenAI Responses / Anthropic Messages
```

## 分层

- `MacAutoTranslateCore`：无 UI 的领域模型、语言方向、prompt 渲染、provider client、持久化、HTTP server。可被 Swift UI 或其他 Swift 程序直接 import。
- `MacAutoTranslateApp`：SwiftUI 视图与 AppKit `NSPanel`/Carbon hotkey 适配；启动时在进程内启动同一 HTTP service。
- `MacAutoTranslateService`：前台 CLI，加载相同配置并保持 localhost listener。
- `MacAutoTranslateMCP`：无第三方 SDK 的轻量 stdio JSON-RPC 适配器。

## 数据与状态

- `LLMConfiguration`：provider、base URL、model、prompt、timeout、port；写 `config.json`。
- `Credentials`：单独写 `credentials.json`，避免配置导出意外泄漏。
- `TranslationSession`：输入、结果、源/目标语言、自动方向；写 `session.json`。
- App 的 `AppState` 是 UI 单一事实源；核心 store 是磁盘事实源。

## 语言方向

`LanguageDetector` 检查 Unicode Han script：只要包含汉字就视为中文或中文混合，解析为 中文 → 英文；否则 自动检测 → 中文。手动修改任一语言字段会禁用自动方向。

## Provider 适配

- OpenAI：`POST {base}/v1/responses`；`instructions` 为渲染后的 prompt，`input` 为原文，`store=false`。
- Anthropic：`POST {base}/v1/messages`；`system` 为 prompt，`messages[0]` 为原文。
- Endpoint resolver 接受 host、`/v1` 或已经完整 endpoint 的 Base URL，避免重复 `/v1`。
- Provider 响应按异构内容块解析：忽略 `thinking`、`reasoning`、tool 等非文本块，仅拼接最终文本块。
- LLM 使用无磁盘缓存的 ephemeral URLSession，避免原文和译文进入 HTTP cache。

## 服务生命周期

- AppDelegate 启动后创建 `TranslationHTTPServer`，并注册 `⇧⌘6`；退出时取消 listener 和 hotkey。
- CLI 直接创建同一 server 并进入 `RunLoop`。
- App 与独立 CLI 不能同时绑定同一端口；App 会显示端口占用错误，但浮窗直连核心库仍可翻译。

## 设计决策

- 不引入第三方 package：降低供应链和构建复杂度。
- Carbon hotkey：此固定普通组合键无需 Accessibility 权限。
- SwiftPM 多 product：核心复用与命令行构建简单；`build-app.sh` 生成开发用 `.app` bundle。
- 原始 HTTP parser 仅服务小型本地 JSON 请求，设置 2 MB 上限；生产扩展可替换为成熟 server framework，核心接口不变。
