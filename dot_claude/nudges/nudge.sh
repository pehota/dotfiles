#!/usr/bin/env bash
# shellcheck disable=SC2329  # matches_* functions are called via dynamic dispatch
# UserPromptSubmit hook: shows self-improvement nudges as a systemMessage.
# Never blocks the prompt, never adds Claude context, never fails: any error -> silent exit 0.
set -u

RULES_BUDGET=188
STATE_DIR="${NUDGE_STATE_DIR:-$HOME/.local/state/claude-nudges}"
RULES_FILE="${NUDGE_RULES_FILE:-$HOME/.claude/MY_RULES.md}"

today() { echo "${NUDGE_TODAY:-$(date +%F)}"; }

read_prompt() { jq -r 'if type == "object" and (.prompt | type) == "string" then .prompt else empty end' 2>/dev/null; }

# has_word <lowercased text> <ERE alternatives>: word-bounded match
has_word() { [[ "$1" =~ (^|[^[:alnum:]_])($2)([^[:alnum:]_]|$) ]]; }

matches_challenge() { has_word "$1" "per recs|go with (your |the )?recs"; }

matches_rule_budget() {
  [[ -f "$RULES_FILE" ]] || return 1
  has_word "$1" "my_rules|me\.md|me_voice\.md|claude\.md|add a rule|new rule"
}

matches_limits() {
  has_word "$1" "implement|fix|build|add|refactor|create" || return 1
  ! has_word "$1" "stop|until|commit|max|only|don't|do not"
}

rule_line_count() { wc -l <"$RULES_FILE" | tr -d ' '; }

nudge_text() {
  case "$1" in
    challenge) echo "Nudge: accepting all recs. Which one would you challenge, and why?" ;;
    rule-budget) echo "Nudge: MY_RULES is $(rule_line_count) lines (budget $RULES_BUDGET). Can this replace a rule, or be enforced in code instead?" ;;
    limits) echo "Nudge: no stop point stated. Where should it stop, and how many review rounds?" ;;
  esac
}

already_fired_today() { [[ "$(cat "$STATE_DIR/$1.last" 2>/dev/null)" == "$(today)" ]]; }

record_fire() {
  printf '%s\n' "$(today)" >"$STATE_DIR/$1.last"
  printf '%s\t%s\n' "$(today)" "$1" >>"$STATE_DIR/hits.tsv"
}

fired_patterns() {
  local lowered="$1" pattern
  for pattern in challenge rule-budget limits; do
    "matches_${pattern//-/_}" "$lowered" || continue
    already_fired_today "$pattern" && continue
    record_fire "$pattern"
    echo "$pattern"
  done
}

join_texts() {
  local pattern out="" sep=""
  while read -r pattern; do
    out+="$sep$(nudge_text "$pattern")"
    sep=" | "
  done
  printf '%s' "$out"
}

main() {
  command -v jq >/dev/null || return 0
  local prompt lowered message
  prompt="$(read_prompt)" || return 0
  [[ -n "$prompt" ]] || return 0
  lowered="$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')"
  mkdir -p "$STATE_DIR" || return 0
  message="$(fired_patterns "$lowered" | join_texts)"
  [[ -n "$message" ]] || return 0
  jq -cn --arg m "$message" '{systemMessage: $m}'
}

main 2>/dev/null || true
exit 0
