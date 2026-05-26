#!/usr/bin/env bash
# Output the daily note title (filename without .md) for today or a given date.
# Usage:
#   get-daily-note-title.sh              → today's title
#   get-daily-note-title.sh YYYY-MM-DD   → title for the given date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.config"

fmt="${daily_note_date_format:-MM-DD (ddd)}"

# Convert format tokens to strftime specifiers (BSD date / macOS)
date_fmt="${fmt//YYYY/%Y}"
date_fmt="${date_fmt//MM/%m}"
date_fmt="${date_fmt//DD/%d}"
date_fmt="${date_fmt//ddd/%a}"

if [[ -n "$1" ]]; then
  date -j -f "%Y-%m-%d" "$1" +"$date_fmt"
else
  date +"$date_fmt"
fi
