# CLAUDE.md — Obsidian Claude Workflow

## Path conventions
Always use vault-relative paths (e.g. `.obsidian`, `Backlog`, `templates/daily-note-template.md`) when referencing files in this vault. Do not use absolute paths.

## Workflow config location
All workflow settings are stored in `.claude/.config`. This file is the source of truth for:
- `daily_notes_folder` — where daily notes live
- `archive_enabled` / `archive_after_days` — auto-archive behaviour
- `bedtime` — implied end time for the last Timeline block of the day (default `23:00`)
- `backlog_dir` — folder containing backlog category pages
- `default_backlog_page` — default page for uncategorized tasks (e.g. `Brain Dump`)
- `min_block_minutes` — minimum timeline slot size in minutes (default `15`)
- `week_start` — first day of the week (default `Monday`); used to count completions for flexible weekly recurring tasks

Do not read `Obsidian Claude Workflow Config.md` in the vault root; it is a legacy file that can be deleted.

## Canonical model
- A task is either in a backlog category page or in a daily note.
- **Recurring tasks** are copied to the daily note; the backlog entry is never removed.
- **One-time tasks** are moved to the daily note; they can be moved back to backlog if deferred.
- Completed tasks remain in the daily note where they were completed — never moved back to backlog.
- The daily note is both plan and journal.
- Timeline entries are checkboxes: `- [ ] HH:mm - HH:mm Task` (or `- [ ] HH:mm Task` when duration unknown). Timed tasks live here only — never duplicated in Today tasks.
- `# Today tasks` is exclusively for untimed tasks.
- "Urgent" is a visual highlight state (`==text==`), not a scheduling policy.

## Vault conventions
### Daily note location
Daily notes live in the **vault root** (empty `daily_notes_folder` in config). `/planner-setup` configures Obsidian's core Daily Notes plugin (`.obsidian/daily-notes.json`) to use `templates/daily-note-template.md` as the template. If today's note is missing when `/new-day` runs, it creates it automatically from `templates/daily-note-template.md` — do not stop and ask the user to open Obsidian.

### Daily note sections (in order)
- `# Today tasks` — unscheduled tasks the user has not yet placed on the timeline
- `# Timeline` — committed schedule; tasks with known times go here, not in Today tasks

Both sections are H1. No extra heading before them (no date H1 — Obsidian shows the filename as the title). No "Candidate from backlog" or "Move back to backlog" sections in the final note — those are transient planning scratchpads, never persisted.

A task must not appear in both sections. Once it has a time and is in the Timeline, remove it from Today tasks.

### Timeline format
Checkbox list under H1 `# Timeline`. Use explicit ranges when duration is known; the last block of the day without a known duration ends at `bedtime` from config.
```md
# Timeline
- [ ] 08:00 - 08:30 Morning review
- [ ] 09:00 - 10:00 Finish project proposal
- [ ] 12:00 - 13:00 Lunch
- [ ] 21:00 - 23:00 Evening routine
```
When duration is unknown and the entry is not the last timed block, `- [ ] HH:mm Task` is acceptable (Day Planner stretches to the next block). For the **last** timed entry with no duration, write `- [ ] HH:mm - <bedtime> Task`.

All times must be rounded to the nearest `min_block_minutes` increment (default 15): 12:06 → 12:00, 12:08 → 12:15. Never write an odd start time like 12:06 PM.

### Urgent format
Wrap the visible task text in Obsidian highlight syntax: `- [ ] ==Call contractor==`

## Source of truth rules
- **Backlog categories**: derived at runtime by listing `.md` files under the configured `backlog_dir`. Never use a hardcoded list.
- **Official skills installed**: derived at runtime by checking whether skill files exist under `.claude/skills/`. Do not persist this as a config value.

## Edge case: backlog directory not found

If a skill cannot locate the directory named in `backlog_dir`:
1. Search the vault for any flat directory of `.md` files where most files consist primarily of `- [ ]` task lines — this pattern identifies a renamed or relocated backlog folder.
2. If exactly one candidate is found, tell the user: "I found `<path>` which looks like the backlog folder — use this? (y/n)"
3. If the user confirms, update `backlog_dir` in `.claude/.config` to the new path.
4. If multiple candidates are found, list them and ask the user to pick one.
5. If no candidates are found, tell the user the configured path is missing and ask them to provide the correct path.
6. If the user provides a path that does not exist yet, ask: "Directory `<path>` doesn't exist — create it? (y/n)"
7. On confirmation, create the directory and update `.claude/.config`.

## Obsidian plugins
The workflow configures two Obsidian core plugins during `/planner-setup`:
- **Templates** (`.obsidian/templates.json`) — folder set to `templates/`
- **Daily Notes** (`.obsidian/daily-notes.json`) — template set to `templates/daily-note-template`, folder set to match `daily_notes_folder`

The Day Planner community plugin is optional but recommended for the Timeline sidebar. Claude will scan `.obsidian/plugins/` during setup and offer to install it if absent.