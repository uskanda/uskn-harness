#!/usr/bin/env bats
# Tests for hooks/hooks.json (spec: claude-plugin-packaging, the start conditions). An `if` holds one permission
# rule, and Edit(...) matches the Edit tool only, so each file-selective hook sits once under a Write matcher and
# once under an Edit matcher, each with its own tool's rule.
HOOKS="$BATS_TEST_DIRNAME/../hooks.json"

# handlers <event> <script>: "<matcher>\t<if>" for every handler of the script in the event
handlers() {
  jq -r --arg e "$1" --arg s "$2" '.hooks[$e][] | .matcher as $m | .hooks[]
    | select(.command | endswith("/" + $s)) | "\($m // "")\t\(.if // "")"' "$HOOKS" | sort
}

@test "hooks.json is valid JSON" {
  jq -e . "$HOOKS" >/dev/null
}

@test "textlint-check and terms-check: one Write handler with Write(**/*.md), one Edit handler with Edit(**/*.md)" {
  for s in textlint-check.sh terms-check.sh; do
    run handlers PostToolUse "$s"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf 'Edit\tEdit(**/*.md)\nWrite\tWrite(**/*.md)')" ]
  done
}

@test "grilling-guard: Write and Edit handlers limited to openspec changes; NotebookEdit without if" {
  run handlers PreToolUse grilling-guard.sh
  [ "$output" = "$(printf 'Edit\tEdit(**/openspec/changes/**)\nNotebookEdit\t\nWrite\tWrite(**/openspec/changes/**)')" ]
}

@test "an if names the same tool as its matcher" {
  run jq -r '.hooks[][] | .matcher as $m | .hooks[] | select(.if) | "\($m) \(.if)"' "$HOOKS"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  while read -r m rule; do [ "${rule%%(*}" = "$m" ]; done <<< "$output"
}

@test "write-guard, bash-guard, and the SessionStart and Stop hooks carry no if" {
  run handlers PreToolUse write-guard.sh
  [ "$output" = "$(printf 'Write|Edit|NotebookEdit\t')" ]
  run handlers PreToolUse bash-guard.sh
  [ "$output" = "$(printf 'Bash\t')" ]
  run jq -r '[.hooks.SessionStart[], .hooks.Stop[] | .hooks[] | select(.if)] | length' "$HOOKS"
  [ "$output" = 0 ]
}
