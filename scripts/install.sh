#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$("$ROOT_DIR/scripts/build_app_bundle.sh" | tail -n 1)"

echo "Built app:"
echo "  $APP_PATH"
echo
echo "Open it with:"
echo "  open \"$APP_PATH\""
echo
echo "First-time Google OAuth setup:"
echo "  $ROOT_DIR/docs/google-oauth-setup.md"
