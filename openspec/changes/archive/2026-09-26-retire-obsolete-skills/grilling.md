# grilling 記録: retire-obsolete-skills

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 削除するスキル | `nessun-dorma`（ネイティブの `/goal` が代わる）、`using-git-worktrees`（ネイティブのworktree）、`verification-before-completion` と `pre-merge`（`verify` に統合） | 監査の提案をユーザーが承認（2026-09-25） |
| エイリアス | `mr`、`mr-main`、`mr-qa`、`merge-develop`、`switch-develop-branch` は残す | ユーザーの指示（2026-09-25） |
| OpenSpecの配布 | commandsだけ（`/opsx:*`）にする。`archive-push` は `opsx:archive` を呼ぶ | 第1ラウンド Q8 |
| OpenSpecの版と生成 | 1.13.2に上げる。全体の設定は変えず、`sync` の中だけ `XDG_CONFIG_HOME` を差し替えてcommandsで生成する。ハーネスが入れた `~/.claude/skills/openspec-*` を消し、doctorは `commands/opsx` を検査する。上流spec-drivenの案内文の改善をuskn schemaに移す | 第1ラウンド Q25 |
| verifyへの統合 | 実行したコマンドと結果を示してから完了と言う規則と、規約が無いときにCIの設定から確認コマンドを導く手順を `verify` に足す | 第1ラウンド Q9 |
| 削除したスキルのsymlink | `sync` が、ハーネスの `skills/` を指していて実体の無いsymlinkを消す | 第1ラウンド Q10 |
| 移行スクリプト | `templates/chezmoi/run_onchange_before_remove-migrated-claude-skills.sh.tmpl` を削除する。dotfilesのコピーはfresh cloneからdraft PRで消す | 第1ラウンド Q11 |

## 後回しにしたもの

- なし

## 状態

frontierは空。共有理解は2026-09-25に/okで確認済み。
