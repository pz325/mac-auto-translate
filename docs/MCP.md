# MCP Server

`mac-auto-translate-mcp` exposes the core library as one stdio tool named `translate`. It implements JSON-RPC initialization, ping, tool discovery, and tool calls. Protocol messages are newline-delimited UTF-8 JSON; diagnostics never go to stdout.

## Build

```bash
swift build -c release --product mac-auto-translate-mcp
```

Executable path:

```text
<repository>/.build/release/mac-auto-translate-mcp
```

## Client configuration

Use the absolute executable path in your MCP client's configuration:

```json
{
  "mcpServers": {
    "mac-auto-translate": {
      "command": "/absolute/path/to/.build/release/mac-auto-translate-mcp",
      "args": []
    }
  }
}
```

The server reads the same app-owned configuration as the UI and HTTP service. Configure and test the provider in the MacAutoTranslate menu-bar settings first.

## Tool

```json
{
  "name": "translate",
  "arguments": {
    "text": "需要翻译的文本",
    "sourceLanguage": "中文",
    "targetLanguage": "英文"
  }
}
```

Only `text` is required. The result contains both MCP text content and structured fields for translated text, resolved languages, provider, and model.
