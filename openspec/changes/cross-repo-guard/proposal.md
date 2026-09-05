## Why

「作業ディレクトリ外のプロジェクトを直接編集しない」はユーザーの明示的な制約で、この session でも一度破られた（sandbox 検証の副作用）。ファイル編集ツールは対象パスが明確なので確実に止め、Bash は典型だけを止める。解除はセッション限定の明示的な操作にする。

## What Changes

- PreToolUse hook `write-guard.sh`（Write / Edit / MultiEdit / NotebookEdit）: プロジェクトルート外への書き込みを deny。許可リストと `/allow-repo` の解除を除く
- PreToolUse hook `bash-guard.sh`（Bash）: `chezmoi apply|add|update|edit|re-add|merge` と、ルート外の repo への `git push|commit|reset|checkout|switch|rebase|merge|cherry-pick|apply`（`git -C <外>` と `cd <外> &&` の両形）を deny。ルート外へのリダイレクトと `cp|mv|rm|ln|tee|mkdir|touch` は `additionalContext` で警告
- `allow-repo` スキルと `allow-repo.sh`: `sessions/<sid>/allow` にパスを追記し、そのセッションだけ両ガードが通す
- `templates/user/CLAUDE.md` の Boundaries を hook 前提の文言に更新

## Capabilities

### New Capabilities
- `write-guard`: ファイル編集ツールのルート外拒否と許可リスト
- `bash-guard`: Bash の deny / warn パターン
- `allow-repo-skill`: セッション限定の解除

### Modified Capabilities
（なし）

## Impact

- 新規: `plugins/uskn-harness/hooks/scripts/{write-guard.sh,bash-guard.sh,allow-repo.sh}`、同 tests、`skills/allow-repo/`
- 変更: `hooks.json`、`templates/user/CLAUDE.md`、`README.md`
