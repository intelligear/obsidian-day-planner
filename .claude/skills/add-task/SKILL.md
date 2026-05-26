---
name: add-task
description: Append a task to a backlog category page in Obsidian. Default category is Brain Dump. Trigger when the user says things like "add task X", "capture X", "remind me to X", or names a category followed by a task (e.g. "personal proj: debug xyz", "study: read chapter 4").
---

# Add Task

## Purpose
Quickly append a task to a backlog category page under the configured backlog folder without disturbing the daily note or timeline.

## Config resolution
Before matching any category, read `.claude/.config` to get:
- `backlog_dir` — the folder containing backlog pages (default `Backlog/`)
- `default_backlog_page` — the page used when no category is named (default `Brain Dump`)

## Default behavior
- If the user does not name a category, append the task to `<backlog_dir>/<default_backlog_page>.md`.
- If the user names a category (explicit or fuzzy), append to that category's page instead.
- Append, do not replace. New tasks go at the end of the file.
- Tasks are written as `- [ ] <task text>` with no hashtags, due dates, or duration fields.

## Category resolution
List all `.md` files under `backlog_dir` at runtime — do not rely on a hardcoded list. The filename without extension is the category name.

Match the user's category hint case-insensitively against filenames under `backlog_dir`:
- Partial matches (e.g. `well` → `Wellbeing` if that file exists)
- Common abbreviations only when unambiguous (e.g. first letters of multi-word category names)
- Plural/singular variants when they clearly refer to one category

If the hint matches more than one category or matches none, ask the user to disambiguate. Do not silently guess.

## Input parsing
Accept either form:
- `<task text>` → defaults to the configured default backlog page.
- `<category>: <task text>` → routes to the named category.

Trim whitespace. Preserve the user's exact task wording, including capitalization and punctuation. Do not paraphrase.

## File-write rules
- Confirm the target backlog file exists; if it does not, ask the user before creating it.
- Append the new `- [ ] ...` line at the end of the file (after the last existing task).
- Preserve trailing newline conventions of the file.
- Do not touch other sections, daily notes, or the timeline.

## Backlog directory missing
If `backlog_dir` does not exist, follow the edge case handling described in `CLAUDE.md` before proceeding.

## Confirmation
After writing, report a one-line confirmation: which file was updated and the task text appended. Do not summarize the file or list other tasks.

## Out of scope
- Do not add the task to today's daily note. (Use `/new-day` for that.)
- Do not mark urgency. (That is a daily-note concern.)
- Do not create new category pages without explicit user confirmation. When creating one, seed it with a single `- [ ] ` line before appending the new task.
- Do not reorder or deduplicate existing tasks.
