## MODIFIED Requirements

### Requirement: 実行条件
PostToolUse hook（Write / Edit）がtextlintを実行する条件は3つある。
書き込まれたファイルが `.md` であること。日本語で書かれていること。textlintが実行できること。
3つすべてを満たすときだけ実行しなければならない（MUST）。
`if` を解するClaude Codeでは、`hooks.json` の `if` により、作業ディレクトリの下の `.md` だけでhookが起動する。
「日本語で書かれている」の判定は、かなの出現数がファイルのバイト数に占める割合で行う。
既定の下限は6パーセントで、`USKN_TEXTLINT_MIN_JA` で上書きできる。
日本語の例を引用するだけの英語文書（スキル、AGENTS.md）は対象外になる。
それ以外のとき、または `USKN_SKIP_TEXTLINT=1` のときは、何も出力せず終了コード0で終わる。
textlintの実行には25秒の上限をかける。GNUの `timeout` が無い環境でも同じ上限を守る。

#### Scenario: 日本語の Markdown
- **WHEN** 日本語を含む `docs/x.md` をWriteで書く
- **THEN** textlintがそのファイルに対して実行される

#### Scenario: 英語の Markdown
- **WHEN** 英語だけの `SKILL.md` を書く
- **THEN** textlintは実行されず、出力は空

#### Scenario: 日本語を引用する英語文書
- **WHEN** 英語のスキル文書に日本語の例を数行だけ含めて書く
- **THEN** textlintは実行されず、出力は空

#### Scenario: 拡張子が .markdown
- **WHEN** 日本語を含む `docs/x.markdown` をWriteで書く
- **THEN** textlintは実行されず、出力は空

#### Scenario: textlint 未導入
- **WHEN** PATHにtextlintが無い
- **THEN** 出力は空で終了コード0

#### Scenario: timeout の無い macOS
- **WHEN** PATHに `timeout` と `gtimeout` のどちらも無い環境で、textlintが25秒を超えて止まらない
- **THEN** textlintは打ち切られ、hookは終了コード0で終わる

### Requirement: 設定の選択
hookは `cwd` のgitルートに `.textlintrc*` があれば、それを使わなければならない（MUST）。
無ければハーネスの `skills/ja-writing/textlintrc.json` を使う。
`CLAUDE_PROJECT_DIR` がほかの場所を指していても、`cwd` のgitルートで探す。

#### Scenario: リポジトリの設定
- **WHEN** プロジェクトルートに `.textlintrc.json` がある
- **THEN** `--config` を付けずにプロジェクトルートで実行し、その設定が使われる

#### Scenario: worktree の設定
- **WHEN** `CLAUDE_PROJECT_DIR` がリポジトリ `a` で、`cwd` が `a` のworktreeを指し、そのworktreeにだけ `.textlintrc.json` がある
- **THEN** worktreeの `.textlintrc.json` が使われる
