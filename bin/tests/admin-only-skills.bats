#!/usr/bin/env bats
# The skills that only make sense on the administrator's own machine, with a screen and its processes
# (spec: utility-skills): their frontmatter carries metadata uskn-environment: admin, which the confined sync reads.

REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
ADMIN_ONLY="cleanup set-workspace-theme"

# environment_of <SKILL.md>: the uskn-environment value under metadata in the frontmatter, or nothing
environment_of() {
  awk 'NR == 1 { if ($0 != "---") exit; next } $0 == "---" { exit }
       /^[^[:space:]]/ { meta = ($0 ~ /^metadata:[[:space:]]*$/) ; next }
       meta && /^[[:space:]]+uskn-environment:/ { sub(/^[[:space:]]+uskn-environment:[[:space:]]*/, ""); gsub(/["\047[:space:]]/, ""); print; exit }' "$1"
}

@test "cleanup and set-workspace-theme are marked admin-only in their frontmatter metadata" {
  for n in $ADMIN_ONLY; do
    f="$(find "$REPO/skills" -path "*/$n/SKILL.md" | head -n 1)"
    [ -n "$f" ] || { echo "no SKILL.md for $n"; false; }
    [ "$(environment_of "$f")" = admin ] || { echo "$n: metadata uskn-environment is not admin"; false; }
  done
}

@test "no other skill is admin-only" {
  for f in $(find "$REPO/skills" -name SKILL.md); do
    n="$(basename "$(dirname "$f")")"
    case " $ADMIN_ONLY " in *" $n "*) continue ;; esac
    [ -z "$(environment_of "$f")" ] || { echo "$n is marked $(environment_of "$f")"; false; }
  done
}
