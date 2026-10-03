#!/usr/bin/env bats
# Tests for the harness textlint configs in skills/ja-writing/ (spec: ja-writing-skill): the metaphor-verb patterns
# in textlintrc.json, and textlintrc.desumasu.json, its copy for 敬体 (PR and MR bodies). Runs the real textlint
# with the harness configs. The example sentences live in fixtures/ja-writing/.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
CONF="$REPO/skills/ja-writing/textlintrc.json"
DESU="$REPO/skills/ja-writing/textlintrc.desumasu.json"
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

@test "the desumasu config asks for ですます in body text and in list items" {
  run jq -r '.rules["preset-ja-technical-writing"]["no-mix-dearu-desumasu"] | .preferInBody, .preferInList' "$DESU"
  [ "$status" -eq 0 ]
  [ "$output" = "ですます
ですます" ]
}

@test "the two configs are the same apart from no-mix-dearu-desumasu" {
  # A textlint config cannot extend another, so the desumasu config is a full copy; a rule added to one only fails here.
  local strip='del(.rules["preset-ja-technical-writing"]["no-mix-dearu-desumasu"])'
  [ -f "$DESU" ]
  diff <(jq -S "$strip" "$CONF") <(jq -S "$strip" "$DESU")
}

@test "a PR body in 敬体 passes the desumasu config, and the である config reports its register" {
  need_textlint
  run textlint --config "$DESU" --format compact "$FIX/body.pr.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  run lint "$FIX/body.pr.md"
  [[ "$output" == *"(ja-technical-writing/no-mix-dearu-desumasu)"* ]] || false
}

# pr_body_lint <skill>: every textlint command in the skill lints a <body>.pr.md file with the desumasu config, and
# the skill names no other placeholder Markdown file (<body>.md, <copy>.md) and not the である config.
pr_body_lint() {
  local lines bad
  lines="$(grep -E '^[[:space:]]*textlint ' "$1" || true)"
  [ -n "$lines" ] || { echo "no textlint command in $1"; return 1; }
  bad="$(grep -vE -- '--config [^ ]*/skills/ja-writing/textlintrc\.desumasu\.json .*<[a-z-]+>\.pr\.md$' <<<"$lines" || true)"
  [ -z "$bad" ] || { printf 'not the desumasu config on a <body>.pr.md file:\n%s\n' "$bad"; return 1; }
  bad="$(grep -nE '<[a-z-]+>\.md|textlintrc\.json' "$1" || true)"
  [ -z "$bad" ] || { printf 'a body file outside the <body>.pr.md form, or the である config:\n%s\n' "$bad"; return 1; }
}

@test "the pr skill lints the PR or MR body as a <body>.pr.md file with the desumasu config" {
  pr_body_lint "$REPO/skills/git/pr/SKILL.md"
}

@test "the spec-pr skill lints the spec PR body as a <body>.pr.md file with the desumasu config" {
  pr_body_lint "$REPO/skills/spec-pr/SKILL.md"
}
