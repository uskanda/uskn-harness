## Context

動機はproposal.mdのWhyにある。
今の設定 `skills/ja-writing/textlintrc.json` は、文体の規則 `no-mix-dearu-desumasu` を持つ。
その値は `preferInBody: "である"` と `preferInList: "である"` である。
textlintのhook `textlint-check.sh` は、gitルートに `.textlintrc*` があればそれを、無ければこの設定を使う。
`pr` と `spec-pr` は、本文を一時ファイルに書き、この設定を `--config` で明示してlintする。

## Goals / Non-Goals

**Goals:**
- PRとMRの本文を敬体で書いたとき、文体以外の規則（文の長さ、表記、比喩の動詞など）だけが指摘される
- 常体の文書の検査は今のまま変えない

**Non-Goals:**
- uskn-loopが書くコメントのlint（grillingで後回しにした）
- チャットの返答のlint

## Decisions

- **敬体の設定は、今の設定の丸ごとの写しにする。** textlintの設定ファイルは、ほかの設定を継承できないためである。違いは `no-mix-dearu-desumasu` の値だけで、`preferInBody` と `preferInList` を `"ですます"` にする
- **写しのずれはbatsで止める。** `bin/tests/ja-writing-rules.bats` が、2つの設定から文体の規則を取り除いたJSONを比べる。jqで比べるので、textlintが無いマシンでも走る
- **敬体の設定を使う目印は、`<body>.pr.md` の形のファイル名にする。** hookは名前だけで判定でき、本文の中身を読まない。PRとMRの本文は、ja-writingの文体の表で敬体と決まっている成果物なので、成果物の種類を名前に表す
- **`<body>.pr.md` の形のファイルには、常に敬体の設定を使う。** リポジトリに自前の設定があっても同じである。 PRの文体はユーザー層の規則である。リポジトリの文書の設定とは別物として扱う。`pr` と `spec-pr` が既にハーネスの設定を明示しているのとも揃う
- **スキルの検査はbatsで確かめる。** `pr` と `spec-pr` の本文が、敬体の設定と `<body>.pr.md` の形の名前を使うことを、文字列の検査で確かめる

## Risks / Trade-offs

- 2つの設定に同じ変更を入れ忘れる → batsがずれを報告して `make verify` が失敗する
- 名前の約束を知らないエージェントが、PRの本文を普通の `.md` に書く → hookは常体の設定で指摘する。`pr` と `spec-pr` の手順に名前を書くことで防ぐ
- `no-mix-dearu-desumasu` は、「ですます」という引用語も敬体の文末と判定することがある → 常体の文書では、引用語を言い換えるかコードとして書く
