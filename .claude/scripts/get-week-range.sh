#!/usr/bin/env bash
# Output the calendar week containing TARGET, bounded by week_start from .config.
# Usage: bash .claude/scripts/get-week-range.sh [YYYY-MM-DD]
# Prints:
#   WEEK_START=YYYY-MM-DD
#   WEEK_END=YYYY-MM-DD
#   WEEK_START_DAY=Monday   (from config)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.config"

TARGET="${1:-$(date +%Y-%m-%d)}"
start_name="${week_start:-Monday}"

start_name_lc=$(printf '%s' "$start_name" | tr '[:upper:]' '[:lower:]')
case "$start_name_lc" in
  monday)    start_dow=1 ;;
  tuesday)   start_dow=2 ;;
  wednesday) start_dow=3 ;;
  thursday)  start_dow=4 ;;
  friday)    start_dow=5 ;;
  saturday)  start_dow=6 ;;
  sunday)    start_dow=7 ;;
  *)         start_dow=1; start_name=Monday ;;
esac

dow=$(date -j -f "%Y-%m-%d" "$TARGET" +%u)   # 1=Mon … 7=Sun
days_back=$(( (dow - start_dow + 7) % 7 ))

week_start=$(date -j -v-"${days_back}"d -f "%Y-%m-%d" "$TARGET" +%Y-%m-%d)
week_end=$(date -j -v+6d -f "%Y-%m-%d" "$week_start" +%Y-%m-%d)

printf 'WEEK_START=%s\n' "$week_start"
printf 'WEEK_END=%s\n' "$week_end"
printf 'WEEK_START_DAY=%s\n' "$start_name"
