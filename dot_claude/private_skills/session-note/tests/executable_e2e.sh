#!/usr/bin/env bash
# End-to-end: kickstart the real launchd job, wait for it, check the real inbox note.
# Usage: tests/e2e.sh   (exit 0 = green). Writes one real note for the job's date (today, or yesterday
# before 06:00) into ~/Work/mine/obsidian-vault/brain/inbox. Costs one Sonnet run.
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SKILL="$(cd "$HERE/.." && pwd)"
readonly LABEL="local.claude.session-note-daily"
readonly TARGET="gui/$(id -u)/$LABEL"
readonly LOG="$HOME/Library/Logs/session-note-daily.log"
readonly INBOX="$HOME/Work/mine/obsidian-vault/brain/inbox"
readonly WAIT_SECONDS=1200

fail() { echo "FAIL $*"; exit 1; }

main() {
  launchctl print "$TARGET" >/dev/null 2>&1 || fail "job $LABEL is not loaded (launchctl bootstrap gui/\$(id -u) ~/Library/LaunchAgents/$LABEL.plist)"
  local step1_date step1_lines
  step1_date="$(bash "$SKILL/scripts/digest.sh" | jq -r .date)"
  step1_lines="$( [ -f "$LOG" ] && wc -l <"$LOG" | tr -d ' ' || echo 0)"
  echo "date $step1_date; kickstarting $TARGET"

  launchctl kickstart -k "$TARGET"
  local waited=0 result=""
  while [ "$waited" -lt "$WAIT_SECONDS" ]; do
    result="$(tail -n "+$((step1_lines + 1))" "$LOG" 2>/dev/null | grep -E '^[0-9T:+-]+ (ok|FAIL) ' | tail -1 || true)"
    [ -z "$result" ] || break
    sleep 10; waited=$((waited + 10))
  done
  [ -n "$result" ] || fail "no result line in $LOG after ${WAIT_SECONDS}s"
  echo "log: $result"
  case "$result" in *" FAIL "*) tail -n "+$((step1_lines + 1))" "$LOG" | tail -20; fail "job reported failure" ;; esac

  local note="$INBOX/claude sessions $step1_date.md"
  [ -f "$note" ] || fail "note missing: $note"
  case "$result" in *"$note"*) ;; *) fail "log names another file than $note" ;; esac
  grep -qx "# Claude sessions $step1_date" "$note" || fail "title missing"
  grep -qx "## How I worked" "$note" || fail "How I worked missing"
  bash "$SKILL/scripts/note.sh" --recheck "$note" || fail "gate re-check failed"
  echo "ok   $note written by launchd and passes the gate re-check"
}

main "$@"
