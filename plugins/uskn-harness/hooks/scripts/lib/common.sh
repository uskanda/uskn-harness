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
# json_out <jq-program> [--arg k v ...]: emit JSON with jq when present (callers keep a printf fallback)
