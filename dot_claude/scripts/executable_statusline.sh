#!/usr/bin/env bash
# Claude Code status line, two rows:
#   Model: Opus 5.5 | Ctx: 24.0% | Sess: 1.0% (4hr 19m)            Weekly: 15.0% (3d 16hr 29m)
#   𖠰 main
# Sess is the 5-hour usage window, Weekly the 7-day one; the bracket is the time until it resets.
# Ctx turns yellow at 50% and red at 65%; Sess and Weekly at 70% and 90%.
# Claude Code sends all of it as JSON on stdin (rate_limits included), so there is no API call
# and no Node start-up. Event-driven only: leave `refreshInterval` unset in settings.json.
# Install and behaviour: see README.md next to this file.
set -euo pipefail
shopt -s extglob
export LC_NUMERIC=C

RED=$'\e[31m'; YELLOW=$'\e[33m'; MAGENTA=$'\e[35m'; DIM=$'\e[2m'; RESET=$'\e[0m'
# Columns kept free on the right: Claude Code cuts a full-width row short with "…" (4 characters lost at margin 2)
RIGHT_MARGIN="${STATUSLINE_MARGIN:-6}"
# Percent from which a value turns yellow, then red
USAGE_YELLOW=70; USAGE_RED=90
CONTEXT_YELLOW=50; CONTEXT_RED=65

# humanize_remaining <seconds> -> 3d 16hr 29m | 4hr 19m | 12m | now
humanize_remaining() {
  local s="$1"
  if (( s <= 0 )); then echo "now"
  elif (( s >= 86400 )); then echo "$(( s / 86400 ))d $(( s % 86400 / 3600 ))hr $(( s % 3600 / 60 ))m"
  elif (( s >= 3600 )); then echo "$(( s / 3600 ))hr $(( s % 3600 / 60 ))m"
  else echo "$(( s / 60 ))m"
  fi
}

# format_percent <number> -> 24.0%
format_percent() { printf '%.1f%%' "$1"; }

# measure <text> -> sets VISIBLE to the characters on screen, colour codes not counted (no subshell)
measure() {
  local plain="${1//$'\e'\[+([0-9;])m/}"
  VISIBLE="${#plain}"
}

# visible_length <text> -> prints the same number, for callers that want a value
visible_length() { measure "$1"; echo "$VISIBLE"; }

# paint <text> <percent> <yellow_from> <red_from> -> text in yellow or red once the percent reaches the threshold
paint() {
  local text="$1" whole="${2%.*}" yellow_from="$3" red_from="$4"
  whole="${whole:-0}"
  if (( whole >= red_from )); then echo "${RED}${text}${RESET}"
  elif (( whole >= yellow_from )); then echo "${YELLOW}${text}${RESET}"
  else echo "$text"
  fi
}

# usage_segment <label> <used_percentage> <resets_at_epoch> <now_epoch> -> "Sess: 1.0% (4hr 19m)", empty without data
usage_segment() {
  local label="$1" pct="$2" resets="$3" now="$4"
  [[ -z "$pct" ]] && return 0
  local text
  text="${DIM}$label:${RESET} $(paint "$(format_percent "$pct")" "$pct" "$USAGE_YELLOW" "$USAGE_RED")"
  [[ -n "$resets" ]] && text+=" ${DIM}($(humanize_remaining $(( resets - now ))))${RESET}"
  echo "$text"
}

# context_segment <used_percentage> -> "Ctx: 27.0%", empty without data
context_segment() {
  local pct="$1"
  [[ -z "$pct" ]] && return 0
  echo "${DIM}Ctx:${RESET} $(paint "$(format_percent "$pct")" "$pct" "$CONTEXT_YELLOW" "$CONTEXT_RED")"
}

# join_segments <segment>... -> segments separated by " | ", empty ones dropped
join_segments() {
  local out="" seg
  for seg in "$@"; do
    [[ -z "$seg" ]] && continue
    out+="${out:+ | }$seg"
  done
  echo "$out"
}

# layout_line <left> <right> <width> -> left text, right text pushed to the right edge (3 spaces minimum between)
layout_line() {
  local left="$1" right="$2" width="$3"
  if [[ -z "$right" ]]; then echo "$left"; return; fi
  if [[ -z "$left" ]]; then echo "$right"; return; fi
  measure "$left"; local left_width="$VISIBLE"
  measure "$right"; local right_width="$VISIBLE"
  local gap=$(( width - left_width - right_width ))
  (( gap < 3 )) && gap=3
  printf '%s%*s%s\n' "$left" "$gap" "" "$right"
}

# render <model> <context> <session> <weekly> <branch> <width> -> the rows for a terminal <width> columns wide (0 = unknown)
# One row when everything fits, Weekly pushed to the right edge. Narrower: Weekly moves down to the branch row.
# Narrower than Ctx and Sess alone: the model name is dropped first.
render() {
  local model="$1" context="$2" session="$3" weekly="$4" branch="$5" width="$6"
  local left; left=$(join_segments "$model" "$context" "$session")
  measure "$left"
  if (( width > 0 && VISIBLE > width )); then
    left=$(join_segments "$context" "$session")
    measure "$left"
  fi
  local left_width="$VISIBLE"
  measure "$weekly"
  if (( width == 0 || left_width + 3 + VISIBLE <= width )); then
    layout_line "$left" "$weekly" "$width"
    [[ -n "$branch" ]] && echo "$branch"
  else
    echo "$left"
    join_segments "$weekly" "$branch"
  fi
  return 0
}

main() {
  local now="${STATUSLINE_NOW:-$(date +%s)}"
  local model ctx five five_reset week week_reset dir
  IFS='|' read -r model ctx five five_reset week week_reset dir < <(
    jq -r '[
      (.model.display_name // "?"),
      (.context_window.used_percentage // ""),
      (.rate_limits.five_hour.used_percentage // ""),
      (.rate_limits.five_hour.resets_at // ""),
      (.rate_limits.seven_day.used_percentage // ""),
      (.rate_limits.seven_day.resets_at // ""),
      (.workspace.current_dir // .cwd // "")
    ] | map(tostring) | join("|")'
  )
  local branch=""
  [[ -n "$dir" ]] && branch=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null || true)
  local width=0
  (( ${COLUMNS:-0} > 0 )) && width=$(( COLUMNS - RIGHT_MARGIN ))
  render \
    "${DIM}Model:${RESET} ${model}" \
    "$(context_segment "$ctx")" \
    "$(usage_segment Sess "$five" "$five_reset" "$now")" \
    "$(usage_segment Weekly "$week" "$week_reset" "$now")" \
    "${branch:+${MAGENTA}𖠰 $branch${RESET}}" \
    "$width"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main; fi
