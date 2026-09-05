#!/usr/bin/env bash
# verify-gate.sh: Stop hook. When this session changed the working tree, run the repository's verify
# convention (make verify -> pnpm run verify / npm run verify) and refuse to stop while it fails.
# Contract (openspec: verify-gate): silent unless blocking; exit 0 always; never runs for subagents,
# when stop_hook_active is true, when USKN_SKIP_VERIFY=1, outside git, or without a convention.
set -u
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
INPUT="$(cat 2>/dev/null || true)"
[ -z "$(json_field "$INPUT" '.agent_type' agent_type)" ] || exit 0
[ "${USKN_SKIP_VERIFY:-0}" = 1 ] && exit 0
[ "$(json_bool "$INPUT" stop_hook_active)" = true ] && exit 0
SID="$(json_field "$INPUT" '.session_id' session_id)"; CWD="$(json_field "$INPUT" '.cwd' cwd)"
[ -n "$SID" ] || exit 0
TOP="$(git -C "${CWD:-$PWD}" rev-parse --show-toplevel 2>/dev/null || true)"; [ -n "$TOP" ] || exit 0
DIR="$USKN_STATE/sessions/$SID"; mkdir -p "$DIR" 2>/dev/null || exit 0
NOW="$(tree_fingerprint "$TOP")"
if [ ! -s "$DIR/baseline" ]; then
  printf '%s\n' "$NOW" > "$DIR/baseline"; ( cd "$TOP" && pwd -P ) > "$DIR/project"; [ -s "$DIR/started" ] || now_iso > "$DIR/started"
  exit 0
fi
[ "$NOW" = "$(cat "$DIR/baseline")" ] && exit 0
[ -s "$DIR/verified" ] && [ "$NOW" = "$(cat "$DIR/verified")" ] && exit 0

CMD=""
for mk in Makefile GNUmakefile; do
  if [ -z "$CMD" ] && [ -f "$TOP/$mk" ] && grep -qE '^verify[[:space:]]*:' "$TOP/$mk"; then CMD="make verify"; fi
done
if [ -z "$CMD" ] && [ -f "$TOP/package.json" ]; then
  if { have jq && jq -e '.scripts.verify' "$TOP/package.json" >/dev/null 2>&1; } || { ! have jq && grep -q '"verify"' "$TOP/package.json"; }; then
    if [ -f "$TOP/pnpm-lock.yaml" ]; then CMD="pnpm run verify"; else CMD="npm run verify"; fi
  fi
fi
[ -n "$CMD" ] || exit 0

LOG="$DIR/verify.log"
if have timeout; then ( cd "$TOP" && timeout 570 bash -c "$CMD" ) >"$LOG" 2>&1; RC=$?
else ( cd "$TOP" && bash -c "$CMD" ) >"$LOG" 2>&1; RC=$?; fi
# Record the tree as it is after the run: a verify that writes files (logs, lockfiles) must not trigger itself again.
if [ "$RC" -eq 0 ]; then tree_fingerprint "$TOP" > "$DIR/verified"; exit 0; fi

NOTE=""; [ "$RC" -eq 124 ] && NOTE=" (timed out after 570s)"
REASON="uskn-harness verify gate: \`$CMD\` failed with exit $RC$NOTE in $TOP. Fix the failures and finish again; do not report the work as done until it passes. Full log: $LOG. To bypass deliberately, set USKN_SKIP_VERIFY=1.

Last lines:
$(tail -n 40 "$LOG")"
if have jq; then
  jq -c -n --arg r "$REASON" '{decision:"block", reason:$r, hookSpecificOutput:{hookEventName:"Stop", decision:"block", reason:$r}}'
else
  esc="$(printf '%s' "$REASON" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}')"
  printf '{"decision":"block","reason":"%s","hookSpecificOutput":{"hookEventName":"Stop","decision":"block","reason":"%s"}}\n' "$esc" "$esc"
fi
exit 0
