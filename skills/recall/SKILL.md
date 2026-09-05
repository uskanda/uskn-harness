---
name: recall
description: Search past session journals for a keyword or a session id and summarize what was decided then. Use when the user asks what was decided before, why something is the way it is, when a commit's Session trailer needs context, or before re-deciding something that may already be settled. Arguments - keywords, or a session id (8 hex chars), optionally --all to search every project.
allowed-tools: Bash, Read, Grep
---

# recall: look up earlier sessions

Journals live in `~/.ai-sessions/<owner>__<repo>/*.md` (front matter `session:`, then Prompts / Changes / Commits /
Skills, then Decisions / Open / Next written by the agent).

## Steps

1. Scope: the current project directory `<owner>__<repo>` (from `<repo-context>`: owner and repo of the remote), or all of `~/.ai-sessions` with `--all`.
2. Search:
   - session id (8 hex chars, for example from a commit's `Session: 3f2a9c1d` trailer): `grep -rl "^session: 3f2a9c1d" <scope>` and open that file.
   - keywords: `rg -n -i -S "<keywords>" <scope>` (fall back to `grep -rn -i` when `rg` is missing). Sort hits by file name descending (names start with the date) so the newest sessions come first.
3. For each matching journal (newest first, at most five), read `title`, `## Decisions`, `## Next`, and the matching lines.
4. Answer the question in the user's language with the decisions found, each with its date and file name. Say plainly when nothing was found.

## Rules

- Read journals; do not edit them here (that is the `journal` skill).
- Quote decisions as written; do not reinterpret them.
