#!/usr/bin/env bats
# Tests for bin/uskn-loop (spec: loop-run, loop-criteria, loop-progress-comment).
# Each test builds a bare origin and a clone under $BATS_TEST_TMPDIR. origin's configured URL is a GitHub (or GitLab)
# URL that git rewrites to the bare repository through url.<path>.insteadOf, so the loop sees a real host while every
# fetch and push stays local. Fake claude, gh, glab, and openspec from fixtures/loop-bin come first on PATH.

REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
CLI="$REPO/bin/uskn-loop"
FAKES="$BATS_TEST_DIRNAME/fixtures/loop-bin"

setup() {
  T="$BATS_TEST_TMPDIR"
  export FAKE_DIR="$T/fake"
  mkdir -p "$FAKE_DIR"
  export XDG_STATE_HOME="$T/state"
  unset USKN_STATE_DIR
  export GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1
  : > "$GIT_CONFIG_GLOBAL"
  git config --global init.defaultBranch main
  git config --global user.name tester
  git config --global user.email tester@example.com
  export PATH="$FAKES:$PATH"
  CLONE="$T/clone"
  STATE="$T/state/uskn-harness/loop/github.com/acme/app/12"
  WT="$CLONE/.claude/worktrees/loop-pr-12"
}

# make_repo [github|gitlab]: origin with main (a Makefile whose verify prints verify-raw-output and fails while
# .fail-verify exists, and one test),
# the PR branch change/add-x that adds the change add-x with an open task, and the clone on main.
make_repo() {
  local host="${1:-github}" seed="$T/seed" url
  case "$host" in
    github) url="https://github.com/acme/app.git" ;;
    gitlab) url="https://gitlab.com/acme/app.git"
            STATE="$T/state/uskn-harness/loop/gitlab.com/acme/app/12" ;;
  esac
  git init -q --bare "$T/origin.git"
  git config --global "url.$T/origin.git.insteadOf" "$url"
  git init -q "$seed"
  printf 'verify:\n\t@echo verify-raw-output\n\t@test ! -f .fail-verify\n' > "$seed/Makefile"
  mkdir -p "$seed/tests" && printf '@test "a" { true; }\n' > "$seed/tests/a.bats"
  git -C "$seed" add -A && git -C "$seed" commit -qm base
  git -C "$seed" remote add origin "$url"
  git -C "$seed" push -q origin main
  git -C "$seed" switch -qc change/add-x
  add_change "$seed" add-x
  git -C "$seed" push -q origin change/add-x
  git clone -q "$url" "$CLONE"
  fake_pr
}

# add_change <dir> <name>: commit a complete change with one open task.
add_change() {
  local d="$1/openspec/changes/$2"
  mkdir -p "$d/specs/x"
  echo "# grilling" > "$d/grilling.md"
  echo "# proposal" > "$d/proposal.md"
  printf '## ADDED Requirements\n\n### Requirement: x\n\n#### Scenario: s\n- **WHEN** a\n- **THEN** b\n' > "$d/specs/x/spec.md"
  printf '## 1. Work\n\n- [ ] 1.1 do it\n' > "$d/tasks.md"
  git -C "$1" add -A && git -C "$1" commit -qm "$2"
}

# fake_pr [key=value ...]: the PR (GitHub shape) and the MR (GitLab shape) the fakes serve.
# Keys: state (open), draft (true), fork (false), author (me), conflict (false).
fake_pr() {
  local state=open draft=true fork=false author=me conflict=false kv
  for kv in "$@"; do eval "${kv%%=*}=\${kv#*=}"; done
  jq -n --arg s "$state" --argjson d "$draft" --argjson f "$fork" --arg a "$author" --argjson c "$conflict" '{
    state: ($s | ascii_upcase), isDraft: $d, isCrossRepository: $f, author: {login: $a},
    headRefName: "change/add-x", baseRefName: "main", mergeable: (if $c then "CONFLICTING" else "MERGEABLE" end),
    url: "https://github.com/acme/app/pull/12"}' > "$FAKE_DIR/gh-pr.json"
  jq -n --arg s "$state" --argjson d "$draft" --argjson f "$fork" --arg a "$author" --argjson c "$conflict" '{
    state: (if $s == "open" then "opened" else $s end), draft: $d,
    source_project_id: (if $f then 2 else 1 end), target_project_id: 1, author: {username: $a},
    source_branch: "change/add-x", target_branch: "main", has_conflicts: $c,
    web_url: "https://gitlab.com/acme/app/-/merge_requests/12"}' > "$FAKE_DIR/glab-mr.json"
}

# step <k> <bash>: what the k-th claude call does in its working directory.
step() { printf '%s\n' "$2" > "$FAKE_DIR/claude.$1.sh"; }
# cost <k> <usd>: the total_cost_usd the k-th claude call reports.
cost() { echo "$2" > "$FAKE_DIR/claude.$1.cost"; }
# finish_tasks: a step body that checks every task and commits it.
finish_tasks='sed -i "s/- \[ \]/- [x]/" openspec/changes/add-x/tasks.md && git commit -qam "tasks done"'
# verdict <k> <pass|fail> [blocking-file ...] [?question]: the k-th claude call returns this verdict. Each file becomes
# one blocking finding; an argument starting with ? becomes the question.
verdict() {
  local k="$1" v="$2" q="" a findings="[]"
  shift 2
  for a in "$@"; do
    case "$a" in
      \?*) q="${a#\?}" ;;
      *) findings="$(jq -c --arg f "$a" '. + [{severity: "blocking", file: $f, line: 1, summary: ("fix " + $f), evidence: "e"}]' <<< "$findings")" ;;
    esac
  done
  jq -n --arg v "$v" --arg q "$q" --argjson fs "$findings" \
    '{verdict: $v, scenarios: [{scenario: "s", tests: ["tests/a.bats"], status: $v}], findings: $fs, question: $q}' \
    > "$FAKE_DIR/claude.$k.verdict"
}
loop() { (cd "$CLONE" && "$CLI" run "$@"); }
comments() { cat "$FAKE_DIR"/comments/*.body 2>/dev/null; }
ncomments() { find "$FAKE_DIR/comments" -name '*.body' 2>/dev/null | wc -l | tr -d ' '; }

@test "uskn-loop with no arguments shows the usage and exits 2" {
  run "$CLI"
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage: uskn-loop run"* ]]
}

@test "an unknown subcommand shows the usage and exits 2" {
  run "$CLI" watch 12
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage: uskn-loop run"* ]]
}

# ---- limits (task 1.3) -------------------------------------------------------------------------------------------

@test "the limits come from loop/limits.env" {
  LOOP_DIR="$REPO/loop"
  . "$REPO/loop/lib/util.sh"
  load_limits
  [ "$ROUNDS" = 5 ] && [ "$PR_BUDGET_USD" = 40 ]
  [ "$IMPL_BUDGET_USD" = 10 ] && [ "$IMPL_MINUTES" = 60 ]
  [ "$AUDIT_BUDGET_USD" = 3 ] && [ "$AUDIT_MINUTES" = 20 ]
  [ "$VERIFY_MINUTES" = 30 ]
}

@test "USKN_LOOP_<NAME> overrides a limit" {
  LOOP_DIR="$REPO/loop"
  . "$REPO/loop/lib/util.sh"
  USKN_LOOP_ROUNDS=2 USKN_LOOP_PR_BUDGET_USD=7.5 load_limits
  [ "$ROUNDS" = 2 ] && [ "$PR_BUDGET_USD" = 7.5 ] && [ "$IMPL_BUDGET_USD" = 10 ]
}

# ---- host and acceptance (tasks 2.1-2.3) ---------------------------------------------------------------------------

@test "a GitHub clone reads the PR with gh" {
  make_repo github
  fake_pr state=closed
  run loop 12
  [ "$status" -eq 2 ]
  grep -q '^pr view 12 --repo github.com/acme/app' "$FAKE_DIR/gh.log"
  [ ! -e "$FAKE_DIR/glab.log" ]
}

@test "a GitLab clone reads the MR with glab" {
  make_repo gitlab
  fake_pr state=closed
  run loop 12
  [ "$status" -eq 2 ]
  grep -q 'projects/acme%2Fapp/merge_requests/12' "$FAKE_DIR/glab.log"
  [ ! -e "$FAKE_DIR/gh.log" ]
}

@test "a PR URL works as the reference" {
  make_repo github
  fake_pr state=closed
  run loop https://github.com/acme/app/pull/12
  [ "$status" -eq 2 ]
  grep -q '^pr view 12 ' "$FAKE_DIR/gh.log"
}

@test "an origin that is neither GitHub nor GitLab is refused" {
  make_repo github
  git -C "$CLONE" remote set-url origin https://example.org/acme/app.git
  run loop 12
  [ "$status" -eq 2 ]
  [[ "$output" == *"neither a GitHub nor a GitLab"* ]]
}

@test "outside a clone the loop refuses and creates nothing" {
  run bash -c "cd '$T' && '$CLI' run 12"
  [ "$status" -eq 2 ]
  [[ "$output" == *"not inside a git clone"* ]]
  [ ! -e "$T/state/uskn-harness/loop" ]
}

@test "a closed PR is not accepted: no worktree, no comment" {
  make_repo github
  fake_pr state=closed
  run loop 12
  [ "$status" -eq 2 ]
  [[ "$output" == *"not open (state: closed)"* ]]
  [ ! -e "$WT" ] && [ "$(ncomments)" = 0 ]
}

@test "a PR from a fork is not accepted" {
  make_repo github
  fake_pr fork=true
  run loop 12
  [ "$status" -eq 2 ]
  [[ "$output" == *"fork"* ]]
  [ ! -e "$WT" ] && [ "$(ncomments)" = 0 ]
}

@test "someone else's PR is not accepted and gets no comment" {
  make_repo github
  fake_pr author=someone
  run loop 12
  [ "$status" -eq 2 ]
  [[ "$output" == *"its author is someone, not me"* ]]
  [ ! -e "$WT" ] && [ "$(ncomments)" = 0 ]
  [ ! -e "$FAKE_DIR/claude.count" ]
}

@test "a PR that adds two changes is not accepted and both names are reported" {
  make_repo github
  git -C "$T/seed" switch -q change/add-x
  add_change "$T/seed" add-y
  git -C "$T/seed" push -q origin change/add-x
  run loop 12
  [ "$status" -eq 2 ]
  [[ "$output" == *"2 changes: add-x, add-y"* ]]
  [ ! -e "$WT" ] && [ "$(ncomments)" = 0 ]
}

@test "a change without tasks.md is not accepted" {
  make_repo github
  git -C "$T/seed" switch -q change/add-x
  git -C "$T/seed" rm -q openspec/changes/add-x/tasks.md && git -C "$T/seed" commit -qm "no tasks"
  git -C "$T/seed" push -q origin change/add-x
  run loop 12
  [ "$status" -eq 2 ]
  [[ "$output" == *"the change add-x lacks: tasks.md"* ]]
}

@test "a repository without a verify convention is not accepted" {
  make_repo github
  git -C "$T/seed" switch -q change/add-x
  printf 'build:\n\ttrue\n' > "$T/seed/Makefile" && git -C "$T/seed" commit -qam "no verify"
  git -C "$T/seed" push -q origin change/add-x
  run loop 12
  [ "$status" -eq 2 ]
  [[ "$output" == *"no verify convention"* ]]
  [ ! -e "$WT" ]
}

# ---- worktree and state (tasks 3.1-3.2) ----------------------------------------------------------------------------

@test "the loop works in .claude/worktrees/loop-pr-12 and leaves the clone's tree and branch alone" {
  make_repo github
  echo local > "$CLONE/local.txt"
  echo "# local" >> "$CLONE/Makefile"
  before="$(git -C "$CLONE" status --porcelain)"
  step 1 "$finish_tasks"
  verdict 2 pass "?which status code?"
  run loop 12
  [ "$status" -eq 3 ]
  [ "$(cat "$FAKE_DIR/claude.1.cwd")" = "$WT" ]
  [ "$(git -C "$CLONE" status --porcelain)" = "$before" ]
  [ "$(git -C "$CLONE" branch --show-current)" = main ]
  grep -qx '.claude/worktrees/' "$CLONE/.git/info/exclude"
}

@test "a second run reuses the worktree" {
  make_repo github
  step 1 'echo one > one.txt && git add one.txt && git commit -qm one'
  USKN_LOOP_ROUNDS=1 run loop 12
  [ "$status" -eq 3 ]
  step 2 "test -f one.txt && $finish_tasks"
  verdict 3 pass
  run loop 12
  [ "$status" -eq 0 ]
  [ "$(cat "$FAKE_DIR/claude.2.cwd")" = "$WT" ]
}

@test "a second loop on the same PR is refused while the first runs" {
  make_repo github
  mkdir -p "$STATE/lock"
  sleep 30 & echo $! > "$STATE/lock/pid"
  run loop 12
  kill "$(cat "$STATE/lock/pid")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"already running"* ]]
  [ ! -e "$FAKE_DIR/claude.count" ]
}

@test "after an interruption the loop continues the round count and the cost" {
  make_repo github
  cost 1 2
  step 2 "kill -9 \$(cat '$STATE/lock/pid')"
  run loop 12
  [ "$(jq .completed "$STATE/state.json")" = 1 ]
  step 3 "$finish_tasks"
  verdict 4 pass
  run loop 12
  [ "$status" -eq 0 ]
  [[ "$(cat "$FAKE_DIR/claude.3.prompt")" == "Continue the change add-x"* ]]
  [ "$(jq -c '[.rounds[].round]' "$STATE/state.json")" = "[1,2]" ]
  [ "$(jq .cost "$STATE/state.json")" = 4 ]
}

@test "--reset starts again from round 1" {
  make_repo github
  USKN_LOOP_ROUNDS=1 run loop 12
  [ "$status" -eq 3 ]
  step 2 "$finish_tasks"
  verdict 3 pass
  run loop 12 --reset
  [ "$status" -eq 0 ]
  [ "$(cat "$FAKE_DIR/claude.2.prompt")" = "/opsx:apply add-x" ]
}

# ---- rounds (tasks 4.1-4.5) ---------------------------------------------------------------------------------------

@test "the implementer runs unattended with its limits, and /opsx:apply in round 1" {
  make_repo github
  step 1 "$finish_tasks"
  verdict 2 pass
  run loop 12
  [ "$status" -eq 0 ]
  a="$(cat "$FAKE_DIR/claude.1.args")"
  [ "$(cat "$FAKE_DIR/claude.1.prompt")" = "/opsx:apply add-x" ]
  grep -qx -- '--permission-mode' <<< "$a" && grep -qx auto <<< "$a"
  grep -qx -- '--permission-prompts' <<< "$a" && grep -qx none <<< "$a"
  grep -qx -- '--max-budget-usd' <<< "$a" && grep -qx 10 <<< "$a"
  grep -qx "$REPO/loop/prompts/implementer.md" <<< "$a"
  ! grep -qx -- '--model' <<< "$a"
}

@test "round 2 tells the implementer the auditor's blocking findings" {
  make_repo github
  step 1 "$finish_tasks"
  verdict 2 fail src/a.ts
  verdict 4 pass
  run loop 12
  [ "$status" -eq 0 ]
  p="$(cat "$FAKE_DIR/claude.3.prompt")"
  [[ "$p" == *'`src/a.ts:1` fix src/a.ts'* ]]
}

@test "each round pushes its commits to the head branch before the audit, and nowhere else" {
  make_repo github
  step 1 "$finish_tasks"
  step 2 "git --git-dir='$T/origin.git' log --format=%s change/add-x | grep -qx 'tasks done' || touch '$FAKE_DIR/not-pushed'"
  verdict 2 pass
  run loop 12
  [ "$status" -eq 0 ]
  [ ! -e "$FAKE_DIR/not-pushed" ]
  [ "$(git --git-dir="$T/origin.git" for-each-ref --format='%(refname:short)' refs/heads | sort | paste -sd' ' -)" = "change/add-x main" ]
}

@test "a rejected push stops the loop" {
  make_repo github
  printf '#!/bin/sh\nexit 1\n' > "$T/origin.git/hooks/pre-receive" && chmod +x "$T/origin.git/hooks/pre-receive"
  step 1 "$finish_tasks"
  run loop 12
  [ "$status" -eq 3 ]
  [[ "$(comments)" == *"pushの拒否"* ]]
}

@test "sensor: an uncommitted change fails the round, is not pushed, and no audit runs" {
  make_repo github
  step 1 "$finish_tasks && echo x > loose.txt"
  USKN_LOOP_ROUNDS=1 run loop 12
  [ "$status" -eq 3 ]
  [ "$(cat "$FAKE_DIR/claude.count")" = 1 ]
  [ "$(jq -c '.rounds[0].failed' "$STATE/state.json")" = '["uncommitted"]' ]
  ! git --git-dir="$T/origin.git" cat-file -e change/add-x:loose.txt
}

@test "sensor: a failing verify fails the round and its output reaches the next implementer" {
  make_repo github
  step 1 "$finish_tasks && touch .fail-verify && git add .fail-verify && git commit -qm fail"
  USKN_LOOP_ROUNDS=2 run loop 12
  [ "$status" -eq 3 ]
  [ "$(jq -c '.rounds[0].failed' "$STATE/state.json")" = '["verify"]' ]
  [[ "$(cat "$FAKE_DIR/claude.2.prompt")" == *"### verify"*"verify-raw-output"* ]]
}

@test "sensor: openspec validate --strict failing fails the round" {
  make_repo github
  echo "spec broken" > "$FAKE_DIR/openspec-fail"
  step 1 "$finish_tasks"
  USKN_LOOP_ROUNDS=1 run loop 12
  [ "$status" -eq 3 ]
  [ "$(jq -c '.rounds[0].failed' "$STATE/state.json")" = '["openspec"]' ]
  grep -q '^validate add-x --strict' "$FAKE_DIR/openspec.log"
}

@test "sensor: an open task fails the round" {
  make_repo github
  USKN_LOOP_ROUNDS=1 run loop 12
  [ "$status" -eq 3 ]
  [ "$(jq -c '.rounds[0].failed' "$STATE/state.json")" = '["tasks"]' ]
  [[ "$(cat "$STATE/round-1/tasks.txt")" == *"- [ ] 1.1 do it"* ]]
}

@test "sensor: deleting a test file is a blocking failure" {
  make_repo github
  step 1 "$finish_tasks && git rm -q tests/a.bats && git commit -qm drop"
  USKN_LOOP_ROUNDS=1 run loop 12
  [ "$status" -eq 3 ]
  [ "$(jq -c '.rounds[0].failed' "$STATE/state.json")" = '["test-deletion"]' ]
  [ "$(cat "$STATE/round-1/test-deletion.txt")" = tests/a.bats ]
}

@test "sensor: a test deletion that tasks.md asks for passes" {
  make_repo github
  git -C "$T/seed" switch -q change/add-x
  printf -- '- [ ] 1.2 remove tests/a.bats\n' >> "$T/seed/openspec/changes/add-x/tasks.md"
  git -C "$T/seed" commit -qam "ask for it" && git -C "$T/seed" push -q origin change/add-x
  step 1 "$finish_tasks && git rm -q tests/a.bats && git commit -qm drop"
  verdict 2 pass
  run loop 12
  [ "$status" -eq 0 ]
}

@test "sensor: an added skip is a blocking failure" {
  make_repo github
  step 1 "$finish_tasks && printf '@test \"b\" {\n  skip\n}\n' >> tests/a.bats && git commit -qam skip"
  USKN_LOOP_ROUNDS=1 run loop 12
  [ "$status" -eq 3 ]
  [ "$(jq -c '.rounds[0].failed' "$STATE/state.json")" = '["skip-added"]' ]
}

@test "sensor: a changed verify setting goes to the auditor as an item to check" {
  make_repo github
  step 1 "$finish_tasks && echo '# note' >> Makefile && git commit -qam make"
  verdict 2 pass
  run loop 12
  [ "$status" -eq 0 ]
  grep -qx -- '- Makefile' "$FAKE_DIR/claude.2.prompt"
}

@test "the auditor runs with read-only tools, opus, high effort, and its own limits" {
  make_repo github
  step 1 "$finish_tasks"
  verdict 2 pass
  run loop 12
  [ "$status" -eq 0 ]
  a="$(cat "$FAKE_DIR/claude.2.args")"
  grep -qx opus <<< "$a" && grep -qx high <<< "$a"
  grep -qx 'Read,Grep,Glob,Bash' <<< "$a"
  grep -qx 'Edit,Write,NotebookEdit' <<< "$a"
  grep -qx -- '--json-schema' <<< "$a" && grep -qx 3 <<< "$a" && grep -qx none <<< "$a"
}

# The real claude, not the fake: a schema the CLI rejects stops every round with "no verdict". An unknown model ends
# the call before any API request, signed in or not, so the test costs nothing. CI (VERIFY_STRICT=1) has claude.
@test "the real claude accepts the verdict schema for --json-schema" {
  real="$(PATH="${PATH#"$FAKES:"}" command -v claude || true)"
  if [ -z "$real" ]; then
    if [ "${VERIFY_STRICT:-0}" = 1 ]; then echo "claude is missing (VERIFY_STRICT=1)"; return 1; fi
    skip "claude is not installed"
  fi
  mkdir -p "$T/home"
  run env -u ANTHROPIC_API_KEY HOME="$T/home" "$real" -p ok --model uskn-loop-no-such-model \
    --no-session-persistence --strict-mcp-config --output-format json \
    --json-schema "$(cat "$REPO/loop/verdict.schema.json")"
  [[ "$output" != *"not a valid JSON Schema"* ]]
  [[ "$output" == *"unrecognized_model"* ]]
}

@test "a verdict without the four fields stops the loop" {
  make_repo github
  step 1 "$finish_tasks"
  run loop 12
  [ "$status" -eq 3 ]
  [[ "$(comments)" == *"監査役の判定なし"* ]]
}

@test "the worktree goes back to its state before the audit" {
  make_repo github
  step 1 "$finish_tasks"
  step 2 'mkdir -p tmp && echo log > tmp/out.log && echo junk >> Makefile && git commit -qam junk'
  verdict 2 pass "?stop here"
  run loop 12
  [ "$status" -eq 3 ]
  [ ! -e "$WT/tmp/out.log" ]
  [ "$(git -C "$WT" log -1 --format=%s)" = "tasks done" ]
  [ -z "$(git -C "$WT" status --porcelain)" ]
}

@test "stop: five rounds without meeting the criteria, and no sixth" {
  make_repo github
  step 2 "$finish_tasks && touch .fail-verify && git add .fail-verify && git commit -qm v"
  step 3 'sed -i "s/- \[x\]/- [ ]/" openspec/changes/add-x/tasks.md && git rm -q .fail-verify && git commit -qam t'
  step 4 "$finish_tasks && touch .fail-verify && git add .fail-verify && git commit -qm v"
  step 5 'sed -i "s/- \[x\]/- [ ]/" openspec/changes/add-x/tasks.md && git rm -q .fail-verify && git commit -qam t'
  run loop 12
  [ "$status" -eq 3 ]
  [ "$(cat "$FAKE_DIR/claude.count")" = 5 ]
  [[ "$(comments)" == *"ラウンドの上限（5回）"* ]]
}

@test "stop: the PR's estimated cost passes the budget" {
  make_repo github
  cost 1 41
  run loop 12
  [ "$status" -eq 3 ]
  [ "$(cat "$FAKE_DIR/claude.count")" = 1 ]
  [[ "$(comments)" == *'費用の上限（$40.00）'* ]]
}

@test "stop: two rounds with the same failures make no progress" {
  make_repo github
  run loop 12
  [ "$status" -eq 3 ]
  [ "$(cat "$FAKE_DIR/claude.count")" = 2 ]
  [[ "$(comments)" == *"2ラウンド続けて進展なし"* ]]
}

@test "stop: the auditor's question keeps the PR a draft and the worktree" {
  make_repo github
  step 1 "$finish_tasks"
  verdict 2 fail "?期限切れのトークンを401と403のどちらで返すか"
  run loop 12
  [ "$status" -eq 3 ]
  [ ! -e "$FAKE_DIR/ready" ] && [ -d "$WT" ]
  c="$(comments)"
  [[ "$c" == *"期限切れのトークンを401と403のどちらで返すか"* ]]
  [[ "$c" == *'`uskn-loop run 12`'* ]]
}

@test "stop: a PR in conflict with its base starts no round" {
  make_repo github
  fake_pr conflict=true
  run loop 12
  [ "$status" -eq 3 ]
  [ ! -e "$FAKE_DIR/claude.count" ]
  [[ "$(comments)" == *"基底ブランチとの衝突"* ]]
}

@test "done: the PR leaves draft, the worktree goes, and nothing is merged, archived, or labelled" {
  make_repo github
  step 1 "$finish_tasks"
  verdict 2 pass
  run loop 12
  [ "$status" -eq 0 ]
  grep -q '^pr ready 12' "$FAKE_DIR/ready"
  [ ! -e "$WT" ] && [ ! -e "$FAKE_DIR/forbidden" ]
  ! git -C "$CLONE" show-ref --verify --quiet refs/heads/loop/pr-12
  git --git-dir="$T/origin.git" cat-file -e change/add-x:openspec/changes/add-x/tasks.md
}

@test "done on GitLab: the MR leaves draft through glab" {
  make_repo gitlab
  step 1 "$finish_tasks"
  verdict 2 pass
  run loop 12
  [ "$status" -eq 0 ]
  grep -q '^mr update 12 --ready' "$FAKE_DIR/ready"
  [ "$(ncomments)" = 2 ]
}

# ---- comments (tasks 5.1-5.2) -------------------------------------------------------------------------------------

@test "one progress comment holds every round" {
  make_repo github
  step 2 "$finish_tasks"
  verdict 3 fail src/a.ts
  verdict 5 pass
  run loop 12
  [ "$status" -eq 0 ]
  [ "$(grep -l -- '<!-- uskn-loop -->' "$FAKE_DIR"/comments/*.body | wc -l | tr -d ' ')" = 1 ]
  p="$(cat "$(grep -l -- '<!-- uskn-loop -->' "$FAKE_DIR"/comments/*.body)")"
  [[ "$p" == *"| 1 |"* && "$p" == *"| 2 |"* && "$p" == *"| 3 |"* ]]
}

@test "a rerun rewrites the progress comment it finds by its mark" {
  make_repo github
  mkdir -p "$FAKE_DIR/comments"
  printf '<!-- uskn-loop -->\nold\n' > "$FAKE_DIR/comments/50.body" && echo me > "$FAKE_DIR/comments/50.author"
  printf '<!-- uskn-loop -->\nnot mine\n' > "$FAKE_DIR/comments/51.body" && echo someone > "$FAKE_DIR/comments/51.author"
  fake_pr conflict=true
  run loop 12
  [ "$status" -eq 3 ]
  grep -q 'uskn-loop：停止' "$FAKE_DIR/comments/50.body"
  grep -q 'not mine' "$FAKE_DIR/comments/51.body"
  [ "$(grep -l -- '<!-- uskn-loop -->' "$FAKE_DIR"/comments/*.body | wc -l | tr -d ' ')" = 2 ]
}

@test "the progress comment shows the phase, the change, and the rounds so far" {
  make_repo github
  step 2 "$finish_tasks"
  step 3 "cp \"\$(grep -l -- '<!-- uskn-loop -->' '$FAKE_DIR'/comments/*.body)\" '$FAKE_DIR/during-audit.md'"
  verdict 3 pass
  run loop 12
  [ "$status" -eq 0 ]
  d="$(cat "$FAKE_DIR/during-audit.md")"
  [[ "$d" == *"### uskn-loop：監査中"* && "$d" == *'`add-x`'* ]]
  [[ "$d" == *"| 1 | 失敗（tasks） | - |"* && "$d" == *"| 2 | 監査中 |"* ]]
  [[ "$d" == *"費用の見積もりの合計は"* ]]
}

@test "comments carry no raw output; it stays in the state directory" {
  make_repo github
  step 1 "$finish_tasks && touch .fail-verify && git add .fail-verify && git commit -qm fail"
  USKN_LOOP_ROUNDS=1 run loop 12
  [ "$status" -eq 3 ]
  [[ "$(comments)" != *"verify-raw-output"* ]]
  [[ "$(comments)" == *"失敗（verify）"* ]]
  grep -q verify-raw-output "$STATE/round-1/verify.txt"
}

@test "done: a new comment names the rounds and the /archive-push step" {
  make_repo github
  step 1 "$finish_tasks"
  verdict 2 pass
  run loop 12
  [ "$status" -eq 0 ]
  [ "$(ncomments)" = 2 ]
  c="$(comments)"
  [[ "$c" == *"1ラウンドで完了基準を満たしました"* && "$c" == *'`/archive-push add-x`'* ]]
}
