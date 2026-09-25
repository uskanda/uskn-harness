---
name: commit
description: Commit the current changes in meaningful units with well-formed messages. Use when the user asks to commit, or when another skill needs uncommitted work committed first.
argument-hint: "[issue-id] [instructions on how to split and word the commits]"
context: fork
model: sonnet
effort: low
background: false
allowed-tools: Bash, Read, Grep, Glob
---

# Commit the current changes

This skill runs as a fork: it sees the working tree and its arguments, not the conversation that called it. Every
reason the caller wants in a message must arrive in the arguments.

## Arguments

`$ARGUMENTS` is `[issue id] [instructions]`, both optional.

- The first word is an issue id when it is a number or `#<number>`. Prefix every summary line with `#<number> ` (add
  the `#` when it is missing).
- Everything after the issue id, or the whole argument when the first word is not an issue id, is instructions. They
  bind the order of the commits, how the changes are split, the summary lines, and the bodies. Follow them ahead of
  rule 1 wherever they conflict.
- No arguments: split by purpose alone and prefix nothing.

## Rules

1. Split the work into 1–5 commits by purpose. A change that serves one purpose is one commit, even when it spans
   implementation, tests, and specs; never split by file type and never pad.
2. Message language: follow the language policy in the user or repository instructions. Default to Japanese.
3. Message format: line 1 is a short summary of what was done; line 2 is blank; lines 3 and after explain the details in 2–5 lines.
4. Do not use `--no-verify`, `--amend`, or anything that rewrites published history. Reorganizing commits is the `rebase` skill's job.
5. If a staged file looks like a secret (`.env*`, credentials, tokens, private keys), do not commit it. Stop and report.
6. End every message with the trailer `Co-Authored-By: Claude <noreply@anthropic.com>` (blank line before it), in
   every run: this skill runs as a fork, where Claude Code's own attribution note does not arrive.

## Steps

1. Read the arguments as described above.
2. Inspect everything, including untracked files: `git status --porcelain`, `git diff`, `git diff --cached`.
3. Group the changes by purpose and decide the order, following the instructions when given.
4. Japanese messages: lint them before committing. Write the message to a scratch `.md` with the summary line as
   a heading (`# <summary>`) so the subject is not read as an unterminated sentence, then run

   ```bash
   textlint --config ~/.local/share/uskn-harness/skills/ja-writing/textlintrc.json --format compact <scratch>.md
   ```

   and fix what it reports (the `ja-writing` skill has the rules and the fixes). The `# ` exists only in the scratch
   file; the summary line you commit starts with the summary text itself. Skip this when textlint is not
   installed, and say so in the report. English messages follow `en-writing`; they are not linted.
5. For each group: `git add <paths>` for that group only, then commit with the message on stdin so quoting cannot break it:

   ```bash
   git commit -q -F - <<'MSG'
   <summary line>

   <detail line>
   <detail line>

   Co-Authored-By: Claude <noreply@anthropic.com>
   MSG
   ```

6. Confirm with `git status --short` (should be empty unless files were deliberately left out) and `git log --oneline -5`.
7. Report the commits made (hash and summary line) and anything intentionally left uncommitted.

## Examples

`/commit` with a new feature, its tests, and its spec uncommitted: one purpose, one commit.

`/commit` with two new skills in their own directories, each with its tests: two purposes, two commits. A file
both of them touch, such as a README line for each, goes into the later of the two commits.

`/commit 123`: every summary line starts with `#123 `.

`/commit openspec/changes/archive/ 以下と openspec/specs/ 以下は1つのコミットにし、要約行は「add-xをarchiveし、main specsに反映」とする`:
the first word is not an issue id, so the whole text is instructions. The archive paths become exactly that commit;
other changes are split by purpose ahead of it.

## Example message

```
ユーザー認証機能を追加

- JWT トークンを使った認証処理を実装
- ログイン / ログアウトの API エンドポイントを追加
- 認証ミドルウェアを作成し、保護されたルートに適用

Co-Authored-By: Claude <noreply@anthropic.com>
```
