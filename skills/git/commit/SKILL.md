---
name: commit
description: Commit the current changes in meaningful units with well-formed messages. Use when the user asks to commit, or when another skill needs uncommitted work committed first. Optional argument: an issue id (`123` or `#123`) to prefix every message with.
allowed-tools: Bash, Read, Grep, Glob
---

# Commit the current changes

## Rules

1. Split the work into 2–5 commits by concern. One small change is one commit; never pad.
2. Message language: follow the language policy in the user or repository instructions. Default to Japanese.
3. Message format: line 1 is a short summary of what was done; line 2 is blank; lines 3 and after explain the details in 2–5 lines.
4. If `$ARGUMENTS` is a number or `#<number>`, treat it as an issue-tracker id and prefix every summary line with `#<number> ` (add the `#` when it is missing).
5. Do not use `--no-verify`, `--amend`, or anything that rewrites published history. Reorganizing commits is the `rebase` skill's job.
6. If a staged file looks like a secret (`.env*`, credentials, tokens, private keys), do not commit it. Stop and report.
7. If the session's `<repo-context>` block has a `session:` line, end every message with the trailer `Session: <sid8>` (blank line before it). It links the commit to the session journal (`recall <sid8>`). Without that line, add no trailer.

## Steps

1. Inspect everything, including untracked files: `git status --porcelain`, `git diff`, `git diff --cached`.
2. Group the changes by concern and decide the order.
3. For each group: `git add <paths>` for that group only, then commit with the message on stdin so quoting cannot break it:

   ```bash
   git commit -q -F - <<'MSG'
   <summary line>

   <detail line>
   <detail line>

   Session: <sid8>
   MSG
   ```

4. Confirm with `git status --short` (should be empty unless files were deliberately left out) and `git log --oneline -5`.
5. Report the commits made and anything intentionally left uncommitted.

## Example message

```
ユーザー認証機能を追加

- JWT トークンを使った認証処理を実装
- ログイン / ログアウトの API エンドポイントを追加
- 認証ミドルウェアを作成し、保護されたルートに適用
```
