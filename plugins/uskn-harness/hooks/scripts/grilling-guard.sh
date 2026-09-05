#!/usr/bin/env bash
# grilling-guard.sh: PreToolUse hook (Write | Edit | MultiEdit | NotebookEdit).
#
# Denies a write to an OpenSpec change's proposal.md, design.md, tasks.md, or specs/** when that change
# has no grilling.md yet. Prints nothing otherwise, so the normal permission flow applies.
# Contract (openspec: grilling-guard): never fails the session; exit 0 always.
set -u
have() { command -v "$1" >/dev/null 2>&1; }

INPUT="$(cat 2>/dev/null || true)"
[ -n "$INPUT" ] || exit 0
if have jq; then
  FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null || true)"
  CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)"
else
  FILE="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  CWD="$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
fi
[ -n "$FILE" ] || exit 0

case "$FILE" in /*) ABS="$FILE" ;; *) ABS="${CWD:-$PWD}/$FILE" ;; esac
if have realpath; then ABS="$(realpath -m "$ABS" 2>/dev/null || printf '%s' "$ABS")"; fi

case "$ABS" in
  */openspec/changes/archive/*) exit 0 ;;
  */openspec/changes/*/grilling.md) exit 0 ;;
esac
CHANGE_DIR="$(printf '%s' "$ABS" | sed -n 's#^\(.*/openspec/changes/[^/]*\)/.*$#\1#p')"
[ -n "$CHANGE_DIR" ] || exit 0
REL="${ABS#"$CHANGE_DIR"/}"
case "$REL" in
  proposal.md | design.md | tasks.md | specs/*) ;;
  *) exit 0 ;;
esac
[ -f "$CHANGE_DIR/grilling.md" ] && exit 0

NAME="$(basename "$CHANGE_DIR")"
REASON="uskn-harness: OpenSpec change '$NAME' has no grilling.md. Spec decisions go through the grilling interview first: run the spec skill (or the grilling skill), get the user's confirmation that the frontier is empty, write $CHANGE_DIR/grilling.md, and only then write $REL."
if have jq; then
  jq -c -n --arg r "$REASON" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
else
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$(printf '%s' "$REASON" | sed 's/\\/\\\\/g; s/"/\\"/g')"
fi
exit 0
