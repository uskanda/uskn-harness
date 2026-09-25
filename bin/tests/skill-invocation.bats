#!/usr/bin/env bats
# Tests for how skills are invoked (spec: skill-invocation). A model-invoked skill's description sits in the
# model's context every turn, so it has a length budget; argument details go to `argument-hint`, which only the
# slash-command autocomplete shows; and a skill with `disable-model-invocation: true` cannot be run through the
# Skill tool, so no other skill may try.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
MAX_DESCRIPTION=200

setup() {
  python3 -c 'import yaml' 2>/dev/null || skip "python3 with PyYAML is required to read the frontmatter"
}

# skills_tsv: one line per SKILL.md under skills/ -- name, dmi (true/false), description + when_to_use length,
# whether argument-hint is set, whether the body reads arguments, and the skills the body runs through the Skill
# tool (space-separated).
skills_tsv() {
  python3 - "$REPO/skills" <<'PY'
import glob, os, re, sys, yaml
calls = [re.compile(r"Run the Skill tool with `([a-z0-9:-]+)`"), re.compile(r"`([a-z0-9:-]+)` skill with the Skill tool")]
reads_args = re.compile(r"\$ARGUMENTS|^## Arguments?\s*$", re.M)
for path in sorted(glob.glob(os.path.join(sys.argv[1], "**", "SKILL.md"), recursive=True)):
    lines = open(path, encoding="utf-8").read().split("\n")
    end = [ln.strip() for ln in lines].index("---", 1)
    meta = yaml.safe_load("\n".join(lines[1:end])) or {}
    body = "\n".join(lines[end + 1:])
    text = (meta.get("description") or "") + (meta.get("when_to_use") or "")
    called = sorted({m for rx in calls for m in rx.findall(body)})
    print("\t".join([
        str(meta.get("name")),
        "true" if meta.get("disable-model-invocation") is True else "false",
        str(len(text)),
        "true" if str(meta.get("argument-hint") or "").strip() else "false",
        "true" if reads_args.search(body) else "false",
        " ".join(called),
    ]))
PY
}

@test "every skill is read" {
  run skills_tsv
  [ "$status" -eq 0 ]
  [ "$(grep -c . <<<"$output")" -ge 10 ]
}

@test "rule: a model-invoked skill's description and when_to_use fit in $MAX_DESCRIPTION characters" {
  bad=""
  while IFS=$'\t' read -r name dmi len _ _ _; do
    [ "$dmi" = true ] && continue
    [ "$len" -le "$MAX_DESCRIPTION" ] || bad="$bad $name=$len"
  done < <(skills_tsv)
  [ -z "$bad" ] || { echo "model-invoked skills over $MAX_DESCRIPTION characters:$bad"; false; }
}

@test "rule: a skill that reads arguments has an argument-hint" {
  bad=""
  while IFS=$'\t' read -r name _ _ hint reads _; do
    [ "$reads" = true ] || continue
    [ "$hint" = true ] || bad="$bad $name"
  done < <(skills_tsv)
  [ -z "$bad" ] || { echo "skills that read arguments without argument-hint:$bad"; false; }
}

@test "rule: no skill runs a user-invoked skill through the Skill tool" {
  tsv="$(skills_tsv)"
  user_only=" $(awk -F'\t' '$2 == "true" { printf "%s ", $1 }' <<<"$tsv")"
  bad=""
  while IFS=$'\t' read -r name _ _ _ _ called; do
    for c in $called; do
      case "$user_only" in *" $c "*) bad="$bad $name->$c" ;; esac
    done
  done <<<"$tsv"
  [ -z "$bad" ] || { echo "skills that run a user-invoked skill through the Skill tool:$bad"; false; }
}
