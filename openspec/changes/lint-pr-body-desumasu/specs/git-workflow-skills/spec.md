## MODIFIED Requirements

### Requirement: 日本語の成果物の検査
`commit` と `pr` スキルは、日本語で書いた本文をtextlintで確認しなければならない（MUST）。
本文はファイルではないため、一時ファイルに書いてから検査する。
`pr` は、PRとMRの本文を `<body>.pr.md` の形の名前の一時ファイルに書かなければならない（MUST）。
`pr` は、その一時ファイルをハーネスの敬体の設定 `skills/ja-writing/textlintrc.desumasu.json` で検査しなければならない（MUST）。
textlintが使えないときは検査を飛ばし、その旨を報告する。指摘が残るときは直してから確定する。

#### Scenario: 日本語のコミットメッセージ
- **WHEN** 日本語のコミットメッセージを書く
- **THEN** 確定の前にtextlintで確認され、指摘があれば直される

#### Scenario: textlint が無い
- **WHEN** textlintがPATHに無い
- **THEN** 検査は飛ばされ、コミットは続行する

#### Scenario: 敬体のPR本文
- **WHEN** `pr` が敬体で書いたPRの本文を検査する
- **THEN** 敬体の設定が使われ、文体の指摘は出ない
