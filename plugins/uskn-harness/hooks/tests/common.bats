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
