#!/usr/bin/env bash
# note.sh <facts.json> — turn LLM-written session facts into an Obsidian pointer note.
#
# Steps: validate schema -> redaction gate -> resolve id/model/date/repo -> render -> upsert by id.
# Prints the written note's path. Writes nothing unless every check passes.
#
# Env:
#   CLAUDE_CODE_SESSION_ID  required; the note id
#   SESSION_NOTE_DIR        target dir (default ~/Work/mine/obsidian-vault/brain/inbox)
#   SESSION_NOTE_DENYLIST   extra terms/regexes, one per line (default <skill>/denylist.txt)
#   CLAUDE_PROJECTS_DIR     transcript root (default ~/.claude/projects)
#
# Exit: 0 ok · 1 environment error · 2 usage/schema error · 3 redaction reject
set -euo pipefail

readonly SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly OUT_DIR="${SESSION_NOTE_DIR:-$HOME/Work/mine/obsidian-vault/brain/inbox}"
readonly DENYLIST="${SESSION_NOTE_DENYLIST:-$SKILL_DIR/denylist.txt}"
readonly PROJECTS_DIR="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"

die() { local code="$1"; shift; printf 'note.sh: %s\n' "$*" >&2; exit "$code"; }

# --- pure functions: each reads its arguments, prints its result -------------

# schema_errors <facts.json> -> one "SCHEMA ..." line per violation
schema_errors() {
  jq -r '
    def nonempty: type == "string" and (gsub("\\s"; "") | length > 0);
    def oneline: nonempty and (test("[\\n\\r]") | not);
    def each_obj($name; $keys):
      if type != "array" then "\($name): array required"
      else to_entries[]
        | select((.value | type) != "object" or any($keys[] as $k | .value[$k]; nonempty | not))
        | "\($name)[\(.key)]: needs non-empty \($keys | join(", "))"
      end;
    if type != "object" then "top level: object required" else
      (keys - ["title","session_name","status","outcome","done","decisions","open",
               "next_steps","links","touched_paths"] | .[] | "unknown key: \(.)"),
      (if .title | oneline then empty else "title: non-empty single-line string required" end),
      (if has("session_name") and (.session_name | oneline | not)
         then "session_name: non-empty single-line string if given" else empty end),
      (if .status | IN("in-progress", "done", "blocked") then empty
         else "status: must be in-progress|done|blocked" end),
      (if .outcome | nonempty then empty else "outcome: non-empty string required" end),
      (.done | each_obj("done"; ["item", "evidence"])),
      (.decisions | each_obj("decisions"; ["decision", "by", "date"])),
      (.decisions | if type == "array" then to_entries[]
         | select((.value.by | type) == "string"
             and (.value.by | ascii_downcase | IN("dimitar", "team", "reviewer", "owner", "product") | not))
         | "decisions[\(.key)].by: one of Dimitar|team|reviewer|owner|product" else empty end),
      (.decisions | if type == "array" then to_entries[]
         | select((.value.date | type) == "string" and (.value.date | test("^\\d{4}-\\d{2}-\\d{2}$") | not))
         | "decisions[\(.key)].date: YYYY-MM-DD required" else empty end),
      (.open | each_obj("open"; ["question", "rec"])),
      (.links | each_obj("links"; ["label", "target"])),
      (.next_steps, .touched_paths | if type == "array" and all(.[]; nonempty) then empty
         else "next_steps/touched_paths: array of non-empty strings required" end)
    end
    | "SCHEMA \(.)"' "$1"
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

# redaction_findings <facts.json> <denylist-file> -> one "REJECT <class> at <field>: <match>" line per hit
redaction_findings() {
  local deny=""
  [ -f "$2" ] && deny="$(cat "$2")"
  normalise_facts "$1" | jq -r --arg deny "$deny" '
    def rules: [
      {class: "token", re: "(?<![A-Za-z0-9])(?:sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|xox[abposr]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|Bearer\\s+[A-Za-z0-9._~+/=-]{10,}|[0-9a-fA-F]{41,})"},
      {class: "secret assignment", re: "(?i)\\b(?:secret|token|api[_-]?key|passw(?:or)?d|pwd|client[_-]?secret)\\s*[:=]\\s*\\S+"},
      {class: "private key", re: "-----BEGIN [A-Z ]*PRIVATE KEY-----"},
      {class: "secret in url", re: "[?&](?i:token|key|sig|signature|access_token)=[^\\s&#]*"},
      {class: "connection string", re: "[A-Za-z][A-Za-z0-9+.-]*://[^/@\\s:]+:[^/@\\s]+@|mongodb(?:\\+srv)?://\\S+|(?:postgres(?:ql)?|mysql|redis|amqp|mssql|jdbc:[a-z]+)://\\S*@|(?i:password)=\\S+"},
      {class: "ipv4", re: "(?<![0-9.])(?:[0-9]{1,3}\\.){3}[0-9]{1,3}(?![0-9]|\\.[0-9])"},
      {class: "ipv6", re: "(?<![\\w:])(?:(?:[0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){1,7}:(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4}){0,6})?|::(?:[0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4})(?![\\w:])"},
      # any label: api.corp.example.com, db.internal, printer.local; a file like settings.local.json is not a host
      {class: "internal hostname", re: "(?i)\\b[a-z0-9-]+(?:\\.[a-z0-9-]+)*\\.(?:internal|local|corp|lan|intranet)(?!\\.(?:json|ya?ml|toml|md|txt|env|ini|conf|cfg|xml|lock|properties|ts|js|mjs|cjs|tsx|jsx|sh|py|rb|go|sql|bak)\\b)(?:\\.[a-z0-9-]+)*\\b"}
    ];
    # SSH git remotes (git@host:org/repo.git) are not emails.
    def ssh_git_re: "\\bgit@[A-Za-z0-9.-]+:[\\w.~-]+/[\\w./~-]+";
    def email_re: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
    # File paths, rooted (/a, ~/a, ./a) or relative with a letter-led first segment; optional :line[:col].
    # An all-digit segment ends the path, so "spend/2067" does not hide a figure.
    def path_re: "(?<![\\w.~/-])(?:(?:~|\\.{1,2})?/|[A-Za-z_.@][\\w.@+-]*/)(?:(?!\\d+(?:[/:\\s]|$))[\\w.@~+-]+/?)*(?::\\d+)*";
    # Long base64 blobs; paths/URLs (many slashes) and single-case words are not secrets.
    def base64_like: test("[0-9]") and test("[A-Z]") and test("[a-z]")
      and ([match("/"; "g")] | length) <= 3 and (contains("//") | not);
    # Identifier shapes carry digits but are not figures. Whatever digit survives this is a figure.
    def strip_identifiers:
      gsub("[A-Za-z][A-Za-z0-9+.-]*://\\S+"; " ")
      | gsub(ssh_git_re; " ")
      | gsub("(?i)\\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\b"; " ")
      | gsub("(?i)\\blocalhost:\\d+\\b"; " ")
      | gsub(path_re; " ")
      | gsub("(?<![\\w.-])[\\w-]*[A-Za-z_][\\w-]*(?:\\.[\\w-]+)*\\.[A-Za-z][A-Za-z0-9]{0,9}(?::\\d+)*\\b"; " ")
      | gsub("\\b\\d{4}-\\d{2}-\\d{2}(?:[T ]\\d{2}:\\d{2}(?::\\d{2}(?:\\.\\d+)?)?(?:Z|[+-]\\d{2}:?\\d{2})?)?\\b"; " ")
      | gsub("\\b(?:[01]?\\d|2[0-3]):[0-5]\\d(?::[0-5]\\d)?\\b"; " ")
      | gsub("(?i)(?:\\bv|@|\\b(?:version|release[sd]?|tag(?:ged)?|(?:bump|upgrade|downgrade)(?:d|ed)? to)\\s+v?)\\d+(?:\\.\\d+)*(?:-[0-9A-Za-z.]+)?\\b"; " ")
      | gsub("\\b[A-Z][A-Z0-9]*-\\d+\\b"; " ")
      | gsub("\\b(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\\b"; " ")
      | gsub("(?i)\\bround \\w+ of \\w+\\b|\\bstep \\d+\\b"; " ")
      | gsub("^\\s*\\d+[.)]\\s"; " ");
    def figure_re: "\\d[\\d.,]*(?:\\s*[^\\s\\d]+)?";
    # Spelled-out counts: a number word followed within three words by a noun-ish word.
    def num_word: "(?:one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundreds?|thousands?|millions?|billions?|dozens?)";
    def stop_words: ["a","an","the","of","and","or","but","to","in","on","at","by","for","with","from","as","is","are","was","were","be","been","it","its","this","that","these","those","than","then","more","less","about","over","under","up","down","out","off","per","each","all","any","no","not","so","too","very","only","just","also","into","via","if","when","while","which","who","what","where","how","there","here","we","you","they","he","she","i","me","my","our","your","their","them","us","his","her","has","have","had","do","does","did","will","would","can","could","should","may","might","must"];
    def number_word_hits:
      match("(?i)\\b" + num_word + "(?:[- ]" + num_word + ")*\\b(?!-)((?:\\s+[A-Za-z][\\w\u0027/-]*){1,3})"; "g")
      | select(.captures[0].string | ascii_downcase | [scan("[a-z][a-z\u0027-]*")]
          | any(.[]; . as $w | (stop_words | index([$w])) == null and (test("^" + num_word + "$") | not)))
      | .string;
    def hits($re; $flags): [match($re; "g" + $flags) | .string] | .[];
    def deny_terms: $deny | split("\n") | map(select(test("^\\s*(#|$)") | not));

    paths(strings) as $p
    | ($p | map(tostring) | join(".")) as $field
    | getpath($p) as $s
    | (   (rules[] as $r | $s | hits($r.re; "") | {class: $r.class, m: .})
        , ($s | gsub(ssh_git_re; " ") | hits(email_re; "") | {class: "email", m: .})
        , ($s | gsub(path_re; " ") | hits("(?<![A-Za-z0-9+/])[A-Za-z0-9+/]{40,}={0,2}"; "") | select(base64_like) | {class: "token", m: .})
        , (deny_terms[] as $d | $s | hits($d; "i") | {class: "denylist", m: .})
        , (if $field | test("^links\\.\\d+\\.target$") then empty
           else ($s | gsub("(?i)\\bround \\w+ of \\w+\\b"; " ") | number_word_hits | {class: "number word", m: .}),
                ($s | strip_identifiers | hits(figure_re; "") | {class: "metric claim", m: .}) end)
      )
    | "REJECT \(.class) at \($field): \(.m)"'
}

# find_transcript <session-id> <cwd> -> transcript path (cwd slug first, then any project)
find_transcript() {
  local id="$1" slug f
  slug="$(printf '%s' "$2" | sed 's/[^A-Za-z0-9]/-/g')"
  for f in "$PROJECTS_DIR/$slug/$id.jsonl" "$PROJECTS_DIR"/*/"$id.jsonl"; do
    [ -f "$f" ] && { printf '%s\n' "$f"; return 0; }
  done
  return 1
}

# last_model <transcript.jsonl> -> model of the last real assistant message
last_model() {
  jq -rR 'fromjson? | select(.type == "assistant") | .message.model // empty | select(. != "<synthetic>")' "$1" \
    | tail -n 1
}

# repo_names <facts.json> -> git top-level basenames of touched_paths, first-seen order, non-git skipped
repo_names() {
  jq -r '.touched_paths[]' "$1" | while IFS= read -r p; do
    [ -d "$p" ] || p="$(dirname "$p")"
    git -C "$p" rev-parse --show-toplevel 2>/dev/null || true
  done | while IFS= read -r top; do basename "$top"; done | awk '!seen[$0]++'
}

# render_note <facts.json> <id> <model> <date> <repos-newline-separated> -> markdown
render_note() {
  jq -r --arg id "$2" --arg model "$3" --arg date "$4" --arg repos "$5" '
    def yaml_scalar: if test("^[A-Za-z0-9._/@-]+$") then . else tojson end;
    def bullets(f): if length == 0 then "- none" else map("- " + f) | join("\n") end;
    def numbered(f): if length == 0 then "- none" else to_entries | map("\(.key + 1). " + (.value | f)) | join("\n") end;
    def link: if .target | test("^[A-Za-z][A-Za-z0-9+.-]*://") then "[\(.label)](\(.target))" else "\(.label): `\(.target)`" end;
    ($repos | split("\n") | map(select(length > 0))) as $repo_list
    | [ "---",
        "id: \($id)",
        "source: claude-session",
        "model: \($model | yaml_scalar)",
        "date: \($date)",
        (if $repo_list | length == 0 then "repo: []"
         else "repo:\n" + ($repo_list | map("  - " + yaml_scalar) | join("\n")) end),
        "status: \(.status)",
        "---", "",
        "# \(.title)", "",
        "## Outcome", "", .outcome, "",
        "## Done", "", (.done | bullets("\(.item) — \(.evidence)")), "",
        "## Decisions", "", (.decisions | bullets("\(.decision) — \(.by), \(.date)")), "",
        "## Open", "", (.open | numbered("\(.question) **Rec:** \(.rec)")), "",
        "## Next steps", "", (.next_steps | numbered(.)), "",
        "## Links", "", (.links | bullets(link)), "",
        "## Resume", "",
        ("`claude --resume \($id)`" + (if .session_name then " (session **\(.session_name)**)" else "" end))
      ] | join("\n")' "$1"
}

# frontmatter_id <note.md> -> value of `id:` inside the leading frontmatter block
frontmatter_id() {
  awk 'NR == 1 { if ($0 != "---") exit; next }
       $0 == "---" { exit }
       /^id:/ { sub(/^id:[ \t]*/, ""); gsub(/["\047]/, ""); print; exit }' "$1"
}

# frontmatter_source <note.md> -> value of `source:` inside the leading frontmatter block
frontmatter_source() {
  awk 'NR == 1 { if ($0 != "---") exit; next }
       $0 == "---" { exit }
       /^source:/ { sub(/^source:[ \t]*/, ""); gsub(/["\047]/, ""); print; exit }' "$1"
}

# find_note_by_id <dir> <id> -> path of the session note (source: claude-session) carrying that id
find_note_by_id() {
  local f
  for f in "$1"/*.md; do
    [ -f "$f" ] && [ "$(frontmatter_id "$f")" = "$2" ] && [ "$(frontmatter_source "$f")" = "claude-session" ] \
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

TMP_NOTE=""
trap 'rm -f "${TMP_NOTE:-}"' EXIT

main() {
  command -v jq >/dev/null 2>&1 || die 1 "jq required (brew install jq)"
  [ "$#" -eq 1 ] && [ -f "$1" ] || die 2 "usage: note.sh <facts.json>"
  local facts="$1"
  jq -e . "$facts" >/dev/null 2>&1 || die 2 "SCHEMA $facts is not valid JSON"

  local id="${CLAUDE_CODE_SESSION_ID:-}"
  [ -n "$id" ] || die 1 "CLAUDE_CODE_SESSION_ID is unset; run inside a Claude Code session"
  [[ "$id" =~ ^[0-9a-f-]{36}$ ]] || die 1 "CLAUDE_CODE_SESSION_ID is not a session id: $id"
  [ -d "$OUT_DIR" ] || die 1 "note dir does not exist: $OUT_DIR"

  local step1_schema
  step1_schema="$(schema_errors "$facts")"
  [ -z "$step1_schema" ] || die 2 "facts rejected:"$'\n'"$step1_schema"

  local step2_redaction
  step2_redaction="$(redaction_findings "$facts" "$DENYLIST")"
  [ -z "$step2_redaction" ] || die 3 "facts rejected, rewrite these as pointers:"$'\n'"$step2_redaction"

  local transcript model date repos
  transcript="$(find_transcript "$id" "$PWD")" || die 1 "no transcript $id.jsonl under $PROJECTS_DIR"
  model="$(last_model "$transcript")"
  [ -n "$model" ] || die 1 "no assistant model found in transcript $transcript"
  date="$(TZ=Europe/Berlin date +%F)"
  repos="$(repo_names "$facts")"

  local note target tmp
  note="$(render_note "$facts" "$id" "$model" "$date" "$repos")"
  target="$(find_note_by_id "$OUT_DIR" "$id")" \
    || target="$(new_note_path "$OUT_DIR" "$(jq -r .title "$facts")" "$date" "$id")"
  tmp="$(mktemp "$OUT_DIR/.session-note.XXXXXX")"
  TMP_NOTE="$tmp"
  printf '%s\n' "$note" >"$tmp"
  mv "$tmp" "$target"
  TMP_NOTE=""
  printf '%s\n' "$target"
}

main "$@"
