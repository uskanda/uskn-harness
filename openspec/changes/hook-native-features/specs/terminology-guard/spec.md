## MODIFIED Requirements

### Requirement: hook の対象は Markdown
`terms-check` はhookとして呼ばれたとき、書かれたファイルの拡張子が `.md` の場合だけ検査しなければならない（MUST）。
それ以外のファイルでは何も出力せず、終了コード0で終わる。

#### Scenario: 日本語のコメントを持つコード
- **WHEN** 用語集に無いカタカナ語をコメントに含む `.ts` ファイルをWriteで書く
- **THEN** 出力は空

#### Scenario: 拡張子が .markdown
- **WHEN** 実在しない名前を含む `.markdown` ファイルをWriteで書く
- **THEN** 出力は空

## ADDED Requirements

### Requirement: 読むリポジトリ
`terms-check` は、用語集、既知の名前の一覧、追跡ファイルを、作業ディレクトリのgitルートから読まなければならない（MUST）。
作業ディレクトリは、hookでは入力の `cwd`、CLIでは実行したディレクトリである。
`CLAUDE_PROJECT_DIR` がほかの場所を指していても、読む場所は変えない。

#### Scenario: worktree の用語集
- **WHEN** `CLAUDE_PROJECT_DIR` がリポジトリ `a` で、`cwd` が `a` のworktreeを指し、worktreeの用語集にだけある語を含む文書を書く
- **THEN** その語は指摘されない

#### Scenario: worktree での make verify
- **WHEN** `CLAUDE_PROJECT_DIR` がリポジトリ `a` を指す環境で、`a` のworktreeに入って `make verify` を実行する
- **THEN** 検査はworktreeの用語集と追跡ファイルを使う
