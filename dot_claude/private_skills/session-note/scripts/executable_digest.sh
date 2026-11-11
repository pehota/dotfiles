#!/usr/bin/env bash
# digest.sh [YYYY-MM-DD] — compact JSON digest of the Claude Code sessions active on one local day.
#
# Steps: resolve date -> list candidate transcripts -> one digest per session (entries of that day) -> day totals.
# Prints JSON on stdout: {date, tz, idle_gap_min, day: {figures}, sessions: [{session_id, project, first, last,
#   figures, prompts, assistant_tail, commits}]}. `project` and the text fields are for the LLM only; note.sh
#   renders nothing from this digest except the numbers and HH:MM times.
#
# Date: the argument, else today in Europe/Berlin; before 06:00 local the default is yesterday.
# Selection is by entry timestamp (UTC in the file, compared as the Europe/Berlin calendar date), never by
# file mtime. mtime and a grep for the UTC dates only pre-filter. Excluded:
#   - subagent transcripts (<project>/<session>/subagents/*.jsonl; only <project>/*.jsonl is read)
#   - sidechain entries
#   - headless runs: project folders starting -private-tmp or -private-var-folders-, folders containing
#     -scratchpad-, and sessions whose entries carry an sdk entrypoint (claude -p)
#   - the session running this script (CLAUDE_CODE_SESSION_ID)
#
# Figures (per session; the day merges overlapping time of parallel sessions once):
#   active_min      sum of gaps between consecutive entries that day, gaps over 30 min count as away
#   waiting_min     sum of gaps from the entry before one of my messages to that message (turn end -> my
#                   reply), same 30 min cap
#   my_messages     my prompts that day (typed text, slash commands, ! shell input)
#   permission_denials  tool calls denied: rejected by me, by a deny rule, or by the auto-mode classifier
#
# Env:
#   CLAUDE_PROJECTS_DIR     transcript root (default ~/.claude/projects)
#   CLAUDE_CODE_SESSION_ID  excluded from the digest when set
#   SESSION_NOTE_NOW        epoch seconds used as "now" for the default date (default: current time)
#
# Exit: 0 ok · 1 environment error · 2 usage error
set -euo pipefail

readonly PROJECTS_DIR="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"
readonly SELF_ID="${CLAUDE_CODE_SESSION_ID:-}"
readonly IDLE_GAP_SECONDS=1800
export TZ=Europe/Berlin

die() { local code="$1"; shift; printf 'digest.sh: %s\n' "$*" >&2; exit "$code"; }

# --- pure functions: each reads its arguments, prints its result -------------

# default_date <epoch> -> local date; before 06:00 local it is the day before
default_date() {
  jq -nr --argjson now "$1" '$now | if (strflocaltime("%H") | tonumber) < 6 then . - 86400 else . end | strflocaltime("%Y-%m-%d")'
}

# valid_date <YYYY-MM-DD> -> exit 0 when it is a real calendar date
valid_date() {
  [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] \
    && jq -en --arg d "$1" '($d | strptime("%Y-%m-%d") | mktime | strftime("%Y-%m-%d")) == $d' >/dev/null 2>&1
}

# utc_dates <YYYY-MM-DD> -> the UTC dates a local day can touch (day before, day, day after), one per line
utc_dates() {
  jq -nr --arg d "$1" '($d | strptime("%Y-%m-%d") | mktime) as $t | ($t - 86400, $t, $t + 86400) | strftime("%Y-%m-%d")'
}

# is_headless_project <project folder name> -> exit 0 for headless/scratch run folders
is_headless_project() {
  case "$1" in
    -private-tmp* | -private-var-folders-* | *-scratchpad-*) return 0 ;;
    *) return 1 ;;
  esac
}

# candidate_transcripts <date> -> top-level transcripts modified since that day that mention one of its UTC dates
candidate_transcripts() {
  local date="$1" f project pattern=()
  local d; for d in $(utc_dates "$date"); do pattern+=(-e "\"timestamp\":\"${d}T"); done
  find "$PROJECTS_DIR" -mindepth 2 -maxdepth 2 -type f -name '*.jsonl' -newermt "$date 00:00:00" 2>/dev/null | sort \
    | while IFS= read -r f; do
        project="$(basename "$(dirname "$f")")"
        is_headless_project "$project" && continue
        [ -n "$SELF_ID" ] && [ "$(basename "$f" .jsonl)" = "$SELF_ID" ] && continue
        if grep -q -F "${pattern[@]}" "$f"; then printf "%s\n" "$f"; fi
      done
}

# session_digest <transcript.jsonl> <date> -> one session object (with _active/_waits intervals), or nothing
session_digest() {
  local f="$1"
  jq -nc -R --arg date "$2" --arg sid "$(basename "$f" .jsonl)" --arg project "$(basename "$(dirname "$f")")" \
    --argjson idle "$IDLE_GAP_SECONDS" '
    def epoch: try (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) catch null;
    def cut($n): if length > $n then .[0:$n] + "..." else . end;
    def text_of: if type == "string" then .
      elif type == "array" then [.[] | select(.type == "text") | .text] | join(" ") else "" end;
    # my_prompt -> the prompt text when this entry is a message I sent, else empty.
    # The auto-compaction summary is a plain-text user entry Claude Code writes itself.
    def my_prompt:
      select(.type == "user" and .isMeta != true and .isCompactSummary != true)
      | .message.content
      | select(type == "string" or (type == "array" and all(.[]; .type != "tool_result")))
      | text_of | sub("^\\s+"; "")
      | if test("^<command-(name|message)>") then
          ([capture("<command-name>(?<n>[^<]*)</command-name>")][0].n // "")
          + ([capture("<command-args>(?<a>[^<]+)</command-args>")][0].a | if . then " " + . else "" end)
        elif test("^<bash-input>") then "! " + ([capture("<bash-input>(?<c>[^<]*)</bash-input>")][0].c // "")
        elif test("^<pasted_content") then .
        elif test("^<|^Another Claude session sent a message|^\\[Request interrupted|^\\[Image") then empty
        else . end
      | select(gsub("\\s"; "") | length > 0);
    def denials:
      if .type == "user" and (.message.content | type) == "array" then
        [.message.content[] | select(.type == "tool_result") | .content | text_of
          | select(test("^The user doesn.t want to proceed with this tool use|^Permission to use .* has been denied|^Permission for this action was denied"))]
        | length
      else 0 end;
    def commit_messages:
      select(.type == "assistant") | .message.content | select(type == "array") | .[]
      | select(.type == "tool_use" and .name == "Bash") | .input.command // ""
      | select(test("\\bgit\\b[^\\n]*\\bcommit\\b"))
      | ( ([capture("<<-?\\s*[\u0027\"]?(?<w>[A-Za-z_]+)[\u0027\"]?\\s*\\n(?<m>[^\\n]*)")][0].m // null)
          // ([capture("-m\\s+\"(?<m>[^\"\\n]*)")][0].m // null)
          // ([capture("-m\\s+\u0027(?<m>[^\u0027\\n]*)")][0].m // null) )
      | select(. != null and length > 0) | cut(120);
    # spans <sorted times> -> [[from, to], ...] for each gap within the idle cap
    def spans: [range(1; length) as $i | [.[$i - 1], .[$i]] | select(.[1] - .[0] <= $idle)];
    def seconds: map(.[1] - .[0]) | add // 0;

    [inputs | fromjson? | select(type == "object")] as $all
    | if any($all[]; (.entrypoint // "") | startswith("sdk")) then empty else
      [$all[] | select(.isSidechain != true and (.type | IN("user", "assistant", "system")) and (.timestamp | type) == "string")
        | . + {t: (.timestamp | epoch)} | select(.t != null and (.t | strflocaltime("%Y-%m-%d")) == $date)]
      | sort_by(.t) as $day
      | if ($day | length) == 0 then empty else
        ([$day[].t] | spans) as $active
        | ([range(1; $day | length) as $i | select([$day[$i] | my_prompt] | length > 0)
            | [$day[$i - 1].t, $day[$i].t] | select(.[1] - .[0] <= $idle)]) as $waits
        | [$day[] | my_prompt | cut(200)] as $prompts
        | {
            session_id: $sid,
            project: $project,
            first: ($day[0].t | strflocaltime("%H:%M")),
            last: ($day[-1].t | strflocaltime("%H:%M")),
            active_min: ($active | seconds / 60 | round),
            waiting_min: ($waits | seconds / 60 | round),
            my_messages: ($prompts | length),
            permission_denials: ([$day[] | denials] | add // 0),
            prompts: (if ($prompts | length) > 15 then $prompts[0:3] + ["(earlier prompts omitted)"] + $prompts[-12:] else $prompts end),
            assistant_tail: ([$day[] | select(.type == "assistant") | .message.content | select(type == "array") | .[]
                               | select(.type == "text") | .text | select(gsub("\\s"; "") | length > 0) | cut(400)] | .[-5:]),
            commits: [$day[] | commit_messages],
            _active: $active,
            _waits: $waits
          }
        end
      end' <"$f"
}

# day_digest <date> -> full digest JSON from session objects on stdin
day_digest() {
  jq -s --arg date "$1" --argjson idle "$IDLE_GAP_SECONDS" '
    def union_seconds: sort_by(.[0])
      | reduce .[] as $s ([]; if length > 0 and $s[0] <= .[-1][1]
          then .[-1][1] = ([.[-1][1], $s[1]] | max) else . + [$s] end)
      | map(.[1] - .[0]) | add // 0;
    sort_by(.first, .session_id) as $s
    | {
        date: $date,
        tz: "Europe/Berlin",
        idle_gap_min: ($idle / 60),
        day: {
          sessions: ($s | length),
          active_min: ([$s[]._active[]] | union_seconds / 60 | round),
          waiting_min: ([$s[]._waits[]] | union_seconds / 60 | round),
          my_messages: ([$s[].my_messages] | add // 0),
          permission_denials: ([$s[].permission_denials] | add // 0)
        },
        sessions: [$s[] | del(._active, ._waits)]
      }'
}

# --- main: named steps; the only place with side effects ---------------------

main() {
  command -v jq >/dev/null 2>&1 || die 1 "jq required (brew install jq)"
  [ "$#" -le 1 ] || die 2 "usage: digest.sh [YYYY-MM-DD]"
  [ -d "$PROJECTS_DIR" ] || die 1 "transcript root does not exist: $PROJECTS_DIR"

  local step1_date="${1:-}"
  [ -n "$step1_date" ] || step1_date="$(default_date "${SESSION_NOTE_NOW:-$(date +%s)}")"
  valid_date "$step1_date" || die 2 "date must be a real YYYY-MM-DD: $step1_date"

  local step2_files
  step2_files="$(candidate_transcripts "$step1_date")"

  local f
  { [ -z "$step2_files" ] || while IFS= read -r f; do session_digest "$f" "$step1_date"; done <<<"$step2_files"; } \
    | day_digest "$step1_date"
}

main "$@"
