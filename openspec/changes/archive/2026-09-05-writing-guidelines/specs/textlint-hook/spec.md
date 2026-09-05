## Purpose

Markdown を書き込んだ直後に textlint を実行し、日本語文章の指摘をエージェントに返す PostToolUse hook。指針 `ja-writing` の計算的センサー。

## ADDED Requirements

### Requirement: 実行条件
PostToolUse hook（Write / Edit / MultiEdit）が textlint を実行する条件は 3 つある。
書き込まれたファイルが `.md` であること。ひらがなかカタカナを含むこと。textlint が実行できること。
3 つすべてを満たすときだけ実行しなければならない（MUST）。
それ以外のとき、または `USKN_SKIP_TEXTLINT=1` のときは、何も出力せず終了コード 0 で終わる。

#### Scenario: 日本語の Markdown
- **WHEN** 日本語を含む `docs/x.md` を Write で書く
- **THEN** textlint がそのファイルに対して実行される

#### Scenario: 英語の Markdown
- **WHEN** 英語だけの `SKILL.md` を書く
- **THEN** textlint は実行されず、出力は空

#### Scenario: textlint 未導入
- **WHEN** PATH に textlint が無い
- **THEN** 出力は空で終了コード 0

### Requirement: 設定の選択
hook はプロジェクトルートに `.textlintrc*` があれば、それを使わなければならない（MUST）。
無ければハーネスの `skills/ja-writing/textlintrc.json` を使う。

#### Scenario: repo の設定
- **WHEN** プロジェクトルートに `.textlintrc.json` がある
- **THEN** `--config` を付けずにプロジェクトルートで実行し、その設定が使われる

### Requirement: 指摘の返し方
指摘があるとき、hook は `additionalContext` を返さなければならない（MUST）。
入れるのはファイル名、件数、指摘（最大 20 行）、直してから終える旨、`ja-writing` スキルへの参照。
書き込みを拒否したり block したりしてはならない（MUST NOT）。指摘が無ければ出力は空。

#### Scenario: 指摘あり
- **WHEN** textlint が 3 件の指摘を返す
- **THEN** JSON の `hookSpecificOutput.additionalContext` に 3 件の指摘と `ja-writing` が含まれる

#### Scenario: 指摘なし
- **WHEN** textlint が指摘を返さない
- **THEN** 出力は空
