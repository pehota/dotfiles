#!/usr/bin/env bash
# note.sh — turn LLM-written session facts into an Obsidian note of progress and learnings.
#
# Usage:
#   note.sh [--dry-run] <facts.json>                       single session note, upserted by session id
#   note.sh [--dry-run] --daily <YYYY-MM-DD> <facts.json>  one "claude sessions <date>.md"; a rerun overwrites it
#   note.sh --recheck <note.md>                            re-run the gate over a written note
#
# Steps: validate schema -> redaction gate -> (daily) figures from digest.sh -> render -> atomic write.
# Prints the written note's path (--dry-run: prints the rendered note, writes nothing). Writes nothing unless
# every check passes.
#
# Daily figures (times, message and denial counts) come from scripts/digest.sh, never from facts.json: the
# schema rejects any key it does not know, the figures are inserted after the gate, and only numbers and
# HH:MM times from the digest reach them. --recheck accepts a script-made line only in its exact shape;
# every other line goes through the full gate.
#
# Env:
#   CLAUDE_CODE_SESSION_ID  single mode: required; the note id
#   SESSION_NOTE_DIR        target dir (default ~/Work/mine/obsidian-vault/brain/inbox)
#   SESSION_NOTE_DENYLIST   extra terms/regexes, one per line (default <skill>/denylist.txt)
#   SESSION_NOTE_WORK_ROOT  folder whose sub-folder names are work repo names to block (default ~/Work/job/git;
#                           on a machine without work repos point it at an empty folder)
#   CLAUDE_PROJECTS_DIR     transcript root, passed through to digest.sh
#
# Exit: 0 ok · 1 environment error · 2 usage/schema error · 3 redaction reject
set -euo pipefail

readonly SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly OUT_DIR="${SESSION_NOTE_DIR:-$HOME/Work/mine/obsidian-vault/brain/inbox}"
readonly DENYLIST="${SESSION_NOTE_DENYLIST:-$SKILL_DIR/denylist.txt}"
readonly WORK_ROOT="${SESSION_NOTE_WORK_ROOT:-$HOME/Work/job/git}"
readonly UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

die() { local code="$1"; shift; printf 'note.sh: %s\n' "$*" >&2; exit "$code"; }

# --- pure functions: each reads its arguments, prints its result -------------

# jq definitions shared by both schemas
readonly JQ_SCHEMA_LIB='
  def nonempty: type == "string" and (gsub("\\s"; "") | length > 0);
  # every LLM-written string is one line: a line break could start a heading or a fake figures line
  def oneline: nonempty and (test("[\\n\\r\u000b\u000c\u0085\u2028\u2029]") | not);
  def strings_array($name):
    if type == "array" and all(.[]; oneline) then empty else "\($name): array of non-empty single-line strings required" end;
  def each_obj($name; $keys):
    if type != "array" then "\($name): array required"
    else to_entries[]
      | select((.value | type) != "object" or (.value | keys - $keys | length > 0)
               or any($keys[] as $k | .value[$k]; oneline | not))
      | "\($name)[\(.key)]: needs exactly non-empty single-line \($keys | join(", "))"
    end;
  def unknown_keys($allowed; $where): keys - $allowed | .[] | "unknown key\($where): \(.)";
  def session_fields($p):
    (if .title | oneline then empty else "\($p)title: non-empty single-line string required" end),
    (if .status | IN("in-progress", "done", "blocked") then empty else "\($p)status: must be in-progress|done|blocked" end),
    (if .progress | oneline then empty else "\($p)progress: non-empty single-line string required" end),
    (.learnings | strings_array("\($p)learnings")),
    (.bottlenecks | strings_array("\($p)bottlenecks")),
    (.next_steps | strings_array("\($p)next_steps"));'

# schema_errors <facts.json> -> one "SCHEMA ..." line per violation (single session)
schema_errors() {
  jq -r "$JQ_SCHEMA_LIB"'
    if type != "object" then "top level: object required" else
      unknown_keys(["title","session_name","status","progress","learnings","bottlenecks","next_steps"]; ""),
      session_fields(""),
      (if has("session_name") and (.session_name | oneline | not)
         then "session_name: non-empty single-line string if given" else empty end)
    end
    | "SCHEMA \(.)"' "$1"
}

# daily_schema_errors <facts.json> <digest.json> -> one "SCHEMA ..." line per violation (daily)
daily_schema_errors() {
  jq -r --slurpfile digest "$2" --arg uuid "$UUID_RE" "$JQ_SCHEMA_LIB"'
    ([$digest[0].sessions[].session_id]) as $known
    | if type != "object" then "top level: object required" else
      unknown_keys(["sessions","how_i_worked"]; ""),
      (if .sessions | type == "array" and length > 0 then
         (.sessions | to_entries[] | .key as $i | .value
          | if type != "object" then "sessions[\($i)]: object required" else
              unknown_keys(["session_ids","title","status","progress","learnings","bottlenecks","next_steps"]; " in sessions[\($i)]"),
              session_fields("sessions[\($i)]."),
              (if .session_ids | type == "array" and length > 0 then
                 (.session_ids[] | if type == "string" and test($uuid) then
                    (if IN($known[]) then empty else "sessions[\($i)].session_ids: \(.) is not a session of this day" end)
                  else "sessions[\($i)].session_ids: session id required" end)
               else "sessions[\($i)].session_ids: non-empty array required" end)
            end),
         ([.sessions[]? | .session_ids? | arrays | .[]] | group_by(.) | map(select(length > 1) | .[0])[]
          | "session_ids: \(.) used in more than one section")
       else "sessions: non-empty array required" end),
      (if .how_i_worked | type == "object" then
         (.how_i_worked | unknown_keys(["blockers","automate"]; " in how_i_worked"),
           (.blockers | each_obj("how_i_worked.blockers"; ["what", "rec"])),
           (.automate | each_obj("how_i_worked.automate"; ["what", "rec"])))
       else "how_i_worked: object with blockers and automate required" end)
    end
    | "SCHEMA \(.)"' "$1"
}

# work_repo_names <work root> -> non-hidden sub-folder names, one per line
work_repo_names() {
  find -L "$1" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -exec basename {} \; | sort -u
}

# normalise_facts <facts.json> -> same JSON, every string NFKC-normalised, format chars (\p{Cf}:
# zero-width, soft hyphen, BOM) stripped, whitespace runs (incl. newlines) squeezed to one space.
# The gate matches on this view so look-alike and invisible characters cannot slip past it.
normalise_facts() {
  perl -CS -MJSON::PP -MUnicode::Normalize -0777 -e '
    sub norm {
      my $v = shift;
      return { map { $_ => norm($v->{$_}) } keys %$v } if ref $v eq "HASH";
      return [ map { norm($_) } @$v ] if ref $v eq "ARRAY";
      return $v if ref $v || !defined $v;
      $v =~ s/\p{Cf}//g; $v = NFKC($v); $v =~ s/\p{Cf}//g; $v =~ s/\s+/ /g;
      return $v;
    }
    my $json = JSON::PP->new->utf8(0)->canonical;
    print $json->encode(norm($json->decode(scalar <STDIN>)));' <"$1"
}

# redaction_findings <facts.json> <denylist-file> <repo names, newline-separated>
#   -> one "REJECT <class> at <field>: <match>" line per hit. Daily session_ids are checked by the schema
#   (exact UUID of a session of that day), so the gate skips only those fields.
redaction_findings() {
  local deny=""
  [ -f "$2" ] && deny="$(cat "$2")"
  normalise_facts "$1" | jq -r --arg deny "$deny" --arg repos "$3" '
    def rules: [
      {class: "token", re: "(?<![A-Za-z0-9])(?:sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|xox[abposr]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|Bearer\\s+[A-Za-z0-9._~+/=-]{10,}|[0-9a-fA-F]{41,})"},
      {class: "secret assignment", re: "(?i)\\b(?:secret|token|api[_-]?key|passw(?:or)?d|pwd|client[_-]?secret)\\s*[:=]\\s*\\S+"},
      {class: "private key", re: "-----BEGIN [A-Z ]*PRIVATE KEY-----"},
      {class: "secret in url", re: "[?&](?i:token|key|sig|signature|access_token)=[^\\s&#]*"},
      {class: "connection string", re: "[A-Za-z][A-Za-z0-9+.-]*://[^/@\\s:]+:[^/@\\s]+@|mongodb(?:\\+srv)?://\\S+|(?:postgres(?:ql)?|mysql|redis|amqp|mssql|jdbc:[a-z]+)://\\S*@|(?i:password)=\\S+"},
      {class: "ipv4", re: "(?<![0-9.])(?:[0-9]{1,3}\\.){3}[0-9]{1,3}(?![0-9]|\\.[0-9])"},
      {class: "ipv6", re: "(?<![\\w:])(?:(?:[0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){1,7}:(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4}){0,6})?|::(?:[0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4})(?![\\w:])"},
      # any label: api.corp.example.com, db.internal, printer.local; a file like settings.local.json is not a host
      {class: "internal hostname", re: "(?i)\\b[a-z0-9-]+(?:\\.[a-z0-9-]+)*\\.(?:internal|local|corp|lan|intranet)(?!\\.(?:json|ya?ml|toml|md|txt|env|ini|conf|cfg|xml|lock|properties|ts|js|mjs|cjs|tsx|jsx|sh|py|rb|go|sql|bak)\\b)(?:\\.[a-z0-9-]+)*\\b"},
      # work identifiers: links and commits point into company systems
      {class: "url", re: "(?i)\\b[a-z][a-z0-9+.-]*://\\S*"},
      # any dotted name ending in an alphabetic TLD of 2+ letters in any case; the only exemption is a sentence
      # join, a lower-case word directly followed by a Capitalised word ("done.Next"); the label before the TLD
      # needs a letter (not "1.0.0.RELEASE"); a file extension is no TLD
      {class: "hostname", re: "\\b(?![a-z]+\\.[A-Z][a-z]+\\b(?![.-][A-Za-z0-9]))(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\\.)*(?=[A-Za-z0-9-]*[A-Za-z])[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\\.(?!(?i:json|jsonl|ya?ml|toml|md|mdx|txt|env|ini|conf|cfg|xml|lock|properties|ts|js|mjs|cjs|tsx|jsx|sh|py|rb|go|sql|bak|log|csv|html?|css|scss|java|kt|gradle|vue|svelte|png|jpe?g|gif|svg|plist|diff|patch)\\b)[A-Za-z]{2,}\\b(?![.-][A-Za-z0-9])"},
      {class: "commit sha", re: "(?i)\\b(?=[0-9a-f]*[0-9])(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\\b"},
      {class: "ticket key", re: "\\b[A-Z]+-\\d+\\b"}
    ];
    def email_re: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
    # Long base64 blobs; paths (many slashes) and single-case words are not secrets.
    def base64_like: test("[0-9]") and test("[A-Z]") and test("[a-z]")
      and ([match("/"; "g")] | length) <= 3 and (contains("//") | not);
    # Digits allowed only in dates, times, versions ("v" / "version" etc. in front), filenames and
    # localhost:port; a leading list number is markup. Whatever digit survives this is a figure.
    def strip_allowed_numbers:
      gsub("(?i)\\blocalhost:\\d+\\b"; " ")
      | gsub("(?<![\\w.-])[\\w-]*[A-Za-z_][\\w-]*(?:\\.[\\w-]+)*\\.[A-Za-z][A-Za-z0-9]{0,9}\\b"; " ")
      | gsub("\\b\\d{4}-\\d{2}-\\d{2}(?:[T ]\\d{2}:\\d{2}(?::\\d{2}(?:\\.\\d+)?)?(?:Z|[+-]\\d{2}:?\\d{2})?)?\\b"; " ")
      | gsub("\\b(?:[01]?\\d|2[0-3]):[0-5]\\d(?::[0-5]\\d)?\\b"; " ")
      | gsub("(?i)(?:\\bv|@|\\b(?:version|release[sd]?|tag(?:ged)?|(?:bump|upgrade|downgrade)(?:d|ed)? to)\\s+v?)\\d+(?:\\.\\d+)*(?:-[0-9A-Za-z.]+)?\\b"; " ")
      | gsub("^\\s*\\d+[.)]\\s"; " ");
    def figure_re: "\\d[\\d.,]*(?:\\s*[^\\s\\d]+)?";
    # Spelled-out counts: a number word followed within three words by a noun-ish word. "one" is not one.
    def num_word: "(?:two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundreds?|thousands?|millions?|billions?|dozens?)";
    def stop_words: ["a","an","the","of","and","or","but","to","in","on","at","by","for","with","from","as","is","are","was","were","be","been","it","its","this","that","these","those","than","then","more","less","about","over","under","up","down","out","off","per","each","all","any","no","not","so","too","very","only","just","also","into","via","if","when","while","which","who","what","where","how","there","here","we","you","they","he","she","i","me","my","our","your","their","them","us","his","her","has","have","had","do","does","did","will","would","can","could","should","may","might","must"];
    def number_word_hits:
      match("(?i)\\b" + num_word + "(?:[- ]" + num_word + ")*\\b(?!-)((?:\\s+[A-Za-z][\\w\u0027/-]*){1,3})"; "g")
      | select(.captures[0].string | ascii_downcase | [scan("[a-z][a-z\u0027-]*")]
          | any(.[]; . as $w | (stop_words | index([$w])) == null and (test("^" + num_word + "$") | not)))
      | .string;
    # A number word right after a label word ("round two", "step three") is a count too.
    def label_number_hits:
      match("(?i)\\b([A-Za-z][\\w\u0027-]*)\\s+" + num_word + "\\b"; "g")
      | select(.captures[0].string | ascii_downcase | . as $w
          | (stop_words | index([$w])) == null and (test("^" + num_word + "$") | not))
      | .string;
    def hits($re; $flags): [match($re; "g" + $flags) | .string] | .[];
    def deny_terms: $deny | split("\n") | map(select(test("^\\s*(#|$)") | not));
    def repo_re: $repos | split("\n") | map(select(length > 0) | gsub("(?<c>[.+*?()|\\[\\]{}^$\\\\])"; "\\\(.c)"))
      | if length == 0 then null else "\\b(?:" + join("|") + ")\\b" end;

    repo_re as $repo_re
    | paths(strings) as $p
    | ($p | map(tostring) | join(".")) as $field
    | select($field | test("^sessions\\.\\d+\\.session_ids\\.\\d+$") | not)
    | getpath($p) as $s
    | (   (rules[] as $r | $s | hits($r.re; "") | {class: $r.class, m: .})
        , ($s | hits(email_re; "") | {class: "email", m: .})
        , ($s | hits("(?<![A-Za-z0-9+/])[A-Za-z0-9+/]{40,}={0,2}"; "") | select(base64_like) | {class: "token", m: .})
        , (deny_terms[] as $d | $s | hits($d; "i") | {class: "denylist", m: .})
        , (if $repo_re then $s | hits($repo_re; "i") | {class: "work repo name", m: .} else empty end)
        , ($s | number_word_hits | {class: "number word", m: .})
        , ($s | label_number_hits | {class: "number word", m: .})
        , ($s | strip_allowed_numbers | hits(figure_re; "") | {class: "metric claim", m: .})
      )
    | "REJECT \(.class) at \($field): \(.m)"'
}

# gate <facts.json> -> REJECT lines (empty when clean); dies when the work root is missing
gate() {
  [ -d "$WORK_ROOT" ] || die 1 "work repo root not found: $WORK_ROOT (set SESSION_NOTE_WORK_ROOT; an empty folder on a machine without work repos)"
  local repos; repos="$(work_repo_names "$WORK_ROOT")"
  redaction_findings "$1" "$DENYLIST" "$repos"
}

# render_single <facts.json> <id> <date> -> markdown
render_single() {
  jq -r --arg id "$2" --arg date "$3" '
    def list($label): if length == 0 then "- **\($label):** none" else "- **\($label):**\n" + (map("  - " + .) | join("\n")) end;
    def numbered($label): if length == 0 then "- **\($label):** none"
      else "- **\($label):**\n" + (to_entries | map("  \(.key + 1). \(.value)") | join("\n")) end;
    [ "---", "id: \($id)", "source: claude-session", "created: \($date)", "---", "",
      "# \(.title)", "",
      "- **Status:** \(.status)",
      "- **Progress:** \(.progress)",
      (.learnings | list("Learnings")),
      (.bottlenecks | list("Bottlenecks")),
      (.next_steps | numbered("Next")), "",
      "## Resume", "",
      "`claude --resume \($id)`",
      (if .session_name then "\nSession name: \(.session_name)" else empty end)
    ] | join("\n")' "$1"
}

# render_daily <facts.json> <digest.json> <date> -> markdown. Figures come from the digest only.
render_daily() {
  jq -r --slurpfile digest "$2" --arg date "$3" '
    def list($label): if length == 0 then "- **\($label):** none" else "- **\($label):**\n" + (map("  - " + .) | join("\n")) end;
    def numbered($label): if length == 0 then "- **\($label):** none"
      else "- **\($label):**\n" + (to_entries | map("  \(.key + 1). \(.value)") | join("\n")) end;
    def recs($label): if length == 0 then "- **\($label):** none"
      else "- **\($label):**\n" + (map("  - \(.what) **Rec:** \(.rec)") | join("\n")) end;
    def num: if type == "number" then floor | tostring else error("figure is not a number") end;
    def clock: if type == "string" and test("^[0-2][0-9]:[0-5][0-9]$") then . else error("time is not HH:MM") end;
    def dur: (if type == "number" then floor else error("duration is not a number") end) as $m
      | if $m >= 60 then "\($m / 60 | floor)h \($m % 60 | tostring | if length == 1 then "0" + . else . end)m" else "\($m)m" end;
    def figures: "active \(.active_min | dur) · waiting on me \(.waiting_min | dur) · my messages \(.my_messages | num) · permission denials \(.permission_denials | num)";
    ($digest[0].sessions | map({key: .session_id, value: .}) | from_entries) as $by_id
    | [ "---", "source: claude-session", "created: \($date)", "---", "",
        "# Claude sessions \($date)", "",
        ( .sessions[] | [$by_id[.session_ids[]]] as $s
          | ([$s[].first] | min | clock) as $first | ([$s[].last] | max | clock) as $last
          | { active_min: ([$s[].active_min] | add), waiting_min: ([$s[].waiting_min] | add),
              my_messages: ([$s[].my_messages] | add), permission_denials: ([$s[].permission_denials] | add) } as $f
          | "## \(.title)\n\n- **Status:** \(.status)\n- **Progress:** \(.progress)\n"
            + (.learnings | list("Learnings")) + "\n" + (.bottlenecks | list("Bottlenecks")) + "\n"
            + (.next_steps | numbered("Next")) + "\n"
            + "- **Time:** \($first) to \($last) · \($f | figures)\n" ),
        "## How I worked", "",
        "- **Sessions:** \($digest[0].day.sessions | num)",
        "- **Time:** \($digest[0].day | figures)",
        (.how_i_worked.blockers | recs("Avoidable blockers")),
        (.how_i_worked.automate | recs("Automate or delegate"))
      ] | join("\n")' "$1"
}

# script_shaped_line <line> -> exit 0 when the line is one note.sh itself makes from non-LLM data
script_shaped_line() {
  local dur='([0-9]+h [0-9]{2}m|[0-9]+m)'
  local figs="active $dur · waiting on me $dur · my messages [0-9]+ · permission denials [0-9]+"
  [[ "$1" =~ ^(---|source:\ claude-session|created:\ [0-9]{4}-[0-9]{2}-[0-9]{2}|id:\ [0-9a-f-]{36})$ ]] \
    || [[ "$1" =~ ^-\ \*\*Sessions:\*\*\ [0-9]+$ ]] \
    || [[ "$1" =~ ^-\ \*\*Time:\*\*\ ([0-2][0-9]:[0-5][0-9]\ to\ [0-2][0-9]:[0-5][0-9]\ ·\ )?$figs$ ]] \
    || [[ "$1" =~ ^\`claude\ --resume\ [0-9a-f-]{36}\`$ ]]
}

# note_lines_json <note.md> -> {"lines": [every line that is not script-shaped, markup stripped]}
note_lines_json() {
  local line out=()
  while IFS= read -r line || [ -n "$line" ]; do
    script_shaped_line "$line" && continue
    line="$(printf '%s' "$line" | sed -E 's/^#+ //; s/^ *- //; s/^\*\*[A-Za-z ]+:\*\* ?//; s/\*\*Rec:\*\*//g')"
    out+=("$line")
  done <"$1"
  if [ "${#out[@]}" -eq 0 ]; then printf '{"lines":[]}\n'; else printf '%s\n' "${out[@]}" | jq -R . | jq -s '{lines: .}'; fi
}

# frontmatter_value <note.md> <key> -> value of `<key>:` inside the leading frontmatter block
frontmatter_value() {
  awk -v key="$2" 'NR == 1 { if ($0 != "---") exit; next }
       $0 == "---" { exit }
       index($0, key ":") == 1 { sub("^" key ":[ \t]*", ""); gsub(/["\047]/, ""); print; exit }' "$1"
}

# find_note_by_id <dir> <id> -> path of the session note (source: claude-session) carrying that id
find_note_by_id() {
  local f
  for f in "$1"/*.md; do
    [ -f "$f" ] && [ "$(frontmatter_value "$f" id)" = "$2" ] && [ "$(frontmatter_value "$f" source)" = "claude-session" ] \
      && { printf '%s\n' "$f"; return 0; }
  done
  return 1
}

# new_note_path <dir> <title> <date> <id> -> "<dir>/<safe title> <date>.md" (full id suffix on name clash)
# The safe title is capped at 120 bytes, cut on a UTF-8 character boundary.
new_note_path() {
  local safe base
  safe="$(printf '%s' "$2" | sed -E 's,[][/\\:*?"<>|#^],-,g; s/^[ .]+//' | head -c 120 | iconv -c -f UTF-8 -t UTF-8 \
    | sed -E 's/[ .]+$//')"
  base="$1/${safe:-session-note} $3"
  if [ -e "$base.md" ]; then printf '%s\n' "$base $4.md"; else printf '%s\n' "$base.md"; fi
}

# --- main: named steps; the only place with side effects ---------------------

TMP_FILES=()
cleanup() { [ "${#TMP_FILES[@]}" -eq 0 ] || rm -f "${TMP_FILES[@]}"; }
trap cleanup EXIT

# write_atomic <target> <content>: temp file in the target dir, then mv into place
write_atomic() {
  local tmp; tmp="$(mktemp "$OUT_DIR/.session-note.XXXXXX")"
  TMP_FILES+=("$tmp")
  printf '%s\n' "$2" >"$tmp"
  mv "$tmp" "$1"
}

check_facts_json() {
  [ -f "$1" ] || die 2 "facts file not found: $1"
  jq -e . "$1" >/dev/null 2>&1 || die 2 "SCHEMA $1 is not valid JSON"
}

run_gate() {
  local findings; findings="$(gate "$1")"
  [ -z "$findings" ] || die 3 "facts rejected, rewrite these without work details or figures:"$'\n'"$findings"
}

main_single() {
  local dry="$1" facts="$2"
  check_facts_json "$facts"
  local id="${CLAUDE_CODE_SESSION_ID:-}"
  [ -n "$id" ] || die 1 "CLAUDE_CODE_SESSION_ID is unset; run inside a Claude Code session"
  [[ "$id" =~ ^[0-9a-f-]{36}$ ]] || die 1 "CLAUDE_CODE_SESSION_ID is not a session id: $id"

  local step1_schema; step1_schema="$(schema_errors "$facts")"
  [ -z "$step1_schema" ] || die 2 "facts rejected:"$'\n'"$step1_schema"
  run_gate "$facts"

  local date note
  date="$(TZ=Europe/Berlin date +%F)"
  note="$(render_single "$facts" "$id" "$date")"
  [ "$dry" = 0 ] || { printf '%s\n' "$note"; return 0; }

  [ -d "$OUT_DIR" ] || die 1 "note dir does not exist: $OUT_DIR"
  local target
  target="$(find_note_by_id "$OUT_DIR" "$id")" \
    || target="$(new_note_path "$OUT_DIR" "$(jq -r .title "$facts")" "$date" "$id")"
  write_atomic "$target" "$note"
  printf '%s\n' "$target"
}

main_daily() {
  local dry="$1" date="$2" facts="$3"
  [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || die 2 "usage: note.sh --daily <YYYY-MM-DD> <facts.json>"
  check_facts_json "$facts"

  local digest; digest="$(mktemp)"; TMP_FILES+=("$digest")
  local rc=0; bash "$SKILL_DIR/scripts/digest.sh" "$date" >"$digest" || rc=$?
  [ "$rc" = 0 ] || die "$rc" "digest.sh failed for $date"

  local step1_schema; step1_schema="$(daily_schema_errors "$facts" "$digest")"
  [ -z "$step1_schema" ] || die 2 "facts rejected:"$'\n'"$step1_schema"
  run_gate "$facts"

  local note; note="$(render_daily "$facts" "$digest" "$date")" || die 1 "render failed for $date"
  [ "$dry" = 0 ] || { printf '%s\n' "$note"; return 0; }

  [ -d "$OUT_DIR" ] || die 1 "note dir does not exist: $OUT_DIR"
  local target="$OUT_DIR/claude sessions $date.md"
  if [ -e "$target" ] && { [ -n "$(frontmatter_value "$target" id)" ] || [ "$(frontmatter_value "$target" source)" != "claude-session" ]; }; then
    die 1 "refusing to overwrite a note that is not a daily session note: $target"
  fi
  write_atomic "$target" "$note"
  printf '%s\n' "$target"
}

main_recheck() {
  [ -f "$1" ] || die 2 "usage: note.sh --recheck <note.md>"
  local lines; lines="$(mktemp)"; TMP_FILES+=("$lines")
  note_lines_json "$1" >"$lines"
  run_gate "$lines"
  printf 'clean %s\n' "$1"
}

main() {
  command -v jq >/dev/null 2>&1 || die 1 "jq required (brew install jq)"
  local dry=0
  [ "${1:-}" != "--dry-run" ] || { dry=1; shift; }
  case "${1:-}" in
    --daily) [ "$#" -eq 3 ] || die 2 "usage: note.sh [--dry-run] --daily <YYYY-MM-DD> <facts.json>"; main_daily "$dry" "$2" "$3" ;;
    --recheck) [ "$#" -eq 2 ] && [ "$dry" = 0 ] || die 2 "usage: note.sh --recheck <note.md>"; main_recheck "$2" ;;
    *) [ "$#" -eq 1 ] || die 2 "usage: note.sh [--dry-run] <facts.json>"; main_single "$dry" "$1" ;;
  esac
}

main "$@"
