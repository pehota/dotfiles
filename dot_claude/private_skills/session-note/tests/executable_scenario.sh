#!/usr/bin/env bash
# Scenario checks with real headless Claude runs (Sonnet). Usage: tests/scenario.sh   (exit 0 = all green)
#
#   a  "daily summary for 2026-11-06" through the skill, into a temp SESSION_NOTE_DIR: every section,
#      How I worked figures equal digest.sh output, the written note passes the gate re-check
#   b  "dump this into brain" for a described session, into a temp dir: single note, gate re-check passes
#   c  daily.sh with a planted work repo name (real claude run over fixture transcripts, then the leak is
#      planted into its facts): non-zero, nothing written, logged, notification called (osascript stubbed)
#
# Cost: three Sonnet runs. Reads the real ~/.claude/projects for 2026-11-06 in (a).
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SKILL="$(cd "$HERE/.." && pwd)"
readonly TILDE="~${SKILL#"$HOME"}"
readonly DAY="2026-11-06"
readonly TMP="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT
PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); echo "ok   $1"; }
ko() { FAIL=$((FAIL + 1)); echo "FAIL $1"; }
check() { if eval "$2"; then ok "$1"; else ko "$1"; fi; }
md_count() { find "$1" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' '; }

# dur <minutes> -> "Xh YYm" or "Ym", as note.sh renders it
dur() { if [ "$1" -ge 60 ]; then printf '%dh %02dm' $(($1 / 60)) $(($1 % 60)); else printf '%dm' "$1"; fi; }

# run_claude <work dir> <prompt>: headless skill run, hooks off, tools limited to the skill scripts
run_claude() {
  local work="$1" prompt="$2"
  (cd "$work" && timeout 900 claude -p "$prompt" --model sonnet --settings '{"disableAllHooks":true}' \
    --tools Bash,Read,Write,Edit,Skill \
    --allowedTools "Skill" \
      "Bash(bash $SKILL/scripts/digest.sh *)" "Bash(bash $SKILL/scripts/note.sh *)" \
      "Bash(bash $TILDE/scripts/digest.sh *)" "Bash(bash $TILDE/scripts/note.sh *)" \
      "Read(/$SKILL/**)" "Read(/$work/**)" "Edit(/$work/**)" \
    --permission-mode dontAsk --strict-mcp-config --no-session-persistence --output-format json --max-budget-usd 3)
}

scenario_daily() {
  local out="$TMP/a-out" work="$TMP/a-work"; mkdir -p "$out" "$work"
  SESSION_NOTE_DIR="$out" run_claude "$work" \
    "daily summary for $DAY. Use $work as your scratchpad directory for facts.json." >"$TMP/a.json" 2>"$TMP/a.err" || true
  local f="$out/claude sessions $DAY.md"
  check "a: exactly the daily note was written" '[ -f "$f" ] && [ "$(md_count "$out")" = 1 ]'
  [ -f "$f" ] || { jq -r '.result // empty' "$TMP/a.json" | tail -20; tail -5 "$TMP/a.err"; return; }

  check "a: frontmatter and title" '[ "$(sed -n 1,4p "$f" | tr "\n" "|")" = "---|source: claude-session|created: $DAY|---|" ] && grep -qx "# Claude sessions $DAY" "$f"'
  local sections; sections="$(grep -c '^## ' "$f")"
  check "a: at least one session section plus How I worked (got $sections)" '[ "$sections" -ge 2 ] && [ "$(grep "^## " "$f" | tail -1)" = "## How I worked" ]'
  local n_status n_time
  n_status="$(grep -c '^- \*\*Status:\*\* ' "$f")"; n_time="$(grep -c '^- \*\*Time:\*\* [0-9][0-9]:[0-9][0-9] to ' "$f")"
  check "a: every session section has Status, Progress, Learnings, Bottlenecks, Next and Time" \
    '[ "$n_status" = $((sections - 1)) ] && [ "$(grep -c "^- \*\*Progress:\*\* " "$f")" = "$n_status" ] && [ "$(grep -c "^- \*\*Learnings:\*\*" "$f")" = "$n_status" ] && [ "$(grep -c "^- \*\*Bottlenecks:\*\*" "$f")" = "$n_status" ] && [ "$(grep -c "^- \*\*Next:\*\*" "$f")" = "$n_status" ] && [ "$n_time" = "$n_status" ]'

  (unset CLAUDE_CODE_SESSION_ID; bash "$SKILL/scripts/digest.sh" "$DAY") >"$TMP/a-digest.json"
  local d_session d_waiting d_msgs d_denials d_sessions
  read -r d_session d_waiting d_msgs d_denials d_sessions < <(jq -r '.day | "\(.session_min) \(.waiting_min) \(.my_messages) \(.permission_denials) \(.sessions)"' "$TMP/a-digest.json")
  check "a: How I worked sessions equal digest.sh" 'grep -qxF -- "- **Sessions:** $d_sessions" "$f"'
  check "a: How I worked figures equal digest.sh" \
    'grep -qxF -- "- **Time:** session time $(dur "$d_session") · waiting on me $(dur "$d_waiting") · my messages $d_msgs · permission denials $d_denials" "$f"'
  check "a: blockers and automate sections" 'grep -q "^- \*\*Avoidable blockers:\*\*" "$f" && grep -q "^- \*\*Automate or delegate:\*\*" "$f"'
  check "a: gate re-check passes" 'bash "$SKILL/scripts/note.sh" --recheck "$f" >/dev/null'
  cp "$f" "$TMP/a-note.md"
}

scenario_single() {
  local out="$TMP/b-out" work="$TMP/b-work"; mkdir -p "$out" "$work"
  SESSION_NOTE_DIR="$out" run_claude "$work" "Earlier in this session we fixed a flaky date-parsing test in the footprint-calculator repo: the agent found a timezone assumption, fixed it in commit 4e1f2a9 for ticket FC-482, added a regression test, and the suite ran green; a fresh reviewer passed it. The support queue had 57 tickets about it, customer Globex reported it first. Use $work as your scratchpad directory. Now dump this into brain." \
    >"$TMP/b.json" 2>"$TMP/b.err" || true
  local f; f="$(find "$out" -maxdepth 1 -name '*.md' | head -1)"
  check "b: exactly one single note written" '[ -n "$f" ] && [ "$(md_count "$out")" = 1 ]'
  [ -n "$f" ] || { jq -r '.result // empty' "$TMP/b.json" | tail -20; tail -5 "$TMP/b.err"; return; }
  check "b: frontmatter id, source, created" '[ "$(sed -n 1p "$f")" = "---" ] && grep -qE "^id: [0-9a-f-]{36}$" "$f" && grep -qx "source: claude-session" "$f" && grep -qE "^created: [0-9]{4}-[0-9]{2}-[0-9]{2}$" "$f"'
  check "b: progress, learnings, bottlenecks, next" 'grep -q "^- \*\*Progress:\*\* " "$f" && grep -q "^- \*\*Learnings:\*\*" "$f" && grep -q "^- \*\*Bottlenecks:\*\*" "$f" && grep -q "^- \*\*Next:\*\*" "$f"'
  check "b: no repo, sha, ticket, figure or customer" '! grep -qiE "footprint-calculator|4e1f2a9|FC-482|57|Globex" "$f"'
  check "b: gate re-check passes" 'bash "$SKILL/scripts/note.sh" --recheck "$f" >/dev/null'
  cp "$f" "$TMP/b-note.md"
}

scenario_leak() {
  local out="$TMP/c-out" bin="$TMP/c-bin" repo
  mkdir -p "$out" "$bin"
  repo="$(find -L "$HOME/Work/job/git" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -exec basename {} \; | sort | head -1)"
  cp -R "$HERE/fixtures/transcripts" "$TMP/c-projects"; find "$TMP/c-projects" -type f -exec touch {} +
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >>"%s/osascript.calls"\n' "$TMP" >"$bin/osascript"
  # claude wrapper: the real headless run, then plants the repo name into the facts it wrote.
  cat >"$bin/claude-planting" <<EOF
#!/usr/bin/env bash
facts="\$(printf '%s' "\$2" | grep -oE '/[^ ]*/facts\.json' | head -1)"
claude "\$@"; rc=\$?
[ -f "\$facts" ] && jq '.sessions[0].title = "Fix in $repo (work)"' "\$facts" >"\$facts.tmp" && mv "\$facts.tmp" "\$facts"
exit \$rc
EOF
  chmod +x "$bin/osascript" "$bin/claude-planting"
  local rc=0
  PATH="$bin:$PATH" SESSION_NOTE_DIR="$out" CLAUDE_PROJECTS_DIR="$TMP/c-projects" SESSION_NOTE_LOG="$TMP/c.log" \
    SESSION_NOTE_CLAUDE="$bin/claude-planting" CLAUDE_CODE_SESSION_ID="" bash "$SKILL/scripts/daily.sh" "$DAY" || rc=$?
  check "c: planted leak -> non-zero exit (rc=$rc)" '[ "$rc" != 0 ]'
  check "c: planted leak -> nothing written" '[ "$(md_count "$out")" = 0 ]'
  check "c: planted leak -> gate reject logged" 'grep -q "FAIL note.sh rejected" "$TMP/c.log" && grep -q "work repo name" "$TMP/c.log"'
  check "c: planted leak -> notification called" 'grep -q "display notification" "$TMP/osascript.calls"'
  tail -4 "$TMP/c.log" | sed 's/^/       log: /'
}

main() {
  scenario_daily
  scenario_single
  scenario_leak
  for f in "$TMP/a.json" "$TMP/b.json"; do [ -f "$f" ] && jq -r '"cost usd: \(.total_cost_usd // "?")"' "$f" 2>/dev/null || true; done
  if [ -n "${SCENARIO_KEEP:-}" ]; then mkdir -p "$SCENARIO_KEEP" && cp "$TMP"/*-note.md "$SCENARIO_KEEP"/ 2>/dev/null || true; fi
  echo "---"
  echo "passed: $PASS  failed: $FAIL"
  [ "$FAIL" = 0 ]
}

main "$@"
