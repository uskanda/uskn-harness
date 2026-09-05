# grilling 記録: cross-repo-guard

本 change の決定は Phase 2 の grilling（`docs/proposal-2026-09.md` §14 第6ラウンド）と、ハーネス全体の
grilling（同 §10）で確定済み。該当箇所の抜粋。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 制約 | 作業ディレクトリ外のプロジェクトを直接編集しない。他 repo は PR か handoff | §11（ユーザー指示） |
| 強制レベル | Write / Edit / NotebookEdit はルート外 deny。Bash はパターン一致で警告、`chezmoi apply|add` と他 repo への git 操作は deny。`/allow-repo <path>` でセッション限定に解除 | 第4ラウンド Q30 |
| 細部 | 許可リスト: scratchpad、`/tmp`、`~/.ai-sessions`、`~/.claude/projects/*/memory`、プラグインの状態ディレクトリ。deny パターン: `chezmoi apply|add|update|edit`、`git -C <外>` / `cd <外> &&` に続く push / commit / reset / checkout / rebase / merge。警告: 外へのリダイレクトと `cp` / `mv` / `rm` / `ln` / `tee` | 第6ラウンド Q45 |

## 後回しにしたもの

- PR を作る `pr-to` のような別 repo 向けスキル（別クローンで PR を作る手順の自動化）

## 状態

frontier は空。共有理解は 2026-09-05 に確認済み。
