#!/usr/bin/env bash
# verify-gate.sh: Stop hook. When this session changed the working tree, run the repository's verify
# convention at the git top level of cwd (make verify-fast -> make verify -> pnpm run verify / npm run verify) and
# refuse to stop while it fails: at most 3 blocks in a turn, then a systemMessage says the tree is still failing.
# A continuation (stop_hook_active) is verified too; with the tree unchanged since the failed run, the last result
# is reused instead of running verify again. Turn state: sessions/<id>/verify-blocks (count, tree, exit code).
# Contract (openspec: verify-gate): silent unless blocking; exit 0 always; never runs for subagents,
# when USKN_SKIP_VERIFY=1, outside git, or without a convention.
# The run is capped at USKN_VERIFY_TIMEOUT seconds (default 570, inside the hook's 600) through with_timeout, which
# works without GNU timeout too. A block is {decision, reason} only: the Stop schema has nothing else for it.
# In a confined environment (the checkout's .uskn-environment) the convention and the fingerprint's git run under
# lib/confined.sb through sandbox-exec, with only the shared tools added to PATH. Without the rules (not macOS, no
# sandbox-exec) nothing of the repository runs: a systemMessage says the work is not verified, and nothing blocks.
set -u
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
PATH="$(hook_path)"; export PATH
say() { # <systemMessage>
  if have jq; then jq -c -n --arg m "$1" '{systemMessage:$m}'
  else printf '{"systemMessage":"%s"}\n' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"; fi
}
INPUT="$(cat 2>/dev/null || true)"
[ -z "$(json_field "$INPUT" '.agent_type' agent_type)" ] || exit 0
[ "${USKN_SKIP_VERIFY:-0}" = 1 ] && exit 0
ACTIVE="$(json_bool "$INPUT" stop_hook_active)"   # true: a continuation after a Stop hook blocked, same turn
SID="$(json_field "$INPUT" '.session_id' session_id)"; CWD="$(json_field "$INPUT" '.cwd' cwd)"
[ -n "$SID" ] || exit 0
TOP="$(git -C "${CWD:-$PWD}" rev-parse --show-toplevel 2>/dev/null || true)"; [ -n "$TOP" ] || exit 0
DIR="$USKN_STATE/sessions/$SID"; mkdir -p "$DIR" 2>/dev/null || exit 0
BLOCKS="$DIR/verify-blocks"
[ "$ACTIVE" = true ] || rm -f "$BLOCKS"   # a Stop that is not a continuation starts a turn: count from zero
CMD=""
for mk in Makefile GNUmakefile; do
  if [ -n "$CMD" ] || [ ! -f "$TOP/$mk" ]; then continue; fi
  if grep -qE '^verify-fast[[:space:]]*:' "$TOP/$mk"; then CMD="make verify-fast"
  elif grep -qE '^verify[[:space:]]*:' "$TOP/$mk"; then CMD="make verify"; fi
done
if [ -z "$CMD" ] && [ -f "$TOP/package.json" ]; then
  if { have jq && jq -e '.scripts.verify' "$TOP/package.json" >/dev/null 2>&1; } || { ! have jq && grep -q '"verify"' "$TOP/package.json"; }; then
    if [ -f "$TOP/pnpm-lock.yaml" ]; then CMD="pnpm run verify"; else CMD="npm run verify"; fi
  fi
fi
[ -n "$CMD" ] || exit 0
if ! run_prefix; then   # confined, and the rules cannot be used: run nothing of the repository, not even git
  say "uskn-harness verify gate: not verified. This is a confined environment, where \`$CMD\` and git run only under the rules of lib/confined.sb, and those need macOS with sandbox-exec ($(host_os) here). Nothing in $TOP was run; check the work by other means before reporting it as done."
  exit 0
fi
NOW="$(tree_fingerprint "$TOP")"
if [ ! -s "$DIR/baseline" ]; then
  printf '%s\n' "$NOW" > "$DIR/baseline"
  exit 0
fi
[ "$NOW" = "$(cat "$DIR/baseline")" ] && exit 0
[ -s "$DIR/verified" ] && [ "$NOW" = "$(cat "$DIR/verified")" ] && exit 0


LOG="$DIR/verify.log"
LIMIT="${USKN_VERIFY_TIMEOUT:-570}"
MAX_BLOCKS=3
# verify-blocks, within one turn: the blocks so far, the tree after the last failed run, and its exit code
COUNT=0 FP="" RC=""
if [ -s "$BLOCKS" ]; then { read -r COUNT; read -r FP; read -r RC; } < "$BLOCKS"; fi
case "$COUNT" in '' | *[!0-9]*) COUNT=0 ;; esac
if [ -n "$FP" ] && [ "$NOW" = "$FP" ] && [ -s "$LOG" ] && [ -n "$RC" ]; then
  : # nothing changed since the failed run in this turn: the same failure, without running it again
else
  ( cd "$TOP" && with_timeout "$LIMIT" ${RUN_PREFIX[@]+"${RUN_PREFIX[@]}"} bash -c "$CMD" ) >"$LOG" 2>&1; RC=$?
  # Record the tree as it is after the run: a verify that writes files (logs, lockfiles) must not trigger itself again.
  FP="$(tree_fingerprint "$TOP")"
  if [ "$RC" -eq 0 ]; then printf '%s\n' "$FP" > "$DIR/verified"; rm -f "$BLOCKS"; exit 0; fi
fi
case "$RC" in '' | *[!0-9]*) RC=1 ;; esac

NOTE=""; [ "$RC" -eq 124 ] && NOTE=" (timed out after ${LIMIT}s)"
if [ "$COUNT" -ge "$MAX_BLOCKS" ]; then
  say "uskn-harness verify gate: \`$CMD\` still fails with exit $RC$NOTE in $TOP after $MAX_BLOCKS blocks in this turn, so the turn ends with the tree failing. Full log: $LOG."
  exit 0
fi
printf '%s\n%s\n%s\n' "$((COUNT + 1))" "$FP" "$RC" > "$BLOCKS"
REASON="uskn-harness verify gate: \`$CMD\` failed with exit $RC$NOTE in $TOP. Fix the failures and finish again; do not report the work as done until it passes. Full log: $LOG. To bypass deliberately, set USKN_SKIP_VERIFY=1.

Last lines:
$(tail -n 40 "$LOG")"
if have jq; then
  jq -c -n --arg r "$REASON" '{decision:"block", reason:$r}'
else
  esc="$(printf '%s' "$REASON" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}')"
  printf '{"decision":"block","reason":"%s"}\n' "$esc"
fi
exit 0
