#!/usr/bin/env bats
# Tests for the ui-guidelines skill's body and the user layer's UI line (specs: ui-guidelines-skill,
# user-layer-instructions). A new UI starts from frontend-design, on the web and on Expo, with or without DESIGN.md,
# and its choices go into DESIGN.md before any UI code.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SKILL="$REPO/skills/ui-guidelines/SKILL.md"
USER_CLAUDE="$REPO/templates/user/CLAUDE.md"

surface() { sed -n '/^## Working on a surface/,/^## What Impeccable/p' "$SKILL"; }
surface_joined() { surface | tr '\n' ' ' | tr -s ' '; }   # prose wraps at 120 columns
new_ui_step() { surface | grep -E '^[0-9]+\. ' | grep -F 'frontend-design'; }

@test "a numbered step of Working on a surface runs frontend-design for a new UI" {
  new_ui_step | grep -qi 'new UI'
}

@test "the frontend-design step comes right after reading DESIGN.md and PRODUCT.md" {
  surface | grep -E '^2\. ' | grep -qF 'frontend-design'
}

@test "the frontend-design step covers the web and Expo, with or without DESIGN.md" {
  surface | grep -qF 'Expo'
  surface_joined | grep -qiE 'with or without (a )?DESIGN\.md'
}

@test "the frontend-design choices go into DESIGN.md before the UI code" {
  surface_joined | grep -qiE 'DESIGN\.md (first|before)'
}

@test "a small fix to an existing screen skips frontend-design" {
  surface_joined | grep -qiE 'small (fix|change)'
}

@test "the old fallback condition is gone" {
  run grep -qF 'A new web surface with no DESIGN.md yet' "$SKILL"
  [ "$status" -eq 1 ]
}

@test "the user layer's UI line names frontend-design for a new UI" {
  grep -E '^- UI:' "$USER_CLAUDE" | grep -qF '`frontend-design`'
}
