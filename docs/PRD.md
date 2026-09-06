# MacAutoTranslate PRD

## 1. 产品定义

MacAutoTranslate 是面向高频双语写作的 macOS 菜单栏工具。核心价值是“不离开当前工作流，用一次快捷键打开、一次快捷键翻译，并把结果直接放进剪贴板”。

## 2. 目标用户与场景

- 中英文混合工作的开发者、产品经理、研究人员和内容创作者。
- 在任意 app 中需要快速翻译一段多行文本。
- Agent、脚本或其他 UI 需要复用同一翻译 prompt 和 provider 配置。

## 3. 成功标准

- 冷启动后能从菜单栏进入设置并完成 provider 测试。
- app 运行时 `⇧⌘6` 在 150 ms 内显示可输入浮窗。
- 多行文本布局不截断主要操作；网络请求期间 UI 保持响应。
- 成功翻译后剪贴板内容与结果完全一致。
- 核心库、HTTP 和 MCP 返回一致的翻译结果与语言方向。
- 仓库及 Git 历史不含凭证。

## 4. 用户流程

1. 首次启动：菜单栏出现图标；浮窗第一次打开为空。
2. 用户在设置中选择 OpenAI/Anthropic，输入 Base URL、model、API key 和 prompt，点击“测试连接”。
3. 用户在任意 app 按 `⇧⌘6`，输入文字。
4. 自动方向开启时：包含汉字则显示 中文 → 英文，否则显示 自动检测 → 中文。
5. 用户可直接编辑源/目标语言；编辑即切换为手动方向。
6. 按 `⇧T` 或翻译图标。结果出现在下方并自动复制。
7. 关闭再打开浮窗仍显示上次输入和结果；首次记录不存在时为空。

## 5. 范围

### MVP

- Spotlight 风格浮窗、菜单栏设置、全局/局部快捷键、多行自适应。
- OpenAI Responses 与 Anthropic Messages（含 Kimi 预设）。
- app 私有文件配置、会话恢复、连接测试。
- Swift library、localhost HTTP API、CLI daemon、stdio MCP server、文档和测试。

### 非目标

- 首版不做 OCR、划词、自动粘贴回原 app、翻译历史搜索、云同步、App Store 签名/公证。
- 不内置或代理任何 API key。

## 6. 关键交互与错误

- 翻译按钮在空文本时禁用；请求中显示进度并避免重复提交。
- `Esc` 关闭浮窗；再次打开恢复状态。
- 配置缺失、HTTP 非 2xx、服务返回错误、无可解析文本均显示在浮窗或设置窗口。
- 复制按钮提供短暂成功反馈。
- 全局快捷键注册冲突时在设置/菜单中显示明确错误。

## 7. 安全与隐私

- API key 不进 UserDefaults、Keychain、环境变量、日志、HTTP summary、MCP 输出或仓库。
- 按用户约束，凭证存 app 自有 `credentials.json`，目录 `0700`、文件 `0600`。这是本地明文存储；共享账号/不可信本机场景应改为 Keychain（需用户重新授权设计变更）。
- HTTP 仅监听 `127.0.0.1`，不提供远程绑定参数。
- OpenAI 请求设置 `store: false`；其他 provider 的数据保留遵循其服务条款。

## 8. 验收用例

- 中/中英混合/英文/日文输入的默认方向正确。
- `[Source]`、`[Target]` 在 prompt 中全部替换；格式原样发送。
- 两种 provider 的 URL、header、JSON body、响应解析通过 mock 测试。
- app 重启恢复会话；凭证与普通配置分文件且权限正确。
- `/health`、`/v1/translate` 可调用；MCP `initialize`、`tools/list`、`tools/call` 可用。
