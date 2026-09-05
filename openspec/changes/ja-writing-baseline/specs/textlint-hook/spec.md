## MODIFIED Requirements

### Requirement: 実行条件
PostToolUse hook（Write / Edit / MultiEdit）がtextlintを実行する条件は3つある。
書き込まれたファイルが `.md` であること。日本語で書かれていること。textlintが実行できること。
3つすべてを満たすときだけ実行しなければならない（MUST）。
「日本語で書かれている」の判定は、かなの出現数がファイルのバイト数に占める割合で行う。
既定の下限は6パーセントで、`USKN_TEXTLINT_MIN_JA` で上書きできる。
日本語の例を引用するだけの英語文書（スキル、AGENTS.md）は対象外になる。
それ以外のとき、または `USKN_SKIP_TEXTLINT=1` のときは、何も出力せず終了コード0で終わる。

#### Scenario: 日本語の Markdown
- **WHEN** 日本語を含む `docs/x.md` をWriteで書く
- **THEN** textlintがそのファイルに対して実行される

#### Scenario: 英語の Markdown
- **WHEN** 英語だけの `SKILL.md` を書く
- **THEN** textlintは実行されず、出力は空

#### Scenario: 日本語を引用する英語文書
- **WHEN** 英語のスキル文書に日本語の例を数行だけ含めて書く
- **THEN** textlintは実行されず、出力は空

#### Scenario: textlint 未導入
- **WHEN** PATHにtextlintが無い
- **THEN** 出力は空で終了コード0
