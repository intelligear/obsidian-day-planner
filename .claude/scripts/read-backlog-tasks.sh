#!/usr/bin/env bash
# read-backlog-tasks.sh — classify backlog tasks and print for /new-day
# Usage: bash .claude/scripts/read-backlog-tasks.sh [YYYY-MM-DD]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
VAULT_DIR="$(dirname "$CLAUDE_DIR")"
source "$CLAUDE_DIR/.config"
N="${daily_adhoc_task_per_category:-1}"

# ── Date ──────────────────────────────────────────────────────────────────────
TARGET="${1:-$(date +%Y-%m-%d)}"
DOW=$(date -j -f "%Y-%m-%d" "$TARGET" +%u)         # 1=Mon … 7=Sun
ABBR=$(date -j -f "%Y-%m-%d" "$TARGET" +%a)        # Mon
FULL=$(date -j -f "%Y-%m-%d" "$TARGET" +%A)        # Monday
MD=$(date -j -f "%Y-%m-%d" "$TARGET" +%-m-%-d)     # 5-25 (used for matching)
MNAME=$(date -j -f "%Y-%m-%d" "$TARGET" +%B)       # May
DAYNUM=$(date -j -f "%Y-%m-%d" "$TARGET" +%-d)     # 25
IS_WD=0; (( DOW <= 5 )) && IS_WD=1

# ── Top-level arrays (each entry: "task<TAB>category") ────────────────────────
recurring=()       # daily + every-weekday that apply today
weekday_today=()   # specific weekday matching today
date_today=()      # date literal matching today
flexible=()        # twice-a-week style
typos=()
categories=()      # ordered safe names
labels=()          # parallel display names

# ── Classification ────────────────────────────────────────────────────────────
matches() { echo "$1" | grep -qiE "$2"; }

is_daily()    { matches "$1" '\b(every[ -]?days?|everyday|everydya|everday|evryday|daily|each[ -]?day)\b' \
              || matches "$1" '\b(once|twice|[0-9]+[ ]*x|[0-9]+[ ]+times?)[ ]+(a|per)[ ]+day\b'; }
is_wdrecur()  { matches "$1" '\b(every[ -]?week[ -]?days?|weekdays?|wekdays?)\b'; }
has_namedday(){ matches "$1" '\bevery[ ]+(Mon|Tue|Wed|Thu|Fri|Sat|Sun|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)'; }
hits_today()  { matches "$1" '\bevery\b' && matches "$1" "\b(${ABBR}|${FULL})\b"; }
is_flexible() { matches "$1" '\b(once|twice|[0-9]+[ ]*x|[0-9]+[ ]+times?)[ ]+(a|per)[ ]+(week|month)\b'; }
is_urgent()   { matches "$1" '==.+=='; }
is_datehit()  { matches "$1" "${TARGET}|(^|[^0-9])${MD}([^0-9]|$)|\b${MNAME}[ ]+${DAYNUM}(st|nd|rd|th)?\b"; }

extract_time() {  # → HH:MM (24h) or empty
  local s h m ap
  # Try AM/PM first
  s=$(echo "$1" | grep -oiE '[0-9]{1,2}(:[0-9]{2})?[ ]*(AM|PM)' | head -1) || true
  if [[ -n "$s" ]]; then
    h=$(echo "$s" | grep -oE '^[0-9]+')
    m=$(echo "$s" | grep -oE ':[0-9]+' | tr -d ':'); [[ -z "$m" ]] && m=0
    ap=$(echo "$s" | grep -oiE 'AM|PM' | tr '[:lower:]' '[:upper:]')
    [[ "$ap" == PM && "$h" -ne 12 ]] && h=$((h+12))
    [[ "$ap" == AM && "$h" -eq 12 ]] && h=0
    printf '%02d:%02d' "$h" "$m"
    return
  fi
  # Fall back to 24h HH:MM (colon required to avoid matching bare integers)
  s=$(echo "$1" | grep -oE '\b([01]?[0-9]|2[0-3]):[0-5][0-9]\b' | head -1) || true
  [[ -z "$s" ]] && { echo ""; return; }
  h=$(echo "$s" | cut -d: -f1)
  m=$(echo "$s" | cut -d: -f2)
  printf '%02d:%02d' "$((10#$h))" "$((10#$m))"
}

cat_from_file() {
  basename "$1" .md | LC_ALL=C sed 's/^[^A-Za-z0-9]*//;s/[[:space:]]*$//'
}
safe_var() { printf '%s' "$1" | LC_ALL=C tr -cs 'A-Za-z0-9' '_' | sed 's/^_*//;s/_*$//'; }
in_arr()   { local n=$1; shift; for x in "$@"; do [[ "$x" == "$n" ]] && return 0; done; return 1; }

# ── Main loop ─────────────────────────────────────────────────────────────────
backlog_path="${VAULT_DIR}/${backlog_dir%/}"

if [[ ! -d "$backlog_path" ]]; then
  echo "ERROR: backlog_dir not found: ${backlog_dir}" >&2
  exit 1
fi

# Week range for flexible recurring (week_start from config)
week_meta=$(bash "$SCRIPT_DIR/get-week-range.sh" "$TARGET")
eval "$week_meta"

for mdfile in "$backlog_path"/*.md; do
  [[ -f "$mdfile" ]] || continue
  cat=$(cat_from_file "$mdfile")
  safe=$(safe_var "$cat")
  [[ -z "$safe" ]] && continue

  # Register category
  if ! in_arr "$safe" "${categories[@]:-}"; then
    categories+=("$safe")
    labels+=("$cat")
    eval "urgent_${safe}=()"
    eval "top_${safe}=()"
    eval "topn_${safe}=0"
  fi

  # Typos
  while IFS= read -r tl; do
    typos+=("$(basename "$mdfile"): $tl")
  done < <(grep -inE 'everydya|everday|evryday|evry day|wekday|weekdya|weekdas' \
           "$mdfile" 2>/dev/null || true)

  # Tasks  (|| [[ -n "$line" ]] catches the last line if file has no trailing newline)
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[[[:space:]]\][[:space:]] ]] || continue
    task="${line#*\[ \] }"
    task="${task#"${task%%[! ]*}"}"
    [[ -z "$task" ]] && continue

    entry="${task}"$'\t'"${cat}"

    if is_daily "$task";     then recurring+=("$entry")
    elif is_wdrecur "$task"; then (( IS_WD )) && recurring+=("$entry")
    elif has_namedday "$task"; then hits_today "$task" && weekday_today+=("$entry")
    elif is_flexible "$task";  then flexible+=("$entry")
    elif is_datehit "$task";   then date_today+=("$entry")
    elif is_urgent "$task";    then eval "urgent_${safe}+=(\"\$task\")"
    else
      eval "n=\${topn_${safe}}"
      if (( n < N )); then
        eval "top_${safe}+=(\"\$task\")"
        eval "topn_${safe}=$((n+1))"
      fi
    fi
  done < "$mdfile"
done

# ── Print ─────────────────────────────────────────────────────────────────────
hdr() { printf '\n── %s ──\n' "$1"; }
row() { printf '  [%-18s]  %s\n' "$2" "$1"; }

printf 'DATE %s  WEEKDAY %s\n' "$TARGET" "$FULL"
printf 'WEEK %s to %s  (week starts %s)\n' "$WEEK_START" "$WEEK_END" "$WEEK_START_DAY"

# Scheduled (sorted by start time)
hdr "SCHEDULED"
buf=()
for e in "${recurring[@]:-}" "${weekday_today[@]:-}" "${date_today[@]:-}"; do
  [[ -z "$e" ]] && continue
  t="${e%$'\t'*}"; c="${e##*$'\t'}"
  ts=$(extract_time "$t"); [[ -z "$ts" ]] && continue
  buf+=("${ts}"$'\t'"${t}"$'\t'"${c}")
done
if [[ ${#buf[@]} -gt 0 ]]; then
  while IFS=$'\t' read -r ts t c; do
    printf '  %s  %-50s [%s]\n' "$ts" "$t" "$c"
  done < <(printf '%s\n' "${buf[@]}" | sort)
else
  printf '  (none)\n'
fi

# Unscheduled recurring
hdr "UNSCHEDULED RECURRING"
any=0
for e in "${recurring[@]:-}" "${weekday_today[@]:-}" "${date_today[@]:-}"; do
  [[ -z "$e" ]] && continue
  t="${e%$'\t'*}"; c="${e##*$'\t'}"
  [[ -n "$(extract_time "$t")" ]] && continue
  row "$t" "$c"; any=1
done
(( any )) || printf '  (none)\n'

# Flexible
hdr "FLEXIBLE  (count - [x] completions ${WEEK_START} .. ${WEEK_END})"
if [[ ${#flexible[@]:-0} -gt 0 ]]; then
  for e in "${flexible[@]}"; do row "${e%$'\t'*}" "${e##*$'\t'}"; done
else
  printf '  (none)\n'
fi

# Urgent (per category)
hdr "URGENT"
any=0
for i in "${!categories[@]}"; do
  s="${categories[$i]}"; l="${labels[$i]}"
  eval "arr=(\"\${urgent_${s}[@]:-}\")"
  for t in "${arr[@]}"; do [[ -z "$t" ]] && continue; row "$t" "$l"; any=1; done
done
(( any )) || printf '  (none)\n'

# Ad-hoc preview (top N per category)
hdr "AD-HOC PREVIEW  (top ${N} per category)"
any=0
for i in "${!categories[@]}"; do
  s="${categories[$i]}"; l="${labels[$i]}"
  eval "arr=(\"\${top_${s}[@]:-}\")"
  for t in "${arr[@]}"; do [[ -z "$t" ]] && continue; row "$t" "$l"; any=1; done
done
(( any )) || printf '  (none)\n'

# Typos
hdr "TYPOS"
if [[ ${#typos[@]:-0} -gt 0 ]]; then
  for t in "${typos[@]}"; do printf '  %s\n' "$t"; done
else
  printf '  (none)\n'
fi
echo
