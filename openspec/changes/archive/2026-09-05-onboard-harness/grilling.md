# grilling 記録: onboard-harness

Phase 4 の grilling（第7ラウンドと第8ラウンド、2026-09-05）。事実の調査はエージェント、決定はユーザー。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 他 repo への渡し方 | repo ごとに draft PR を作り、手順書の内容を PR 本文に書く。導入時期は他作業の目処が立ってから | 第7ラウンド Q1 |
| 5 点セットの適用範囲 | 「置けるものの上限」であって全部置く義務ではない。UI を持たない repo には DESIGN.md と PRODUCT.md を置かない。この読み替えをハーネス内に明示する | 第7ラウンド Q2 |
| 検証規約 | 両 repo に `make verify` を作る。monolith は `expo lint` と `tsc --noEmit`、uskn75-kb は `python3 tools/gen-layout.py` | 第7ラウンド Q3 |
| 既存指示ファイルの圧縮 | monolith の AGENTS.md は製品固有の事実だけ残して圧縮し、nvm 前提の記述は削る。実際の削除は PR を受けたセッションでユーザーが行ごとに確認する | 第7ラウンド Q4 |
| onboard-harness の形 | スキルと、読み取り専用の `uskn-harness onboard-check <dir>` の対にする | 第7ラウンド Q5 |
| draft PR の中身 | 機械的に置けるもの（`openspec/`、`CLAUDE.md`、Makefile の verify、AGENTS.md の Branch model 節）はコミットする。判断が要るものは PR 本文の手順書に残す。プロダクト repo に手順書ファイルは足さない | 第8ラウンド Q6 |
| PR の単位 | repo ごとに 1 本。ブランチ名 `harness/onboard`、base は monolith が `master`、uskn75-kb が `main` | 第8ラウンド Q7 |
| monolith の DESIGN.md 衝突 | 改名せず併存させる。root の `DESIGN.md` が視覚の正本、`docs/DESIGN.md` がシステム設計。役割は AGENTS.md の表で分ける | 第8ラウンド Q8 |
| uskn75-kb の指示ファイル | `CLAUDE.md` の中身をそのまま `AGENTS.md` へ移し、`CLAUDE.md` は `@AGENTS.md` の 1 行にする。中身は編集しない | 第8ラウンド Q9 |
| 「上限」の明示場所 | `AGENTS.md` の Hard constraints と ADR-0001 §1 原則 3 の文言を直し、onboard の spec にも要求として書く。新しい ADR は起こさない | 第8ラウンド Q10 |

## 後回しにしたもの

- monolith の AGENTS.md をどの行まで削るか。PR を受けたセッションでユーザーと決める
- monolith の DESIGN.md のトークン。`constants/theme.ts` の色を写すが、書体と spacing はユーザーの決定が要る
- dotfiles への導入（第3ラウンド Q28 のパイロット順で 3 番目）
- monolith の `.claude/skills/release-expo` とハーネスの `release` スキルの重複整理

## 状態

frontier は空。共有理解は 2026-09-05 に確認済み。
