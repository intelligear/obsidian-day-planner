#!/usr/bin/env bash
# Register the optional MCP servers this workflow can use with Claude Code:
#   - icloud-calendar : read/write iCloud Calendar events
#   - reminders-mcp   : read/write macOS Reminders (via AppleScript)
# Safe to re-run; `claude mcp add` overwrites the existing entry for a name.
#
# Usage:
#   .claude/scripts/setup-mcp.sh              interactive prompts for iCloud creds
#   ICLOUD_USERNAME=... ICLOUD_PASSWORD=... .claude/scripts/setup-mcp.sh   non-interactive

set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI not found on PATH — install Claude Code first." >&2
  exit 1
fi

echo "== iCloud Calendar MCP =="
if [[ -z "${ICLOUD_USERNAME:-}" ]]; then
  read -r -p "iCloud username (Apple ID email): " ICLOUD_USERNAME
fi
if [[ -z "${ICLOUD_PASSWORD:-}" ]]; then
  read -r -s -p "iCloud app-specific password (generate at appleid.apple.com): " ICLOUD_PASSWORD
  echo
fi

claude mcp add icloud-calendar \
  --env ICLOUD_USERNAME="$ICLOUD_USERNAME" \
  --env ICLOUD_PASSWORD="$ICLOUD_PASSWORD" \
  -- npx @icloud-calendar-mcp/server

echo "== macOS Reminders MCP =="
claude mcp add reminders-mcp -- npx -y reminders-mcp

echo
echo "Done. Verify with: claude mcp list"
echo "Restart Claude Code (or start a new session) to pick up the new tools."
echo "macOS may prompt for Reminders/Calendar automation access on first use — approve it in System Settings > Privacy & Security."
