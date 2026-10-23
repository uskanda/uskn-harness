---
name: allow-repo
description: Let this session write to a path outside the project root, after the user asked for it.
argument-hint: "<path> | --list"
disable-model-invocation: true
allowed-tools: Bash
---

# allow-repo: session-scoped exception to the project boundary

The `write-guard` and `bash-guard` hooks stop writes outside the project root. This skill records an exception for
the current session only, and only because the user asked for it in this conversation. Inside the Claude Code
sandbox, Bash writes only to the working directory and the directories the session added with `/add-dir`, so the
exception reaches Bash once the user also adds the directory.

## Steps

1. Confirm the request came from the user in this session (a sentence such as "dotfiles を直接直してよい"). If it did not, stop and ask.
2. `<sid8>` is the first 8 characters of this session's id, `${CLAUDE_SESSION_ID}`. When that still reads as the
   literal placeholder, take the first 8 characters of the environment variable `CLAUDE_CODE_SESSION_ID` instead.
   Run:
   `"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/allow-repo.sh" --session <sid8> "$ARGUMENTS"`
   The script falls back to `CLAUDE_CODE_SESSION_ID` by itself when `--session` is empty.
3. Report the resolved path and remind the user that changes there still need their own commit or pull request in that repository.
   Then ask the user to type `/add-dir <resolved path>`, so that Bash can write there inside the sandbox.
   Never run `/add-dir` yourself: only the user widens where this session may write.

`--list` instead of a path shows the current exceptions, with no `/add-dir` request. The exception ends with the session.
