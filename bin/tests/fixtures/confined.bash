# Helpers for tests of the confined environment (openspec: environment-kind). Loaded with `load fixtures/confined`.
# The marker sits in the checkout, so a test that marks one works on a copy of the repository, never on $REPO.

# confined_copy <dest>: a copy of the repository's working tree without .git and node_modules
confined_copy() {
  mkdir -p "$1"
  tar -C "$REPO" -cf - --exclude ./.git --exclude ./node_modules --exclude ./.uskn-environment . | tar -C "$1" -xf -
}
# mark_confined <checkout> [tools] [secrets]: write the environment marker of a confined environment
mark_confined() {
  { echo "kind=confined"; [ -z "${2:-}" ] || echo "tools=$2"; [ -z "${3:-}" ] || echo "secrets=$3"; } > "$1/.uskn-environment"
}
# shared_tools <dir>: a shared tools dir whose installed.json matches deps.json, with every third-party skill present
shared_tools() {
  local d="$1" n
  mkdir -p "$d/bin" "$d/skills"
  jq '{runtimes: {node: {version: .runtimes.node.version}, jq: {version: .runtimes.jq.version}},
       clis: (.clis | with_entries(select(.value.global == true)) | map_values({version, bundle: (.bundle // {})})),
       skills: (.skills | with_entries(select(.value.mode == "reference" and .value.via != null)) | map_values({ref, version}))}' \
    "$REPO/deps.json" > "$d/installed.json"
  for n in $(jq -r '.skills | to_entries[] | select(.value.mode == "reference" and .value.via != null) | .key' "$REPO/deps.json"); do
    mkdir -p "$d/skills/$n"; printf -- '---\nname: %s\ndescription: x\n---\n' "$n" > "$d/skills/$n/SKILL.md"
  done
}
