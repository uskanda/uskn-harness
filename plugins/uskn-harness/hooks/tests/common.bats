#!/usr/bin/env bats
# Tests for hooks/scripts/lib/common.sh helpers (with_timeout: spec verify-gate and textlint-hook, the time caps).
LIB="$BATS_TEST_DIRNAME/../scripts/lib/common.sh"

# path_without <cmd>...: a directory of links to everything on PATH except the named commands (first match wins)
path_without() {
  local farm="$BATS_TEST_TMPDIR/farm" d x
  mkdir -p "$farm"
  local IFS=:
  for d in $PATH; do [ -d "$d" ] && ln -s "$d"/* "$farm"/ 2>/dev/null; done
  for x in "$@"; do rm -f "$farm/$x"; done
  printf '%s' "$farm"
}
gone() { # <pid>: the process has exited (a zombie counts as gone once reaped; wait up to 3s)
  local i
  for i in 1 2 3 4 5 6; do kill -0 "$1" 2>/dev/null || return 0; sleep 0.5; done
  return 1
}

@test "with_timeout without timeout and gtimeout: perl caps the command, exits 124, and stops what it started" {
  P="$(path_without timeout gtimeout)"
  [ ! -e "$P/timeout" ]; [ -x "$P/perl" ]
  start="$(date +%s)"
  PATH="$P" run bash -c ". '$LIB'; with_timeout 1 bash -c 'sleep 30 & echo \$! > \"$BATS_TEST_TMPDIR/child\"; sleep 30'"
  [ "$status" -eq 124 ]
  [ $(( $(date +%s) - start )) -lt 10 ]
  gone "$(cat "$BATS_TEST_TMPDIR/child")"
}

@test "with_timeout: a command that finishes in time keeps its output and exit status, on every path" {
  run bash -c ". '$LIB'; with_timeout 5 bash -c 'echo hi; exit 3'"
  [ "$status" -eq 3 ]; [ "$output" = hi ]
  P="$(path_without timeout gtimeout)"
  PATH="$P" run bash -c ". '$LIB'; with_timeout 5 bash -c 'echo hi; exit 3'"
  [ "$status" -eq 3 ]; [ "$output" = hi ]
}

@test "with_timeout uses gtimeout when GNU timeout is missing" {
  P="$(path_without timeout gtimeout)"
  mkdir -p "$BATS_TEST_TMPDIR/g"
  printf '#!/usr/bin/env bash\necho "gtimeout $*" >> "%s/g.log"\nshift; exec "$@"\n' "$BATS_TEST_TMPDIR" > "$BATS_TEST_TMPDIR/g/gtimeout"
  chmod +x "$BATS_TEST_TMPDIR/g/gtimeout"
  PATH="$BATS_TEST_TMPDIR/g:$P" run bash -c ". '$LIB'; with_timeout 7 true"
  [ "$status" -eq 0 ]
  grep -q "gtimeout 7 true" "$BATS_TEST_TMPDIR/g.log"
}

# ---- roots (spec: write-guard, bash-guard: the two roots; textlint-hook, terminology-guard: the cwd git root)
repo() { mkdir -p "$1"; git -C "$1" init -q -b main; }
# worktree <repo> <path>: a linked worktree of the repo (git worktree add needs a commit to start from)
worktree() {
  git -C "$1" -c user.name=t -c user.email=t@x commit -q --allow-empty -m init
  git -C "$1" worktree add -q -b "wt$RANDOM" "$2"
}

@test "project_roots: a worktree of the session repository adds the cwd's git root, one per line" {
  repo "$BATS_TEST_TMPDIR/a"; worktree "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR/a-wt"; mkdir -p "$BATS_TEST_TMPDIR/a-wt/src"
  CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/a" run bash -c ". '$LIB'; project_roots '$BATS_TEST_TMPDIR/a-wt/src'"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "$(realpath "$BATS_TEST_TMPDIR/a")" ]
  [ "${lines[1]}" = "$(realpath "$BATS_TEST_TMPDIR/a-wt")" ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "project_roots: a checkout of another repository adds nothing, wherever it lives" {
  repo "$BATS_TEST_TMPDIR/a"; repo "$BATS_TEST_TMPDIR/b"; repo "$BATS_TEST_TMPDIR/a/.claude/worktrees/c"
  CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/a" run bash -c ". '$LIB'; project_roots '$BATS_TEST_TMPDIR/b'"
  [ "$output" = "$(realpath "$BATS_TEST_TMPDIR/a")" ]
  CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/a" run bash -c ". '$LIB'; project_roots '$BATS_TEST_TMPDIR/a/.claude/worktrees/c'"
  [ "$output" = "$(realpath "$BATS_TEST_TMPDIR/a")" ]
}

@test "project_roots: a session root outside git cannot vouch for the cwd's repository" {
  mkdir -p "$BATS_TEST_TMPDIR/plain"; repo "$BATS_TEST_TMPDIR/b"
  CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/plain" run bash -c ". '$LIB'; project_roots '$BATS_TEST_TMPDIR/b'"
  [ "$output" = "$(realpath "$BATS_TEST_TMPDIR/plain")" ]
}

@test "project_roots: the same root once; no git and no CLAUDE_PROJECT_DIR gives cwd" {
  repo "$BATS_TEST_TMPDIR/a"; mkdir -p "$BATS_TEST_TMPDIR/a/src" "$BATS_TEST_TMPDIR/plain"
  CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/a" run bash -c ". '$LIB'; project_roots '$BATS_TEST_TMPDIR/a/src'"
  [ "$output" = "$(realpath "$BATS_TEST_TMPDIR/a")" ]
  run env -u CLAUDE_PROJECT_DIR bash -c ". '$LIB'; project_roots '$BATS_TEST_TMPDIR/plain'"
  [ "$output" = "$(realpath "$BATS_TEST_TMPDIR/plain")" ]
}

@test "work_root: the git root of cwd, whatever CLAUDE_PROJECT_DIR says; else cwd" {
  repo "$BATS_TEST_TMPDIR/a"; repo "$BATS_TEST_TMPDIR/a-wt"; mkdir -p "$BATS_TEST_TMPDIR/a-wt/src" "$BATS_TEST_TMPDIR/plain"
  CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/a" run bash -c ". '$LIB'; work_root '$BATS_TEST_TMPDIR/a-wt/src'"
  [ "$output" = "$(realpath "$BATS_TEST_TMPDIR/a-wt")" ]
  run bash -c ". '$LIB'; work_root '$BATS_TEST_TMPDIR/plain'"
  [ "$output" = "$(realpath "$BATS_TEST_TMPDIR/plain")" ]
}

@test "path_allowed: inside any of the roots given one per line" {
  mkdir -p "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR/b" "$BATS_TEST_TMPDIR/c"
  roots="$BATS_TEST_TMPDIR/a
$BATS_TEST_TMPDIR/b"
  export USKN_GUARD_ALLOW_DIRS="" USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"
  run bash -c ". '$LIB'; path_allowed '$BATS_TEST_TMPDIR/a/x' \"\$0\" sid" "$roots"; [ "$status" -eq 0 ]
  run bash -c ". '$LIB'; path_allowed '$BATS_TEST_TMPDIR/b/y' \"\$0\" sid" "$roots"; [ "$status" -eq 0 ]
  run bash -c ". '$LIB'; path_allowed '$BATS_TEST_TMPDIR/c/z' \"\$0\" sid" "$roots"; [ "$status" -eq 1 ]
}

# ---- tree_fingerprint and the sandbox's placeholders (spec: session-baseline)
fp_repo() {
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R/docs"; echo a > "$R/README.md"
  ( cd "$R" && git init -q -b main && git add -A && git commit -qm init )
}
fp() { bash -c ". '$LIB'; tree_fingerprint '$R'"; }

@test "tree_fingerprint ignores the placeholders: a 0-byte top-level .bashrc and .claude/agents" {
  fp_repo
  before="$(fp)"
  : > "$R/.bashrc"; mkdir -p "$R/.claude"; : > "$R/.claude/agents"
  [ "$(fp)" = "$before" ]
}

@test "tree_fingerprint counts a top-level dotfile with content and a 0-byte file deeper down" {
  fp_repo
  before="$(fp)"
  echo 'export A=1' > "$R/.envrc"
  [ "$(fp)" != "$before" ] || false
  rm "$R/.envrc"
  [ "$(fp)" = "$before" ]
  : > "$R/docs/.keep"
  [ "$(fp)" != "$before" ] || false
}

@test "untracked_files lists untracked files without the placeholders" {
  fp_repo
  : > "$R/.bashrc"; mkdir -p "$R/.claude/commands"; : > "$R/.claude/agents"; : > "$R/.claude/commands/x.md"
  echo x > "$R/.envrc"; : > "$R/docs/.keep"
  run bash -c ". '$LIB'; untracked_files '$R' | tr '\0' '\n' | LC_ALL=C sort"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '.claude/commands/x.md\n.envrc\ndocs/.keep')" ]
}

# ---- the environment marker (spec: environment-kind). environment_read <checkout> sets ENV_KIND (admin | confined),
# ENV_TOOLS, ENV_SECRETS, and ENV_MARKER (none | ok | invalid). Without an argument it reads the checkout five levels
# above lib/common.sh, whatever USKN_HARNESS_DIR says.
envread() { bash -c ". '$LIB'; environment_read \"\$1\"; printf '%s|%s|%s|%s\n' \"\$ENV_KIND\" \"\$ENV_TOOLS\" \"\$ENV_SECRETS\" \"\$ENV_MARKER\"" _ "$1"; }

@test "environment_read: no marker is the admin environment" {
  mkdir -p "$BATS_TEST_TMPDIR/co"
  run envread "$BATS_TEST_TMPDIR/co"
  [ "$status" -eq 0 ]
  [ "$output" = "admin|||none" ]
}

@test "environment_read: kind=confined with tools and secrets, comments and blank lines skipped, no final newline" {
  mkdir -p "$BATS_TEST_TMPDIR/co"
  printf '# set by the machine base\n\nkind=confined\ntools=/opt/shared\nsecrets=/Users/agent/secrets' > "$BATS_TEST_TMPDIR/co/.uskn-environment"
  run envread "$BATS_TEST_TMPDIR/co"
  [ "$output" = "confined|/opt/shared|/Users/agent/secrets|ok" ]
}

@test "environment_read: a wrong kind, a missing kind, or an unreadable marker is the confined environment" {
  mkdir -p "$BATS_TEST_TMPDIR/co"
  printf 'kind=confind\ntools=/opt/shared\n' > "$BATS_TEST_TMPDIR/co/.uskn-environment"
  run envread "$BATS_TEST_TMPDIR/co"
  [ "$output" = "confined|/opt/shared||invalid" ]
  printf 'tools=/opt/shared\n' > "$BATS_TEST_TMPDIR/co/.uskn-environment"
  run envread "$BATS_TEST_TMPDIR/co"
  [ "$output" = "confined|/opt/shared||invalid" ]
  printf 'kind=admin\n' > "$BATS_TEST_TMPDIR/co/.uskn-environment"
  run envread "$BATS_TEST_TMPDIR/co"
  [ "$output" = "confined|||invalid" ]
  rm "$BATS_TEST_TMPDIR/co/.uskn-environment"; mkdir "$BATS_TEST_TMPDIR/co/.uskn-environment"
  run envread "$BATS_TEST_TMPDIR/co"
  [ "$output" = "confined|||invalid" ]
}

@test "environment_read: a marker that cannot be read is the confined environment" {
  [ "$(id -u)" -ne 0 ] || skip "root reads every file"
  mkdir -p "$BATS_TEST_TMPDIR/co"
  printf 'kind=confined\n' > "$BATS_TEST_TMPDIR/co/.uskn-environment"; chmod 000 "$BATS_TEST_TMPDIR/co/.uskn-environment"
  run envread "$BATS_TEST_TMPDIR/co"
  chmod 600 "$BATS_TEST_TMPDIR/co/.uskn-environment"
  [ "$output" = "confined|||invalid" ]
}

# fake_checkout: a copy of the plugin at plugins/uskn-harness of a checkout of its own, as the hooks find it
fake_checkout() {
  CO="$BATS_TEST_TMPDIR/checkout"; mkdir -p "$CO/plugins"
  cp -R "$BATS_TEST_DIRNAME/../.." "$CO/plugins/uskn-harness"
  CLIB="$CO/plugins/uskn-harness/hooks/scripts/lib/common.sh"
}

@test "environment_read without an argument reads the checkout of the plugin, not USKN_HARNESS_DIR" {
  fake_checkout
  printf 'kind=confined\ntools=/opt/shared\n' > "$CO/.uskn-environment"
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere"
  run env USKN_HARNESS_DIR="$BATS_TEST_TMPDIR/elsewhere" bash -c ". '$CLIB'; environment_read; echo \"\$ENV_KIND|\$ENV_TOOLS\""
  [ "$output" = "confined|/opt/shared" ]
}

# ---- the confined environment's hook PATH and rules (spec: confined-hook-sandbox). A fake sandbox-exec first on PATH
# logs its arguments and runs the command after its options; USKN_HARNESS_OS stands in for uname -s.
fake_sandbox() {
  SBLOG="$BATS_TEST_TMPDIR/sandbox-exec.log"; mkdir -p "$BATS_TEST_TMPDIR/sbx"
  cat > "$BATS_TEST_TMPDIR/sbx/sandbox-exec" <<SB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$SBLOG"
while [ \$# -gt 0 ]; do case "\$1" in -f | -D | -p) shift 2 ;; *) break ;; esac; done
exec "\$@"
SB
  chmod +x "$BATS_TEST_TMPDIR/sbx/sandbox-exec"
}
confined_checkout() { # [secrets]: a fake checkout with a confined marker and a tools dir
  fake_checkout; fake_sandbox
  TOOLS="$BATS_TEST_TMPDIR/tools"; mkdir -p "$TOOLS/bin"
  printf 'kind=confined\ntools=%s\n' "$TOOLS" > "$CO/.uskn-environment"
  [ -z "${1:-}" ] || printf 'secrets=%s\n' "$1" >> "$CO/.uskn-environment"
  RULES="$(cd "$CO" && pwd -P)/plugins/uskn-harness/hooks/scripts/lib/confined.sb"
}

@test "hook_path: the confined environment adds the shared tools' bin/ only, nothing under the home" {
  confined_checkout
  run env HOME="$BATS_TEST_TMPDIR/h" PATH="/usr/bin:/bin" bash -c ". '$CLIB'; hook_path"
  [ "$status" -eq 0 ]
  [ "$output" = "$TOOLS/bin:/usr/bin:/bin" ]
}

@test "hook_path: the admin environment puts the mise shims and ~/.local/bin first, as before" {
  fake_checkout
  run env HOME="$BATS_TEST_TMPDIR/h" PATH="/usr/bin:/bin" bash -c ". '$CLIB'; hook_path"
  [ "$output" = "$BATS_TEST_TMPDIR/h/.local/share/mise/shims:$BATS_TEST_TMPDIR/h/.local/bin:/usr/bin:/bin" ]
}

@test "confined_run on macOS runs the command under sandbox-exec with the rules file and SECRETS" {
  confined_checkout "$BATS_TEST_TMPDIR/secrets"
  [ -f "$BATS_TEST_DIRNAME/../scripts/lib/confined.sb" ]
  run env USKN_HARNESS_OS=Darwin PATH="$BATS_TEST_TMPDIR/sbx:$PATH" bash -c ". '$CLIB'; confined_run echo hi there; echo rc=\$?"
  [ "${lines[0]}" = "hi there" ]
  [ "${lines[1]}" = "rc=0" ]
  [ "$(cat "$SBLOG")" = "-f $RULES -D SECRETS=$BATS_TEST_TMPDIR/secrets echo hi there" ]
}

@test "confined_run without secrets in the marker passes the rules file only, and keeps the exit status" {
  confined_checkout
  run env USKN_HARNESS_OS=Darwin PATH="$BATS_TEST_TMPDIR/sbx:$PATH" bash -c ". '$CLIB'; confined_run bash -c 'exit 3'; echo rc=\$?"
  [ "$output" = "rc=3" ]
  [ "$(cat "$SBLOG")" = "-f $RULES bash -c exit 3" ]
}

@test "confined_run returns 125 without running the command on another OS or without sandbox-exec" {
  confined_checkout
  run env USKN_HARNESS_OS=Linux PATH="$BATS_TEST_TMPDIR/sbx:$PATH" bash -c ". '$CLIB'; confined_run touch '$BATS_TEST_TMPDIR/ran'; echo rc=\$?"
  [ "$output" = "rc=125" ]
  [ ! -e "$BATS_TEST_TMPDIR/ran" ]; [ ! -e "$SBLOG" ]
  P="$(path_without sandbox-exec)"
  run env USKN_HARNESS_OS=Darwin PATH="$P" bash -c ". '$CLIB'; confined_run touch '$BATS_TEST_TMPDIR/ran'; echo rc=\$?"
  [ "$output" = "rc=125" ]
  [ ! -e "$BATS_TEST_TMPDIR/ran" ]
}

@test "confined_run in the admin environment runs the command directly" {
  fake_checkout; fake_sandbox
  run env USKN_HARNESS_OS=Linux PATH="$BATS_TEST_TMPDIR/sbx:$PATH" bash -c ". '$CLIB'; confined_run echo direct"
  [ "$output" = direct ]
  [ ! -e "$SBLOG" ]
}

@test "tree_fingerprint runs its git under the rules in the confined environment" {
  fp_repo; confined_checkout
  run env USKN_HARNESS_OS=Darwin PATH="$BATS_TEST_TMPDIR/sbx:$PATH" bash -c ". '$CLIB'; tree_fingerprint '$R'"
  [ "$status" -eq 0 ]; [ -n "$output" ]
  [ "$output" = "$(fp)" ]
  grep -q "^-f $RULES git -C $R status" "$SBLOG"
  grep -q "^-f $RULES git -C $R diff HEAD" "$SBLOG"
  grep -q "^-f $RULES git -C $R ls-files" "$SBLOG"
}
