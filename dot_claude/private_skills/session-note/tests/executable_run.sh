#!/usr/bin/env bash
# Tests for scripts/note.sh. Usage: tests/run.sh   (exit 0 = all green)
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly NOTE="$HERE/../scripts/note.sh"
readonly VALID="$HERE/fixtures/valid.json"
readonly TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

readonly SID="11111111-2222-3333-4444-555555555555"
readonly SID2="99999999-8888-7777-6666-555555555555"
readonly TODAY="$(TZ=Europe/Berlin date +%F)"
PASS=0
FAIL=0

# --- fixtures --------------------------------------------------------------

setup_fake_git() {
  # Fake `git -C <path> rev-parse --show-toplevel`: a repo root is any dir holding .fakegit.
  mkdir -p "$TMP/bin"
  cat >"$TMP/bin/git" <<'EOF'
#!/usr/bin/env bash
[ "${1:-}" = "-C" ] || exit 1
d="$2"; [ -e "$d" ] || exit 128
while [ "$d" != "/" ]; do
  [ -e "$d/.fakegit" ] && { echo "$d"; exit 0; }
  d="$(dirname "$d")"
done
echo "fatal: not a git repository" >&2; exit 128
EOF
  chmod +x "$TMP/bin/git"
  mkdir -p "$TMP/repos/alpha/sub" "$TMP/repos/beta" "$TMP/plain"
  touch "$TMP/repos/alpha/.fakegit" "$TMP/repos/beta/.fakegit"
}

setup_transcripts() {
  # Session SID lives under the cwd slug; SID2 only under some other project (fallback search).
  mkdir -p "$TMP/work"
  local slug; slug="$(printf '%s' "$TMP/work" | sed 's/[^A-Za-z0-9]/-/g')"
  mkdir -p "$TMP/projects/$slug" "$TMP/projects/-other-project"
  printf '%s\n' \
    '{"type":"assistant","message":{"model":"claude-old-0"}}' \
    '{"type":"assistant","message":{"model":"claude-test-1"}}' \
    '{"type":"assistant","message":{"model":"<synthetic>"}}' \
    '{"type":"user","message":{"role":"user"}}' >"$TMP/projects/$slug/$SID.jsonl"
  printf '%s\n' '{"type":"assistant","message":{"model":"claude-test-2"}}' \
    >"$TMP/projects/-other-project/$SID2.jsonl"
  printf '%s\n' '# test denylist' '' 'Acme Corp' 'Project[[:space:]]+Falcon' >"$TMP/denylist.txt"
}

with_paths() { # valid fixture + touched paths into the fake repos
  jq --arg t "$TMP" '.touched_paths = [$t+"/repos/alpha/sub", $t+"/repos/beta", $t+"/repos/alpha", $t+"/plain", $t+"/missing"]' "$VALID"
}

mutate() { jq "$1" "$VALID" >"$TMP/case.json"; }

# run_note <outdir> <session-id|-> <facts.json>; stdout+stderr -> $TMP/out, $TMP/err; returns exit code
run_note() {
  local dir="$1" sid="$2" facts="$3"
  mkdir -p "$dir"
  (
    cd "$TMP/work"
    export PATH="${EXTRA_PATH:+$EXTRA_PATH:}$TMP/bin:$PATH" SESSION_NOTE_DIR="$dir" CLAUDE_PROJECTS_DIR="$TMP/projects" \
      SESSION_NOTE_DENYLIST="${DENY:-$TMP/denylist.txt}"
    [ -z "${ONLY_PATH:-}" ] || export PATH="$ONLY_PATH"
    if [ "$sid" = "-" ]; then unset CLAUDE_CODE_SESSION_ID; else export CLAUDE_CODE_SESSION_ID="$sid"; fi
    bash "$NOTE" "$facts"
  ) >"$TMP/out" 2>"$TMP/err"
}

# --- assertion helpers ------------------------------------------------------

ok() { PASS=$((PASS + 1)); echo "ok   $1"; }
ko() { FAIL=$((FAIL + 1)); echo "FAIL $1"; [ -s "$TMP/err" ] && sed 's/^/       stderr: /' "$TMP/err" | head -5; return 0; }
md_count() { find "$1" -maxdepth 1 -name '*.md' | wc -l | tr -d ' '; }
frontmatter() { awk 'NR==1 && /^---$/ {f=1; next} f && /^---$/ {exit} f' "$1"; }

# expect_reject <name> <expected stderr fragment> <jq mutation>
expect_reject() {
  local name="$1" frag="$2" dir="$TMP/neg-$RANDOM$RANDOM"
  mutate "$3"
  if ! run_note "$dir" "$SID" "$TMP/case.json" && [ "$(md_count "$dir")" = 0 ] && grep -q -- "$frag" "$TMP/err"; then
    ok "$name"
  else ko "$name (want non-zero, no file, stderr ~ '$frag')"; fi
}

# --- (a) valid facts -> full note ------------------------------------------

test_valid_note() {
  local dir="$TMP/a" f
  with_paths >"$TMP/a.json"
  if run_note "$dir" "$SID" "$TMP/a.json"; then ok "a: valid facts exit 0"; else ko "a: valid facts exit 0"; return; fi
  f="$(cat "$TMP/out")"
  [ -f "$f" ] && ok "a: prints path of written file" || ko "a: prints path of written file"
  [ "$(basename "$f")" = "Widget pipeline spike $TODAY.md" ] && ok "a: filename '<title> <date>.md'" || ko "a: filename"
  [ "$(md_count "$dir")" = 1 ] && ok "a: exactly one file" || ko "a: exactly one file"

  local keys; keys="$(frontmatter "$f" | grep -E '^[a-z_]+:' | cut -d: -f1 | tr '\n' ' ')"
  [ "$keys" = "id source model date repo status " ] && ok "a: frontmatter keys/order exact" || ko "a: frontmatter keys/order exact (got: $keys)"
  local want_fm
  want_fm="$(printf '%s\n' "id: $SID" 'source: claude-session' 'model: claude-test-1' "date: $TODAY" 'repo:' '  - alpha' '  - beta' 'status: in-progress')"
  [ "$(frontmatter "$f")" = "$want_fm" ] && ok "a: frontmatter values (model skips <synthetic>, repo dedup/order, non-git skipped)" \
    || ko "a: frontmatter values (got: $(frontmatter "$f" | tr '\n' '|'))"

  local heads; heads="$(grep -E '^#{1,2} ' "$f" | tr '\n' '|')"
  [ "$heads" = "# Widget pipeline spike|## Outcome|## Done|## Decisions|## Open|## Next steps|## Links|## Resume|" ] \
    && ok "a: all sections in order" || ko "a: all sections in order (got: $heads)"
  grep -qF -- '- Prototype builder — tests/run.sh green' "$f" && ok "a: done item carries evidence" || ko "a: done item carries evidence"
  grep -qF -- '- Keep builder in bash — Dimitar, 2026-11-06' "$f" && ok "a: decision who/when" || ko "a: decision who/when"
  grep -qF -- '1. Split exporter into its own script? **Rec:** Yes, once a second format exists.' "$f" && ok "a: open numbered with rec" || ko "a: open numbered with rec"
  grep -qF -- '1. Run tests/run.sh and fix the first red test' "$f" && ok "a: next steps numbered" || ko "a: next steps numbered"
  grep -qF -- '- [Spec](https://example.atlassian.net/browse/PROJ-12)' "$f" && grep -qF -- '- Handoff: `docs/HANDOFF.md`' "$f" \
    && ok "a: links rendered (url vs path)" || ko "a: links rendered (url vs path)"
  grep -qF -- "\`claude --resume $SID\`" "$f" && grep -qF 'widget-spike' "$f" && ok "a: resume command + session name" || ko "a: resume command + session name"
}

# --- (b) same id -> overwrite same file; (c) new id -> new file --------------

test_upsert() {
  local dir="$TMP/b" first second
  run_note "$dir" "$SID" "$VALID" || true
  first="$(cat "$TMP/out")"
  mutate '.title = "Renamed title" | .outcome = "Second run."'
  if run_note "$dir" "$SID" "$TMP/case.json"; then second="$(cat "$TMP/out")"; else second=""; fi
  [ -n "$first" ] && [ "$first" = "$second" ] && ok "b: same id -> same path" || ko "b: same id -> same path ($first vs $second)"
  [ "$(md_count "$dir")" = 1 ] && ok "b: still one file" || ko "b: still one file"
  [ -n "$second" ] && grep -q '^# Renamed title$' "$second" && grep -q 'Second run.' "$second" \
    && ok "b: content overwritten" || ko "b: content overwritten"

  if run_note "$dir" "$SID2" "$VALID"; then ok "c: different id exit 0"; else ko "c: different id exit 0"; fi
  [ "$(md_count "$dir")" = 2 ] && ok "c: different id -> new file" || ko "c: different id -> new file"
  grep -q '^model: claude-test-2$' "$(cat "$TMP/out")" 2>/dev/null && ok "c: model found via fallback transcript search" \
    || ko "c: model found via fallback transcript search"
}

# --- (d) redaction gate -----------------------------------------------------

test_redaction() {
  expect_reject "d: email"              "email"       '.outcome = "Ping jane.doe@example.com for access."'
  expect_reject "d: github token"       "token"       '.next_steps += ["use ghp_abcdefghijklmnopqrstuvwxyz0123456789"]'
  expect_reject "d: anthropic key"      "token"       '.outcome = "key sk-ant-api03-abcdefghijklmnopqrstuv"'
  expect_reject "d: slack token"        "token"       '.outcome = "xoxb-123456789012-abcdefghij"'
  expect_reject "d: aws key"            "token"       '.outcome = "AKIAIOSFODNN7EXAMPLE"'
  expect_reject "d: bearer"             "token"       '.outcome = "curl -H Authorization: Bearer eyJhbGciOiJIUzI1NiJ9abc"'
  expect_reject "d: long hex secret"    "token"       '.outcome = "secret 3f9a2b7c4d1e8f6a0b5c9d2e7f4a1b8c3d6e9f0a2b5c8d1e4f7a"'
  expect_reject "d: long base64 secret" "token"       '.outcome = "blob dGhpc0lzQVNlY3JldFZhbHVlVGhhdFNob3VsZE5vdExlYWs9PQ=="'
  expect_reject "d: conn string user:pass" "connection" '.outcome = "postgres://admin:hunter2@db.example.com/prod"'
  expect_reject "d: mongodb+srv"        "connection"  '.links += [{"label":"db","target":"mongodb+srv://cluster0.example.net/app"}]'
  expect_reject "d: ipv4"               "ipv4"        '.outcome = "box at 10.0.12.7 is down"'
  expect_reject "d: .internal host"     "hostname"    '.outcome = "call api.billing.internal"'
  expect_reject "d: .corp host"         "hostname"    '.done[0].evidence = "build01.corp log"'
  expect_reject "d: .local host"        "hostname"    '.outcome = "printer.local"'
  expect_reject "d: denylist term"      "denylist"    '.outcome = "Met Acme Corp about it."'
  expect_reject "d: denylist regex"     "denylist"    '.open[0].rec = "Ask Project  Falcon"'
  expect_reject "d: metric tickets/week" "metric"     '.outcome = "Volume is 31 tickets/week."'
  expect_reject "d: metric open"        "metric"      '.outcome = "902 open in the queue"'
  expect_reject "d: metric dollars"     "metric"      '.outcome = "Spend was $2,067 last month"'
  expect_reject "d: metric euros"       "metric"      '.outcome = "Cost 1.200 € per run"'
  expect_reject "d: metric percent"     "metric"      '.outcome = "40% of requests fail"'
  expect_reject "d: metric h median"    "metric"      '.outcome = "Response 3 h median"'
  expect_reject "d: metric customers"   "metric"      '.done[0].item = "Mailed 120 customers"'
  expect_reject "d: metric per day"     "metric"      '.outcome = "about 40/day"'
  expect_reject "d: reports field path" "outcome"     '.outcome = "Ping jane.doe@example.com"'
}

# --- (g) figure gate: any digit outside identifier shapes is a figure ---------

test_figures() {
  local s
  for s in "57 support tickets" "216 line crossings" "1200 active users" "Revenue 3.4M" "Spend 2067 euros" \
           "headcount: 42" "42 FTE" "crossings went 216 -> 39" "1.234.567 entries" "40 percent fail" \
           "6 duplicated triage efforts" "7 dependency lines" "spend was 2067 dollars" \
           "Keep dependency lines on frame 1?" "Node 20.11.1 in use"; do
    expect_reject "g: figure '$s'" "metric" ".outcome = \"$s\""
  done
  expect_reject "g: link label scanned"        "links.2.label" '.links += [{"label":"Q3 board: 31 tickets/week view","target":"https://miro.com/app/board/uXjVERYIKsw=/"}]'
  expect_reject "g: fullwidth digits"          "metric"        '.outcome = "\uff15\uff17 tickets"'
  expect_reject "g: digits hidden by path-like" "metric"       '.outcome = "spend/2067 last month"'
  for s in "twenty tickets" "two rounds of review" "thirty-five customers" "a dozen users" "one fix/skip table" \
           "hundreds of tickets" "Twenty Five engineers"; do
    expect_reject "g: number word '$s'" "number word" ".outcome = \"$s\""
  done
}

# --- (h) secrets, normalisation, shipped denylist ------------------------------

test_secrets() {
  expect_reject "h: key=base64 secret"     "token"           '.outcome = "key=dGhpc0lzQVNlY3JldFZhbHVlVGhhdFNob3VsZE5vdExlYWs9PQ=="'
  expect_reject "h: api_key: value"        "secret assignment" '.outcome = "api_key: abcdefsecret"'
  expect_reject "h: password = value"      "secret assignment" '.outcome = "password = hunter"'
  expect_reject "h: client-secret=value"   "secret assignment" '.outcome = "client-secret=xyzzy"'
  expect_reject "h: pwd:value"             "secret assignment" '.next_steps += ["pwd:abc"]'
  expect_reject "h: PEM rsa key"           "private key"     '.outcome = "-----BEGIN RSA PRIVATE KEY-----"'
  expect_reject "h: PEM plain key"         "private key"     '.outcome = "-----BEGIN PRIVATE KEY-----"'
  expect_reject "h: ipv6 full"             "ipv6"            '.outcome = "host 2001:db8::8a2e:370:7334 down"'
  expect_reject "h: ipv6 link-local"       "ipv6"            '.outcome = "bind fe80::1 now"'
  expect_reject "h: .corp mid label"       "hostname"        '.outcome = "call api.corp.example.com"'
  expect_reject "h: .internal mid label"   "hostname"        '.outcome = "db.internal.example.net is slow"'
  expect_reject "h: token in url query"    "secret in url"   '.links += [{"label":"hook","target":"https://example.com/x?token=abc"}]'
  expect_reject "h: sig in url query"      "secret in url"   '.outcome = "see https://example.com/a?b=c&sig=xyz"'
  expect_reject "h: zero-width token"      "token"           '.outcome = "ghp_abcdefghij\u200bklmnopqrstuvwxyz0123456789"'
  expect_reject "h: fullwidth token"       "token"           '.outcome = "\uff47\uff48\uff50_abcdefghijklmnopqrstuvwxyz0123"'
  expect_reject "h: zero-width denylist"   "denylist"        '.outcome = "Met Acme\u200b Corp"'
  expect_reject "h: newline denylist"      "denylist"        '.outcome = "Met Acme\nCorp"'
  expect_reject "h: case denylist"         "denylist"        '.outcome = "Met ACME corp"'
  expect_reject "h: soft-hyphen email"     "email"           '.outcome = "jane.doe@exam\u00adple.com"'

  local shipped="$HERE/../denylist.txt"
  grep -q 'ADD CUSTOMER AND PERSON NAMES HERE' "$shipped" && ok "h: shipped denylist has names marker" || ko "h: shipped denylist has names marker"
  DENY="$shipped" expect_reject "h: shipped denylist rds host" "denylist" '.outcome = "prod.cluster-cxyz.eu-central.rds.amazonaws.com"'
  DENY="$shipped" expect_reject "h: shipped denylist corp host" "denylist" '.outcome = "build.corp.example.com"'
  local dir="$TMP/h-shipped"
  if DENY="$shipped" run_note "$dir" "$SID" "$VALID"; then ok "h: shipped denylist passes valid facts"; else ko "h: shipped denylist passes valid facts"; fi
}

# --- (i) temp file cleanup and filename cap ------------------------------------

hidden_count() { find "$1" -maxdepth 1 -name '.session-note.*' | wc -l | tr -d ' '; }

test_files() {
  local dir="$TMP/i-long" f name
  mutate '.title = ("x" * 300)'
  if run_note "$dir" "$SID" "$TMP/case.json"; then f="$(cat "$TMP/out")"; name="$(basename "$f" " $TODAY.md")"
    [ -f "$f" ] && [ "${#name}" -le 120 ] && ok "i: 300-char title -> truncated filename (${#name})" || ko "i: 300-char title -> truncated filename"
  else ko "i: 300-char title -> note written"; fi
  [ "$(hidden_count "$dir")" = 0 ] && ok "i: long title leaves no temp file" || ko "i: long title leaves no temp file"

  dir="$TMP/i-utf8"
  mutate '.title = ("\u00e9" * 150)'
  if run_note "$dir" "$SID" "$TMP/case.json"; then f="$(cat "$TMP/out")"; name="$(basename "$f" " $TODAY.md")"
    [ "$(printf '%s' "$name" | wc -c | tr -d ' ')" -le 120 ] && printf '%s' "$name" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1 \
      && ok "i: multibyte title cut at 120 bytes on a char boundary" || ko "i: multibyte title cut at 120 bytes on a char boundary"
  else ko "i: multibyte title -> note written"; fi

  dir="$TMP/i-mvfail"; mkdir -p "$TMP/failbin"
  printf '#!/bin/sh\nexit 1\n' >"$TMP/failbin/mv"; chmod +x "$TMP/failbin/mv"
  if ! EXTRA_PATH="$TMP/failbin" run_note "$dir" "$SID" "$VALID" && [ "$(hidden_count "$dir")" = 0 ] && [ "$(md_count "$dir")" = 0 ]; then
    ok "i: failed mv leaves no temp file"; else ko "i: failed mv leaves no temp file"; fi

  dir="$TMP/i-trav"
  mutate '.title = "../../evil"'
  if run_note "$dir" "$SID" "$TMP/case.json" && [ "$(md_count "$dir")" = 1 ] && [ "$(dirname "$(cat "$TMP/out")")" = "$dir" ] \
     && [ -z "$(find "$TMP" -maxdepth 2 -name 'evil*')" ]; then ok "i: traversal title stays in note dir"; else ko "i: traversal title stays in note dir"; fi
}

# --- (j) environment and upsert hardening -------------------------------------

test_env() {
  local dir="$TMP/j-sid"
  if ! run_note "$dir" "../../../etc/x" "$VALID" && [ "$(md_count "$dir")" = 0 ] && grep -q 'CLAUDE_CODE_SESSION_ID' "$TMP/err"; then
    ok "j: malformed session id rejected"; else ko "j: malformed session id rejected"; fi

  mkdir -p "$TMP/nojq"
  local f; for f in /bin/* /usr/bin/*; do [ "$(basename "$f")" = jq ] || ln -sf "$f" "$TMP/nojq/" 2>/dev/null || true; done
  dir="$TMP/j-nojq"
  local rc
  ONLY_PATH="$TMP/nojq" run_note "$dir" "$SID" "$VALID" && rc=0 || rc=$?
  [ "$rc" = 1 ] && grep -q 'jq required' "$TMP/err" && ok "j: missing jq -> 'jq required', exit 1" || ko "j: missing jq -> 'jq required', exit 1 (rc=$rc)"

  dir="$TMP/j-src"; mkdir -p "$dir"
  printf '%s\n' '---' "id: $SID" 'source: other-tool' '---' 'keep me' >"$dir/foreign.md"
  if run_note "$dir" "$SID" "$VALID" && [ "$(cat "$TMP/out")" != "$dir/foreign.md" ] && grep -q 'keep me' "$dir/foreign.md"; then
    ok "j: upsert ignores same id with other source"; else ko "j: upsert ignores same id with other source"; fi

  dir="$TMP/j-clash"
  run_note "$dir" "$SID" "$VALID" || true
  if run_note "$dir" "$SID2" "$VALID" && [ "$(basename "$(cat "$TMP/out")")" = "Widget pipeline spike $TODAY $SID2.md" ]; then
    ok "j: name clash suffix is full session id"; else ko "j: name clash suffix is full session id (got $(cat "$TMP/out"))"; fi

  dir="$TMP/j-ssh"
  mutate '.outcome = "Cloned git@github.com:org/repo.git and git@gitlab.com:team/sub/tool"'
  if run_note "$dir" "$SID" "$TMP/case.json"; then ok "j: ssh git url not an email"; else ko "j: ssh git url not an email"; fi
  expect_reject "j: ssh url to internal host" "hostname" '.outcome = "git@gitlab.corp:team/tool.git"'

  dir="$TMP/j-longseg"
  mutate '.touched_paths = ["/Users/x/Work/ThisIsAVeryLongFolderNameWithMixedCase2026AndMoreText/sub"] | .links += [{"label":"Deep","target":"docs/ALongDirectoryNameThatHasDigits42AndCapitalsInIt/x.md"}]'
  if run_note "$dir" "$SID" "$TMP/case.json"; then ok "j: long path segments not a base64 token"; else ko "j: long path segments not a base64 token"; fi
  expect_reject "j: sha256 still a token" "token" '.outcome = "digest e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"'
}

# --- (e) schema -------------------------------------------------------------

test_schema() {
  expect_reject "e: done item without evidence" "SCHEMA" '.done[0] |= del(.evidence)'
  expect_reject "e: done item empty evidence"   "SCHEMA" '.done[0].evidence = "  "'
  expect_reject "e: bad status"                 "SCHEMA" '.status = "wip"'
  expect_reject "e: missing title"              "SCHEMA" 'del(.title)'
  expect_reject "e: empty outcome"              "SCHEMA" '.outcome = ""'
  expect_reject "e: unknown key"                "SCHEMA" '.tags = ["x"]'
  expect_reject "e: decision bad date"          "SCHEMA" '.decisions[0].date = "06.11.2026"'
  expect_reject "e: link without target"        "SCHEMA" '.links[0] |= del(.target)'
  expect_reject "e: next_steps wrong type"      "SCHEMA" '.next_steps = "do it"'
  expect_reject "e: open item without rec"      "SCHEMA" '.open[0] |= del(.rec)'
  expect_reject "e: decision by a person name"  "SCHEMA" '.decisions[0].by = "Alice"'
  expect_reject "e: decision by role not in list" "SCHEMA" '.decisions[0].by = "the team lead"'
  local dir="$TMP/e-noid"
  if ! run_note "$dir" "-" "$VALID" && [ "$(md_count "$dir")" = 0 ] && grep -q 'CLAUDE_CODE_SESSION_ID' "$TMP/err"; then
    ok "e: unset CLAUDE_CODE_SESSION_ID fails loudly"
  else ko "e: unset CLAUDE_CODE_SESSION_ID fails loudly"; fi
  local dir2="$TMP/e-notranscript"
  if ! run_note "$dir2" "00000000-0000-0000-0000-000000000000" "$VALID" && [ "$(md_count "$dir2")" = 0 ] && grep -q 'transcript' "$TMP/err"; then
    ok "e: missing transcript fails loudly"
  else ko "e: missing transcript fails loudly"; fi
}

# --- (f) allowed look-alikes ------------------------------------------------

test_allowed() {
  local dir="$TMP/f"
  mutate '.outcome = "Released v2.1.319 and version 1.4.2 on 2026-11-06T10:15:00Z for INIT-216, AI-12, F-3 and PROJ-1234 (commit 9ab99d1, full 9ab99d1e0f3c4b5a6d7e8f9a0b1c2d3e4f5a6b7c). Dev server on localhost:3000, config in /Users/x/settings.local.json and src/utils/date.ts:42, migration 0042_add_region.sql, standup 09:30, round 2 of 2, round two of two, next step 1, run 0b1c2d3e-4f5a-6b7c-8d9e-0f1a2b3c4d5e."
    | .decisions += [{"decision":"Ship it","by":"TEAM","date":"2026-11-06"},{"decision":"Merge","by":"reviewer","date":"2026-11-06"}]
    | .next_steps += ["Open https://miro.com/app/board/uXjVERYIKsw=/ and https://example.atlassian.net/wiki/spaces/DIG/pages/123456789/Discovery+Notes"]
    | .links += [{"label":"Board","target":"https://miro.com/app/board/uXjVERYIKsw=/"},
                 {"label":"Initiative","target":"INIT-216"},
                 {"label":"Artifact","target":"https://claude.ai/code/artifact/0b1c2d3e-4f5a-6b7c-8d9e-0f1a2b3c4d5e"}]'
  if run_note "$dir" "$SID" "$TMP/case.json" && [ "$(md_count "$dir")" = 1 ]; then
    ok "f: identifier shapes not flagged"
  else ko "f: identifier shapes not flagged"; fi
}

# --- main -------------------------------------------------------------------

main() {
  setup_fake_git
  setup_transcripts
  test_valid_note
  test_upsert
  test_redaction
  test_schema
  test_allowed
  test_figures
  test_secrets
  test_files
  test_env
  echo "---"
  echo "passed: $PASS  failed: $FAIL"
  [ "$FAIL" = 0 ]
}

main "$@"
