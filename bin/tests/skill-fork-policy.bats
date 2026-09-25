#!/usr/bin/env bats
# Tests for the frontmatter rules of forked and inline skills (spec: skill-fork-policy), plus the expected
# frontmatter of the skill that runs as a fork (spec: git-workflow-skills).
# A fork runs in a subagent without the conversation's context, so it may carry `model:` and `effort:`; an inline
# skill may not, because an inline `effort:` lasts to the end of the turn and rebuilds the conversation cache.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

# frontmatter <SKILL.md>: the lines between the two `---` fences.
frontmatter() { sed -n '2,/^---$/p' "$1" | sed '$d'; }
# field <SKILL.md> <key>: the value of a top-level frontmatter key, empty when absent.
field() { frontmatter "$1" | sed -n "s/^$2: *//p" | head -1; }
all_skills() { find "$REPO/skills" -mindepth 2 -maxdepth 3 -name SKILL.md | sort; }
# skill_name <SKILL.md>: the directory name, used in failure output.
skill_name() { basename "$(dirname "$1")"; }

@test "every skill is found" {
  [ "$(all_skills | wc -l)" -ge 4 ]
}

@test "rule: a fork skill has background: false" {
  bad=""
  while IFS= read -r f; do
    [ "$(field "$f" context)" = fork ] || continue
    [ "$(field "$f" background)" = false ] || bad="$bad $(skill_name "$f")"
  done < <(all_skills)
  [ -z "$bad" ] || { echo "fork skills without 'background: false':$bad"; false; }
}

@test "rule: a fork skill does not allow AskUserQuestion" {
  bad=""
  while IFS= read -r f; do
    [ "$(field "$f" context)" = fork ] || continue
    # The whole frontmatter, so a YAML list under allowed-tools counts too.
    if frontmatter "$f" | grep -qw AskUserQuestion; then bad="$bad $(skill_name "$f")"; fi
  done < <(all_skills)
  [ -z "$bad" ] || { echo "fork skills that allow AskUserQuestion:$bad"; false; }
}

@test "rule: model and effort appear only in fork skills" {
  bad=""
  while IFS= read -r f; do
    [ "$(field "$f" context)" = fork ] && continue
    if frontmatter "$f" | grep -qE '^(model|effort):'; then bad="$bad $(skill_name "$f")"; fi
  done < <(all_skills)
  [ -z "$bad" ] || { echo "inline skills with model: or effort::$bad"; false; }
}

@test "rule: model is an alias (haiku, sonnet, opus, fable)" {
  bad=""
  while IFS= read -r f; do
    m="$(field "$f" model)"
    [ -z "$m" ] && continue
    case "$m" in haiku|sonnet|opus|fable) ;; *) bad="$bad $(skill_name "$f")=$m" ;; esac
  done < <(all_skills)
  [ -z "$bad" ] || { echo "skills whose model: is not an alias:$bad"; false; }
}

@test "rule: a haiku skill has no effort" {
  bad=""
  while IFS= read -r f; do
    [ "$(field "$f" model)" = haiku ] || continue
    [ -z "$(field "$f" effort)" ] || bad="$bad $(skill_name "$f")"
  done < <(all_skills)
  [ -z "$bad" ] || { echo "haiku skills with effort::$bad"; false; }
}

# expect_fork <skill dir> <model> [effort]: the frontmatter of a fork skill.
expect_fork() {
  local f="$REPO/skills/$1/SKILL.md"
  [ -f "$f" ]
  [ "$(field "$f" context)" = fork ]
  [ "$(field "$f" background)" = false ]
  [ "$(field "$f" model)" = "$2" ]
  [ "$(field "$f" effort)" = "${3:-}" ]
}

@test "commit runs as a fork on sonnet with effort low" {
  expect_fork git/commit sonnet low
}
