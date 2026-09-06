# AI coding guide for MacAutoTranslate

This is a native macOS 13+ Swift 6 tool built with Swift Package Manager. It exposes one library and three executable products: the menu-bar app, localhost HTTP service, and stdio MCP server.

## Non-negotiable rules

- Never commit API keys, access tokens, credentials, personal paths, or generated app data.
- Keep translation behavior in `MacAutoTranslateCore`; UI, HTTP, CLI, and MCP are adapters.
- Preserve provider-neutral models. Provider-specific wire formats belong in `LLMClient`.
- Use structured concurrency (`async`/`await`) for new asynchronous work.
- Keep UI state on `@MainActor`; do not block the main thread with network or file work.
- Prefer Foundation, SwiftUI, AppKit, Network, and Carbon already supplied by macOS. Ask before adding dependencies.
- Avoid force unwraps and `try!`. Return actionable, user-safe errors without including secrets.
- Add or update unit tests for language detection, prompt rendering, endpoint resolution, persistence, and provider response parsing.
- All externally visible core types require concise documentation comments.
- Keep source files focused; do not place unrelated types in one large file.

## Build and verification

```bash
swift build
swift test
./scripts/check-secrets.sh
./scripts/build-app.sh
```

For a release, also launch `dist/MacAutoTranslate.app`, verify `⇧⌘6`, test both providers, call `/health` and `/v1/translate`, and connect an MCP inspector/client.

## Style

- Four-space indentation; one primary type per file where practical.
- Types use `UpperCamelCase`; methods/properties use `lowerCamelCase`.
- Prefer value types and protocol boundaries. Use actors or explicit isolation for mutable cross-task state.
- In SwiftUI use semantic colors, SF Symbols, `foregroundStyle`, and accessible labels.
- User-facing errors should state what failed and the corrective action.

## Git workflow

- Use `feat/`, `fix/`, `docs/`, or `chore/` branches for collaborative work.
- Before every push, run tests and the secret scanner and inspect `git diff --check` plus staged changes.
- Never put credentials into a remote URL or command-line argument.
