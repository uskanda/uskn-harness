---
name: allow-repo
description: Let this session write to a path outside the project root, such as another repository, after the user explicitly asked for it. Argument - the path to allow. Never run this on your own initiative.
disable-model-invocation: true
allowed-tools: Bash
---

# allow-repo: session-scoped exception to the project boundary

The `write-guard` and `bash-guard` hooks stop writes outside the project root. This skill records an exception for
the current session only, and only because the user asked for it in this conversation.

## Steps

1. Confirm the request came from the user in this session (a sentence such as "dotfiles を直接直してよい"). If it did not, stop and ask.
2. Take `session: <sid8>` from the `<repo-context>` block and run:
   `"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/allow-repo.sh" --session <sid8> "$ARGUMENTS"`
3. Report the resolved path and remind the user that changes there still need their own commit or pull request in that repository.

`--list` instead of a path shows the current exceptions. The exception ends with the session.
