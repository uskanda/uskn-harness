#!/usr/bin/env bash
# bash-guard.sh: PreToolUse hook (Bash). Denies the typical ways of changing another repository from the shell
# (chezmoi apply/add/update/edit, git writes via `git -C <outside>` or `cd <outside> && git ...`) and warns, via
# additionalContext, about copies / moves / redirects that target paths outside the project root.
# Contract (openspec: bash-guard): exit 0 always; silent for commands that stay inside the root.
set -u
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
INPUT="$(cat 2>/dev/null || true)"; [ -n "$INPUT" ] || exit 0
CMD="$(json_field "$INPUT" '.tool_input.command' command)"; [ -n "$CMD" ] || exit 0
CWD="$(json_field "$INPUT" '.cwd' cwd)"; SID="$(json_field "$INPUT" '.session_id' session_id)"
ROOT="$(project_root "${CWD:-$PWD}")"
# expand ~ and $HOME for the path checks only
CMDX="$(printf '%s' "$CMD" | sed "s#\(^\|[[:space:]=]\)~/#\1$HOME/#g; s#\\\$HOME/#$HOME/#g; s#\\\${HOME}/#$HOME/#g")"
WRITE_VERBS='(push|commit|reset|checkout|switch|rebase|merge|cherry-pick|apply|am)'
DENY=""; WARN=""
outside() { # <path>: absolute, resolved, and not allowed
  case "$1" in /*) ;; *) return 1 ;; esac
  path_allowed "$(realpath_m "$1")" "$ROOT" "$SID" && return 1
  return 0
}
add_deny() { DENY="${DENY:+$DENY }$1"; }
add_warn() { case " $WARN " in *" $1 "*) ;; *) WARN="${WARN:+$WARN }$1" ;; esac; }

# 1. chezmoi writes to the live dotfiles / home
if printf '%s' "$CMDX" | grep -qE '(^|[;&|[:space:]])chezmoi[[:space:]]+(apply|add|update|edit|re-add|merge)([[:space:]]|$)'; then
  add_deny "chezmoi apply/add/update/edit changes the live dotfiles and home; dotfiles are changed through a PR to the dotfiles repository, and applied by the user."
fi
# 2. git -C <outside> <write verb>
while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  p="$(printf '%s' "$seg" | awk '{print $3}')"
  if outside "$p" && printf '%s' "$seg" | grep -qE "[[:space:]]$WRITE_VERBS([[:space:]]|$)"; then add_deny "git write in another repository: $seg"; fi
done < <(printf '%s' "$CMDX" | grep -oE 'git[[:space:]]+-C[[:space:]]+[^[:space:]]+[^;&|]*' || true)
# 3. cd <outside> ... git <write verb>
while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  p="$(printf '%s' "$seg" | awk '{print $2}')"
  rest="${CMDX#*"$seg"}"
  if outside "$p" && printf '%s' "$rest" | grep -qE "(^|[;&|[:space:]])git[[:space:]]+([^;&|]*[[:space:]])?$WRITE_VERBS([[:space:]]|$)"; then add_deny "git write after cd into another repository: $p"; fi
done < <(printf '%s' "$CMDX" | grep -oE '(^|[;&|][[:space:]]*)cd[[:space:]]+[^[:space:];&|]+' | sed -E 's/^[;&|[:space:]]*//' || true)
# 4. warnings: file operations and redirects that target outside paths
while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  while IFS= read -r p; do [ -n "$p" ] && outside "$p" && add_warn "$p"; done < <(printf '%s' "$seg" | grep -oE '(^|[[:space:]"'"'"'=])/[^[:space:]"'"'"']+' | sed -E 's/^[[:space:]"'"'"'=]//' || true)
done < <(printf '%s' "$CMDX" | grep -oE '(^|[;&|][[:space:]]*)(cp|mv|rm|ln|tee|mkdir|touch|rsync|install|sed[[:space:]]+-i[^[:space:]]*)([[:space:]][^;&|]*)?' || true)
while IFS= read -r p; do [ -n "$p" ] && outside "$p" && add_warn "$p"; done < <(printf '%s' "$CMDX" | grep -oE '>>?[[:space:]]*/[^[:space:];&|]+' | sed -E 's/^>>?[[:space:]]*//' || true)

if [ -n "$DENY" ]; then
  deny_json "uskn-harness: $DENY Other repositories are changed through a pull request from a fresh clone in the scratchpad, or a handoff document. If the user explicitly allowed it in this session, run /allow-repo <path> first. Project root: $ROOT."
  exit 0
fi
if [ -n "$WARN" ]; then
  MSG="uskn-harness: this command touches paths outside the project root ($ROOT): $WARN. Other repositories are changed through a PR or a handoff document; if the user explicitly allowed writing there in this session, run /allow-repo <path>."
  if have jq; then jq -c -n --arg m "$MSG" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$m}}'
  else printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')"; fi
fi
exit 0
