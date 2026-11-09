#!/usr/bin/env bash
# daily.sh [YYYY-MM-DD] — unattended daily summary, run by launchd (local.claude.session-note-daily).
#
# Steps: resolve date (digest.sh rule: before 06:00 local = yesterday) -> skip a day without sessions ->
# one headless `claude -p` on Sonnet writes facts.json and checks it with `note.sh --dry-run` ->
# this script runs the real `note.sh --daily` (schema, gate, figures, atomic write).
# The LLM never writes into the vault: its only tools are Read, Write/Edit inside a temp work dir, and
# Bash limited to digest.sh and `note.sh --dry-run`.
# On any failure or gate reject: nothing is written, the reason goes to the log, and a macOS notification
# (no note text) is shown. Exit 0 ok or nothing to do · 1 failure.
#
# Env:
#   SESSION_NOTE_LOG        log file (default ~/Library/Logs/session-note-daily.log)
#   SESSION_NOTE_CLAUDE     claude binary (default claude)
#   SESSION_NOTE_TIMEOUT    seconds for the claude run (default 900)
#   SESSION_NOTE_BUDGET_USD max spend for the claude run (default 2)
#   plus everything note.sh and digest.sh read (SESSION_NOTE_DIR, SESSION_NOTE_WORK_ROOT, CLAUDE_PROJECTS_DIR, ...)
set -euo pipefail

readonly SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly LOG="${SESSION_NOTE_LOG:-$HOME/Library/Logs/session-note-daily.log}"
readonly CLAUDE_BIN="${SESSION_NOTE_CLAUDE:-claude}"
readonly TIMEOUT_SECONDS="${SESSION_NOTE_TIMEOUT:-900}"
readonly BUDGET_USD="${SESSION_NOTE_BUDGET_USD:-2}"

# --- pure functions: each reads its arguments, prints its result -------------

# claude_prompt <date> <facts path> -> the instruction for the headless run
claude_prompt() {
  cat <<EOF
Read $SKILL_DIR/SKILL.md and follow its daily mode for $1. This is an unattended run: nobody can answer
questions. Create $2 with the Write tool and fix it with the Edit or Write tool; Bash only runs
the two skill scripts, one plain command each (no cat, sed, heredocs, pipes or chained commands).
Check the facts with exactly:
bash $SKILL_DIR/scripts/note.sh --dry-run --daily $1 $2
Fix every REJECT or SCHEMA line and rerun until it exits 0. Do not write the note yourself; the caller does.
End with the single word DONE once the dry run exits 0, or FAILED with the reason.
EOF
}

# claude_args <work dir> -> one argument per line: model, tools and permissions for the headless run.
# The script rules are listed with the absolute and the ~ path, as SKILL.md shows the ~ form.
claude_args() {
  local tilde="~${SKILL_DIR#"$HOME"}"
  printf '%s\n' --model sonnet --safe-mode --tools Bash,Read,Write,Edit \
    --allowedTools "Bash(bash $SKILL_DIR/scripts/digest.sh *)" "Bash(bash $SKILL_DIR/scripts/note.sh --dry-run *)" \
      "Bash(bash $tilde/scripts/digest.sh *)" "Bash(bash $tilde/scripts/note.sh --dry-run *)" \
      "Read(/$SKILL_DIR/**)" "Read(/$1/**)" "Edit(/$1/**)" \
    --permission-mode dontAsk --strict-mcp-config --no-session-persistence \
    --output-format json --max-budget-usd "$BUDGET_USD"
}

# with_timeout <seconds> <command...>: coreutils timeout when installed, else unguarded
with_timeout() {
  local seconds="$1"; shift
  if command -v timeout >/dev/null; then timeout "$seconds" "$@"
  elif command -v gtimeout >/dev/null; then gtimeout "$seconds" "$@"
  else "$@"; fi
}

# --- main: named steps; the only place with side effects ---------------------

log() { printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" >>"$LOG"; }

fail() {
  log "FAIL $1"
  [ -z "${2:-}" ] || sed 's/^/    /' "$2" >>"$LOG"
  osascript -e "display notification \"Daily session note not written for ${DATE:-today}. See $LOG\" with title \"session-note\"" \
    >/dev/null 2>&1 || log "notification failed"
  exit 1
}

WORK=""
trap '[ -z "$WORK" ] || rm -rf "$WORK"' EXIT
DATE=""

main() {
  mkdir -p "$(dirname "$LOG")"
  [ "$#" -le 1 ] || fail "usage: daily.sh [YYYY-MM-DD]"
  WORK="$(mktemp -d)"
  WORK="$(cd "$WORK" && pwd -P)"

  local step1_digest="$WORK/digest.json"
  bash "$SKILL_DIR/scripts/digest.sh" "$@" >"$step1_digest" 2>"$WORK/digest.err" || fail "digest.sh failed" "$WORK/digest.err"
  DATE="$(jq -r .date "$step1_digest")"

  local step2_sessions; step2_sessions="$(jq -r .day.sessions "$step1_digest")"
  [ "$step2_sessions" != 0 ] || { log "ok no sessions on $DATE, nothing written"; return 0; }

  local step3_facts="$WORK/facts.json" args=() line
  while IFS= read -r line; do args+=("$line"); done < <(claude_args "$WORK")
  (cd "$WORK" && with_timeout "$TIMEOUT_SECONDS" "$CLAUDE_BIN" -p "$(claude_prompt "$DATE" "$step3_facts")" "${args[@]}") \
    >"$WORK/claude.json" 2>"$WORK/claude.err" || fail "claude run failed or timed out for $DATE" "$WORK/claude.err"
  [ -f "$step3_facts" ] || fail "claude wrote no facts for $DATE" "$WORK/claude.json"

  local step4_note
  step4_note="$(bash "$SKILL_DIR/scripts/note.sh" --daily "$DATE" "$step3_facts" 2>"$WORK/note.err")" \
    || fail "note.sh rejected the facts for $DATE; nothing written" "$WORK/note.err"
  log "ok $step4_note"
}

main "$@"
