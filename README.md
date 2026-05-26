# Obsidian Daily Planner (w/ Claude Code)

## Why?

We rarely execute our daily plans perfectly, so why do we bother making them?

**Immediate Direction**
A plan eliminates the friction of deciding what to do next. In idle moments, it provides immediate direction, protecting your time from the gravity of mindless scrolling.

**Proactive Focus**
Planning forces prioritization. It acts as an early warning system, revealing when you are running out of time. This gives you the runway to pivot, ask for help, or find a workaround before a deadline hits.

**Built-In Urgency**
Writing down a task transforms a vague intention into a personal contract. Scheduling a 5 PM run creates a psychological anchor that not only ensures the run happens, but naturally forces you to timebox whatever you are working on right before it.

**A Holistic Audit**
Daily planning provides a continuous reality check on your life and career. It reveals the true gap between how you *want* to allocate your time and how you *actually* spend it.

**A plan isn’t a rigid script, it is a compass. It does not make the day predictable, it makes the day intentional.**

---

## 1. Prerequisites

**Required:**

1. **Obsidian** — [https://obsidian.md](https://obsidian.md) (free)
2. **A vault** — open Obsidian → *Create new vault* → pick or create a folder. The vault is just a folder of markdown files on disk.
3. **Claude Code** — [https://docs.claude.com/en/docs/claude-code/quickstart](https://docs.claude.com/en/docs/claude-code/quickstart). Verify with:
  ```bash
   claude --version
  ```

**Shell scripts:** date/archive helpers under `.claude/scripts/` use BSD `date` and `stat` (macOS). On Linux, run `/new-day` from Claude Code (it can work without the scripts) or adapt the scripts for GNU `date`.

**Optional (only if you install via `npx` below):**

- **Node.js** — [https://nodejs.org](https://nodejs.org) so `npx` is available. Verify with `node -v`. Not needed if you copy the files from a ZIP instead.

---

## 2. Install into your vault

Pick either method. Both put the same files into your vault folder.

### Option A — Download ZIP (no Node.js)

1. On GitHub, open this repo → **Code** → **Download ZIP**.
2. Unzip the archive.
3. Move **everything inside** the unzipped folder into your vault folder (merge with existing files if the vault isn't empty).

### Option B — `npx degit` (terminal)

Requires Node.js. From a terminal:

```bash
cd "/path/to/your/Vault"
npx degit <github-user>/<this-repo> . --force
```

This copies the workflow into your vault without git history. `--force` allows installing into a folder that already has files.

> If `degit` refuses a non-empty folder, use Option A, or unzip to a temp folder and move the contents into your vault manually.

### After install

You should see (among other files):

```
.claude/              ← workflow config, commands, and skills
Backlog/              ← starter backlog (Brain Dump only until setup)
templates/            ← template for new daily notes
README.md             ← this guide
```

This bundle ships **no personal tasks**, daily notes, or Obsidian app settings. Run `/planner-setup` next (see below) to create your own backlog categories and wire up Obsidian.

> **Note:** Claude Code may create `.claude/settings.local.json` on your machine (extra permissions). That file is gitignored and should not be committed.

---

## 3. Set up the workflow

In the vault folder, start Claude Code:

```bash
claude
```

Then run:

```
/planner-setup
```

Follow the prompts to wire up Obsidian (Daily Notes, Templates, and optionally Day Planner).

When setup finishes:

1. **Quit and reopen Obsidian** so plugin settings reload.
2. If Day Planner was just installed, **Trust** it when prompted, then enable it under *Settings → Community plugins*.

To review or change behavior later, run:

```
/planner-config
```

---

## 4. How tasks move through your vault

A task can sit in one of three places:

- **Backlog** — category notes under `Backlog/` (e.g. `Brain Dump.md`, `Wellbeing.md`). Each file is a flat list of `- [ ]` lines. Things you *might* do.
- **Today tasks** — untimed work you've committed to today.
- **Timeline** — timed blocks for today.

Today tasks and Timeline are not separate files. They are two headings inside **one daily note** (e.g. `05-25 (Mon).md` at the vault root). Day Planner reads the `# Timeline` section for its sidebar.

You can add a task anywhere directly — you don't have to start in the backlog.

```
        ┌──────────────────────────────────────────────────────────────┐
        │                          BACKLOG                             │
        │       Brain Dump · Wellbeing · Personal Project · …          │
        │       Flat lists of "- [ ] task" lines, by category          │
        └──────────────────────────────────────────────────────────────┘
              │                                          ▲
              │ /new-day proposes + you confirm          │  "move back
              │  one-time → moved                        │   to backlog"
              │  recurring → copied (backlog kept)       │   (defer)
              ▼                                          │
        ┌──────────────────────────────────────────────────────────────┐
        │     DAILY NOTE  (e.g. 05-25 (Mon).md)                        │
        │                                                              │
        │   # Today tasks     ◀───────────▶     # Timeline             │
        │   untimed work                        timed blocks           │
        │                     "schedule X                              │
        │                      at HH:mm"                               │
        │                     (or drag in Day Planner)                 │
        └──────────────────────────────────────────────────────────────┘
                       │
                       │ check the box  →  - [x]  (stays in the note)
                       ▼

  Short-cuts (say to Claude or use a command):
    /add-task Buy milk                    → Backlog / Brain Dump (default)
    /add-task wellbeing: Book dentist     → Backlog / Wellbeing
    "add X to today"                      → Today tasks in today's note
    "schedule X at 14:00 today"           → Timeline
```

### By task type

**Recurring** (wording like `everyday`, `every weekday`, `twice a week`, `at 7:15 AM every Sunday`)

The backlog line stays forever — `/new-day` **copies** it into the daily note each time it applies. Timed copies go to Timeline; untimed copies go to Today tasks. Same-day repeats like `Cold shower x3` become three numbered lines (`(1st)`, `(2nd)`, `(3rd)`).

**One-time (ad-hoc)**

No recurrence in the text. When you pull one into today, `/new-day` **moves** it: removed from backlog, added to the daily note. To defer, ask Claude to move it back to its category note.

**Completed (`- [x]`)**

Stay in the daily note. The note is both plan and journal — Claude won't move finished work back to backlog.

**Leftovers from yesterday**

Nothing moves automatically overnight. Next `/new-day`, Claude may propose sending unfinished one-time tasks back to backlog or carrying them forward. You choose.

### Who does what


|                        | Typical actions                                                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **You in Obsidian**    | Check boxes, edit lines, drag blocks in Day Planner, type new tasks in backlog or daily notes.                             |
| **You in Claude Code** | `/new-day`, `/add-task`, `/planner-config`, or chat: *schedule Lunch at 12:30*, *move X back to backlog*, *mark X urgent*. |
| **Day Planner**        | Live sidebar for `# Timeline`; edits sync back to the daily note.                                                          |


---

## 5. Adding backlog tasks

**In Obsidian:** open a note under `Backlog/` and add a line:

```markdown
- [ ] Your task here
```

**In Claude Code:**

```
/add-task Buy birthday card
/add-task wellbeing: Book dentist
```

Without a category prefix, tasks go to your default backlog page (usually Brain Dump).

`/new-day` understands recurrence, times, durations, and urgency from the **task text** — no extra fields. Examples:

```markdown
- [ ] Buy birthday card
- [ ] Morning run 30 mins, 7:15 AM everyday
- [ ] Judo class 6:45 PM - 8:30 PM, every weekday
- [ ] Tennis class 1 hour, at 4 PM every Sunday, till end of May
- [ ] Resistance Training 45 mins, twice a week
- [ ] Call parents, once a week
- [ ] Meditation 15 mins, twice a day
- [ ] Walk x3
- [ ] ==Call contractor about leak==      ← urgent (highlight in Obsidian)
```

> **Timeline ↔ Day Planner:** everything under `# Timeline` in today's daily note appears in the Day Planner sidebar. Checking, dragging, or resizing a block updates the note.

---

## 6. The daily flow

1. **Run `/new-day`** in Claude Code (or say `today`). Claude opens or creates today's note, pulls in recurring work, and shows one numbered proposal — tasks to add, yesterday's carryovers, Brain Dump triage. Reply once: `Y`, `n`, or `n 3,5` to skip items. Safe to run again later; already-imported recurring tasks won't duplicate.
2. **Open Day Planner.** Command Palette (`Cmd/Ctrl+P`) → *Day Planner: Show timeline*, then pin the panel.
3. **During the day.** Edit the note, drag blocks, or ask Claude (*move Lunch to 12:30*, *send Read chapter 4 back to Study*, *mark Call contractor urgent*).
4. **Put a Today task on the Timeline**


| Method        | How                                                                                      |
| ------------- | ---------------------------------------------------------------------------------------- |
| Ask Claude    | *Schedule X at 14:00* — moves the task and adds a timed Timeline line                    |
| Edit the note | Add a `- [ ] HH:mm - HH:mm …` line under `# Timeline`, remove it from Today tasks        |
| Day Planner   | Drag on the timeline to create a block, then paste the task name into the note if needed |


---

## 7. Tips and things to know

### How `/new-day` chooses backlog tasks for today

Each run, Claude scans your backlog and yesterday's note, then does two things: **auto-import** (no prompt) and a **proposal** (you confirm once).


| Kind of task                                                                             | What happens                                                                                                                       |
| ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Daily recurring with a time** (`everyday`, `every weekday`, `at 4 PM every Sunday`, …) | Copied straight into **Timeline** (if auto-import is on — default)                                                                 |
| **Daily recurring without a time**                                                       | Copied into **Today tasks** (if auto-import is on)                                                                                 |
| **Flexible recurring** (`twice a week`, `once a month`)                                  | Offered in the proposal only if you haven't checked it off enough times in the current week (or month window)                      |
| **Urgent** (`==highlighted text==`)                                                      | Always in the proposal — never auto-imported, so you choose consciously                                                            |
| **One-time**                                                                             | A small sample per category in the proposal (default: one task per backlog note); say *show more from Wellbeing* for a longer list |
| **Yesterday's unfinished one-time**                                                      | May appear as move back to backlog or roll forward                                                                                 |


**Auto-import (recurring, default on):** matching recurring tasks land in today's note immediately. The backlog line stays. Re-running `/new-day` won't duplicate what's already there.

**Proposal (everything else):** one numbered list — add to today, defer to backlog, sort Brain Dump items into categories. `Y` applies all; `n 3,5` skips those numbers. Accepting a **one-time** task removes it from backlog; accepting **recurring** copies it and leaves backlog unchanged.

**Where tasks go:** timed → Timeline only; untimed → Today tasks only — never both.

**Flexible recurring:** Claude counts checkoffs of the same task across daily notes in the current week (week starts on Monday by default). Done enough for the period? Skipped. Still due? Shows up like `(recurring: 1/2 done this week)`.

**Urgent:** highlight syntax only — makes the task stand out and ensures it appears in the morning proposal. It does not auto-schedule or jump the queue.

**One-time preview:** keeps the morning list short. Ask for more from a category anytime, or raise *tasks per category in the proposal* in `/planner-config`.

### Other tips

- **Same-day multipliers:** `Walk x3` → three lines `(1st)`, `(2nd)`, `(3rd)` in Today tasks. `twice a week` is different — that's flexible recurring, not same-day expansion.
- **No recycling completions:** checked-off tasks stay in the daily note; Claude won't move them back to backlog.
- **Moved your Backlog folder?** Tell Claude where it is, or run `/planner-config` to point at the new location.
- **Multiple devices:** the vault is plain files — use iCloud, Obsidian Sync, Syncthing, Git, or any folder sync.
- **Start fresh today:** delete today's daily note and run `/new-day` again. Backlog remains the long-term list.

