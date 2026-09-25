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
now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
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
# ---- session journals
USKN_SESSIONS="${USKN_SESSIONS_DIR:-$HOME/.ai-sessions}"
sid8() { printf '%s' "${1:0:8}"; }
# project_key <repo-top>: origin owner/repo as owner__repo (nested groups keep joining with __); else the dir name
project_key() {
  local url path
  url="$(git -C "$1" remote get-url origin 2>/dev/null || true)"
  if [ -n "$url" ]; then
    path="$(printf '%s' "$url" | sed -E 's#\.git/?$##; s#^[a-z+]+://[^/]+/##; s#^[^@/]+@[^:]+:##; s#^/##')"
    printf '%s' "$path" | sed 's#/#__#g'
  else basename "$1"; fi
}
# session_dir_for_prefix <sid8>: the newest state dir whose name starts with the prefix
session_dir_for_prefix() {
  local d; d="$(ls -1dt "$USKN_STATE/sessions/$1"* 2>/dev/null | head -n 1)"
  [ -n "$d" ] && [ -d "$d" ] && printf '%s' "$d"
}
# to_local_stamp <iso-utc>: YYYY-MM-DD-HHMM in local time; falls back to now
to_local_stamp() {
  date -d "$1" +%Y-%m-%d-%H%M 2>/dev/null || date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$1" +%Y-%m-%d-%H%M 2>/dev/null || date +%Y-%m-%d-%H%M
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
# work_root <cwd>: the git top level of cwd, else cwd (resolved). The checks (verify gate, textlint, terms) work
# here: in a worktree, cwd moves while CLAUDE_PROJECT_DIR stays at the session's start.
work_root() {
  local r
  r="$(git -C "${1:-$PWD}" rev-parse --show-toplevel 2>/dev/null || true)"
  realpath_m "${r:-${1:-$PWD}}"
}
# git_common_dir <dir>: the repository's shared .git directory (the same for all its worktrees), resolved; empty when
# the directory is not in a repository or git is too old for --path-format (2.31).
git_common_dir() {
  local d
  d="$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 0
  [ -n "$d" ] && realpath_m "$d"
  return 0
}
# project_roots <cwd>: the roots the guards allow, one per line: CLAUDE_PROJECT_DIR, plus the git top level of cwd
# only when that checkout belongs to the same repository (the same git common dir: a worktree of it, wherever it
# lives). Bash can move cwd into any directory; a checkout of another repository must not become a root, so when
# either common dir cannot be read the cwd's top level is left out. Without CLAUDE_PROJECT_DIR: the git top level
# of cwd, else cwd.
project_roots() {
  local p="" t pc
  [ -n "${CLAUDE_PROJECT_DIR:-}" ] && p="$(realpath_m "$CLAUDE_PROJECT_DIR")"
  t="$(git -C "${1:-$PWD}" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$t" ] && t="$(realpath_m "$t")"
  if [ -n "$p" ] && [ -n "$t" ] && [ "$t" != "$p" ]; then
    pc="$(git_common_dir "$p")"
    { [ -n "$pc" ] && [ "$pc" = "$(git_common_dir "$t")" ]; } || t=""
  fi
  [ -n "$p" ] || [ -n "$t" ] || t="$(realpath_m "${1:-$PWD}")"
  [ -n "$p" ] && printf '%s\n' "$p"
  [ -n "$t" ] && [ "$t" != "$p" ] && printf '%s\n' "$t"
  return 0
}
# roots_text <roots>: the roots on one line, for a reason text
roots_text() { printf '%s' "$1" | paste -sd, - | sed 's/,/, /g'; }
# is_allow_file <abs-path>: the path (symlinks resolved) is a session allow file, sessions/<id>/allow in the state
# dir. Only allow-repo.sh writes those; the guards deny every other write, whatever the allow files say.
is_allow_file() {
  local p st
  p="$(realpath_m "$1")"; st="$(realpath_m "$USKN_STATE")"
  case "$p" in "$st"/sessions/*/allow) return 0 ;; esac
  return 1
}
# The verify gate's state in sessions/<id>/. The gate trusts these files (rewriting verified or removing baseline
# skips the check), so the guards deny every write by the agent, whatever the allow files say; only hooks write them.
GATE_FILES="baseline verified verify-blocks"
GATE_DENY="is the verify gate's state (sessions/<id>/ baseline, verified, verify-blocks in $USKN_STATE). Only the harness hooks write it, and nothing lifts this restriction. To skip the gate deliberately, the user sets USKN_SKIP_VERIFY=1."
state_real() { [ -n "${_USKN_STATE_REAL:-}" ] || _USKN_STATE_REAL="$(realpath_m "$USKN_STATE")"; }   # sets _USKN_STATE_REAL
# is_gate_file <abs-path>: the path (symlinks resolved) is one of the gate's state files of some session
is_gate_file() {
  local p rest
  p="$(realpath_m "$1")"; state_real
  case "$p" in "$_USKN_STATE_REAL"/sessions/*/*) ;; *) return 1 ;; esac
  rest="${p#"$_USKN_STATE_REAL"/sessions/}"
  case "$rest" in */*/*) return 1 ;; esac
  case " $GATE_FILES " in *" ${rest#*/} "*) return 0 ;; esac
  return 1
}
# is_session_dir <abs-path>: the path is a session's state dir itself, sessions/<id>
is_session_dir() {
  local p rest
  p="$(realpath_m "$1")"; state_real
  case "$p" in "$_USKN_STATE_REAL"/sessions/?*) ;; *) return 1 ;; esac
  rest="${p#"$_USKN_STATE_REAL"/sessions/}"
  case "$rest" in */*) return 1 ;; esac
  return 0
}
# holds_state <abs-path>: removing the path removes the state of every session: sessions/, the state dir, or above
holds_state() {
  local p
  p="$(realpath_m "$1")"; state_real
  [ "$p" = "$_USKN_STATE_REAL/sessions" ] && return 0
  under "$_USKN_STATE_REAL" "$p"
}
# path_allowed <abs-path> <roots> <session_id>: inside one of the roots (one per line, see project_roots), the fixed
# allowlist, or the session's allow file. The scratch/tmp part of the allowlist is USKN_GUARD_ALLOW_DIRS
# (colon-separated; default /tmp and $TMPDIR).
# A session allow file is never allowed (is_allow_file), even though the state dir is on the list.
path_allowed() {
  local p="$1" roots="$2" sid="$3" a dirs
  is_allow_file "$p" && return 1
  while IFS= read -r a; do [ -n "$a" ] && under "$p" "$a" && return 0; done <<< "$roots"
  case "$p" in /dev/*) return 0 ;; esac   # /dev/null and friends are not a repository
  dirs="${USKN_GUARD_ALLOW_DIRS-/tmp:${TMPDIR:-}}"
  for a in $(printf '%s' "$dirs" | tr ':' ' ') "$HOME/.ai-sessions" "$USKN_STATE" "${CLAUDE_PLUGIN_DATA:-}"; do
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
