#!/usr/bin/env bats
# Tests for the dotfiles bootstrap template in templates/chezmoi/ (spec: machine-bootstrap). The template's body is
# a bash script between chezmoi directives; the tests strip the directives and run the body against a temporary
# HOME, with sync's network steps stubbed and a fake mise so nothing is downloaded.

REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
TEMPLATE="$REPO/templates/chezmoi/run_after_uskn-harness.sh.tmpl"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  export USKN_HARNESS_STUB_NET=1
  export USKN_HARNESS_STUB_LOG="$BATS_TEST_TMPDIR/net.log"
  export XDG_STATE_HOME="$HOME/.local/state"; unset USKN_STATE_DIR USKN_HARNESS_DIR CHEZMOI_DEST_DIR
  mkdir -p "$HOME/.local/bin" "$HOME/repos"
  printf '#!/bin/sh\nexit 0\n' > "$HOME/.local/bin/mise"; chmod +x "$HOME/.local/bin/mise"
  printf '#!/bin/sh\necho "9.9.9 (Claude Code)"\n' > "$HOME/.local/bin/claude"; chmod +x "$HOME/.local/bin/claude"
  export PATH="$HOME/.local/bin:$PATH"
  BODY="$BATS_TEST_TMPDIR/body.sh"
  grep -v '^{{' "$TEMPLATE" > "$BODY"
}

refute() { ! "$@"; }

@test "the bootstrap is a run_after_ template; the run_once one is gone" {
  [ -f "$TEMPLATE" ]
  refute ls "$REPO"/templates/chezmoi/run_once_* 2>/dev/null
}

@test "the template does nothing on Windows: its first and last lines are the chezmoi guard" {
  [ "$(head -n 1 "$TEMPLATE")" = '{{- if ne .chezmoi.os "windows" -}}' ]
  [ "$(tail -n 1 "$TEMPLATE")" = '{{- end }}' ]
}

@test "the body is valid bash, passes shellcheck, and ends by running sync" {
  bash -n "$BODY"
  if command -v shellcheck >/dev/null; then shellcheck "$BODY"; fi
  grep -qE '^exec "\$H/bin/uskn-harness" sync$' "$BODY"
}

@test "on a machine with a checkout in ~/repos, the body links the stable path to it and runs sync" {
  ln -s "$REPO" "$HOME/repos/uskn-harness"
  run bash "$BODY"
  [ "$status" -eq 0 ]
  [ "$(readlink "$HOME/.local/share/uskn-harness")" = "$HOME/repos/uskn-harness" ]
  [[ "$output" == *"done"*"failure(s)"* ]] || false
}

@test "a second run goes through sync again and changes nothing" {
  ln -s "$REPO" "$HOME/repos/uskn-harness"
  bash "$BODY" >/dev/null
  run bash "$BODY"
  [ "$status" -eq 0 ]
  [[ "$output" == *"done      0 change(s)"* ]] || false
}

@test "CHEZMOI_DEST_DIR takes the place of HOME, so a --destination run stays out of the real home" {
  dest="$BATS_TEST_TMPDIR/dest"
  mkdir -p "$dest/repos" "$dest/.local/bin"; cp "$HOME/.local/bin/mise" "$dest/.local/bin/mise"
  ln -s "$REPO" "$dest/repos/uskn-harness"
  CHEZMOI_DEST_DIR="$dest" run bash "$BODY"
  [ "$status" -eq 0 ]
  [ -L "$dest/.local/share/uskn-harness" ]
  [ ! -e "$HOME/.local/share/uskn-harness" ]
}
