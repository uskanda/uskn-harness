## MODIFIED Requirements

### Requirement: 基準と確認手順
`ja-writing` スキルは、日本語の文章の基準と、textlintで確認する手順を含まなければならない（MUST）。
基準には次を含める。成果物ごとの文体、1文の長さ、箇条書きの形、避ける表現、表記の統一。
文体は成果物で分ける。仕様、ADR、設計、コミットメッセージは常体。pull request本文、チャット、UI文言は敬体。
「暫定」の断り書きは置かない。基準は確定している。

#### Scenario: 仕様を書く前に読む
- **WHEN** エージェントが日本語のOpenSpec成果物やドキュメントを書く
- **THEN** スキルの基準に沿って書き、textlintで確認してから終える

#### Scenario: pull request の本文
- **WHEN** pull requestの本文を書く
- **THEN** 敬体で書く

### Requirement: textlint 設定の所在
textlintの設定はハーネス側の `skills/ja-writing/textlintrc.json` に置かなければならない（MUST）。
有効にするプリセットは3つ。`preset-ja-technical-writing`、`@textlint-ja/preset-ai-writing`、`preset-jtf-style`。
`no-mix-dearu-desumasu` は本文と箇条書きの両方を「である」に設定する。
表記ゆれは `textlint-rule-prh` と `skills/ja-writing/prh.yml` で検査する。
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
- **WHEN** 検査対象の文書の本文を敬体で書く
- **THEN** 常体でない旨の指摘が出る

## ADDED Requirements

### Requirement: 表記の統一
スキルは表記の規則をJTF日本語標準スタイルガイドに従うと定めなければならない（MUST）。
全角文字と半角文字の間にスペースを入れない。コロンを使うときは全角にする。
用語は `prh.yml` の辞書で統一する。辞書には少なくとも、実測で混在が見つかった語を入れる。

#### Scenario: 半角と全角の間
- **WHEN**「textlintの設定」と書く
- **THEN** スペースを入れない旨の指摘が出て、`--fix` で直せる

#### Scenario: 辞書にある語
- **WHEN** 地の文で「リポジトリ」と書く
- **THEN** 辞書の統一先が指摘される
