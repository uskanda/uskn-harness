#!/usr/bin/env bats
# Tests for the Makefile's strict mode (spec: ci-verify). A PATH with only the shell basics makes every
# tool-dependent check skip; HOME is moved so the mise shims the Makefile prepends do not exist either.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
  # an outer make (make verify-fast CHANGED=..., make verify VERIFY_STRICT=1) passes its variables down through
  # MAKEFLAGS; the makes under test must not inherit them
  unset MAKEFLAGS MFLAGS MAKELEVEL VERIFY_BASE CHANGED
  NOTOOLS="$BATS_TEST_TMPDIR/bin"; mkdir -p "$NOTOOLS" "$BATS_TEST_TMPDIR/home"
  local t p
  for t in make bash sh env grep sed awk find jq head tail wc sort uniq cut basename dirname cat tr xargs; do
    p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$NOTOOLS/$t"
  done
}
mk() { env -i HOME="$BATS_TEST_TMPDIR/home" PATH="$NOTOOLS" make -C "$REPO" "$@"; }
# skill <dir> <description line>: a SKILL.md whose frontmatter carries that raw description line
skill() { mkdir -p "$1"; printf -- '---\nname: %s\n%s\n---\n\n# body\n' "$(basename "$1")" "$2" > "$1/SKILL.md"; }
has_yaml() { python3 -c 'import yaml' >/dev/null 2>&1; }
# copy_makefile <dir>: the Makefile and the hooks' lib it reads, in a directory of their own
copy_makefile() {
  mkdir -p "$1/docs/adr" "$1/plugins/uskn-harness/hooks/scripts/lib"
  cp "$REPO/Makefile" "$1/"
  cp "$REPO/plugins/uskn-harness/hooks/scripts/lib/common.sh" "$1/plugins/uskn-harness/hooks/scripts/lib/"
}

@test "default: a missing tool is reported as skipped and the target succeeds" {
  run mk verify-design
  [ "$status" -eq 0 ]; [[ "$output" == *"[design.md] skipped"* ]] || false
  run mk verify-textlint
  [ "$status" -eq 0 ]; [[ "$output" == *"[textlint] skipped"* ]] || false
}

@test "VERIFY_STRICT=1: a missing tool fails the target and names the check" {
  run mk verify-design VERIFY_STRICT=1
  [ "$status" -ne 0 ]; [[ "$output" == *"[design.md]"* ]] || false; [[ "$output" == *"VERIFY_STRICT"* ]] || false
  run mk verify-textlint VERIFY_STRICT=1
  [ "$status" -ne 0 ]; [[ "$output" == *"[textlint]"* ]] || false; [[ "$output" == *"VERIFY_STRICT"* ]] || false
  run mk verify-plugin VERIFY_STRICT=1
  [ "$status" -ne 0 ]; [[ "$output" == *"[plugin]"* ]] || false
}

@test "verify-terms without python3: skipped by default, a failure under VERIFY_STRICT=1" {
  run mk verify-terms
  [ "$status" -eq 0 ]; [[ "$output" == *"skipped"* ]] || false
  run mk verify-terms VERIFY_STRICT=1
  [ "$status" -ne 0 ]; [[ "$output" == *"[terms]"* ]] || false; [[ "$output" == *"VERIFY_STRICT"* ]] || false
}

@test "verify-skills parses every frontmatter as YAML: an unquoted colon fails and names the file" {
  has_yaml || skip "python3 with PyYAML is not available"
  fx="$BATS_TEST_TMPDIR/skills"
  skill "$fx/good" 'description: Do a thing - argument is a name.'
  skill "$fx/git/bad" 'description: Do a thing. Optional argument: a name.'
  run make -C "$REPO" verify-skills SKILLS_DIR="$fx"
  [ "$status" -ne 0 ]
  [[ "$output" == *"$fx/git/bad/SKILL.md"* ]] || false
  [[ "$output" != *"$fx/good/SKILL.md"* ]] || false
}

@test "verify-skills: a name that differs from the directory and an empty description fail" {
  has_yaml || skip "python3 with PyYAML is not available"
  fx="$BATS_TEST_TMPDIR/skills"
  skill "$fx/one" 'description: ""'
  mkdir -p "$fx/two"; printf -- '---\nname: other\ndescription: x\n---\n' > "$fx/two/SKILL.md"
  run make -C "$REPO" verify-skills SKILLS_DIR="$fx"
  [ "$status" -ne 0 ]
  [[ "$output" == *"one/SKILL.md"*"description"* ]] || false
  [[ "$output" == *"two/SKILL.md"*"name"* ]] || false
}

@test "verify-skills passes on this repository's skills" {
  has_yaml || skip "python3 with PyYAML is not available"
  run make -C "$REPO" verify-skills
  [ "$status" -eq 0 ]
  [[ "$output" == *"[skills]"* ]] || false
}

@test "verify-skills without PyYAML: skipped by default, a failure under VERIFY_STRICT=1" {
  run mk verify-skills
  [ "$status" -eq 0 ]; [[ "$output" == *"skipped"* ]] || false
  run mk verify-skills VERIFY_STRICT=1
  [ "$status" -ne 0 ]; [[ "$output" == *"[skills]"* ]] || false; [[ "$output" == *"VERIFY_STRICT"* ]] || false
}

@test "VERIFY_STRICT=0 behaves like the default" {
  run mk verify-design VERIFY_STRICT=0
  [ "$status" -eq 0 ]; [[ "$output" == *"skipped"* ]] || false
}

# ---- verify-fast (spec: verify-fast). verify-fast-plan prints what verify-fast would check, one "<check>: <files>"
# line each; CHANGED on the make command line stands in for the files that changed.
plan() { make -s -C "$REPO" verify-fast-plan "$@"; }
line() { printf '%s\n' "$output" | sed -n "s/^$1: *//p"; }
count() { line "$1" | wc -w; }

@test "verify-fast-plan: one changed document gets textlint and terms, nothing else" {
  run plan CHANGED="docs/adr/0001-harness-architecture.md"
  [ "$status" -eq 0 ]
  [ "$(line textlint)" = "docs/adr/0001-harness-architecture.md" ]
  [ "$(line terms)" = "docs/adr/0001-harness-architecture.md" ]
  [ -z "$(line shellcheck)" ]
  [ -z "$(line bats)" ]
}

@test "verify-fast-plan: a skill is an English document: terms only; its own and the all-skills tests run" {
  run plan CHANGED="skills/ok/SKILL.md"
  [ -z "$(line textlint)" ]
  [ "$(line terms)" = "skills/ok/SKILL.md" ]
  [[ " $(line bats) " == *" bin/tests/ok-skill.bats "* ]] || false
}

@test "verify-fast-plan: the glossary sends every document to terms; the textlint config sends every one to textlint" {
  run plan CHANGED="openspec/glossary.yml"
  [ "$(count terms)" -gt 10 ]
  [ -z "$(line textlint)" ]
  run plan CHANGED="skills/ja-writing/prh.yml"
  [ "$(count textlint)" -gt 10 ]
}

@test "verify-fast-plan: one hook script gets shellcheck and its own bats file" {
  run plan CHANGED="plugins/uskn-harness/hooks/scripts/verify-gate.sh"
  [ "$(line shellcheck)" = "plugins/uskn-harness/hooks/scripts/verify-gate.sh" ]
  [ "$(line bats)" = "plugins/uskn-harness/hooks/tests/verify-gate.bats" ]
  [ -z "$(line textlint)" ]
}

@test "verify-fast-plan: the shared lib sends every script to shellcheck and runs every hook test" {
  run plan CHANGED="plugins/uskn-harness/hooks/scripts/lib/common.sh"
  [ "$(count shellcheck)" -ge 10 ]
  [ "$(count bats)" -eq "$(ls "$REPO"/plugins/uskn-harness/hooks/tests/*.bats | wc -l)" ]
}

@test "verify-fast-plan: the installer and the Makefile map to their tests; a changed test runs itself" {
  run plan CHANGED="bin/uskn-harness Makefile plugins/uskn-harness/hooks/tests/common.bats"
  [ "$(line shellcheck)" = "bin/uskn-harness" ]
  [ "$(line bats)" = "bin/tests/makefile.bats bin/tests/uskn-harness.bats plugins/uskn-harness/hooks/tests/common.bats" ]
}

@test "verify-fast-plan: bin/uskn-loop and loop/ map to the loop's test" {
  run plan CHANGED="loop/prompts/auditor.md"
  [ "$(line bats)" = "bin/tests/uskn-loop.bats" ]
  run plan CHANGED="bin/uskn-loop loop/lib/run.sh"
  [ "$(line bats)" = "bin/tests/uskn-loop.bats" ]
  [ "$(line shellcheck)" = "bin/uskn-loop" ]
}

@test "verify-fast-plan: hooks.json and the plugin's bin/ map to their own tests; a skill runs the all-skills tests" {
  run plan CHANGED="plugins/uskn-harness/hooks/hooks.json"
  [ "$(line bats)" = "plugins/uskn-harness/hooks/tests/hooks-json.bats" ]
  run plan CHANGED="plugins/uskn-harness/bin/uskn-repo-context"
  [ "$(line bats)" = "plugins/uskn-harness/hooks/tests/plugin-bin.bats" ]
  [ "$(line shellcheck)" = "plugins/uskn-harness/bin/uskn-repo-context" ]
  run plan CHANGED="skills/git/push/SKILL.md"
  [[ " $(line bats) " == *" bin/tests/skill-commands.bats "* ]] || false
}

@test "verify-fast: nothing changed passes without running a check" {
  run mk verify-fast CHANGED=
  [ "$status" -eq 0 ]
  [[ "$output" == *"nothing to check"* ]] || false
  [[ "$output" != *"[terms]"* ]] || false
}

@test "verify-fast: a failing check fails the target; a missing tool skips, and fails under VERIFY_STRICT=1" {
  printf '#!/usr/bin/env bash\necho "fake terms: $*"; exit 1\n' > "$BATS_TEST_TMPDIR/terms"; chmod +x "$BATS_TEST_TMPDIR/terms"
  run mk verify-fast CHANGED=README.md TERMS_CHECK="$BATS_TEST_TMPDIR/terms"
  [ "$status" -ne 0 ]
  [[ "$output" == *"fake terms: README.md"* ]] || false
  [[ "$output" == *"[textlint] skipped"* ]] || false
  run mk verify-fast CHANGED=README.md VERIFY_STRICT=1
  [ "$status" -ne 0 ]; [[ "$output" == *"VERIFY_STRICT"* ]] || false
}

@test "verify-fast: the changed files are the commits since the remote base plus the working tree and untracked files" {
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  T="$BATS_TEST_TMPDIR/repo"; copy_makefile "$T"
  echo a > "$T/README.md"; echo b > "$T/docs/adr/0001-a.md"; echo c > "$T/docs/adr/0002-b.md"
  ( cd "$T" && git init -q -b main && git add -A && git commit -qm base && git update-ref refs/remotes/origin/main HEAD )
  echo a2 > "$T/README.md"; ( cd "$T" && git commit -qam change )
  echo b2 > "$T/docs/adr/0001-a.md"
  echo d > "$T/docs/adr/0003-new.md"
  ( cd "$T" && git rm -q docs/adr/0002-b.md )
  run make -s -C "$T" verify-fast-plan
  [ "$status" -eq 0 ]
  [ "$(line textlint)" = "README.md docs/adr/0001-a.md docs/adr/0003-new.md" ]
  VERIFY_BASE=HEAD run make -s -C "$T" verify-fast-plan
  [ "$(line textlint)" = "docs/adr/0001-a.md docs/adr/0003-new.md" ]
}

@test "verify-fast: the sandbox's placeholders are not changed files" {
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  T="$BATS_TEST_TMPDIR/repo"; copy_makefile "$T"
  echo a > "$T/README.md"
  ( cd "$T" && git init -q -b main && git add -A && git commit -qm base && git update-ref refs/remotes/origin/main HEAD )
  : > "$T/.mcp.json"; echo b > "$T/docs/adr/0001-a.md"
  run make -s -C "$T" verify-fast-plan
  [ "$status" -eq 0 ]
  [[ "$output" != *.mcp.json* ]] || false
  [[ "$output" == *docs/adr/0001-a.md* ]] || false
}

# ---- verify-archive (spec: ci-verify; ADR-0014)
# pr_repo [file]: a repository whose HEAD is the merge commit of a pull request into main, as actions/checkout gives
# it. The request adds openspec/changes/add-x/proposal.md, plus openspec/changes/add-x/<file> when one is named.
pr_repo() {
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  T="$BATS_TEST_TMPDIR/repo"; copy_makefile "$T"
  cp "$REPO/plugins/uskn-harness/hooks/scripts/archive-check.sh" "$T/plugins/uskn-harness/hooks/scripts/"
  echo a > "$T/README.md"
  ( cd "$T" && git init -q -b main && git add -A && git commit -qm base && git switch -q -c change/add-x \
      && mkdir -p openspec/changes/add-x && echo x > openspec/changes/add-x/proposal.md \
      && { [ -z "${1:-}" ] || echo "follow-up in #20" > "openspec/changes/add-x/$1"; } \
      && git add -A && git commit -qm add-x && git switch -q main && git merge -q --no-ff -m merge change/add-x )
}
# event <draft>: the pull_request event file GitHub Actions points GITHUB_EVENT_PATH at
event() { printf '{"pull_request":{"number":1,"draft":%s}}\n' "$1" > "$BATS_TEST_TMPDIR/event.json"; }
pr_make() { GITHUB_EVENT_NAME=pull_request GITHUB_EVENT_PATH="$BATS_TEST_TMPDIR/event.json" GITHUB_SHA= make -s -C "$T" "$@"; }

@test "verify-archive outside a pull request: skipped, exit 0" {
  pr_repo
  GITHUB_EVENT_NAME=push run make -s -C "$T" verify-archive
  [ "$status" -eq 0 ]
  [[ "$output" == *"[archive] skipped"* ]] || false
  run env -u GITHUB_EVENT_NAME make -s -C "$T" verify-archive VERIFY_STRICT=1
  [ "$status" -eq 0 ]
  [[ "$output" == *"[archive] skipped"* ]] || false
}

@test "verify-archive on a draft pull request: not checked, exit 0" {
  pr_repo; event true
  run pr_make verify-archive VERIFY_STRICT=1
  [ "$status" -eq 0 ]
  [[ "$output" == *draft* ]] || false
  [[ "$output" != *add-x* ]] || false
}

@test "verify-archive on a ready pull request that brings in an unarchived change: fails and names it" {
  pr_repo; event false
  run pr_make verify-archive
  [ "$status" -ne 0 ]
  [[ "$output" == *add-x* ]] || false
  [[ "$output" == *"/archive-push"* ]] || false
}

@test "verify-archive on a ready pull request whose change declares archive-later: passes" {
  pr_repo .archive-later; event false
  run pr_make verify-archive VERIFY_STRICT=1
  [ "$status" -eq 0 ]
}

@test "verify-archive that cannot decide: skipped by default, a failure under VERIFY_STRICT=1" {
  pr_repo; event false
  ( cd "$T" && git reset -q --hard change/add-x && git checkout -q --orphan lone && git commit -qm lone )
  run pr_make verify-archive
  [ "$status" -eq 0 ]
  [[ "$output" == *"[archive]"* ]] || false
  run pr_make verify-archive VERIFY_STRICT=1
  [ "$status" -ne 0 ]
  [[ "$output" == *"[archive]"* ]] || false; [[ "$output" == *VERIFY_STRICT* ]] || false
}

@test "verify runs verify-archive" {
  grep -qE '^verify:.* verify-archive( |$)' "$REPO/Makefile"
}
