#!/usr/bin/env bash
# archive-old-notes.sh — move old daily notes to zzArchive/
# Uses file creation date (birthtime) to avoid year ambiguity in note filenames.
# Usage: bash .claude/scripts/archive-old-notes.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
VAULT_DIR="$(dirname "$CLAUDE_DIR")"
source "$CLAUDE_DIR/.config"

[[ "${archive_enabled:-0}" -eq 0 ]] && exit 0

DAYS="${archive_after_days:-30}"
ARCHIVE_DIR="${VAULT_DIR}/${archive_dir:-zzArchive}"
NOTES_DIR="${VAULT_DIR}${daily_notes_folder:+/${daily_notes_folder%/}}"

mkdir -p "$ARCHIVE_DIR"

today=$(date +%Y-%m-%d)
cutoff=$(date -j -v-"${DAYS}"d -f "%Y-%m-%d" "$today" +%Y-%m-%d)

count=0

for f in "$NOTES_DIR"/*.md; do
  [[ -f "$f" ]] || continue

  filename="$(basename "$f" .md)"

  # Get file creation date (birthtime) — macOS stat
  created=$(stat -f "%SB" -t "%Y-%m-%d" "$f" 2>/dev/null) || continue
  [[ -z "$created" ]] && continue

  # Skip today and future notes
  [[ "$created" > "$today" || "$created" == "$today" ]] && continue

  # Confirm this file is a daily note: its name must match what the format
  # would produce for its creation date
  expected=$(bash "$SCRIPT_DIR/get-daily-note-title.sh" "$created" 2>/dev/null)
  [[ "$filename" != "$expected" ]] && continue

  # Skip if not old enough
  [[ "$created" > "$cutoff" ]] && continue

  mv "$f" "$ARCHIVE_DIR/$(basename "$f")"
  (( count++ ))
done

if (( count > 0 )); then
  echo "Archived ${count} note$([ $count -eq 1 ] || echo 's')."
else
  echo "Nothing to archive."
fi
