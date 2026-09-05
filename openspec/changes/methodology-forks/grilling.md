# grilling 記録: methodology-forks

本 change の決定はハーネス全体の grilling（`docs/proposal-2026-09.md` §10 第1〜4ラウンド）と ADR-0001 §9 で
確定済み。該当箇所の抜粋。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| superpowers の採用範囲 | 丸ごとは採用しない。test-driven-development / systematic-debugging / verification-before-completion / using-git-worktrees の 4 つを fork する | 第1ラウンド Q7 |
| fork の形 | 改変するものは fork してベンダリング。MIT 表記を付け `deps.json` の `forks` に出所と版を記録する | 第1ラウンド Q3、ADR-0001 §9 |
| TDD と検証の強制 | スキル + Stop hook（verify gate）。検証コマンドは規約（`make verify` → `pnpm run verify` / `npm run verify`） | 第1ラウンド Q8、第2ラウンド Q17 |
| 作業ディレクトリ外 | worktree もプロジェクトルート外への書き込み拒否の対象。ルート内に置くか `/allow-repo` で解除する | 第4ラウンド Q30 |
| 計画フェーズ | brainstorming / writing-plans / executing-plans は採用しない（OpenSpec と二重化するため） | 第1ラウンド Q7 |

## 後回しにしたもの

- mattpocock の `tdd` / `diagnosing-bugs` との比較検証（採用は superpowers 版で確定済み。比較は upstream 更新時に）
- `nessun-dorma` の `/goal` ベース書き直し（§12.9）

## 状態

frontier は空。共有理解は 2026-09-05 に確認済み。
