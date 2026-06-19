# /new-day

Start (or refresh) today's daily planning note. One command for the whole flow: prepare the note, survey backlog and yesterday, propose changes, apply on a single confirmation.

## Purpose
Consolidates archive maintenance, backlog review, and apply into a single Y/N round-trip. Note creation is handled by Obsidian's Daily Notes plugin — `/new-day` focuses on what follows. Safe to re-run mid-day — it re-surveys and only proposes what's actionable.

## Step 1 — Silent prep (no user prompt)
Read `.claude/.config`. Then:

1. Run `bash .claude/scripts/get-daily-note-title.sh` to get today's note title (e.g. `05-25 (Mon)`).
   - Parse today's **date** from this output using `daily_note_date_format`.
   - Parse today's **weekday** directly from the title — e.g. extract `Mon` from `(Mon)`. **Never derive the weekday by mental arithmetic.** The script output is the authoritative source.
   - To get yesterday's title (needed for Step 2), run `bash .claude/scripts/get-daily-note-title.sh $(date -v-1d +%Y-%m-%d)`.
2. Resolve the daily note path: if `daily_notes_folder` is empty or `""`, the note lives at `<title>.md` in the vault root; otherwise at `<daily_notes_folder>/<title>.md`.
3. Check whether today's note exists.
   - **If it does not exist:** create it from the template at `templates/daily-note-template.md`. If the template file is missing, create a minimal note with just a `# Timeline` H1 section. Then continue as if the note had just been created.
   - **If it exists:** ensure the single H1 section `# Timeline` is present. Do not overwrite or reorder any existing content. Only add the section if it is entirely absent. No extra heading, no "Candidate from backlog" or "Move back to backlog" sections — those are transient planning scratchpads and must not appear in the final note.
4. Run the backlog parser to get pre-classified tasks:
   ```
   bash .claude/scripts/read-backlog-tasks.sh <YYYY-MM-DD>
   ```
   where `<YYYY-MM-DD>` is today's date (derived from the title in step 1). The script prints sections separated by `── HEADER ──` lines:
   - **SCHEDULED** — tasks with a specific time that apply today (daily, every-weekday, specific-weekday-matching-today, date-matching-today). Sorted by start time. Format: `HH:MM  <raw task text>  [Category]`
   - **UNSCHEDULED RECURRING** — same applicable tasks but without an explicit time. Format: `[Category]  <raw task text>`
   - **FLEXIBLE** — "twice a week" / "once a month" style. Header includes the week window (`WEEK_START` .. `WEEK_END`) derived from `week_start` in config. Need completion-count check before proposing.
   - **URGENT** — tasks wrapped in `==…==` from any category (always show in proposal).
   - **AD-HOC PREVIEW** — first N non-urgent ad-hoc tasks per category (N = `daily_adhoc_task_per_category` in config, default 1). The script intentionally shows only a preview so the proposal stays short — read the full backlog file for a category only when the user asks for more from that category or when proposing further triage.
   - **TYPOS** — suspected misspellings (`grep` line numbers included).

   **Do not re-read individual backlog files for task enumeration** — the script output is authoritative for today's classification. You still need to read specific backlog files only for operations that write back to them (Brain Dump triage, move-back-to-backlog, fetching more ad-hoc beyond the preview).

   If `auto_import_daily_recurring` is `1` (`$TRUE`): silently apply every task under SCHEDULED and UNSCHEDULED RECURRING to today's note using the placement and text-trimming rules below. Skip any task already present (match by trimmed task name) to avoid duplicates on re-run. Track each imported task for the final report. If `auto_import_daily_recurring` is `0` (`$FALSE`), skip this step entirely.

   If TYPOS is non-empty, collect for the final report — do not auto-fix in this step.

5. If `archive_enabled` is `1` (`$TRUE`), run `bash .claude/scripts/archive-old-notes.sh` to move old daily notes to `zzArchive/`. Capture its output and include a one-line summary in the final report (e.g. "Archived 3 notes." or "Nothing to archive.").

Do not announce these steps individually — surface them only in the final report.

## Step 2 — Survey
- Today's backlog task data is already loaded from the `read-backlog-tasks.sh` output in Step 1 (includes `WEEK …` line for flexible recurring).
- Read today's note and (if present) yesterday's note.
- For flexible recurring tasks and Brain Dump triage, read the relevant backlog files only as needed.
- Classify **every** unchecked line in yesterday's `# Timeline` as recurring vs ad-hoc using the rule below; this drives the carryover bucket in Step 3.

### Mandatory ad-hoc audit
After classifying, produce an internal checklist of all ad-hoc items found in yesterday's note (both checked and unchecked). For each unchecked ad-hoc item, verify it is accounted for by one of:
- Already present in today's note (carry-forward happened on a prior re-run), OR
- Being proposed in the Step 3 carryover bucket, OR
- Already completed (- [x]) — those stay in yesterday's note, nothing to do.

If an unchecked ad-hoc item is not yet in today's note and not in the proposal, add it to the proposal. **No ad-hoc leftover may be silently dropped.**

### Classifying yesterday's unchecked tasks (recurring vs ad-hoc)
With everything under a single `# Timeline`, the section no longer tells you whether a leftover is a recurring copy or a moved-out ad-hoc. Resolve it using the tag fast-path first, then fall back to the script-based lookup.

**First, run the backlog parser for yesterday's date** (once, before processing individual lines):
```
bash .claude/scripts/read-backlog-tasks.sh <yesterday-YYYY-MM-DD>
```
Collect the raw task text from the **SCHEDULED** and **UNSCHEDULED RECURRING** sections — these are the authoritative recurring tasks for yesterday. This sidesteps recurrence-format parsing entirely; the script already handles every weekday format (full names, abbreviations with/without dots, ranges like `Mon. - Fri.`, ordinals like `2nd Monday`, mixed multi-day lists like `every Wed., Thu.`, etc.).

For each `- [ ] …` line in yesterday's `# Timeline` (skip `- [x]`):

0. **Fast-path:** If the line contains ` (ad-hoc)` → immediately classify as **ad-hoc one-time**; skip steps 1–3 for this line.

1. **Normalize the daily-note line** to a comparison key:
   - Drop the leading `- [ ] ` (and any leading whitespace).
   - Strip a leading time prefix: `^(\d{1,2}:\d{2})(\s*-\s*\d{1,2}:\d{2})?\s+` → remove.
   - Strip a multiplier marker: `\s*\((1st|2nd|3rd|\d+th)\)\s*` → remove (there is at most one, usually mid-line).
   - Strip duration tokens anywhere in the line: `\b\d+\s*(min|mins|minute|minutes|hr|hrs|hour|hours)\b` → remove. This catches trailing durations like `15 mins` on lines such as `08:15 - 08:30 Check Zillow messages 15 mins`, which exist when an untimed entry with a duration was later given a time slot.
   - Strip Obsidian highlight markers: `==` → remove.
   - Strip the ad-hoc tag: `\s*\(ad-hoc\)` → remove.
   - Strip trailing commas and stray punctuation, collapse internal whitespace, lowercase.

2. **Normalize each task name from yesterday's SCHEDULED/UNSCHEDULED RECURRING:**
   - SCHEDULED lines have format `HH:MM  <raw task text>  [Category]` — strip the leading time and trailing `[Category]` bracket first.
   - UNSCHEDULED RECURRING lines have format `[Category]  <raw task text>` — strip the leading `[Category]` bracket first.
   - Then strip all recurrence and time/duration metadata from the raw backlog text in this order:
     1. `\bevery\b.+` → removes everything from "every" to end (covers `every Wed., Thu.`, `every Mon. - Fri.`, `every 2nd Monday of the month`, `5 hrs every Fri., Sat.`, `every Fri., Sat., 2 hrs every Sun.`, etc.)
     2. `\beveryday\b` → standalone everyday not caught above
     3. `\btwice a \w+\b`, `\bonce a \w+\b`, `\b\d+ times a \w+\b` → frequency hints
     4. `\b\d{1,2}:\d{2}\s*(am|pm)?\s*-\s*\d{1,2}:\d{2}\s*(am|pm)?\b` → time ranges like `6:45 PM - 8:30 PM`
     5. `\b\d{1,2}(:\d{2})?\s*(am|pm)\b` → single times like `7 AM`, `9:15 PM`
     6. `\b\d+\.?\d*\s*(min|mins|minute|minutes|hr|hrs|hour|hours)\b` → durations (including decimals like `1.5 hour`)
     7. `==` → highlight markers; `\s*\(ad-hoc\)` → ad-hoc tag
     8. Strip trailing and leading separators: `[\s,;.|\-]+` from both ends
     9. Collapse internal whitespace, lowercase.

3. **Compare.** Match on normalized key → **recurring copy** (backlog still owns it; no carryover proposal — tomorrow's auto-import handles it). No match → **ad-hoc one-time** that was moved out; include in the Step 3 proposal as either *carry forward to today* or *move back to backlog*.

Notes:
- If a line falls outside normalization (e.g. unusual unicode dashes), treat it as ad-hoc and surface it; better to over-propose than to silently swallow a leftover.
- A backlog match on a *checked* line (`- [x]`) doesn't matter — completed tasks stay put and are never carried.
- For flexible recurring (`twice a week`), the completion-count logic in Step 3 takes precedence; do not also propose them as carryovers.

## Step 3 — Build one numbered proposal
Assemble a single proposal across three buckets, with **sequential numbering across the whole list** so the user can reference any item by one number.

Example:
```
Candidates to add to today:
  1. Finish project proposal   (from Work)
  2. Book dentist              (from Wellbeing)

Move back to backlog:
  3. Read chapter 4            (carryover from yesterday, no progress)

Brain Dump triage:
  4. Set up dev environment    → Work
  5. Unclear note              → keep in Brain Dump
```

Selection heuristics:
- **Carryover ad-hoc items (from yesterday) are mandatory — show ALL of them.** Do not cap or drop any.
- Prefer recently discussed or urgent-highlighted tasks for the "new from backlog" suggestions.
- Keep the optional buckets (flexible recurring, new ad-hoc from backlog, Brain Dump triage) concise (aim 3–5 items combined). Carryovers are not subject to this cap.
- For triage, match wording to the clearest category; if vague, suggest keeping it in the default page.

### Recurring vs one-time tasks — copy vs move
**Recurring tasks** are never removed from the backlog when added to a daily note — they are **copied**. The backlog entry stays intact as the source of truth for future days.

**One-time tasks** (no recurrence hint) are **moved**: removed from the backlog when added to today, and can be moved back to backlog from the daily note if the user defers them.

When proposing "Move back to backlog", only offer one-time tasks from today's note. Never propose moving a recurring task back — it doesn't belong in the backlog's daily note copy.

### Recurring tasks
Recurrence classification is already done by `read-backlog-tasks.sh` — use the section a task appears in, do not re-parse raw task text.

Handling depends on the section:
- **SCHEDULED and UNSCHEDULED RECURRING** — already auto-imported in Step 1 (when `auto_import_daily_recurring=1`). Do not include in the proposal. Mention only as a one-line count in the final report.
- **FLEXIBLE** — have a target count per window but no fixed day. Handle as follows:
  1. Parse the count and window from the raw task text (e.g. "twice a week" → N=2, window=week).
  2. Use the `WEEK … to …` line from `read-backlog-tasks.sh` output (or run `bash .claude/scripts/get-week-range.sh <YYYY-MM-DD>`) for `WEEK_START` and `WEEK_END`. Do not guess week boundaries.
  3. List daily notes whose filenames fall between `WEEK_START` and `WEEK_END` (use `get-daily-note-title.sh` per date if needed). **Only count completed (`- [x]`) instances** under `# Timeline` (both untimed and timed entries).
  4. Dedupe: match task text loosely after stripping recurrence hint. One completion per calendar day.
  5. If completion count ≥ N → skip silently.
  6. If completion count < N → include in **Candidates to add** with label `(recurring: 1/2 done this week)`.
  7. If already present unchecked in today's note → do not propose again.

### Placing tasks into the Timeline section
All tasks for today live as checkboxes under the single `# Timeline` H1. Untimed entries sit at the top of the section as a contiguous block (Day Planner renders them as all-day events); timed entries follow, sorted chronologically.

- If the task description contains a specific time → insert as a checkbox in chronological position among the timed entries.
- If no specific time → append as a checkbox to the untimed block at the top of `# Timeline`.

Never put a task in both forms. Once an untimed entry gets a time, rewrite the same line with the time prefix and re-sort it into the chronological block.

### Timeline entry format
All entries are checkboxes under `# Timeline`.

- **Untimed** → `- [ ] <task name>` (sits in the untimed block at the top)
- **Duration known** → `- [ ] HH:mm - HH:mm <task name>`
- **Duration unknown, not the last timed block** → `- [ ] HH:mm <task name>` (Day Planner stretches to the next block)
- **Duration unknown, last timed block of the day** → `- [ ] HH:mm - <bedtime> <task name>` where `<bedtime>` comes from config (default `23:00`)

After importing or editing timed entries, if the chronologically last timed line has only a start time (no ` - HH:mm` end), set its end to `bedtime`.

Round all times to the nearest `min_block_minutes` increment. Keep timed entries sorted chronologically.

### Task text trimming when copying to daily note
The script preserves the raw task text. Strip metadata when writing to the daily note:

- **Always strip:** recurrence hints (`everyday`, `every Sunday`, `twice a week`, `every weekday`, `till end of May`).
- **For timed entries:** also strip the time and duration — they are encoded in `HH:mm - HH:mm`. Keep only the core task name. The SCHEDULED section already gives you the parsed start time; compute the end time from the duration when present.
- **For untimed entries:** keep the duration (it's not encoded anywhere else), strip the recurrence hint.

### Multiplier expansion
When a task description contains a same-day repetition hint, expand it into multiple numbered entries instead of one. Recognised patterns (case-insensitive):

| Pattern | Count |
|---|---|
| `twice a day`, `2 times a day`, `x2`, `x 2` | 2 |
| `3 times a day`, `x3`, `x 3` | 3 |
| `N times a day`, `xN`, `x N` (any N ≥ 2) | N |

**Do not** expand weekly/monthly hints (`twice a week`, `once a month`) — those are flexible recurring tasks, not same-day multipliers.

For each count N, emit N entries with ordinal suffixes inserted between the task name and the duration: `(1st)`, `(2nd)`, `(3rd)`, `(4th)`, …

Strip the multiplier hint from every generated entry just as you strip other recurrence hints.

Examples:
| Backlog text | Untimed entry (top of Timeline) | Timed entry (chronological in Timeline) |
|---|---|---|
| `Morning run 30 mins, 7:15 AM everyday` | — | `- [ ] 07:15 - 07:45 Morning run` |
| `Meditation 15 mins, twice a day` | `- [ ] Meditation (1st) 15 mins`<br>`- [ ] Meditation (2nd) 15 mins` | — |
| `Cold shower x 3` | `- [ ] Cold shower (1st)`<br>`- [ ] Cold shower (2nd)`<br>`- [ ] Cold shower (3rd)` | — |
| `Resistance Training 45 mins, twice a week` | `- [ ] Resistance Training 45 mins` | — |
| `Tennis class 1 hour, at 4 PM every Sunday` | — | `- [ ] 16:00 - 17:00 Tennis class` |
| `Judo class 6:45 PM - 8:30 PM, every weekday` | — | `- [ ] 18:45 - 20:30 Judo class` |

### Description expansion (when adding one-time tasks from backlog)
Only applies when `auto_expand_tasks` is `1` (`$TRUE`) in the config. When adding a one-time task whose description is a short stub (roughly ≤ 3 words) or ambiguous, attempt to rewrite it into a clearer action phrase. Only do this when confident. Append `*(rewritten, original: <original text>)*` so the user can verify. If not confident, copy as-is.

Skip any empty bucket. If all three are empty, say so and stop (still report Step 1 outcomes).

## Step 4 — Ask once
Present the proposal and ask:
```
Apply all? (Y / n / numbers to skip, e.g. "n 3,5")
```
Also accept free-form adjustments (e.g. "skip 3, also add 'Foo' to Today").

## Step 5 — Apply
Apply only confirmed items:
- **Candidates to add (recurring)** → copy (trimmed text) into today's note using placement rules above; leave backlog entry untouched.
- **Candidates to add (one-time, from backlog)** → move (remove from backlog), add to today's note using placement rules above; append ` (ad-hoc)` to the task text so future `/new-day` runs can identify it instantly without backlog matching.
- **Candidates to add (carryover ad-hoc from yesterday)** → copy into today's note; preserve the original time prefix if the leftover had one (place in timed block at that time, not the untimed block). Keep the ` (ad-hoc)` tag. If the leftover had only a start time (no end) and becomes the last timed entry, append `- <bedtime>`.
- **Move back to backlog** → only for one-time tasks: remove from today's note, append original text (strip ` (ad-hoc)` before writing back) to the appropriate backlog category page.
- **Brain Dump triage** → move the task from the default backlog page to the suggested category page.

## Step 6 — Report
List exactly what changed: added to today, moved back, triaged, plus a one-line archive summary if any notes were archived. Tight, no fluff.

If `auto_import_daily_recurring` is `1` (`$TRUE`), end the report with a section listing every task that was silently auto-imported in Step 1, grouped by form (timed / untimed). Example:

```
Auto-imported daily recurring tasks:
  Timed: Morning review, Morning run, Lunch, Evening routine
  Untimed: Meditation 15 mins, Weekly planning
```

If the TYPOS section is non-empty, append a short note listing the suspected misspellings and ask whether to fix them. Example:
```
Possible typos in backlog: "everday" → "everyday" (Wellbeing.md). Fix? (y/n)
```

## Timeline edits (when the user asks for them)
- Use `HH:mm - HH:mm` when duration is known.
- Use `HH:mm` alone only when a later timed block follows; otherwise end at `bedtime`.
- **Round every time to the nearest `min_block_minutes` increment.** Never write odd times like 12:06.
- Keep entries chronological.
- Mark/unmark urgent with `==text==`.
- Never choose a time slot unless the user explicitly states one (or a relative position like "after Lunch").

## Guardrails
- Do not invent tasks.
- Do not decide for the user; propose, then apply only confirmed items.
- Never remove completed tasks from daily notes.
- Never remove a recurring task from the backlog.
- If a "move back to backlog" target is completed, refuse and explain that completed tasks stay in daily notes.
- Preserve all existing user content.
- If `backlog_dir` is missing, follow the edge case handling in `CLAUDE.md`.
