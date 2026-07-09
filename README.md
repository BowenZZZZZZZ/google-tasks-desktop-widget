# Google Tasks Desktop

A small macOS SwiftUI app that shows incomplete tasks from the Google Tasks list named `Desktop`.

It is intentionally a normal macOS app window: Dock icon, standard window controls, minimizable, closable, and movable between Desktops/Spaces.

## Features

- Shows incomplete tasks from the Google Tasks list named `Desktop`.
- Uses Google OAuth Desktop App flow with localhost callback and PKCE.
- Stores the Google refresh token in macOS Keychain.
- Manual refresh button.
- Auto refresh options: off, 1 hour, 2 hours, 4 hours, 8 hours, 12 hours.
- Opens Google Tasks web UI for task management.
- No task editing/completion support yet.

## Requirements

- macOS 13 or newer
- Xcode Command Line Tools / Swift toolchain
- A Google Cloud OAuth Desktop client

## Build And Run

```bash
git clone <repo-url>
cd GoogleTasksDesktopWidget
bash scripts/install.sh
open ".build/Google Tasks Desktop.app"
```

For development:

```bash
swift run
```

## Google API Setup

Before signing in, create a Google Cloud OAuth Desktop client and enable Google Tasks API:

```text
docs/google-oauth-setup.md
```

Paste the client ID and client secret into the app Settings. Do not commit real client secrets.

Public builds intentionally ship with empty OAuth fields. Your local values are stored in macOS preferences after you click **Save**.

The app requests only:

```text
https://www.googleapis.com/auth/tasks.readonly
```

## Codex Handoff

Give another Codex instance this repository URL and ask it to read:

```text
AGENTS.md
docs/codex-install.md
```

That is enough for another Codex to build the app and guide a user through Google API setup.
