#!/usr/bin/env bash
# Tests for scripts/note.sh, scripts/digest.sh and scripts/daily.sh. Usage: tests/run.sh   (exit 0 = all green)
set -euo pipefail

readonly HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly NOTE="$HERE/../scripts/note.sh"
readonly DIGEST="$HERE/../scripts/digest.sh"
readonly DAILY="$HERE/../scripts/daily.sh"
readonly VALID="$HERE/fixtures/valid.json"
readonly DAILY_FACTS="$HERE/fixtures/daily.json"
readonly TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

readonly SID="11111111-2222-3333-4444-555555555555"
readonly SID2="99999999-8888-7777-6666-555555555555"
readonly SID_A="aaaaaaaa-0000-4000-8000-000000000001"
readonly SID_B="bbbbbbbb-0000-4000-8000-000000000002"
readonly SID_SELF="12345678-0000-4000-8000-000000000008"
readonly DAY="2026-11-06"
readonly TODAY="$(TZ=Europe/Berlin date +%F)"
PASS=0
FAIL=0

# --- fixtures --------------------------------------------------------------

setup_work_root() {
  # Fixture work root: two repo folders, one hidden folder and one plain file (neither is a repo name).
  mkdir -p "$TMP/work-root/acme-portal" "$TMP/work-root/billing" "$TMP/work-root/.hidden-tool"
  printf 'x\n' >"$TMP/work-root/notes.md"
}

setup_transcripts() {
  # Fixture transcripts, copied so their mtime is "now" (selection must not depend on mtime).
  cp -R "$HERE/fixtures/transcripts" "$TMP/projects"
  find "$TMP/projects" -type f -exec touch {} +
  printf '%s\n' '# test denylist' '' 'Acme Corp' 'Project[[:space:]]+Falcon' >"$TMP/denylist.txt"
}

mutate() { jq "$1" "$VALID" >"$TMP/case.json"; }
mutate_daily() { jq "$1" "$DAILY_FACTS" >"$TMP/case.json"; }

# run_note <outdir> <session-id|-> <args...>; stdout+stderr -> $TMP/out, $TMP/err; returns exit code
run_note() {
  local dir="$1" sid="$2"; shift 2
  mkdir -p "$dir"
  (
    export PATH="${EXTRA_PATH:+$EXTRA_PATH:}$PATH" SESSION_NOTE_DIR="$dir" CLAUDE_PROJECTS_DIR="$TMP/projects" \
      SESSION_NOTE_DENYLIST="${DENY:-$TMP/denylist.txt}" SESSION_NOTE_WORK_ROOT="${WORK_ROOT:-$TMP/work-root}"
    [ -z "${ONLY_PATH:-}" ] || export PATH="$ONLY_PATH"
    if [ "$sid" = "-" ]; then unset CLAUDE_CODE_SESSION_ID; else export CLAUDE_CODE_SESSION_ID="$sid"; fi
    bash "$NOTE" "$@"
  ) >"$TMP/out" 2>"$TMP/err"
}

# run_digest <args...>; stdout -> $TMP/digest.json, stderr -> $TMP/err; returns exit code
run_digest() {
  (
    export CLAUDE_PROJECTS_DIR="$TMP/projects" CLAUDE_CODE_SESSION_ID="${SELF:-$SID_SELF}"
    [ -z "${NOW:-}" ] || export SESSION_NOTE_NOW="$NOW"
    bash "$DIGEST" "$@"
  ) >"$TMP/digest.json" 2>"$TMP/err"
}

# --- assertion helpers ------------------------------------------------------

ok() { PASS=$((PASS + 1)); echo "ok   $1"; }
ko() { FAIL=$((FAIL + 1)); echo "FAIL $1"; [ -s "$TMP/err" ] && sed 's/^/       stderr: /' "$TMP/err" | head -5; return 0; }
md_count() { find "$1" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' '; }
frontmatter() { awk 'NR==1 && /^---$/ {f=1; next} f && /^---$/ {exit} f' "$1"; }
check() { if eval "$2"; then ok "$1"; else ko "$1"; fi; }

# expect_reject <name> <expected stderr fragment> <jq mutation>   (single-session facts)
expect_reject() {
  local name="$1" frag="$2" dir="$TMP/neg-$RANDOM$RANDOM"
  mutate "$3"
  if ! run_note "$dir" "$SID" "$TMP/case.json" && [ "$(md_count "$dir")" = 0 ] && grep -q -- "$frag" "$TMP/err"; then
    ok "$name"
  else ko "$name (want non-zero, no file, stderr ~ '$frag')"; fi
}

# expect_pass <name> <jq mutation>   (single-session facts pass the gate and write one note)
expect_pass() {
  local name="$1" dir="$TMP/pos-$RANDOM$RANDOM"
  mutate "$2"
  if run_note "$dir" "$SID" "$TMP/case.json" && [ "$(md_count "$dir")" = 1 ]; then ok "$name"; else ko "$name (want exit 0, one file)"; fi
}

# expect_daily_reject <name> <expected stderr fragment> <jq mutation>
expect_daily_reject() {
  local name="$1" frag="$2" dir="$TMP/dneg-$RANDOM$RANDOM"
  mutate_daily "$3"
  if ! run_note "$dir" "$SID_SELF" --daily "$DAY" "$TMP/case.json" && [ "$(md_count "$dir")" = 0 ] && grep -q -- "$frag" "$TMP/err"; then
    ok "$name"
  else ko "$name (want non-zero, no file, stderr ~ '$frag')"; fi
}

# --- (a) single session: valid facts -> full note ---------------------------

test_valid_note() {
  local dir="$TMP/a" f
  if run_note "$dir" "$SID" "$VALID"; then ok "a: valid facts exit 0"; else ko "a: valid facts exit 0"; return; fi
  f="$(cat "$TMP/out")"
  check "a: prints path of written file" '[ -f "$f" ]'
  check "a: filename '<title> <date>.md'" '[ "$(basename "$f")" = "Widget pipeline spike (personal tooling) $TODAY.md" ]'
  check "a: exactly one file" '[ "$(md_count "$dir")" = 1 ]'

  local want_fm; want_fm="$(printf '%s\n' "id: $SID" 'source: claude-session' "created: $TODAY")"
  check "a: frontmatter is exactly id, source, created (no model/repo/status)" '[ "$(frontmatter "$f")" = "$want_fm" ]'

  local heads; heads="$(grep -E '^#{1,2} ' "$f" | tr '\n' '|')"
  check "a: headings (got: $heads)" '[ "$heads" = "# Widget pipeline spike (personal tooling)|## Resume|" ]'
  check "a: status line" 'grep -qxF -- "- **Status:** in-progress" "$f"'
  check "a: progress line" 'grep -qxF -- "- **Progress:** The pipeline prototype runs end to end. Waiting on my review." "$f"'
  check "a: learnings bullets" 'grep -qxF -- "  - Keep the builder in bash; it stays readable." "$f"'
  check "a: bottlenecks bullets" 'grep -qxF -- "  - The exporter format was unclear until late." "$f"'
  check "a: next steps numbered" 'grep -qxF -- "  1. Run the tests and fix the first red one" "$f"'
  check "a: no links/outcome/done/decisions sections" '! grep -qE "^## (Links|Outcome|Done|Decisions|Open)" "$f"'
  check "a: resume command on its own line" 'grep -qxF -- "\`claude --resume $SID\`" "$f"'
  check "a: session name line" 'grep -qxF -- "Session name: widget-spike" "$f"'
  mutate '.learnings = [] | .bottlenecks = [] | .next_steps = []'
  run_note "$TMP/a-empty" "$SID" "$TMP/case.json" || true
  check "a: empty lists render as none" 'grep -qxF -- "- **Learnings:** none" "$(cat "$TMP/out")" && grep -qxF -- "- **Next:** none" "$(cat "$TMP/out")"'
}

# --- (b) same id -> overwrite same file; (c) new id -> new file --------------

test_upsert() {
  local dir="$TMP/b" first second
  run_note "$dir" "$SID" "$VALID" || true
  first="$(cat "$TMP/out")"
  mutate '.title = "Renamed title" | .progress = "Second run."'
  if run_note "$dir" "$SID" "$TMP/case.json"; then second="$(cat "$TMP/out")"; else second=""; fi
  check "b: same id -> same path ($first vs $second)" '[ -n "$first" ] && [ "$first" = "$second" ]'
  check "b: still one file" '[ "$(md_count "$dir")" = 1 ]'
  check "b: content overwritten" '[ -n "$second" ] && grep -q "^# Renamed title$" "$second" && grep -q "Second run." "$second"'
  check "c: different id exit 0" 'run_note "$dir" "$SID2" "$VALID"'
  check "c: different id -> new file" '[ "$(md_count "$dir")" = 2 ]'
}

# --- (d) redaction gate: secrets, hosts, figures (kept rules) -----------------

test_redaction() {
  expect_reject "d: email"              "email"       '.progress = "Ping jane.doe@example.com for access."'
  expect_reject "d: github token"       "token"       '.next_steps += ["use ghp_abcdefghijklmnopqrstuvwxyz0123456789"]'
  expect_reject "d: anthropic key"      "token"       '.progress = "key sk-ant-api03-abcdefghijklmnopqrstuv"'
  expect_reject "d: slack token"        "token"       '.progress = "xoxb-123456789012-abcdefghij"'
  expect_reject "d: aws key"            "token"       '.progress = "AKIAIOSFODNN7EXAMPLE"'
  expect_reject "d: bearer"             "token"       '.progress = "curl -H Authorization: Bearer eyJhbGciOiJIUzI1NiJ9abc"'
  expect_reject "d: long hex secret"    "token"       '.progress = "secret 3f9a2b7c4d1e8f6a0b5c9d2e7f4a1b8c3d6e9f0a2b5c8d1e4f7a"'
  expect_reject "d: long base64 secret" "token"       '.progress = "blob dGhpc0lzQVNlY3JldFZhbHVlVGhhdFNob3VsZE5vdExlYWs9PQ=="'
  expect_reject "d: conn string user:pass" "connection" '.progress = "postgres://admin:hunter2@db.example.com/prod"'
  expect_reject "d: mongodb+srv"        "connection"  '.learnings += ["mongodb+srv://cluster0.example.net/app"]'
  expect_reject "d: ipv4"               "ipv4"        '.progress = "box at 10.0.12.7 is down"'
  expect_reject "d: .internal host"     "hostname"    '.progress = "call api.billingsvc.internal"'
  expect_reject "d: .corp host"         "hostname"    '.bottlenecks[0] = "build.corp log"'
  expect_reject "d: .local host"        "hostname"    '.progress = "printer.local"'
  expect_reject "d: denylist term"      "denylist"    '.progress = "Met Acme Corp about it."'
  expect_reject "d: denylist regex"     "denylist"    '.learnings[0] = "Ask Project  Falcon"'
  expect_reject "d: metric tickets/week" "metric"     '.progress = "Volume is 31 tickets/week."'
  expect_reject "d: metric open"        "metric"      '.progress = "902 open in the queue"'
  expect_reject "d: metric dollars"     "metric"      '.progress = "Spend was $2,067 last month"'
  expect_reject "d: metric euros"       "metric"      '.progress = "Cost 1.200 € per run"'
  expect_reject "d: metric percent"     "metric"      '.progress = "40% of requests fail"'
  expect_reject "d: metric h median"    "metric"      '.progress = "Response 3 h median"'
  expect_reject "d: metric customers"   "metric"      '.learnings[0] = "Mailed 120 customers"'
  expect_reject "d: metric per day"     "metric"      '.progress = "about 40/day"'
  expect_reject "d: reports field path" "progress"    '.progress = "Ping jane.doe@example.com"'
  expect_reject "d: title is gated"     "title"       '.title = "Spike for Acme Corp"'
  expect_reject "d: session_name is gated" "session_name" '.session_name = "fix PROJ-12"'
}

# --- (k) work identifiers: repo names, SHAs, ticket keys, URLs, hostnames ----

test_work_identifiers() {
  expect_reject "k: work repo folder name"           "work repo name" '.progress = "Fixed the billing export."'
  expect_reject "k: repo name case-insensitive"      "work repo name" '.title = "Acme-Portal cleanup (work)"'
  expect_reject "k: repo name inside a path"         "work repo name" '.learnings[0] = "see ~/Work/job/git/acme-portal/README.md"'
  expect_reject "k: repo name with a suffix folder"  "work repo name" '.progress = "worked in acme-portal-sast"'
  expect_pass   "k: repo name only on word boundary" '.progress = "Rebilling and acme-portals are different words."'
  expect_pass   "k: plain files and hidden dirs are not repo names" '.progress = "Edited notes.md and the .hidden-tool folder."'
  local rc
  WORK_ROOT="$TMP/no-such-root" run_note "$TMP/k-noroot" "$SID" "$VALID" && rc=0 || rc=$?
  check "k: missing work root fails loudly (exit 1, no file)" '[ "$rc" = 1 ] && grep -q "SESSION_NOTE_WORK_ROOT" "$TMP/err" && [ "$(md_count "$TMP/k-noroot")" = 0 ]'

  expect_reject "k: short commit sha"     "commit sha"  '.progress = "Landed in 9ab99d1."'
  expect_reject "k: full commit sha"      "commit sha"  '.progress = "commit 9ab99d1e0f3c4b5a6d7e8f9a0b1c2d3e4f5a6b7c"'
  expect_reject "k: sha in next step"     "commit sha"  '.next_steps[0] = "Revert c01d051"'
  expect_reject "k: ticket key"           "ticket key"  '.progress = "Closed PROJ-1234."'
  expect_reject "k: initiative key"       "ticket key"  '.learnings[0] = "db access goes via INIT-216"'
  expect_reject "k: https url"            "url"         '.progress = "Board at https://miro.com/app/board/uXjVERYIKsw=/"'
  expect_reject "k: any scheme url"       "url"         '.progress = "see file:///tmp/x and ssh://box/y"'
  expect_reject "k: bare hostname"        "hostname"    '.progress = "Deployed to example.com."'
  expect_reject "k: subdomain hostname"   "hostname"    '.progress = "the api.github.io page"'
  expect_reject "k: ssh git remote host"  "hostname"    '.progress = "Cloned git@github.com:org/repo.git"'
  expect_reject "k: uuid now a sha shape" "commit sha"  '.progress = "run 0b1c2d3e-4f5a-6b7c-8d9e-0f1a2b3c4d5e"'

  # any alphabetic TLD is a host, not a fixed list
  local host
  for host in portal.acme.it shop.acme.es api.acme.pl app.acme.fi jira.acme.ca vault.acme.systems acme.zone PORTAL.ACME.IT; do
    expect_reject "k: host $host" "hostname" ".progress = \"Checked $host first.\""
  done
  # a mixed-case TLD is still a TLD
  expect_reject "k: host Acme.Com"            "hostname" '.progress = "Checked Acme.Com today"'
  expect_reject "k: host Portal.Acme.Io"      "hostname" '.progress = "Checked Portal.Acme.Io today"'
  expect_reject "k: host jira.acme.Com"       "hostname" '.progress = "Opened jira.acme.Com"'
  expect_pass   "k: sentence join, file names, versions and abbreviations still pass" \
    '.progress = "Tests done.Next I edit README.md and settings.local.json, try v2.1.rc, e.g. hosts, i.e. names, etc."'
  expect_reject "k: host at sentence end"     "hostname" '.progress = "Moved to acme.zone."'
  expect_reject "k: host with digit labels"   "hostname" '.progress = "Called 1.acme.it"'
  expect_pass   "k: abbreviations, versions and sentence joins are not hosts" \
    '.progress = "Kept the gate strict, e.g. for hosts, i.e. names, etc. Tried v2.1.rc and version 1.0.0.RELEASE, then done.Next we test U.S. spelling and a.m. slots."'
  expect_pass   "k: file names with known extensions are not hosts" \
    '.progress = "Edited settings.local.json, docker-compose.override.yml, pyproject.toml, app.config.ts, run.sh, setup.py, notes.final.md, server.log, styles.scss and Node.js docs."'
}

# --- (g) figure gate: any digit outside dates, times, versions, filenames ----

test_figures() {
  local s
  for s in "57 support tickets" "216 line crossings" "1200 active users" "Revenue 3.4M" "Spend 2067 euros" \
           "headcount: 42" "42 FTE" "crossings went 216 -> 39" "1.234.567 entries" "40 percent fail" \
           "6 duplicated triage efforts" "7 dependency lines" "spend was 2067 dollars" \
           "Keep dependency lines on frame 1?" "Node 20.11.1 in use" \
           "round 2 of 2" "next step 1" "step 3 failed" "see src/utils/date.ts:42" "spend/2067 last month" \
           "UTF-8 output"; do
    expect_reject "g: figure '$s'" "metric" ".progress = \"$s\""
  done
  expect_reject "g: fullwidth digits"          "metric"        '.progress = "\uff15\uff17 tickets"'
  for s in "twenty tickets" "two rounds of review" "thirty-five customers" "a dozen users" \
           "hundreds of tickets" "Twenty Five engineers" "round two of two"; do
    expect_reject "g: number word '$s'" "number word" ".progress = \"$s\""
  done
  expect_pass "g: 'one' is not a number word" '.progress = "One fix/skip table and one more pass."'
}

# --- (h) secrets, normalisation, shipped denylist ------------------------------

test_secrets() {
  expect_reject "h: key=base64 secret"     "token"           '.progress = "key=dGhpc0lzQVNlY3JldFZhbHVlVGhhdFNob3VsZE5vdExlYWs9PQ=="'
  expect_reject "h: api_key: value"        "secret assignment" '.progress = "api_key: abcdefsecret"'
  expect_reject "h: password = value"      "secret assignment" '.progress = "password = hunter"'
  expect_reject "h: client-secret=value"   "secret assignment" '.progress = "client-secret=xyzzy"'
  expect_reject "h: pwd:value"             "secret assignment" '.next_steps += ["pwd:abc"]'
  expect_reject "h: PEM rsa key"           "private key"     '.progress = "-----BEGIN RSA PRIVATE KEY-----"'
  expect_reject "h: PEM plain key"         "private key"     '.progress = "-----BEGIN PRIVATE KEY-----"'
  expect_reject "h: ipv6 full"             "ipv6"            '.progress = "host 2001:db8::8a2e:370:7334 down"'
  expect_reject "h: ipv6 link-local"       "ipv6"            '.progress = "bind fe80::1 now"'
  expect_reject "h: .corp mid label"       "hostname"        '.progress = "call api.corp.example.com"'
  expect_reject "h: .internal mid label"   "hostname"        '.progress = "db.internal.example.net is slow"'
  expect_reject "h: token in url query"    "secret in url"   '.progress = "see https://example.com/x?token=abc"'
  expect_reject "h: zero-width token"      "token"           '.progress = "ghp_abcdefghij\u200bklmnopqrstuvwxyz0123456789"'
  expect_reject "h: fullwidth token"       "token"           '.progress = "\uff47\uff48\uff50_abcdefghijklmnopqrstuvwxyz0123"'
  expect_reject "h: zero-width denylist"   "denylist"        '.progress = "Met Acme\u200b Corp"'
  # a newline is a SCHEMA reject now (e: multi-line ...); other whitespace runs are squeezed before matching
  expect_reject "h: tab denylist"          "denylist"        '.progress = "Met Acme\t \tCorp"'
  expect_reject "h: newline denylist"      "SCHEMA"          '.progress = "Met Acme\nCorp"'
  expect_reject "h: case denylist"         "denylist"        '.progress = "Met ACME corp"'
  expect_reject "h: soft-hyphen email"     "email"           '.progress = "jane.doe@exam\u00adple.com"'
  expect_reject "h: zero-width repo name"  "work repo name"  '.progress = "bill\u200bing export"'
  expect_reject "h: zero-width sha"        "commit sha"      '.progress = "9ab9\u200b9d1 landed"'

  local shipped="$HERE/../denylist.txt"
  check "h: shipped denylist has names marker" 'grep -q "ADD CUSTOMER AND PERSON NAMES HERE" "$shipped"'
  DENY="$shipped" expect_reject "h: shipped denylist rds host" "denylist" '.progress = "prod.cluster-cxyz.eu-central.rds.amazonaws.com"'
  check "h: shipped denylist passes valid facts" 'DENY="$shipped" run_note "$TMP/h-shipped" "$SID" "$VALID"'
}

# --- (f) allowed look-alikes ------------------------------------------------

test_allowed() {
  expect_pass "f: dates, times, versions, filenames, localhost are not flagged" \
    '.progress = "Released v2.1.319 and version 1.4.2 on 2026-11-06T10:15:00Z. Dev server on localhost:3000, config in settings.local.json and tsconfig.app.json, migration 0042_add_region.sql, standup 09:30, Node.js and README.md."'
}

# --- (e) schema -------------------------------------------------------------

test_schema() {
  expect_reject "e: bad status"                 "SCHEMA" '.status = "wip"'
  expect_reject "e: missing title"              "SCHEMA" 'del(.title)'
  expect_reject "e: empty progress"             "SCHEMA" '.progress = ""'
  expect_reject "e: missing learnings"          "SCHEMA" 'del(.learnings)'
  expect_reject "e: bottlenecks wrong type"     "SCHEMA" '.bottlenecks = "slow"'
  expect_reject "e: next_steps empty string"    "SCHEMA" '.next_steps = [" "]'
  expect_reject "e: links no longer allowed"    "SCHEMA" '.links = []'
  expect_reject "e: touched_paths no longer allowed" "SCHEMA" '.touched_paths = []'
  expect_reject "e: outcome no longer allowed"  "SCHEMA" '.outcome = "x"'
  expect_reject "e: multi-line title"           "SCHEMA" '.title = "a\nb"'
  # every LLM-written string is one line, so none can inject a heading or a fake figures line
  expect_reject "e: multi-line progress"        "SCHEMA" '.progress = "Done.\n## How I worked"'
  expect_reject "e: carriage return progress"   "SCHEMA" '.progress = "Done.\r- **Time:** session time 1m"'
  expect_reject "e: multi-line learning"        "SCHEMA" '.learnings[0] = "Keep it.\n## Resume"'
  expect_reject "e: multi-line bottleneck"      "SCHEMA" '.bottlenecks[0] = "Slow.\n# x"'
  expect_reject "e: multi-line next step"       "SCHEMA" '.next_steps[0] = "Run it.\n## Links"'
  expect_reject "e: unicode line separator"     "SCHEMA" '.progress = "Done.\u2028## Resume"'
  local dir="$TMP/e-noid"
  check "e: unset CLAUDE_CODE_SESSION_ID fails loudly" '! run_note "$dir" "-" "$VALID" && [ "$(md_count "$dir")" = 0 ] && grep -q CLAUDE_CODE_SESSION_ID "$TMP/err"'
  check "e: malformed session id rejected" '! run_note "$TMP/e-badid" "../../../etc/x" "$VALID" && [ "$(md_count "$TMP/e-badid")" = 0 ]'
}

# --- (i) temp file cleanup and filename cap ------------------------------------

hidden_count() { find "$1" -maxdepth 1 -name '.session-note.*' | wc -l | tr -d ' '; }

test_files() {
  local dir="$TMP/i-long" f name
  mutate '.title = ("x" * 300)'
  if run_note "$dir" "$SID" "$TMP/case.json"; then f="$(cat "$TMP/out")"; name="$(basename "$f" " $TODAY.md")"
    check "i: 300-char title -> truncated filename (${#name})" '[ -f "$f" ] && [ "${#name}" -le 120 ]'
  else ko "i: 300-char title -> note written"; fi
  check "i: long title leaves no temp file" '[ "$(hidden_count "$dir")" = 0 ]'

  dir="$TMP/i-utf8"
  mutate '.title = ("\u00e9" * 150)'
  if run_note "$dir" "$SID" "$TMP/case.json"; then f="$(cat "$TMP/out")"; name="$(basename "$f" " $TODAY.md")"
    check "i: multibyte title cut at 120 bytes on a char boundary" \
      '[ "$(printf "%s" "$name" | wc -c | tr -d " ")" -le 120 ] && printf "%s" "$name" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1'
  else ko "i: multibyte title -> note written"; fi

  dir="$TMP/i-mvfail"; mkdir -p "$TMP/failbin"
  printf '#!/bin/sh\nexit 1\n' >"$TMP/failbin/mv"; chmod +x "$TMP/failbin/mv"
  check "i: failed mv leaves no temp file" '! EXTRA_PATH="$TMP/failbin" run_note "$dir" "$SID" "$VALID" && [ "$(hidden_count "$dir")" = 0 ] && [ "$(md_count "$dir")" = 0 ]'

  dir="$TMP/i-trav"
  mutate '.title = "../../evil"'
  check "i: traversal title stays in note dir" 'run_note "$dir" "$SID" "$TMP/case.json" && [ "$(md_count "$dir")" = 1 ] && [ "$(dirname "$(cat "$TMP/out")")" = "$dir" ] && [ -z "$(find "$TMP" -maxdepth 2 -name "evil*")" ]'
}

# --- (j) environment and upsert hardening -------------------------------------

test_env() {
  mkdir -p "$TMP/nojq"
  local f; for f in /bin/* /usr/bin/*; do [ "$(basename "$f")" = jq ] || ln -sf "$f" "$TMP/nojq/" 2>/dev/null || true; done
  local rc
  ONLY_PATH="$TMP/nojq" run_note "$TMP/j-nojq" "$SID" "$VALID" && rc=0 || rc=$?
  check "j: missing jq -> 'jq required', exit 1 (rc=$rc)" '[ "$rc" = 1 ] && grep -q "jq required" "$TMP/err"'

  local dir="$TMP/j-src"; mkdir -p "$dir"
  printf '%s\n' '---' "id: $SID" 'source: other-tool' '---' 'keep me' >"$dir/foreign.md"
  check "j: upsert ignores same id with other source" 'run_note "$dir" "$SID" "$VALID" && [ "$(cat "$TMP/out")" != "$dir/foreign.md" ] && grep -q "keep me" "$dir/foreign.md"'

  dir="$TMP/j-clash"
  run_note "$dir" "$SID" "$VALID" || true
  check "j: name clash suffix is full session id" 'run_note "$dir" "$SID2" "$VALID" && [ "$(basename "$(cat "$TMP/out")")" = "Widget pipeline spike (personal tooling) $TODAY $SID2.md" ]'
  mutate '.learnings += ["see docs/ALongDirectoryNameThatHasCapitalsInItAndMoreTextHere/x.md"]'
  check "j: long path segments not a base64 token" 'run_note "$TMP/j-longseg" "$SID" "$TMP/case.json"'
  expect_reject "j: sha256 still a token" "token" '.progress = "digest e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"'
}

# --- (l) digest.sh: selection by entry timestamp, exclusions, figures ----------

test_digest_selection() {
  check "l: digest exit 0" 'run_digest "$DAY"'
  local ids; ids="$(jq -r '[.sessions[].session_id] | join(",")' "$TMP/digest.json")"
  check "l: selects exactly the two sessions active that local day, ordered by first entry (got $ids)" '[ "$ids" = "$SID_A,$SID_B" ]'
  check "l: date echoed" '[ "$(jq -r .date "$TMP/digest.json")" = "$DAY" ]'
  check "l: project folder kept for the LLM" '[ "$(jq -r ".sessions[0].project" "$TMP/digest.json")" = "-Users-x-Work-alpha" ]'
  check "l: UTC 23:10 on the day before counts as local 00:10" '[ "$(jq -r ".sessions[0].first" "$TMP/digest.json")" = "00:10" ]'
  check "l: last local time" '[ "$(jq -r ".sessions[0].last" "$TMP/digest.json")" = "09:31" ]'
  check "l: prompts of that day only, commands named, meta and tool results skipped" \
    '[ "$(jq -c ".sessions[0].prompts" "$TMP/digest.json")" = "[\"Fix the flaky date test\",\"looks good, commit\",\"next task\",\"/dod:verify\"]" ]'
  check "l: text-block prompt counted" '[ "$(jq -c ".sessions[1].prompts" "$TMP/digest.json")" = "[\"Draft the doc\",\"publish it\"]" ]'
  check "l: assistant tail" '[ "$(jq -c ".sessions[0].assistant_tail" "$TMP/digest.json")" = "[\"Found the timezone bug.\",\"Commit was rejected; waiting.\",\"Done next.\",\"Verified.\"]" ]'
  check "l: commit messages from -m and heredoc" '[ "$(jq -c ".sessions[0].commits" "$TMP/digest.json")" = "[\"fix: flaky date test\",\"feat: add parser\"]" ]'
  check "l: sidechain entries ignored" '! grep -q "sidechain noise" "$TMP/digest.json"'

  SELF="00000000-0000-0000-0000-000000000000" run_digest "$DAY" || true
  check "l: running session is excluded only when it is CLAUDE_CODE_SESSION_ID" \
    '[ "$(jq -r "[.sessions[].session_id] | index(\"$SID_SELF\") != null" "$TMP/digest.json")" = true ]'

  run_digest "2026-11-05" || true
  check "l: the day before holds only sessions with entries on it" \
    '[ "$(jq -r "[.sessions[].session_id] | sort | join(\",\")" "$TMP/digest.json")" = "$SID_A,cccccccc-0000-4000-8000-000000000003" ]'
  run_digest "2026-11-07" || true
  check "l: UTC 23:05 counts for the next local day" '[ "$(jq -r "[.sessions[].session_id] | join(\",\")" "$TMP/digest.json")" = "$SID_A" ]'
  run_digest "2026-11-04" || true
  check "l: empty day -> zero sessions, zero figures" '[ "$(jq -c "[(.sessions|length), .day.sessions, .day.session_min]" "$TMP/digest.json")" = "[0,0,0]" ]'
  check "l: bad date -> exit 2" '! run_digest "06.11.2026" && grep -q "YYYY-MM-DD" "$TMP/err"'
}

test_digest_figures() {
  run_digest "$DAY" || true
  local a b d
  a="$(jq -c '.sessions[0] | [.session_min, .waiting_min, .my_messages, .permission_denials]' "$TMP/digest.json")"
  b="$(jq -c '.sessions[1] | [.session_min, .waiting_min, .my_messages, .permission_denials]' "$TMP/digest.json")"
  d="$(jq -c '.day | [.sessions, .session_min, .waiting_min, .my_messages, .permission_denials]' "$TMP/digest.json")"
  check "m: session A figures: gaps over 30 min skipped, wait = turn end -> my next message (got $a)" '[ "$a" = "[44,25,4,1]" ]'
  check "m: session B figures: rule denial counted (got $b)" '[ "$b" = "[20,5,2,1]" ]'
  check "m: day figures: parallel time counted once (got $d)" '[ "$d" = "[2,44,25,6,2]" ]'

  run_digest "2026-11-02" || true
  local c; c="$(jq -c '.sessions[0] | [.my_messages, .waiting_min]' "$TMP/digest.json")"
  check "m: compaction summary is not my message (got $c)" '[ "$c" = "[1,0]" ]'
  check "m: compaction summary not in prompts" '[ "$(jq -c ".sessions[0].prompts" "$TMP/digest.json")" = "[\"Plan the export\"]" ]'
}

test_digest_default_date() {
  NOW="$(TZ=UTC date -j -f '%Y-%m-%dT%H:%M:%S' '2026-11-07T04:30:00' +%s)" run_digest || true
  check "n: before 06:00 local defaults to yesterday" '[ "$(jq -r .date "$TMP/digest.json")" = "2026-11-06" ]'
  NOW="$(TZ=UTC date -j -f '%Y-%m-%dT%H:%M:%S' '2026-11-07T05:30:00' +%s)" run_digest || true
  check "n: from 06:00 local defaults to today" '[ "$(jq -r .date "$TMP/digest.json")" = "2026-11-07" ]'
}

# --- (o) note.sh --daily ---------------------------------------------------------

test_daily_note() {
  local dir="$TMP/o" f
  if run_note "$dir" "$SID_SELF" --daily "$DAY" "$DAILY_FACTS"; then ok "o: daily exit 0"; else ko "o: daily exit 0"; return; fi
  f="$(cat "$TMP/out")"
  check "o: file name 'claude sessions <date>.md'" '[ "$f" = "$dir/claude sessions $DAY.md" ] && [ -f "$f" ]'
  check "o: frontmatter is source + created only" '[ "$(frontmatter "$f")" = "$(printf "%s\n" "source: claude-session" "created: $DAY")" ]'
  local heads; heads="$(grep -E '^#{1,2} ' "$f" | tr '\n' '|')"
  check "o: headings (got $heads)" '[ "$heads" = "# Claude sessions $DAY|## Flaky date test (work)|## Design doc draft (personal tooling)|## How I worked|" ]'
  check "o: per-session sections" 'grep -qxF -- "- **Progress:** Fixed a timezone assumption and added a regression test." "$f" && grep -qxF -- "  - Pin the timezone in tests that touch dates." "$f" && grep -qxF -- "  - The first commit attempt was rejected." "$f" && grep -qxF -- "  1. Watch the next pipeline run" "$f"'
  check "o: session time line from digest" 'grep -qxF -- "- **Time:** 00:10 to 09:31 · session time 44m · waiting on me 25m · my messages 4 · permission denials 1" "$f"'
  check "o: day figures from digest" 'grep -qxF -- "- **Sessions:** 2" "$f" && grep -qxF -- "- **Time:** session time 44m · waiting on me 25m · my messages 6 · permission denials 2" "$f"'
  check "o: blockers and automate with one rec each" 'grep -qxF -- "  - A cleanup command was blocked by a deny rule. **Rec:** Add a narrow allow rule for build folder cleanup." "$f" && grep -qxF -- "  - I ran the verify command by hand after each fix. **Rec:** Let the agent run verify before reporting done." "$f"'
  check "o: no session ids or project folders rendered" '! grep -qE "aaaaaaaa|bbbbbbbb|Work-alpha|Work-beta" "$f"'
  check "o: written note passes the re-check" 'run_note "$dir" - --recheck "$f"'

  mutate_daily '.sessions[1].progress = "Second run."'
  run_note "$dir" "$SID_SELF" --daily "$DAY" "$TMP/case.json" || true
  check "o: rerun overwrites the same file" '[ "$(md_count "$dir")" = 1 ] && grep -q "Second run." "$dir/claude sessions $DAY.md"'

  mutate_daily '.sessions[0].session_ids += ["bbbbbbbb-0000-4000-8000-000000000002"] | .sessions |= [.[0]]'
  run_note "$TMP/o-group" "$SID_SELF" --daily "$DAY" "$TMP/case.json" || true
  check "o: grouped sessions add up their figures" 'grep -qxF -- "- **Time:** 00:10 to 09:31 · session time 1h 04m · waiting on me 30m · my messages 6 · permission denials 2" "$(cat "$TMP/out")"'

  local dry="$TMP/o-dry"
  check "o: --dry-run checks and prints, writes nothing" 'run_note "$dry" "$SID_SELF" --dry-run --daily "$DAY" "$DAILY_FACTS" && [ "$(md_count "$dry")" = 0 ] && grep -qF "## How I worked" "$TMP/out"'
  mutate_daily '.sessions[0].title = "billing fix"'
  check "o: --dry-run still rejects a leak" '! run_note "$dry" "$SID_SELF" --dry-run --daily "$DAY" "$TMP/case.json" && grep -q "work repo name" "$TMP/err"'

  local guard="$TMP/o-guard"; mkdir -p "$guard"
  printf '%s\n' '---' "id: $SID" 'source: claude-session' '---' 'single note' >"$guard/claude sessions $DAY.md"
  check "o: never overwrites a single-session note with the daily name" '! run_note "$guard" "$SID_SELF" --daily "$DAY" "$DAILY_FACTS" && grep -q "single note" "$guard/claude sessions $DAY.md"'
}

test_daily_schema() {
  expect_daily_reject "p: unknown session id"            "SCHEMA" '.sessions[0].session_ids = ["cccccccc-0000-4000-8000-000000000003"]'
  expect_daily_reject "p: excluded headless session id"  "SCHEMA" '.sessions[0].session_ids = ["dddddddd-0000-4000-8000-000000000004"]'
  expect_daily_reject "p: session id used twice"         "SCHEMA" '.sessions[1].session_ids = ["aaaaaaaa-0000-4000-8000-000000000001"]'
  expect_daily_reject "p: malformed session id"          "SCHEMA" '.sessions[0].session_ids = ["not-a-uuid"]'
  expect_daily_reject "p: empty session_ids"             "SCHEMA" '.sessions[0].session_ids = []'
  expect_daily_reject "p: LLM cannot supply figures"     "SCHEMA" '.sessions[0].session_min = 5'
  expect_daily_reject "p: LLM cannot supply day figures" "SCHEMA" '.how_i_worked.figures = "session time 9h"'
  expect_daily_reject "p: blocker without rec"           "SCHEMA" '.how_i_worked.blockers[0] |= del(.rec)'
  expect_daily_reject "p: automate wrong type"           "SCHEMA" '.how_i_worked.automate = "x"'
  expect_daily_reject "p: missing how_i_worked"          "SCHEMA" 'del(.how_i_worked)'
  expect_daily_reject "p: bad status"                    "SCHEMA" '.sessions[0].status = "wip"'
  expect_daily_reject "p: multi-line session progress"   "SCHEMA" '.sessions[0].progress = "Done.\n## How I worked"'
  expect_daily_reject "p: multi-line session learning"   "SCHEMA" '.sessions[1].learnings = ["a\nb"]'
  expect_daily_reject "p: multi-line blocker what"       "SCHEMA" '.how_i_worked.blockers[0].what = "Blocked.\n## How I worked"'
  expect_daily_reject "p: multi-line automate rec"       "SCHEMA" '.how_i_worked.automate[0].rec = "Do it.\n- **Sessions:** 9"'
  expect_daily_reject "p: leak in a session field"       "ticket key" '.sessions[1].learnings = ["Track it in PROJ-9"]'
  expect_daily_reject "p: leak in a blocker"             "work repo name" '.how_i_worked.blockers[0].what = "acme-portal deploy hung"'
  expect_daily_reject "p: figure in a rec"               "metric"  '.how_i_worked.automate[0].rec = "Saves 40 minutes a day"'
  local rc
  run_note "$TMP/p-date" "$SID_SELF" --daily "2026-13-45" "$DAILY_FACTS" && rc=0 || rc=$?
  check "p: invalid date -> exit 2" '[ "$rc" = 2 ]'
}

test_recheck() {
  local dir="$TMP/q" f
  run_note "$dir" "$SID_SELF" --daily "$DAY" "$DAILY_FACTS" || true
  f="$(cat "$TMP/out")"
  sed 's/^- \*\*Sessions:\*\* 2$/- **Sessions:** 2 at acme-portal/' "$f" >"$TMP/q1.md"
  check "q: text smuggled into a figures line is gated" '! run_note "$dir" - --recheck "$TMP/q1.md" && grep -q "work repo name" "$TMP/err"'
  sed 's/^- \*\*Progress:\*\* Drafted the doc.$/- **Progress:** Drafted 12 docs./' "$f" >"$TMP/q2.md"
  check "q: figure in prose is rejected" '! run_note "$dir" - --recheck "$TMP/q2.md" && grep -q "metric" "$TMP/err"'
  printf '%s\n' '---' 'source: claude-session' 'created: 2026-11-06' 'repo: billing' '---' '# x' >"$TMP/q3.md"
  check "q: unexpected frontmatter is gated" '! run_note "$dir" - --recheck "$TMP/q3.md"'
  run_note "$TMP/q-single" "$SID" "$VALID" || true
  check "q: single-session note passes the re-check" 'run_note "$dir" - --recheck "$(cat "$TMP/out")"'
}

# --- (r) daily.sh: launchd wrapper, stubbed claude and osascript ----------------

setup_daily_stubs() {
  mkdir -p "$TMP/stubbin"
  # osascript stub: records its arguments.
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >>"%s/osascript.calls"\n' "$TMP" >"$TMP/stubbin/osascript"
  # claude stub: copies $STUB_FACTS to the facts path named in the prompt, like the real run would.
  cat >"$TMP/stubbin/claude" <<'EOF'
#!/usr/bin/env bash
prompt="$2"
facts="$(printf '%s' "$prompt" | grep -oE '/[^ ]*/facts\.json' | head -1)"
day="$(printf '%s' "$prompt" | grep -oE 'daily mode for [0-9]{4}-[0-9]{2}-[0-9]{2}' | grep -oE '[0-9-]{10}$')"
printf '%s\n' "$*" >"$STUB_ARGS"
printf '%s\n' "$day" >>"$STUB_ARGS.days"
[ -n "${STUB_FAIL:-}" ] && exit 7
# STUB_FACTS_DIR/<date>.json wins over STUB_FACTS, so a catch-up run can get facts for each day
if [ -n "${STUB_FACTS_DIR:-}" ] && [ -f "$STUB_FACTS_DIR/$day.json" ]; then cp "$STUB_FACTS_DIR/$day.json" "$facts"
else cp "$STUB_FACTS" "$facts"; fi
echo '{"result":"ok"}'
EOF
  chmod +x "$TMP/stubbin/osascript" "$TMP/stubbin/claude"
}

# run_daily <outdir> [date]; raw dir is $RAW (default an empty temp dir); returns exit code
run_daily() {
  local dir="$1"; shift
  mkdir -p "$dir" "${RAW:-$TMP/raw-empty}"
  (
    export PATH="$TMP/stubbin:$PATH" SESSION_NOTE_DIR="$dir" CLAUDE_PROJECTS_DIR="$TMP/projects" \
      SESSION_NOTE_RAW_DIR="${RAW:-$TMP/raw-empty}" \
      SESSION_NOTE_DENYLIST="$TMP/denylist.txt" SESSION_NOTE_WORK_ROOT="$TMP/work-root" \
      SESSION_NOTE_LOG="$TMP/daily.log" STUB_ARGS="$TMP/claude.args" STUB_FACTS="${STUB_FACTS:-$DAILY_FACTS}"
    [ -z "${NOW:-}" ] || export SESSION_NOTE_NOW="$NOW"
    unset CLAUDE_CODE_SESSION_ID
    bash "$DAILY" "$@"
  ) >"$TMP/out" 2>"$TMP/err"
}

test_daily_wrapper() {
  setup_daily_stubs
  local dir="$TMP/r-ok"
  rm -f "$TMP/osascript.calls"
  check "r: wrapper writes the note" 'run_daily "$dir" "$DAY" && [ -f "$dir/claude sessions $DAY.md" ]'
  check "r: logs success" 'tail -1 "$TMP/daily.log" | grep -q "ok .*claude sessions $DAY.md"'
  check "r: no notification on success" '[ ! -e "$TMP/osascript.calls" ]'
  check "r: claude runs on sonnet, no session persistence, restricted tools" \
    'grep -q -- "--model sonnet" "$TMP/claude.args" && grep -q -- "--no-session-persistence" "$TMP/claude.args" && grep -q -- "--tools Bash,Read,Write,Edit" "$TMP/claude.args" && grep -q -- "--permission-mode dontAsk" "$TMP/claude.args"'
  check "r: claude may only dry-run note.sh" 'grep -qF -- "note.sh --dry-run" "$TMP/claude.args" && ! grep -qE "Bash\(bash [^)]*note\.sh \*\)" "$TMP/claude.args"'

  jq '.sessions[0].title = "acme-portal fix (work)"' "$DAILY_FACTS" >"$TMP/leak.json"
  dir="$TMP/r-leak"
  check "r: planted leak -> non-zero" '! STUB_FACTS="$TMP/leak.json" run_daily "$dir" "$DAY"'
  check "r: planted leak -> nothing written" '[ "$(md_count "$dir")" = 0 ]'
  check "r: planted leak -> logged" 'tail -5 "$TMP/daily.log" | grep -q "FAIL" && grep -q "work repo name" "$TMP/daily.log"'
  check "r: planted leak -> notification" 'grep -q "display notification" "$TMP/osascript.calls"'
  check "r: notification carries no note text" '! grep -q "acme-portal" "$TMP/osascript.calls"'

  rm -f "$TMP/osascript.calls"
  check "r: claude failure -> non-zero and notification" '! STUB_FAIL=1 run_daily "$TMP/r-fail" "$DAY" && grep -q "display notification" "$TMP/osascript.calls" && [ "$(md_count "$TMP/r-fail")" = 0 ]'
  rm -f "$TMP/osascript.calls" "$TMP/claude.args"
  check "r: day without sessions -> no claude call, nothing written, exit 0" 'run_daily "$TMP/r-empty" "2026-11-04" && [ ! -e "$TMP/claude.args" ] && [ "$(md_count "$TMP/r-empty")" = 0 ] && [ ! -e "$TMP/osascript.calls" ]'
}

# --- (s) daily.sh catch-up: a missed evening run is summarised on the next run ---

test_daily_catchup() {
  local next="2026-11-07" late days
  late="$(TZ=UTC date -j -f '%Y-%m-%dT%H:%M:%S' '2026-11-07T22:00:00' +%s)"   # 23:00 Berlin on the 7th
  mkdir -p "$TMP/stubfacts"
  cp "$DAILY_FACTS" "$TMP/stubfacts/$DAY.json"
  jq '.sessions |= [.[0]]' "$DAILY_FACTS" >"$TMP/stubfacts/$next.json"   # only session A is active on the 7th

  local dir="$TMP/s-missed"; rm -f "$TMP/claude.args.days"
  check "s: yesterday missing from inbox and raw -> exit 0" 'NOW="$late" STUB_FACTS_DIR="$TMP/stubfacts" run_daily "$dir"'
  days="$(tr '\n' ',' <"$TMP/claude.args.days" 2>/dev/null || true)"
  check "s: yesterday summarised first, then today (got $days)" '[ "$days" = "$DAY,$next," ]'
  check "s: both notes written" '[ -f "$dir/claude sessions $DAY.md" ] && [ -f "$dir/claude sessions $next.md" ] && [ "$(md_count "$dir")" = 2 ]'

  local raw="$TMP/s-raw"; dir="$TMP/s-inraw"; mkdir -p "$raw"; rm -f "$TMP/claude.args.days"
  printf '%s\n' '---' 'source: claude-session' "created: $DAY" '---' 'processed' >"$raw/claude sessions $DAY.md"
  check "s: yesterday already in raw -> exit 0" 'RAW="$raw" NOW="$late" STUB_FACTS_DIR="$TMP/stubfacts" run_daily "$dir"'
  check "s: yesterday in raw is not regenerated" '[ "$(cat "$TMP/claude.args.days")" = "$next" ] && [ ! -e "$dir/claude sessions $DAY.md" ] && grep -qx processed "$raw/claude sessions $DAY.md"'

  dir="$TMP/s-ininbox"; mkdir -p "$dir"; rm -f "$TMP/claude.args.days"
  printf '%s\n' '---' 'source: claude-session' "created: $DAY" '---' 'kept' >"$dir/claude sessions $DAY.md"
  NOW="$late" STUB_FACTS_DIR="$TMP/stubfacts" run_daily "$dir" || true
  check "s: yesterday in inbox is not regenerated" '[ "$(cat "$TMP/claude.args.days")" = "$next" ] && grep -qx kept "$dir/claude sessions $DAY.md" && [ -f "$dir/claude sessions $next.md" ]'

  dir="$TMP/s-explicit"; rm -f "$TMP/claude.args.days"
  STUB_FACTS_DIR="$TMP/stubfacts" run_daily "$dir" "$next" || true
  check "s: an explicit date runs that day only" '[ "$(cat "$TMP/claude.args.days")" = "$next" ] && [ "$(md_count "$dir")" = 1 ]'

  dir="$TMP/s-fail"; rm -f "$TMP/osascript.calls" "$TMP/claude.args.days"
  jq '.sessions[0].title = "acme-portal fix (work)"' "$DAILY_FACTS" >"$TMP/stubfacts/$DAY.json"
  local rc; NOW="$late" STUB_FACTS_DIR="$TMP/stubfacts" run_daily "$dir" && rc=0 || rc=$?
  check "s: failed catch-up -> exit 1, notification for that day" '[ "$rc" = 1 ] && grep -q "display notification.*$DAY" "$TMP/osascript.calls"'
  check "s: failed catch-up still writes today" '[ ! -e "$dir/claude sessions $DAY.md" ] && [ -f "$dir/claude sessions $next.md" ]'
}

# --- main -------------------------------------------------------------------

main() {
  setup_work_root
  setup_transcripts
  test_valid_note
  test_upsert
  test_redaction
  test_work_identifiers
  test_schema
  test_allowed
  test_figures
  test_secrets
  test_files
  test_env
  test_digest_selection
  test_digest_figures
  test_digest_default_date
  test_daily_note
  test_daily_schema
  test_recheck
  test_daily_wrapper
  test_daily_catchup
  echo "---"
  echo "passed: $PASS  failed: $FAIL"
  [ "$FAIL" = 0 ]
}

main "$@"
