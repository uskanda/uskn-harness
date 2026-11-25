# textlint-hook Specification

## Purpose
Markdownを書き込んだ直後にtextlintを実行し、日本語文章の指摘をエージェントに返すPostToolUse hook。指針 `ja-writing` の計算的センサー。

## Requirements

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
hookは、書いたファイルが属するgitルートに `.textlintrc*` があれば、それを使わなければならない（MUST）。
無ければハーネスの `skills/ja-writing/textlintrc.json` を使う。
textlintは、そのgitルートを作業ディレクトリにして実行する。textlintがgitルートの `.textlintignore` を読むため。
gitルートは、ファイルの置き場のディレクトリから求め、symlinkを解決する。
入力の `cwd` と `CLAUDE_PROJECT_DIR` がほかの場所を指していても、ファイルの側のgitルートで探す。
ファイルがどのgitリポジトリにも属さないときは、ハーネスの設定を使い、ファイルの置き場を作業ディレクトリにする。

#### Scenario: リポジトリの設定
- **WHEN** プロジェクトルートに `.textlintrc.json` がある
- **THEN** `--config` を付けずにプロジェクトルートで実行し、その設定が使われる

#### Scenario: worktree の設定
- **WHEN** `CLAUDE_PROJECT_DIR` がリポジトリ `a` で、そのworktreeにだけ `.textlintrc.json` がある。そのworktreeの中の文書を書く
- **THEN** worktreeの `.textlintrc.json` が使われる

#### Scenario: 別のリポジトリの文書
- **WHEN** `cwd` が `.textlintrc*` の無いリポジトリ `a` で、`.textlintrc.json` のあるリポジトリ `b` の文書を書く
- **THEN** `b` の `.textlintrc.json` が使われ、textlintは `b` のルートで実行される

#### Scenario: 除外したファイル
- **WHEN** gitルートの `.textlintignore` が `docs/legacy/**` の行を持ち、`docs/legacy/a.md` に指摘のある日本語を書く
- **THEN** 出力は空

#### Scenario: リポジトリの外の文書
- **WHEN** gitリポジトリの外の `/tmp/x.md` に、指摘のある日本語を書く
- **THEN** ハーネスの設定で検査され、指摘が返る

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

### Requirement: 閉じた環境での textlint の実行
閉じた環境の間、hookはtextlintを、confined-hook-sandboxの規則の中で実行しなければならない（MUST）。
リポジトリの `.textlintrc.js` やプラグインは、エージェントが書けるコードであるため。
textlintは、環境の印の `tools` が指す共有の置き場の `bin/` から選ぶ。
規則を使えないときは、textlintを実行せず、検査しなかったことを `additionalContext` で返す。

#### Scenario: リポジトリの設定が外へ送る
- **WHEN** 閉じた環境のmacOSで、`.textlintrc.js` が外のホストへ接続するリポジトリの文書を書く
- **THEN** 接続は拒否され、書き込みはblockされない

#### Scenario: 規則を使えない
- **WHEN** 閉じた環境のLinuxで、日本語の文書を書く
- **THEN** textlintは実行されず、`additionalContext` に検査しなかったことが含まれる
