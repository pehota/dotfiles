#!/usr/bin/env bash
# daily.sh [YYYY-MM-DD] — unattended daily summary, run by launchd (local.claude.session-note-daily).
#
# Steps: resolve date (digest.sh rule: before 06:00 local = yesterday) -> catch up the day before when its
# note is missing -> per day: skip a day without sessions -> one headless `claude -p` on Sonnet writes
# facts.json and checks it with `note.sh --dry-run` -> this script runs the real `note.sh --daily` (schema,
# gate, figures, atomic write).
# Catch-up: without a date argument (the scheduled run), when "claude sessions <day before>.md" is in
# neither the inbox nor brain/raw (where the evening brain processor moves inbox notes), the day before is
# summarised first. A Mac that wakes after 06:00 would otherwise skip the missed evening. A day already in
# raw is never regenerated. An explicit date runs that day only.
# The LLM never writes into the vault: its only tools are Read, Write/Edit inside a temp work dir, and
# Bash limited to digest.sh and `note.sh --dry-run`.
# On any failure or gate reject: nothing is written, the reason goes to the log, and a macOS notification
# (no note text) is shown; a failed catch-up day does not stop today's run. Exit 0 ok or nothing to do ·
# 1 any day failed.
#
# Env:
#   SESSION_NOTE_LOG        log file (default ~/Library/Logs/session-note-daily.log)
#   SESSION_NOTE_CLAUDE     claude binary (default claude)
#   SESSION_NOTE_TIMEOUT    seconds for the claude run (default 900)
#   SESSION_NOTE_BUDGET_USD max spend for the claude run (default 2)
#   SESSION_NOTE_DIR        inbox (default ~/Work/mine/obsidian-vault/brain/inbox), also read by note.sh
#   SESSION_NOTE_RAW_DIR    processed notes (default ~/Work/mine/obsidian-vault/brain/raw)
#   plus everything note.sh and digest.sh read (SESSION_NOTE_DIR, SESSION_NOTE_WORK_ROOT, CLAUDE_PROJECTS_DIR, ...)
set -euo pipefail

readonly SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly LOG="${SESSION_NOTE_LOG:-$HOME/Library/Logs/session-note-daily.log}"
readonly CLAUDE_BIN="${SESSION_NOTE_CLAUDE:-claude}"
readonly TIMEOUT_SECONDS="${SESSION_NOTE_TIMEOUT:-900}"
readonly BUDGET_USD="${SESSION_NOTE_BUDGET_USD:-2}"
readonly INBOX_DIR="${SESSION_NOTE_DIR:-$HOME/Work/mine/obsidian-vault/brain/inbox}"
readonly RAW_DIR="${SESSION_NOTE_RAW_DIR:-$HOME/Work/mine/obsidian-vault/brain/raw}"

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

# day_before <YYYY-MM-DD> -> the calendar date before it
day_before() {
  jq -nr --arg d "$1" '$d | strptime("%Y-%m-%d") | mktime - 86400 | strftime("%Y-%m-%d")'
}

# daily_note_exists <YYYY-MM-DD> -> exit 0 when that day's note is in the inbox or in raw
daily_note_exists() {
  [ -e "$INBOX_DIR/claude sessions $1.md" ] || [ -e "$RAW_DIR/claude sessions $1.md" ]
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

# fail <date> <reason> [detail file]: log, notify (no note text), return 1
fail() {
  log "FAIL $2"
  [ -z "${3:-}" ] || sed 's/^/    /' "$3" >>"$LOG"
  osascript -e "display notification \"Daily session note not written for $1. See $LOG\" with title \"session-note\"" \
    >/dev/null 2>&1 || log "notification failed"
  return 1
}

WORK=""
trap '[ -z "$WORK" ] || rm -rf "$WORK"' EXIT

# summarise_digest <work dir> <digest.json>: claude writes the facts, note.sh writes the note; 1 on failure
summarise_digest() {
  local work="$1" digest="$2"
  local date; date="$(jq -r .date "$digest")"

  local step1_sessions; step1_sessions="$(jq -r .day.sessions "$digest")"
  [ "$step1_sessions" != 0 ] || { log "ok no sessions on $date, nothing written"; return 0; }

  local step2_facts="$work/facts.json" args=() line
  while IFS= read -r line; do args+=("$line"); done < <(claude_args "$work")
  (cd "$work" && with_timeout "$TIMEOUT_SECONDS" "$CLAUDE_BIN" -p "$(claude_prompt "$date" "$step2_facts")" "${args[@]}") \
    >"$work/claude.json" 2>"$work/claude.err" || { fail "$date" "claude run failed or timed out for $date" "$work/claude.err"; return 1; }
  [ -f "$step2_facts" ] || { fail "$date" "claude wrote no facts for $date" "$work/claude.json"; return 1; }

  local step3_note
  step3_note="$(bash "$SKILL_DIR/scripts/note.sh" --daily "$date" "$step2_facts" 2>"$work/note.err")" \
    || { fail "$date" "note.sh rejected the facts for $date; nothing written" "$work/note.err"; return 1; }
  log "ok $step3_note"
}

# digest_into <work dir> [date]: digest.sh into <work dir>/digest.json; 1 on failure
digest_into() {
  local work="$1"; shift
  mkdir -p "$work"
  bash "$SKILL_DIR/scripts/digest.sh" "$@" >"$work/digest.json" 2>"$work/digest.err" \
    || { fail "${1:-today}" "digest.sh failed" "$work/digest.err"; return 1; }
}

main() {
  mkdir -p "$(dirname "$LOG")"
  [ "$#" -le 1 ] || { fail today "usage: daily.sh [YYYY-MM-DD]"; exit 1; }
  WORK="$(mktemp -d)"
  WORK="$(cd "$WORK" && pwd -P)"
  local status=0

  local step1_today="$WORK/today"
  digest_into "$step1_today" "$@" || exit 1
  local date; date="$(jq -r .date "$step1_today/digest.json")"

  local step2_before; step2_before="$(day_before "$date")"
  if [ "$#" -eq 0 ] && ! daily_note_exists "$step2_before"; then
    log "catch-up: no note for $step2_before in inbox or raw"
    { digest_into "$WORK/before" "$step2_before" && summarise_digest "$WORK/before" "$WORK/before/digest.json"; } || status=1
  fi

  summarise_digest "$step1_today" "$step1_today/digest.json" || status=1
  exit "$status"
}

main "$@"
