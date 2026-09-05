# grilling 記録: docs-match-reality

引き継ぎ文書の残り 3 件と 4 件を 1 つの change にした。引き継ぎは `docs/handoffs/2026-09-05-next-session.md`。日付は 2026-09-05、セッション d69404e3。
事実の調査はエージェント、決定はユーザー。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| `hooks/scripts/` と `hooks/adapters/` の扱い | 記述を実体に合わせて直す。hook の正本は `plugins/uskn-harness/hooks/`。アダプタは必要になったときに置く（ADR-0002 の方針どおり） | 会話中に確認 |
| `docs/principles.md` と `docs/portability-matrix.md` | 作らず、構成表から消す。原則と移植性マトリクスは ADR-0001 §1 と §7 が持つ | 会話中に確認 |
| `docs/trends/` の扱い | 一覧から消し、ローカルの空ディレクトリも削除する。調査は `docs/proposal-2026-09.md` に 1 本あれば足りる | 第 1 ラウンド Q1 |
| proposal §12.2 をどこまで直すか | 決めた 2 行を消したうえで、冒頭に「現状の構成は AGENTS.md の Layout を正とする」と注記する。他の行は記録として残す | 第 1 ラウンド Q2 |
| hook の置き場の書き方 | ADR-0001 §3 は `plugins/uskn-harness/hooks/` を hook 本体の置き場とし、アダプタの将来の置き場を ADR にだけ書く。AGENTS.md は今あるものだけを載せ、`hooks/` の行を消す。プラグイン README のアダプタの文は「他ツールは `~/.local/share/uskn-harness` 経由で同じスクリプトを呼ぶ。まだ無い」に直す。ローカルの空 `hooks/` は削除する | 第 1 ラウンド Q3 |
| ADR-0001 §7 の Stop / SessionEnd の行 | 実装に合わせて直す。骨格の生成と更新は Stop、SessionEnd は最終更新と commit・push。proposal §12.3 は触らない | 第 1 ラウンド Q4 |
| `templates/chezmoi/` の記載 | AGENTS.md の Layout と ADR-0001 §3 の両方に追加する | 第 1 ラウンド Q5 |

## 後回しにしたもの

- 他ツール向けアダプタの実装。必要が出た時点で `hooks/adapters/<tool>/` を作る。ハーネス全体の第 1 ラウンド Q1「用意するが検証しない」は据え置き

## 状態

frontier は空。共有理解は 2026-09-05 に確認済み。
