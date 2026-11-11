---
name: session-note
description: Writes Claude Code sessions into the Obsidian brain inbox as progress and learnings, never work details. Single mode for the current session ("dump session", "dump this", "dump this into brain", "brain dump this session"); daily mode for all of a day's sessions ("summarise today", "summarize today", "daily summary", optionally with a date). Also runs via /session-note. Use only when the user explicitly asks. Never on your own initiative.
---

# Session note

A session note gives the evening brain processor just enough context: **progress, learnings, bottlenecks, next steps**. The vault syncs beyond the work machine, so the note holds no work identifiers at all.

## Modes

| Says | Mode | Writes |
| --- | --- | --- |
| "dump session", "dump this (into brain)" | single | `<title> <date>.md`, upserted by session id |
| "summarise today", "summarize today", "daily summary [for YYYY-MM-DD]" | daily | `claude sessions <date>.md`; a rerun overwrites it |

Both write to `~/Work/mine/obsidian-vault/brain/inbox` (override: `SESSION_NOTE_DIR`). A launchd job runs daily mode by itself at 23:00 (see "Scheduled run").

## Policy (both modes)

Write, in plain short sentences:
- **progress**: where the work stands, one or two sentences
- **learnings**: what worked, what to repeat or avoid, phrased so they hold beyond this task
- **bottlenecks**: what slowed the work down
- **next steps**: the first is what to do on resume

Label each title with its area in brackets, generic: "Faster linting (work)", "Session restore (personal)", "Read-only database skill (work tooling)".

Keep out. The script gate rejects all of these:
- work repo names (every folder name in `~/Work/job/git/`), product, customer and person names (Dimitar is the one exception)
- commit SHAs, ticket keys (`ABC-123`), any URL, hostnames, paths into work repos, tool names that identify internal systems
- every number except dates, times, versions with `v`/`version` in front and filenames: no counts, volumes, spend, durations, "step 2", "round 2 of 2", "frame 7". Spelled-out counts ("two rounds", "twenty tickets") and a number word after a label ("round two") too. "one" is fine.
- secrets, tokens, connection strings, IPs, emails, copied doc text

**Sanitise first (mandatory).** Before writing any JSON, list every proper noun and every number you are about to write. Replace names with roles or generic labels ("the linter", "a customer", "the reviewer"), drop the numbers. The script gate is the backstop, not the filter.

## Running the scripts

Create and fix `facts.json` with the Write or Edit tool. Run each script as one plain `bash ~/.claude/skills/session-note/scripts/<script> ...` command: no `cat`, `sed`, heredocs, pipes or chained commands. Headless and scheduled runs allow exactly these and deny the rest.

## Single mode

1. Sanitise, then write `facts.json` to the scratchpad:

   ```json
   {
     "title": "Faster linting (work)",
     "session_name": "faster-lint",
     "status": "in-progress",
     "progress": "Switched linting to a faster tool. Waiting on review.",
     "learnings": ["Prove a replacement linter matches the old one by planting violations and running both."],
     "bottlenecks": ["Main moved fast, so the branch needed rebasing more than once."],
     "next_steps": ["Merge after approval", "Start the test-cleaner skill"]
   }
   ```

   All keys required except `session_name`; arrays may be empty. `status`: `in-progress` | `done` | `blocked`. No other keys.
2. Run `bash ~/.claude/skills/session-note/scripts/note.sh <scratchpad>/facts.json`. It validates, gates and upserts by `CLAUDE_CODE_SESSION_ID` (same session, same file).
3. On a `REJECT` or `SCHEMA` line: rewrite that field without the flagged part and rerun. Done when it exits 0.
4. Tell the user the printed path. Nothing else.

## Daily mode

1. Run `bash ~/.claude/skills/session-note/scripts/digest.sh [YYYY-MM-DD]` (no date: today; before 06:00: yesterday). It prints JSON: per session the project folder, first/last local time, my prompts, the last assistant texts and commit messages, plus script-computed figures. The current session is excluded. Zero sessions: tell the user and stop.
2. Read the digest. Write one section per topic: a session, or several sessions on the same topic grouped together. Skip sessions with nothing worth keeping. The project folder tells you the area (`-Users-...-Work-job-git-...` is work); never copy it.
3. Write the day's **How I worked** findings, about how Dimitar works *with* the AI:
   - `blockers`: avoidable blockers: corrections, re-asks, wrong direction, slow handoffs. Read them from the prompts ("no, I meant", repeated asks, long waits).
   - `automate`: steps to automate or delegate: repeated manual steps, checks he ran himself that the agent could run.
   - Exactly one `rec` each. Do not write any figures; the script adds them.
4. Sanitise, then write `facts.json`:

   ```json
   {
     "sessions": [
       {
         "session_ids": ["<session_id from the digest>"],
         "title": "Faster linting (work)",
         "status": "in-progress",
         "progress": "Switched linting to a faster tool. Waiting on review.",
         "learnings": ["When main moves fast, expect to rebase more than once before merging."],
         "bottlenecks": [],
         "next_steps": ["Merge after approval"]
       }
     ],
     "how_i_worked": {
       "blockers": [{ "what": "I re-explained the scope after the agent widened it.", "rec": "State the scope in the first prompt." }],
       "automate": [{ "what": "I ran the test suite myself before each commit.", "rec": "Let the agent run it before reporting done." }]
     }
   }
   ```

   `session_ids` must be ids from the digest, each used once. No other keys anywhere.
5. Run `bash ~/.claude/skills/session-note/scripts/note.sh --daily <date> <scratchpad>/facts.json`. On `REJECT`/`SCHEMA`: fix and rerun until it exits 0.
6. Tell the user the printed path. Nothing else.

`--dry-run` (first argument) runs every check and prints the note without writing it.

## What the scripts add

| Part | Source |
| --- | --- |
| Frontmatter: single `id`, `source: claude-session`, `created`; daily `source`, `created` | note.sh |
| Per section `Time:` line: first to last local time, active, waiting on me, my messages, permission denials | digest.sh numbers, inserted after the gate |
| How I worked `Sessions:` and `Time:` lines (parallel time counted once) | digest.sh numbers, inserted after the gate |
| Single mode `## Resume` with `claude --resume <id>` | note.sh |

Figures, as digest.sh computes them: **active** sums the gaps between consecutive transcript entries that day, a gap over 30 minutes counts as away; **waiting on me** sums the gaps from the entry before each of my messages to that message (same cap); **my messages** counts typed prompts, slash commands and `!` shell input; **permission denials** counts tool calls rejected by me, a deny rule or the auto-mode classifier (approved prompts leave no trace in the transcript). A grouped section adds up its sessions. Sessions are picked by entry timestamp (Europe/Berlin date), not file mtime; subagent transcripts, sidechain entries and headless runs (`-private-tmp*`, `-private-var-folders-*`, `*-scratchpad-*` folders, `claude -p` sessions) are excluded.

## The gate (note.sh)

Every LLM-written string is NFKC-normalised, stripped of invisible format characters and whitespace-squeezed, then checked for: secrets, tokens, PEM keys, connection strings, IPv4/IPv6, emails, internal hosts (`.corp`, `.internal`, `.local`, ...), URLs, hostnames (any dotted name ending in an alphabetic TLD of two or more letters, whatever the TLD and in any case, so `Acme.Com`, `jira.acme.Com` and dotted code such as `message.content` or `JSON.parse` also reject; exempt are a sentence join, a lower-case word directly followed by a Capitalised word with nothing dotted around it (`done.Next`, which also lets a bare `acme.Com` through), a known file extension such as `.json`, `.md` or `.sh` in TLD position, and a name whose label before the TLD has no letter, such as `v2.1.rc`), commit SHAs, ticket keys, work repo names (built at run time from the folder names in `SESSION_NOTE_WORK_ROOT`, default `~/Work/job/git`), `denylist.txt` terms, number words and any digit outside dates, times, `v`/`version` versions, filenames and `localhost:port`. `settings.local.json` is a filename, not a host. Exit codes: 0 ok, 1 environment, 2 usage/schema, 3 reject. `note.sh --recheck <note.md>` re-gates a written note: a line passes untouched only in the exact shape the script makes.

On a machine without work repos, set `SESSION_NOTE_WORK_ROOT` to an empty folder; a missing root fails loudly.

## Scheduled run

`scripts/daily.sh` is the launchd entry point (`~/Library/LaunchAgents/local.claude.session-note-daily.plist`, 23:00 daily; a run missed while asleep runs on wake, and before 06:00 it summarises the day before). It runs one `claude -p --model sonnet --safe-mode` with only Read, Write inside a temp dir, and Bash limited to `digest.sh` and `note.sh --dry-run`, then writes the note itself with `note.sh --daily`. On any failure or reject it writes nothing, appends the reason to `~/Library/Logs/session-note-daily.log` and shows a macOS notification.

Run it by hand: `launchctl kickstart -k gui/$(id -u)/local.claude.session-note-daily`, or `bash ~/.claude/skills/session-note/scripts/daily.sh [YYYY-MM-DD]`.

## Tests

- `bash ~/.claude/skills/session-note/tests/run.sh`: gate, schema, digest selection and figures, daily rendering, wrapper (stubbed claude and osascript). No LLM calls.
- `bash ~/.claude/skills/session-note/tests/scenario.sh`: real headless Sonnet runs of both modes and a planted leak. Costs a few Sonnet calls.
- `bash ~/.claude/skills/session-note/tests/e2e.sh`: kickstarts the launchd job and checks today's real note in the inbox. Writes one real note.
- `tests/evals.md`: LLM behaviour cases, graded by properties.
