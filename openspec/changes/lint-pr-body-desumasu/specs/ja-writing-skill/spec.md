## MODIFIED Requirements

### Requirement: textlint 設定の所在
textlintの設定はハーネス側の `skills/ja-writing/textlintrc.json` に置かなければならない（MUST）。
有効にするプリセットは3つ。`preset-ja-technical-writing`、`@textlint-ja/preset-ai-writing`、`preset-jtf-style`。
`no-mix-dearu-desumasu` は本文と箇条書きの両方を「である」に設定する。
表記ゆれは `textlint-rule-prh` と `skills/ja-writing/prh.yml` で検査する。
比喩の動詞は、正規表現の一覧で検査するルール `@textlint-rule/textlint-rule-pattern` で検査する。
これらのルールのパッケージは、`deps.json` のtextlintの `bundle` にピンする。
プロダクトリポジトリに `.textlintrc*` があれば、そちらを優先する。

#### Scenario: 設定の無いリポジトリ
- **WHEN** プロダクトリポジトリに `.textlintrc*` が無い
- **THEN** スキルとhookはハーネスの設定でtextlintを実行する

#### Scenario: 設定のあるリポジトリ
- **WHEN** プロダクトリポジトリのルートに `.textlintrc.json` がある
- **THEN** その設定が使われ、ハーネスの設定は使われない

#### Scenario: 常体の本文
- **WHEN** 本文に「〜である」と書く
- **THEN** 指摘は出ない

#### Scenario: 敬体の本文
- **WHEN** 常体の設定で検査する文書の本文を敬体で書く
- **THEN** 常体でない旨の指摘が出る

#### Scenario: ルールのパッケージが無いマシン
- **WHEN** `bundle` に足したパッケージが入っていないマシンで `uskn-harness sync --tools` を実行する
- **THEN** textlintとbundleが入れ直され、`uskn-harness doctor` の警告が消える

## ADDED Requirements

### Requirement: 敬体の設定
ハーネスは、敬体の文書を検査する設定 `skills/ja-writing/textlintrc.desumasu.json` を持たなければならない（MUST）。
敬体の設定は `skills/ja-writing/textlintrc.json` の写しとする。違いは `no-mix-dearu-desumasu` だけで、本文と箇条書きに敬体を求める。
2つの設定は、`no-mix-dearu-desumasu` の設定値のほかは一致しなければならない（MUST）。
PRとMRの本文は、敬体の設定で検査する。

#### Scenario: 敬体のPR本文
- **WHEN** 敬体で書いたPRの本文を敬体の設定で検査する
- **THEN** 文体の指摘は出ない

#### Scenario: 写しのずれ
- **WHEN** `skills/ja-writing/textlintrc.json` だけに規則を1つ足して `make verify` を実行する
- **THEN** batsのテストが、2つの設定のずれを報告して失敗する
