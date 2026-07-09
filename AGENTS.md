# Codex Handoff

This repo is a small macOS SwiftUI app that shows incomplete Google Tasks from a task list named `Desktop`.

## Quick Start

```bash
swift build
bash scripts/build_app_bundle.sh
open ".build/Google Tasks Desktop.app"
```

For a first-time user, set up a Google OAuth Desktop client first:

```text
docs/google-oauth-setup.md
```

The app asks for the OAuth desktop client ID and client secret in Settings. Do not hard-code or commit real credentials.

## Important Files

- `Sources/GoogleTasksDesktopWidget/AppState.swift`: UI state, refresh scheduling, settings storage.
- `Sources/GoogleTasksDesktopWidget/GoogleTasksService.swift`: Google OAuth + Tasks REST client.
- `Sources/GoogleTasksDesktopWidget/OAuthLoopbackServer.swift`: localhost callback server for OAuth installed-app flow.
- `scripts/build_app_bundle.sh`: builds a terminal-free `.app`.
- `scripts/make_app_icon.py`: regenerates app icon assets.

## Checks

Run:

```bash
swift build
bash scripts/build_app_bundle.sh
```

The build may emit a Swift Sendable warning from Network callbacks; it does not block the app.
