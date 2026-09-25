#!/usr/bin/env bash
# Shared helpers for the harness hooks. Sourced, not executed.
# shellcheck disable=SC2034
USKN_STATE="${USKN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/uskn-harness}"
have() { command -v "$1" >/dev/null 2>&1; }
# json_field <input> <jq-path> <key-for-sed-fallback>
json_field() {
  if have jq; then printf '%s' "$1" | jq -r "$2 // empty" 2>/dev/null || true
  else printf '%s' "$1" | sed -n "s/.*\"$3\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1; fi
}
# json_bool <input> <key> -> prints true/false
json_bool() {
  if have jq; then printf '%s' "$1" | jq -r "(.$2 // false) | tostring" 2>/dev/null || echo false
  else printf '%s' "$1" | grep -qE "\"$2\"[[:space:]]*:[[:space:]]*true" && echo true || echo false; fi
}
sha() { if have sha256sum; then sha256sum | cut -d' ' -f1; else shasum -a 256 | cut -d' ' -f1; fi; }
# tree_fingerprint <repo-top>: HEAD, status, tracked diff, and the content hashes of untracked files
# (status alone would miss edits to a file that is untracked from the start).
tree_fingerprint() {
  {
    git -C "$1" rev-parse HEAD 2>/dev/null || echo none
    git -C "$1" status --porcelain 2>/dev/null
    git -C "$1" diff HEAD 2>/dev/null
    git -C "$1" ls-files --others --exclude-standard -z 2>/dev/null | (cd "$1" && xargs -0 git hash-object -- 2>/dev/null) || true
  } | sha
}
# with_timeout <seconds> <command...>: run an external command under a time cap; exit 124 when the cap was hit.
# GNU timeout, else gtimeout (Homebrew coreutils on macOS), else perl: the command runs in a process group of its
# own, which gets TERM and a second later KILL, so what it started (make -> bats) stops too. No perl: no cap.
with_timeout() {
  local t="$1"; shift
  if have timeout; then timeout "$t" "$@"
  elif have gtimeout; then gtimeout "$t" "$@"
  elif have perl; then
    # shellcheck disable=SC2016  # perl code, not shell
    perl -e '
      my $t = shift @ARGV;
      my $pid = fork();
      die "with_timeout: fork failed: $!\n" unless defined $pid;
      if ($pid == 0) { setpgrp(0, 0); exec { $ARGV[0] } @ARGV or exit 127; }
      $SIG{ALRM} = sub { kill "TERM", -$pid; sleep 1; kill "KILL", -$pid; waitpid($pid, 0); exit 124; };
      alarm $t;
      waitpid($pid, 0);
      alarm 0;
      exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
    ' "$t" "$@"
  else "$@"; fi
}
# ---- session state
# session_dir_for_prefix <sid8>: the newest state dir whose name starts with the prefix (allow-repo.sh)
session_dir_for_prefix() {
  local d; d="$(ls -1dt "$USKN_STATE/sessions/$1"* 2>/dev/null | head -n 1)"
  [ -n "$d" ] && [ -d "$d" ] && printf '%s' "$d"
}
# ---- paths and the project boundary
realpath_m() { # resolve symlinks in the existing part of a path that may not exist yet
  if realpath -m / >/dev/null 2>&1; then realpath -m "$1"
  else python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$1" 2>/dev/null || printf '%s' "$1"; fi
}
under() { case "$1" in "$2" | "$2"/*) return 0 ;; *) return 1 ;; esac; }
# harness_dir: the harness checkout. USKN_HARNESS_DIR wins (tests); else five levels above this file, symlinks resolved
harness_dir() {
  if [ -n "${USKN_HARNESS_DIR:-}" ]; then printf '%s' "$USKN_HARNESS_DIR"
  else realpath_m "$(dirname "$(realpath_m "${BASH_SOURCE[0]}")")/../../../../.."; fi
}
# project_root <cwd>: CLAUDE_PROJECT_DIR, else the git top level of cwd, else cwd (resolved)
project_root() {
  local r="${CLAUDE_PROJECT_DIR:-}"
  [ -n "$r" ] || r="$(git -C "${1:-$PWD}" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$r" ] || r="${1:-$PWD}"
  realpath_m "$r"
}
# is_allow_file <abs-path>: the path (symlinks resolved) is a session allow file, sessions/<id>/allow in the state
# dir. Only allow-repo.sh writes those; the guards deny every other write, whatever the allow files say.
is_allow_file() {
  local p st
  p="$(realpath_m "$1")"; st="$(realpath_m "$USKN_STATE")"
  case "$p" in "$st"/sessions/*/allow) return 0 ;; esac
  return 1
}
# path_allowed <abs-path> <root> <session_id>: inside the root, the fixed allowlist, or the session's allow file
# The scratch/tmp part of the allowlist is USKN_GUARD_ALLOW_DIRS (colon-separated; default /tmp and $TMPDIR).
# A session allow file is never allowed (is_allow_file), even though the state dir is on the list.
path_allowed() {
  local p="$1" root="$2" sid="$3" a dirs
  is_allow_file "$p" && return 1
  under "$p" "$root" && return 0
  case "$p" in /dev/*) return 0 ;; esac   # /dev/null and friends are not a repository
  dirs="${USKN_GUARD_ALLOW_DIRS-/tmp:${TMPDIR:-}}"
  for a in $(printf '%s' "$dirs" | tr ':' ' ') "$USKN_STATE" "${CLAUDE_PLUGIN_DATA:-}"; do
    [ -n "$a" ] || continue; [ -e "$a" ] && a="$(realpath_m "$a")"; under "$p" "$a" && return 0
  done
  case "$p" in "$(realpath_m "$HOME")"/.claude/projects/*/memory | "$(realpath_m "$HOME")"/.claude/projects/*/memory/*) return 0 ;; esac
  if [ -n "$sid" ] && [ -f "$USKN_STATE/sessions/$sid/allow" ]; then
    while IFS= read -r a; do [ -n "$a" ] && under "$p" "$(realpath_m "$a")" && return 0; done < "$USKN_STATE/sessions/$sid/allow"
  fi
  return 1
}
deny_json() { # <reason>
  if have jq; then jq -c -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  else printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"; fi
}
