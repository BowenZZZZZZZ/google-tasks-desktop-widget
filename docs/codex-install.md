# Install With Codex

Give another Codex instance this repository URL and ask:

```text
Clone this repo, read AGENTS.md, run the build checks, then build and open the macOS app. If I have not configured Google OAuth yet, guide me through docs/google-oauth-setup.md.
```

Manual install:

```bash
git clone <repo-url>
cd GoogleTasksDesktopWidget
bash scripts/install.sh
```

Then open:

```bash
open ".build/Google Tasks Desktop.app"
```

First launch:

1. Click the gear button.
2. Paste your Google OAuth Desktop client ID.
3. Paste your Google OAuth Desktop client secret.
4. Save.
5. Click **Sign in**.
