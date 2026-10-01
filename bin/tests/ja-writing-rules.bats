#!/usr/bin/env bats
# Tests for the metaphor-verb patterns in skills/ja-writing/textlintrc.json (spec: ja-writing-skill).
# Runs the real textlint with the harness config. The example sentences live in fixtures/ja-writing/.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
CONF="$REPO/skills/ja-writing/textlintrc.json"
FIX="$BATS_TEST_DIRNAME/fixtures/ja-writing"
RULE="@textlint-rule/pattern"

# textlint loads no rule at all when one package in the config is missing, and says "No rules found".
textlint_ready() {
  command -v textlint >/dev/null || return 1
  printf '# t\n\n確かめる。\n' > "$BATS_TEST_TMPDIR/probe.md"
  ! textlint --config "$CONF" "$BATS_TEST_TMPDIR/probe.md" 2>&1 | grep -q 'No rules found'
}

# CI runs `make verify VERIFY_STRICT=1`: there a missing textlint or rule package fails instead of skipping.
need_textlint() {
  textlint_ready && return 0
  if [ "${VERIFY_STRICT:-0}" = 1 ]; then
    echo "textlint or a rule package from deps.json is missing (VERIFY_STRICT=1); run uskn-harness sync --tools"
    return 1
  fi
  skip "textlint or a rule package from deps.json is missing; run uskn-harness sync --tools"
}

lint() { textlint --config "$CONF" --format compact "$1" 2>&1; }

@test "every sentence line in detect.txt gets a metaphor-verb finding" {
  need_textlint
  run lint "$FIX/detect.txt"
  local n=0 line missing=""
  while IFS= read -r line; do
    n=$((n + 1))
    case "$line" in '' | '#'*) continue ;; esac
    grep -qE "line $n, col [0-9]+, Error - .*\\($RULE\\)" <<<"$output" || missing="$missing
  line $n: $line"
  done < "$FIX/detect.txt"
  [ -z "$missing" ] || { echo "no $RULE finding for:$missing"; return 1; }
}

@test "a finding names the verb and points at ja-writing" {
  need_textlint
  printf 'この設定は全体に効く。\n' > "$BATS_TEST_TMPDIR/one.txt"
  run lint "$BATS_TEST_TMPDIR/one.txt"
  [[ "$output" == *"効く"*"ja-writing"*"($RULE)"* ]] || false
}

@test "pass.md gets no finding: literal uses, compounds, and bad examples in backticks or a block quote" {
  need_textlint
  run lint "$FIX/pass.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
