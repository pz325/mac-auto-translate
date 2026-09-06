# Security

## Secret handling

MacAutoTranslate never reads API keys from repository files or command-line flags. The app writes the key to:

`~/Library/Application Support/MacAutoTranslate/credentials.json`

The directory is created with owner-only access and the file is forced to mode `0600`. This follows the explicit requirement not to use system credential storage. It is still local plaintext; Keychain would be stronger if that constraint changes.

The HTTP configuration endpoint returns only a redacted `hasAPIKey` boolean. Errors sanitize the configured key if a provider echoes it.

## Before pushing

Run:

```bash
swift test
./scripts/check-secrets.sh
git diff --check
git status --short
```

Review both tracked content and commit history. Revoke any token pasted into chat, logs, shell history, issue bodies, or previous commits before using the repository.

## Local service

The HTTP service binds only to loopback. It has no authentication, so any process running as a local user may call it. Do not expose it through port forwarding or a reverse proxy without adding authentication.
