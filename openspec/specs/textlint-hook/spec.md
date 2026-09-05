# textlint-hook Specification

## Purpose
Markdownを書き込んだ直後にtextlintを実行し、日本語文章の指摘をエージェントに返すPostToolUse hook。指針 `ja-writing` の計算的センサー。

## Requirements

### Requirement: 実行条件
PostToolUse hook（Write / Edit / MultiEdit）がtextlintを実行する条件は3つある。
書き込まれたファイルが `.md` であること。ひらがなかカタカナを含むこと。textlintが実行できること。
3つすべてを満たすときだけ実行しなければならない（MUST）。
それ以外のとき、または `USKN_SKIP_TEXTLINT=1` のときは、何も出力せず終了コード0で終わる。

#### Scenario: 日本語の Markdown
- **WHEN** 日本語を含む `docs/x.md` をWriteで書く
- **THEN** textlintがそのファイルに対して実行される

#### Scenario: 英語の Markdown
- **WHEN** 英語だけの `SKILL.md` を書く
- **THEN** textlintは実行されず、出力は空

#### Scenario: textlint 未導入
- **WHEN** PATHにtextlintが無い
- **THEN** 出力は空で終了コード0

### Requirement: 設定の選択
hookはプロジェクトルートに `.textlintrc*` があれば、それを使わなければならない（MUST）。
無ければハーネスの `skills/ja-writing/textlintrc.json` を使う。

#### Scenario: リポジトリの設定
- **WHEN** プロジェクトルートに `.textlintrc.json` がある
- **THEN** `--config` を付けずにプロジェクトルートで実行し、その設定が使われる

### Requirement: 指摘の返し方
指摘があるとき、hookは `additionalContext` を返さなければならない（MUST）。
入れるのはファイル名、件数、指摘（最大20行）、直してから終える旨、`ja-writing` スキルへの参照。
書き込みを拒否したりblockしたりしてはならない（MUST NOT）。指摘が無ければ出力は空。

#### Scenario: 指摘あり
- **WHEN** textlintが3件の指摘を返す
- **THEN** JSONの `hookSpecificOutput.additionalContext` に3件の指摘と `ja-writing` が含まれる

#### Scenario: 指摘なし
- **WHEN** textlintが指摘を返さない
- **THEN** 出力は空
