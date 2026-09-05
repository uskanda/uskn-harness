---
name: journal
description: Write the judgment part of this session's journal - Decisions, Open questions, Next steps - and give the file a slug. Use when the Stop hook asks for it, when finishing a piece of work with decisions worth remembering, or when the user asks to journal or record the session.
allowed-tools: Bash, Read, Edit
---

# journal: record what was decided in this session

The harness keeps one journal per session under `~/.ai-sessions/<owner>__<repo>/`. The facts (prompts, changed files,
commits, skills used) are written by a hook. Three sections are yours.

## Steps

1. Find the file. `<repo-context>` shows `session: <sid8>`; run
   `"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/journal-update.sh" --session <sid8> --path`
   (prints the path). Read it.
2. Fill the sections after `<!-- agent -->`, in the language of the user instructions (Japanese by default). Only what happened in this conversation:
   - `## Decisions`: one line per decision the user confirmed, with the reason when it is not obvious.
   - `## Open`: questions still unanswered, provisional choices the user has not confirmed.
   - `## Next`: the concrete next actions, in order.
   Do not touch the sections above the marker; the hook regenerates them.
3. Give the file a name that says what the session was about:
   `journal-update.sh --session <sid8> --slug <kebab-case>` (ASCII; the file is renamed, `session:` stays).
4. Say in one line where the journal is. The SessionEnd hook commits and pushes it.

## Rules

- Never paste secrets, tokens, or tool output into the journal.
- Keep it short: a reader should get the session from the three sections in under a minute.
