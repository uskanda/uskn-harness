# grilling 記録: migrate-git-skills

本 change に効く決定は、ハーネス全体の grilling（`docs/proposal-2026-09.md` §10 第1〜5ラウンド）で確定済み。
該当箇所の抜粋。

| 決定 | 出典 |
|---|---|
| 移管対象は git ワークフロー系 13 スキル。chezmoi-merge / sync-claude-settings / set-workspace-theme / cleanup は dotfiles に残す | Q15 |
| 移管時にプロジェクト固有の前提（develop / main / qa 固定、Issue 番号への言及）を汎用化する | Q15 補足 |
| ブランチモデルは自動検出 + AGENTS.md の `## Branch model` 見出し下の fenced yaml で上書き。判定は SessionStart hook が行い、各スキルは再判定しない | Q23, Q36 |
| `pr`（引数で対象ブランチ）、`sync-base`、`switch-base` に統合。旧名（mr, mr-main, mr-qa, merge-develop, switch-develop-branch）は `disable-model-invocation: true` の 1 行エイリアス | Q24 |
| スキル本文は英語。コミット、PR、チャットは日本語（ユーザー層の指示） | Q5 |
| hook は bash + jq、テストは bats | Q20 |
| Claude 向け hook は skills-dir プラグインの symlink で配る。スクリプト正本は `plugins/uskn-harness/hooks/scripts/` | Q33, Q34（ADR-0002） |
| `pr` の意味論: 引数なしは現在ブランチ → 統合ブランチ（auto-merge あり）。`pr <既定ブランチ>` で統合と既定が異なれば「統合 → 既定」のリリース PR（タイトル `<既定> YYYYMMDD HH:MM`）。`pr qa` はソースブランチを残す | 第3ラウンド前提 |
| hosting hook は `session-start.sh` に移植し `--plain` を維持 | 第5ラウンド前提 |
| `nessun-dorma` はそのまま移管（`/goal` ベースの書き直しは後回し） | 第3ラウンド前提 |

frontier は空。共有理解は 2026-09-05 に確認済み。
