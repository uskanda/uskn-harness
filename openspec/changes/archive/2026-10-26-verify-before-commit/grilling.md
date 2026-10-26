# grilling 記録: verify-before-commit

ハーネスのスキル `verify` が、Claude Codeの組み込みの `/verify` と同じ名前になっている（issue #9）。
grillingの前に、3つのファイルを読んだ。`skills/verify/SKILL.md`、`openspec/specs/verify-skill/spec.md`、`openspec/specs/verify-fast/spec.md` である。
Claude Codeの振る舞いは文書（commands、skills、settings-reference）とCHANGELOGで調べた。

調べて分かったことは次のとおり。

- 組み込みの `/verify` は、アプリをビルドして動かし、結果を見て確かめるスキルである。ユーザーが打ったときだけ動く
- ユーザー層の `verify` は組み込みを置き換える。このときClaude Code（2.1.286以降）のcommitの指示は、commitの直前にそのスキルを実行させる。文書とテストだけの変更は除く
- そのため今は、commitのたびにフルの `make verify` が走る

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| commitの直前の呼び出し | 名前は `verify` のままにし、commitの直前の呼び出しを生かす。commitの直前に呼ばれたときは、`verify-fast` があればそれを走らせる。フルの検査は、今と同じくCIと `archive-push` が走らせる | 第1ラウンド Q1 |
| commitの直前の結果と完了の根拠 | 根拠にしない。commitの直前の実行は、commitを止めるかどうかの確認だけに使う。完了と言うときは、今と同じく検証規約を走らせる | 第2ラウンド Q2 |
| changeの名前とブランチ | `verify-before-commit`。mainから `change/verify-before-commit` を切る | 第2ラウンド（最終確認） |
| 変える仕様 | `verify-skill` だけ | 第2ラウンド（最終確認） |
| ADR | 書かない。スキルの振る舞いを1つ足すだけで、ハーネスの構成は変わらないため。理由はdesign.mdに残す | 第2ラウンド（最終確認） |
| 文書 | READMEのverifyの説明に、Claude Code（2.1.286以降）がcommitの直前にこのスキルを呼ぶことを書く | 第2ラウンド（最終確認） |

## 後回しにしたもの

- なし

## 状態

frontierは空。共有理解は2026-10-23に確認済み。
