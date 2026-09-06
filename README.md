# MacAutoTranslate

MacAutoTranslate 是一个原生 Swift 编写的 macOS 菜单栏翻译工具。按 `⇧⌘6` 打开 Spotlight 风格浮窗，输入多行文本后按 `⇧Enter` 翻译；结果自动复制到剪贴板。

项目不仅包含 UI，还把翻译能力拆成了可复用 Swift 库、localhost HTTP API、命令行服务和 MCP Server。

## 功能

- `⇧⌘6` 全局快捷键显示/隐藏浮窗（Carbon hot key，不需要辅助功能权限）
- 源文本框中 `Enter` 换行，`⇧Enter` 或图标按钮执行翻译
- 点击浮窗以外的区域自动关闭浮窗，不遮挡其他应用
- 保留上一次输入和翻译；首次启动为空
- 输入与结果支持多行并按真实文字排版自动增高，不截断内容
- 清空源文本时同步清空翻译结果
- 自动识别中文/中文混合文本并翻译为英文；其他文本翻译为中文
- “自动语言方向”默认开启；可编辑源语言、目标语言，手动编辑后自动关闭该选项
- 翻译成功后自动复制到剪贴板，亦可点击复制图标
- 原生毛玻璃背景、统一圆角和等距四边边距
- OpenAI Responses API 与 Anthropic Messages API
- 内置 Kimi Code（Anthropic 兼容）预设
- 菜单栏设置：provider、Base URL、model、API key、prompt、timeout、服务端口、连接测试
- API key 仅保存到 app 私有配置目录的 `credentials.json`（权限 `0600`），不使用 Keychain、环境变量或仓库文件

## 构建与运行

要求 macOS 13+、Xcode 16+。

```bash
swift build
swift test
swift run MacAutoTranslate
```

构建可双击的 app bundle：

```bash
./scripts/build-app.sh
open dist/MacAutoTranslate.app
```

单独运行核心 HTTP 服务：

```bash
swift run mac-auto-translate-service --port 8765
```

运行 MCP Server：

```bash
swift run mac-auto-translate-mcp
```

详细说明见 [PRD](docs/PRD.md)、[架构](docs/ARCHITECTURE.md)、[API](docs/API.md)、[MCP](docs/MCP.md) 和 [安全](docs/SECURITY.md)。

## 配置位置

默认目录：`~/Library/Application Support/MacAutoTranslate/`

- `config.json`：非敏感模型设置和 prompt
- `credentials.json`：API key，文件权限 `0600`
- `session.json`：上一次输入、结果和语言方向

可在测试或便携运行时通过 `MAC_AUTO_TRANSLATE_HOME` 指定其他目录。不要把该目录放进仓库。

## License

MIT
