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
