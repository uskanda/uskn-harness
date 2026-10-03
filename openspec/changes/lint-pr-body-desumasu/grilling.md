# grilling 記録: lint-pr-body-desumasu

uskn-loopの試験の1件目に使う小さなchange。`add-loop-run` の実装中に、`spec-pr` の本文のlintで見つかった食い違いを直す。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 食い違いの直し方 | 敬体用の設定を別に用意し、PRとMRの本文のlintにはそれを使う。仕様、ADR、設計、コミットメッセージは今の常体の設定のまま検査する | 第1ラウンド Q1 |
| 敬体用の設定の持ち方 | `skills/ja-writing/textlintrc.desumasu.json` を足す。今の設定の写しで、`no-mix-dearu-desumasu` だけを本文と箇条書きとも「ですます」にする。2つの設定が文体の規則以外で一致することをbatsで確かめる | 第2ラウンド Q1 |
| hookと一時ファイルの扱い | 名前が `<body>.pr.md` で終わるMarkdownには、textlintのhookも敬体の設定を使う。`pr` と `spec-pr` は本文の一時ファイルをこの名前で書く | 第2ラウンド Q2 |
| 自前の設定を持つリポジトリ | PRとMRの本文（`<body>.pr.md`）は、リポジトリに `.textlintrc*` があってもハーネスの敬体の設定で検査する。手元のプロダクトリポジトリに自前の設定を持つものは無いことを確かめた | 第2ラウンド Q3 |
| 対象の範囲 | `pr` と `spec-pr` のlintの手順、textlintのhook、ja-writingのスキルと仕様に限る | 第2ラウンド Q4 |

## 後回しにしたもの

- uskn-loopが書くコメント（敬体）をテストで敬体の設定にかけること

## 状態

frontierは空。共有理解は2026-10-01に確認済み。
