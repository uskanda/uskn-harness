---
name: allow-repo
description: Let this session write to a path outside the project root, after the user asked for it.
argument-hint: "<path> | --list"
disable-model-invocation: true
allowed-tools: Bash
---

# allow-repo: session-scoped exception to the project boundary

The `write-guard` and `bash-guard` hooks stop writes outside the project root. This skill records an exception for
the current session only, and only because the user asked for it in this conversation.

## Steps

1. Confirm the request came from the user in this session (a sentence such as "dotfiles を直接直してよい"). If it did not, stop and ask.
2. `<sid8>` is the first 8 characters of this session's id, `${CLAUDE_SESSION_ID}`. When that still reads as the
   literal placeholder, take the first 8 characters of the environment variable `CLAUDE_CODE_SESSION_ID` instead.
   Run:
   `"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/allow-repo.sh" --session <sid8> "$ARGUMENTS"`
   The script falls back to `CLAUDE_CODE_SESSION_ID` by itself when `--session` is empty.
3. Report the resolved path and remind the user that changes there still need their own commit or pull request in that repository.

`--list` instead of a path shows the current exceptions. The exception ends with the session.
