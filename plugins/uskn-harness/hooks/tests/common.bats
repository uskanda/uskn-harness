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
