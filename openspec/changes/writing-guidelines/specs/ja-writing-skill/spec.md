## Purpose

日本語の文章（コミット、PR、仕様、ドキュメント、UI 文言）を書くときの基準と、textlint による確認手順を 1 か所に置くスキル。

## ADDED Requirements

### Requirement: 基準と確認手順
`ja-writing` スキルは、日本語の文章の基準（敬体と常体の使い分け、1 文の長さ、箇条書きの形、避ける表現）と、textlint で確認する手順を含まなければならない（MUST）。基準は「暫定」と明記し、確定は grilling に委ねる旨を書く。

#### Scenario: 仕様を書く前に読む
- **WHEN** エージェントが日本語の OpenSpec 成果物やドキュメントを書く
- **THEN** スキルの基準に沿って書き、textlint で確認してから終える

### Requirement: textlint 設定の所在
textlint の設定はハーネス側の `skills/ja-writing/textlintrc.json` に置かなければならない（MUST）。
有効にするプリセットは `preset-ja-technical-writing` と `@textlint-ja/preset-ai-writing`。
プロダクト repo に `.textlintrc*` があれば、そちらを優先する。

#### Scenario: 設定の無い repo
- **WHEN** プロダクト repo に `.textlintrc*` が無い
- **THEN** スキルと hook はハーネスの設定で textlint を実行する

#### Scenario: 設定のある repo
- **WHEN** プロダクト repo のルートに `.textlintrc.json` がある
- **THEN** その設定が使われ、ハーネスの設定は使われない

### Requirement: 指摘の直し方
スキルは、textlint の典型的な指摘（文の長さ、助詞の重複、冗長表現、AI らしい箇条書きやコロン終わり）ごとに直し方を示さなければならない（MUST）。

#### Scenario: 長い文
- **WHEN** `sentence-length` の指摘が出る
- **THEN** 文を分割して直し、上限の緩和では対応しない

### Requirement: 文体サンプル
スキルは `assets/voice/` のサンプルの使い方（あれば先に読み、語彙と文の長さを合わせる）を含まなければならない（MUST）。サンプルが無いときは基準だけで書く。

#### Scenario: サンプル無し
- **WHEN** `assets/voice/ja/` にサンプルが無い
- **THEN** スキルの基準だけで書き、サンプルが無いことを理由に止まらない
