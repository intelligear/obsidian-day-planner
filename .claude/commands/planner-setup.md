# /planner-setup

Set up an Obsidian daily-planning workflow in the current vault.

## Purpose
Initialize a vault structure for backlog pages, daily notes, archive handling, and Claude-assisted maintenance. The workflow assumes backlog tasks live in category pages under the configured backlog folder, active planned tasks live in daily notes, and completed tasks stay in the daily note as historical journal entries.

## Step 0 — Plugin detection
Before asking any questions, scan `.obsidian/plugins/` (if it exists) and note:
- Whether `obsidian-day-planner` is already installed.
- Any other plugins, listed for information only.

## Interaction contract
Ask the user these questions in order and wait for answers before making changes:
1. Should the official `kepano/obsidian-skills` package be installed into this vault's `.claude/` area? Default: `yes`
2. Where should daily notes live? Default: vault root (leave empty). Enter a folder name only if you want them in a subfolder (e.g. `Daily/`).
3. What folder should hold backlog category pages? Default: `Backlog/`
4. What is the default backlog page name (used when no category is specified)? Default: `Brain Dump`. GTD-style alternative: `Inbox`.
5. What backlog categories should be created? Ask for a short comma-separated list, e.g. `Wellbeing, Business, Study`. The default backlog page from question 4 will be created automatically — do not list it again here.
6. Should old daily notes be auto-archived? Accept:
   - `yes` = enable with default retention 30 days
   - a number = enable with that retention in days
   - `no` = disable auto archive
7. What time do you usually go to bed? This is used as the implied end of your last timeline block. Default: `23:00`
8. Should example starter tasks be added to each backlog page? Default: `no`
9. **Only ask if `obsidian-day-planner` is NOT already installed:** The Day Planner plugin provides a visual timeline sidebar that syncs bidirectionally with the daily note. Install it now? Default: `yes`

## Actions
After collecting answers:
1. If the user approved it, install the official `kepano/obsidian-skills` package into the vault's `.claude/` area.
2. Create folders:
   - The configured backlog folder (default `Backlog/`)
   - Daily notes subfolder only if the user specified one (skip if vault root)
   - `templates/` (daily note template)
   - The archive folder (value of `archive_dir`; default `zzArchive/`)
3. Create the default backlog page (e.g. `Backlog/Brain Dump.md`) plus one page per additional category. When naming each page, prepend a single relevant emoji based on the category name — e.g. "Travel" → `✈️ Travel.md`. Pick the most fitting emoji using common sense. Always exactly one emoji per name.
4. Create `templates/daily-note-template.md` using the daily note template below.
5. Create `.claude/.config` in bash `key=value` format (sourceable by shell scripts). Always include the `readonly TRUE=1` / `readonly FALSE=0` constants at the top, then a blank line, then the settings. Use `$TRUE` / `$FALSE` for all boolean values. Quote values that contain spaces. Example:
   ```bash
   readonly TRUE=1
   readonly FALSE=0

   daily_note_date_format="MM-DD (ddd)"
   daily_notes_folder=""
   archive_enabled=$TRUE
   archive_after_days=30
   archive_dir=zzArchive
   backlog_dir=Backlog/
   default_backlog_page="Brain Dump"
   min_block_minutes=15
   bedtime="23:00"
   auto_expand_tasks=$TRUE
   auto_import_daily_recurring=$TRUE
   week_start=Monday
   daily_adhoc_task_per_category=1
   ```
   Include only the keys listed above. Do NOT include `official_skills_installed` or `backlog_categories` — these are derived at runtime.
   **`archive_after_days` must be omitted when `archive_enabled` is `$FALSE`** — write it only when archive is enabled.
6. **Obsidian core plugin configuration:**
   - Write `.obsidian/templates.json` (read first if the file exists, then do a targeted merge — do not overwrite unrelated settings):
     - `folder`: `"templates"`
   - Write `.obsidian/daily-notes.json` (read first if the file exists, then do a targeted merge):
     - `folder`: the configured `daily_notes_folder` (empty string `""` for vault root)
     - `template`: `"templates/daily-note-template"` (no `.md` extension — Obsidian resolves it automatically)
     - `format`: the configured `daily_note_date_format` (default `"MM-DD (ddd)"`) — this is a moment.js format string; `ddd` produces abbreviated weekday names like `Mon`
   This wires Obsidian's core Daily Notes plugin to apply `templates/daily-note-template.md` whenever the user opens "Open today's daily note" from inside Obsidian. Note: tell the user they may need to restart Obsidian for these settings to take effect.

7. **Day Planner plugin — install if needed, then configure:**
   - If the user agreed to install (question 9): download the latest release from `https://github.com/ivan-lednev/obsidian-day-planner/releases/latest` — fetch `main.js`, `manifest.json`, and `styles.css` and place them in `.obsidian/plugins/obsidian-day-planner/`. Then add `"obsidian-day-planner"` to `.obsidian/community-plugins.json` (create the file if absent, preserve existing entries). Tell the user: "Restart Obsidian and click **Trust** when prompted to activate the plugin."
   - Whether freshly installed or already present, write the following settings to `.obsidian/plugins/obsidian-day-planner/data.json` (read first if the file exists, then do a targeted merge — do not overwrite unrelated settings):
     - `plannerHeading`: `"Timeline"`
     - `plannerHeadingLevel`: `1`
     - `timelineDateFormat`: the configured `daily_note_date_format` (default `"MM-DD (ddd)"`) — must match the daily notes filename format exactly so the plugin can locate today's note
     - `extendDurationUntilNext`: `true`
     - `snapStepMinutes`: `min_block_minutes` (default 15)
     - `minimalDurationMinutes`: `min_block_minutes` (default 15)
     - `defaultDurationMinutes`: `min_block_minutes` (default 15)
8. If example tasks were requested, add 2–3 example unchecked tasks to each category page.
9. Update `.claude/settings.json`: in `permissions.allow`, add or replace `Read(<dir>/**)` and `Write(<dir>/**)` to match `backlog_dir` (e.g. `Backlog/` → `Read(Backlog/**)` and `Write(Backlog/**)`). Remove stale backlog `Read`/`Write` entries for any previous folder.
10. Make any shell scripts under `.claude/scripts/` executable: `chmod +x .claude/scripts/*.sh` (skip silently if the directory is empty or absent).
11. Do not overwrite existing files without showing a concise diff-style summary and asking for confirmation.

## File templates
### Backlog page template
A backlog page is just a flat list of unchecked tasks — no H1 and no section headings. Seed new pages with one empty task line.
```md
- [ ] 
```

### Daily note template
No date H1. A single `# Timeline` H1 section — all task checkboxes (untimed at the top, timed entries below in chronological order) live under it.
```md
# Timeline
```

## Guardrails
- Do not decide the user's categories.
- Do not add due dates, hashtags, or duration fields unless the user explicitly asks.
- Keep completed tasks in daily notes; do not move completed tasks back to backlog.
- Installing official skills should be opt-out, not mandatory, and should not overwrite an existing custom `.claude/` setup without confirmation.

## Final response
Summarize exactly what was created. Show: detected plugins, any plugin installs or config changes, the resulting config values written to `.claude/.config`, and the folder/file structure created. If Day Planner was freshly installed, remind the user to restart Obsidian and trust the plugin.
