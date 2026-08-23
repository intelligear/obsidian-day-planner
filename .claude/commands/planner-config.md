# /planner-config

Display and optionally update the Obsidian Claude workflow configuration.

## Purpose
Provide a single place to review and change workflow settings without manually editing config files.

## Reading boolean values
`.claude/.config` stores booleans as `$TRUE` (resolves to `1`) or `$FALSE` (resolves to `0`). When displaying values, render `1` as `true` and `0` as `false`. When the user provides a new boolean value, accept any of: `true`, `false`, `yes`, `no`, `1`, `0`. Map them to `$TRUE` or `$FALSE` when writing back.

## Actions
1. Read `.claude/.config`.
2. Display all settings in a readable table or list format with a short description of each:
   - `daily_note_date_format` — how your daily note files are named (default `MM-DD (ddd)`, e.g. `05-25 (Sun)`)
   - `daily_notes_folder` — where daily notes are saved; empty means the vault root
   - `archive_enabled` — when on, old daily notes are automatically moved to an archive folder so they don't clutter your vault (shown as `true`/`false`)
   - `archive_after_days` — how many days a daily note stays in your vault before being archived (only shown when `archive_enabled` is `true`)
   - `archive_dir` — folder where archived daily notes are moved (default `zzArchive`; only shown when `archive_enabled` is `true`)
   - `backlog_dir` — folder where your backlog category pages live
   - `default_backlog_page` — which backlog page a task lands on when you don't specify a category (e.g. with `/add-task`)
   - `min_block_minutes` — smallest time slot you can place on the timeline; times are rounded to this increment (default `15` min)
   - `bedtime` — implied end time for the last Timeline block of the day when duration is unknown (default `23:00`)
   - `auto_expand_tasks` — when on, Claude fleshes out vague task names into clearer descriptions as it adds them to today (shown as `true`/`false`)
   - `auto_import_daily_recurring` — when on, daily and weekday recurring tasks are added to today automatically without asking you each time (shown as `true`/`false`)
   - `week_start` — which day your week starts on; used with `get-week-range.sh` / `read-backlog-tasks.sh` to count flexible recurring completions (e.g. `twice a week` from this Monday through Sunday)
   - `daily_adhoc_task_per_category` — how many backlog tasks per category Claude shows you each morning to consider for today (default `1`; raise it to see more options at once)
   - `calendar_sync_names` — comma-separated iCloud calendar names that `/new-day` pulls today's events from (requires the `icloud-calendar` MCP server to be connected). Show as "not configured / off" when the key is absent.
3. Ask: "Would you like to update any of these settings? If yes, tell me which ones and the new values."
4. If the user specifies changes:
   - Validate the new values (e.g. folder paths end with `/`, retention is a positive integer, booleans are recognisable).
   - For boolean fields, map the input to `$TRUE` or `$FALSE` when writing.
   - Show a concise diff-style summary of what will change (use `true`/`false` in the diff, not `1`/`0`).
   - Ask for confirmation before writing.
   - Apply updates to `.claude/.config`.
   - If `backlog_dir` changed, update `.claude/settings.json` (see table below).
   - If any other plugin-sync setting changed (see table below), update the corresponding Obsidian plugin file(s).
   - If the user wants to turn calendar sync **on** (setting or adding to `calendar_sync_names`): check that the `icloud-calendar` MCP server is connected (`claude mcp list`) — if not, tell them to run `.claude/scripts/setup-mcp.sh` first and stop. If connected, call `mcp__icloud-calendar__list_calendars` and confirm each name they give matches a real calendar before writing it.
   - If the user wants to turn calendar sync **off**, remove the `calendar_sync_names` key from `.claude/.config` entirely (do not write it as an empty string — its absence is what disables the feature).
5. If the user declines, end the interaction.

## Guardrails
- Never delete `.claude/.config`.
- Do not apply changes without explicit user confirmation.
- If `archive_enabled` is set to `$FALSE`, remove `archive_after_days` and `archive_dir` from the config (or comment them out).
- If `backlog_dir` is changed, warn the user that the new directory must already exist (or will need to be created manually).
- Never modify the `readonly TRUE=1` / `readonly FALSE=0` constant lines.
- Never write `calendar_sync_names` as an empty string — omit the key entirely to disable calendar sync.

## Plugin sync
Some settings must be kept in sync with Obsidian plugin config files. When the user changes any of the following, update both `.claude/.config` **and** the corresponding plugin file(s) in the same operation:

| Setting | Plugin file(s) | Field(s) to update | Notes |
|---|---|---|---|
| `daily_note_date_format` | `.obsidian/daily-notes.json` | `format` | |
| `daily_note_date_format` | `.obsidian/plugins/obsidian-day-planner/data.json` | `timelineDateFormat` | Day Planner only |
| `daily_notes_folder` | `.obsidian/daily-notes.json` | `folder` | |
| `min_block_minutes` | `.obsidian/plugins/obsidian-day-planner/data.json` | `snapStepMinutes`, `defaultDurationMinutes`, `minimalDurationMinutes` | Day Planner only |
| `week_start` | `.obsidian/plugins/obsidian-day-planner/data.json` | `firstDayOfWeek` | Day Planner only; value must be lowercased (e.g. `Monday` → `"monday"`) |
| `backlog_dir` | `.claude/settings.json` | `permissions.allow` | Replace backlog `Read`/`Write` globs: `Read(<dir>/**)` and `Write(<dir>/**)` where `<dir>` is `backlog_dir` without trailing slash (e.g. `Backlog/` → `Read(Backlog/**)`). Remove entries for the old folder. |

Before writing plugin files, check that the file exists. If a plugin file is missing, skip it and note it in the confirmation summary. Include the plugin file changes in the diff shown to the user before they confirm.
