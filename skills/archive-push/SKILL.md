---
name: archive-push
description: Finish an OpenSpec change in one run - settle its open tasks, verify, archive it with spec sync, commit, and push. Argument - the change name.
disable-model-invocation: true
allowed-tools: Bash, Read, Edit, Glob, Grep, Skill, AskUserQuestion
---

# archive-push: from a finished change to a pushed commit

The user typed `/archive-push`. Run one change through archive, sync, verify, commit, and push, calling the skills
that own each part. This skill supplies only the order and the answers to their questions.

Every question and every stop sits before step 5, while the working tree is still untouched. The one exception is
the second verify in step 6.

## Steps

### 1. Pick the change

- `$ARGUMENTS` names a change under `openspec/changes/`: use it.
- Empty: take the only active change from `openspec list --json`. With several, ask which one with `AskUserQuestion`.

One change per run. Announce the change you use.

### 2. Decide the commit scope

`git status --porcelain`, then sort every listed path:

- **Archive paths**: `openspec/changes/<name>/`, its future place under `openspec/changes/archive/`, and the main
  specs its delta specs touch (`openspec/specs/<capability>/`).
- **Implementation paths**: files named in the change's `tasks.md` or in the Impact section of its `proposal.md`.
  They belong to the change; step 7 commits them ahead of the archive.
- **Unrelated paths**: everything else (another session's work, stray edits).

No unrelated paths: go on without asking. Otherwise ask with `AskUserQuestion`, listing the unrelated paths. Options:
archive only (they stay uncommitted and go into the report), or everything.

### 3. Classify the open tasks

Read `tasks.md`. Put every `- [ ]` line into one class:

| Class | The line asks for | Action |
|---|---|---|
| change | an edit to code, documents, or specs: not implemented, not decided | Stop. Report these lines. Nothing has moved. |
| check | a confirmation you can run as a command (`openspec validate`, `uskn-harness sync --dry-run`, a test) | Run it now. Passes: settled. Fails: stop and report the output. |
| confirm | a confirmation only a person can make, with no edit behind it (the user tries it on another machine) | Settled. |

A line that fits two classes, or none: ask about that line with `AskUserQuestion` (settle it as done, or stop). Ask
one line at a time and wait for each answer. The step is done when every open line is settled or you have stopped.

### 4. First verify

Run the repository's verify convention (`make verify`, else `pnpm run verify` / `npm run verify`). Failure: stop and
report it; the working tree is as you found it.

### 5. Mark the settled lines and archive

1. In `tasks.md`, turn each settled `check` and `confirm` line into `- [x]` and append `（archive-pushで完了とみなした）`
   to the end of the line.
2. Run the Skill tool with `openspec-archive-change` and the change name. Answer its questions this way:
   - delta specs differ from the main specs: sync now.
   - already synced: archive now.
   - a warning about incomplete artifacts or tasks: step 3 missed something. Answer cancel and report it.

The step is done when the archive summary reports the move, and the sync as verified whenever delta specs exist.

### 6. Second verify

Run the verify convention again. Failure: stop without committing. Report the output and the uncommitted archive
paths (the moved change directory, the synced main specs).

### 7. Commit

Run the Skill tool with `commit`, and tell it:

- Uncommitted implementation paths first, in their own commits split by the `commit` rules.
- Then the archive paths as exactly one commit.
- With scope "everything", the unrelated paths last, in their own commits.
- The summary line: `<name>をarchiveし、main specsに反映` when specs were synced, `<name>をarchive` when the change had
  no delta specs.
- The body lists the synced capabilities, and the tasks settled in step 3 if any.

### 8. Push and report

Run the Skill tool with `push`. It pushes the commits as they are and owns the protected-branch decision and any
rejection.

Report: the change and its archive path, the synced capabilities, the tasks settled in step 3 with their class, the
commits, the branch pushed, and any paths left uncommitted.

## Examples

`/archive-push add-x`, a clean tree apart from the change, every task checked: no question. Verify passes, the archive
syncs `x`, verify passes again, one commit `add-xをarchiveし、main specsに反映`, push.

`/archive-push add-y`, the open line `- [ ] 4.3 別の端末でユーザーが動作を確認する`: class confirm. After the first
verify it becomes `- [x] 4.3 別の端末でユーザーが動作を確認する（archive-pushで完了とみなした）`, and the run continues.
The commit body and the report name 4.3.

`/archive-push add-z`, the open line `- [ ] 3.2 README.md に1行足す`: class change. Report 3.2 and stop; nothing
is verified, archived, or committed.
