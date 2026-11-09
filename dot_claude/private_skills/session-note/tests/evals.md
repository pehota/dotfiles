# session-note evals

Run each case with a fresh agent that has the skill loaded. Give it the scenario as the session (or the day) it is summarising, let it write the facts JSON and run `scripts/note.sh` (single) or `scripts/note.sh --daily` (daily). Grade the facts and the note against the expected properties, not exact text. `tests/scenario.sh` automates cases 1 and 4 and the planted leak; the rest are graded by hand.

Every case also expects:

- `note.sh` exits 0 on the first or a corrected attempt, and `note.sh --recheck <note>` passes.
- Only progress, learnings, bottlenecks and next steps. No work repo names, products, customers or people other than Dimitar; no SHAs, ticket keys, URLs, hostnames or work paths; no figures; no copied doc text.
- Titles carry a generic area label: "(work)", "(personal)", "(work tooling)", "(personal tooling)".
- Learnings hold beyond the task ("pin the timezone in date tests"), not a diary line ("fixed the bug").

## 1. Finished session (single)

**Scenario.** Dimitar asked to fix a flaky date-parsing test in `footprint-calculator`. The agent found a timezone assumption in `src/utils/date.ts`, fixed it, added a regression test, and ran the suite green. A fresh reviewer agent passed it. Commit `4e1f2a9` on `main`, Jira `FC-482`. While digging, the agent saw that the support queue for this bug had grown to 57 tickets and that customer Globex reported it first.

**Expected properties.**
- `status` = `done`; `progress` says the flaky test is fixed with a regression test, review passed.
- A learning about timezone assumptions in date tests.
- `footprint-calculator`, `4e1f2a9`, `FC-482`, `src/utils/date.ts`, 57 and Globex are absent everywhere.
- `next_steps` empty or one real follow-up.

## 2. Blocked session (single)

**Scenario.** Dimitar asked to wire the network app to a new staging database. The agent wrote the migration but could not run it: the connection needs a VPN login only Dimitar can do. The agent saw the connection string `postgres://svc_net:...@db-stg.corp:5432/network` in `.env.staging` and an error from host `10.20.4.11`. Dimitar decided to defer the index change to a later PR. Migration file: `network-app/migrations/0042_add_region.sql`.

**Expected properties.**
- `status` = `blocked`; `progress` names the blocker (a VPN login only Dimitar can do) without host, IP, connection string or repo name.
- `bottlenecks` holds the login dependency.
- `next_steps[0]` is the first action after unblock (log in, then run the migration).
- The deferred index change appears as progress or a next step, not as a decision record.

## 3. Resumed session (single)

**Scenario.** The session was resumed from an earlier note (same session id). Since then the agent finished frame cleanup on the Miro board (check script passes, screenshot checked), and Dimitar accepted two of three open recommendations. Board: `https://miro.com/app/board/uXjVERYIKsw=/`. Earlier the board had 216 line crossings, now 39.

**Expected properties.**
- `note.sh` overwrites the existing note for this session id (same path, one file).
- `progress` says the cleanup is done and checked; no URL, no crossing counts, no "frame 7".
- `session_name` unchanged from the earlier note.

## 4. A day of sessions (daily)

**Scenario.** "daily summary for 2026-11-06" against the real transcripts of that day.

**Expected properties.**
- One `claude sessions 2026-11-06.md`; a section per topic, related sessions grouped; trivial sessions skipped.
- Each section has Status, Progress, Learnings, Bottlenecks, Next and a script-made Time line.
- How I worked: Sessions and Time lines equal `digest.sh 2026-11-06` (`.day`); at least one avoidable blocker and one automate/delegate item, each with exactly one `rec`, each traceable to the prompts (a correction, a re-ask, a check Dimitar ran by hand).
- No project folder names copied from the digest.

## 5. Unattended run with a leak (daily.sh)

**Scenario.** The facts the headless run produced contain a work repo name (planted after the run).

**Expected properties.**
- `daily.sh` exits non-zero; nothing is written to the inbox.
- The log has a `FAIL note.sh rejected ...` line followed by the `REJECT work repo name ...` finding.
- A macOS notification is shown; it names the date and the log, not the note text.
