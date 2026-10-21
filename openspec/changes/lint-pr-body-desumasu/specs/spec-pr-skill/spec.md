## ADDED Requirements

### Requirement: 本文の検査
`spec-pr` は、仕様PRの本文を `<body>.pr.md` の形の名前の一時ファイルに書かなければならない（MUST）。
`spec-pr` は、その一時ファイルをハーネスの敬体の設定 `skills/ja-writing/textlintrc.desumasu.json` で検査しなければならない（MUST）。
textlintが使えないときは検査を飛ばし、その旨を報告する。

#### Scenario: 敬体の本文
- **WHEN** `spec-pr` が敬体で書いた仕様PRの本文を検査する
- **THEN** 敬体の設定が使われ、文体の指摘は出ない
