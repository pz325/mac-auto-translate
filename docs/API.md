# HTTP API

Start the service with `swift run mac-auto-translate-service`. It listens only on `127.0.0.1`; default port is `8765`.

## `GET /health`

```json
{"service":"mac-auto-translate","status":"ok","version":"0.1.0"}
```

## `GET /v1/config`

Returns redacted configuration. It never returns the prompt or API key.

```json
{
  "provider": "anthropic",
  "baseURL": "https://api.kimi.com/coding/",
  "model": "kimi-for-coding-flash",
  "timeoutMilliseconds": 600000,
  "servicePort": 8765,
  "hasAPIKey": true
}
```

## `POST /v1/translate`

Request:

```json
{
  "text": "你好，world",
  "sourceLanguage": "中文",
  "targetLanguage": "英文"
}
```

`sourceLanguage` and `targetLanguage` are optional. If omitted, Chinese or Chinese-mixed text resolves to 中文 → 英文; all other input resolves to 自动检测 → 中文.

Response:

```json
{
  "translatedText": "Hello, world",
  "sourceLanguage": "中文",
  "targetLanguage": "英文",
  "provider": "anthropic",
  "model": "kimi-for-coding-flash"
}
```

Example:

```bash
curl -sS http://127.0.0.1:8765/v1/translate \
  -H 'Content-Type: application/json' \
  -d '{"text":"Hello"}'
```

Errors use `{"error":"actionable message"}` and an appropriate HTTP status.
