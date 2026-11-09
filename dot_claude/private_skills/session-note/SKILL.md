---
name: session-note
description: Writes the current Claude Code session as one Obsidian pointer note. Use only when the user explicitly asks, e.g. "dump session", "dump this", "dump this into brain", "brain dump this session" (or close wording), or runs /session-note. Never on your own initiative.
---

# Session note

A **pointer note** records where the work stands and points at where the data lives. Every fact sits behind a company login (Jira, repo, Miro, Confluence, artifact); the note itself holds none of it.

## Steps

1. **Sanitise first (mandatory).** Before writing any JSON, list every proper noun and every figure you are about to write. Replace customer and person names (except Dimitar) with roles: "a customer", "a CM", "the reviewer". Drop each figure and point at its source instead. Only then go to step 2. The script gate is the backstop, not the filter.
2. Write `facts.json` to the scratchpad, following the schema and pointer rules below.
3. Run:

   ```bash
   bash ~/.claude/skills/session-note/scripts/note.sh <scratchpad>/facts.json
   ```

   The script validates, runs the redaction gate, fills id/model/date/repo, and upserts by session id (same session → same file overwritten).
4. On a `REJECT` or `SCHEMA` line: rewrite that field as a pointer and rerun. Done when it exits 0.
5. Tell the user the printed path. Nothing else.

## Pointer rules

Write:
- outcomes, and decisions with their date and a `by` role (see schema)
- open questions, each with your recommendation
- next steps; the first is what to do on resume
- the user's own reasoning
- links: Jira keys, repo-relative or absolute local paths, Miro/Confluence/Claude-artifact URLs, commit SHAs

Keep out (point at the source instead, e.g. "see discovery/README.md headline findings"):
- names of customers and people; the user, Dimitar, is the one exception
- figures from internal systems or prod: counts, volumes, spend, headcount, response times, record counts, line/node tallies
- copied doc or page text
- secrets, tokens, connection strings, internal hostnames/IPs, emails

A `done` item carries its evidence: the test, check, or review that proved it. No evidence → it goes in `open`.

Drop counts and figures; point at the source instead. The gate rejects any digit that is not part of a date, time, version, ticket/initiative key, SHA, UUID, URL, path, `localhost:port` or "round N of M" / "step N", and spelled-out counts ("two rounds", "twenty tickets") too. Name things instead of numbering them ("the legend frame", not "frame 7").

## facts.json

All keys required except `session_name`; arrays may be empty. `status`: `in-progress` | `done` | `blocked`. `decisions[].by`: `Dimitar` | `team` | `reviewer` | `owner` | `product`.

```json
{
  "title": "Digital OS discovery",
  "session_name": "digital-os-discovery",
  "status": "in-progress",
  "outcome": "Discovery docs reviewed; Miro map built. See discovery/README.md headline findings.",
  "done": [{ "item": "Discovery docs", "evidence": "independent review passed" }],
  "decisions": [{ "decision": "Support handling is the first OS capability", "by": "Dimitar", "date": "2026-11-06" }],
  "open": [{ "question": "Keep dependency lines on the overview frame?", "rec": "Keep; they show what everything depends on." }],
  "next_steps": ["Run /dod:verify", "Commit in logical bundles"],
  "links": [{ "label": "Discovery", "target": "/abs/path/digital-os/discovery/README.md" }],
  "touched_paths": ["/abs/path/digital-os/discovery"]
}
```

`touched_paths` must be absolute. They feed the `repo` frontmatter (git top-level folder names; non-git paths skipped). A path inside a git worktree reports the worktree's folder name, not the main repo's.
