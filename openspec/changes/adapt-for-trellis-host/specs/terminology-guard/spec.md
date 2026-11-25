# Spec Delta

## MODIFIED Requirements

### Requirement: 読むリポジトリ
`terms-check` は、用語集、既知の名前の一覧、追跡ファイルを、検査するファイルが属するgitルートから読まなければならない（MUST）。
gitルートは、ファイルの置き場のディレクトリから求め、symlinkを解決する。
hookの入力の `cwd`、CLIを実行したディレクトリ、`CLAUDE_PROJECT_DIR` がほかの場所を指していても、読む場所は変えない。
CLIで複数のリポジトリのファイルを渡されたときは、ファイルごとにそのgitルートを使う。

#### Scenario: worktree の用語集
- **WHEN** `CLAUDE_PROJECT_DIR` がリポジトリ `a` で、`a` のworktreeの中の文書を書く。その文書は、worktreeの用語集にだけある語を含む
- **THEN** その語は指摘されない

#### Scenario: worktree での make verify
- **WHEN** `CLAUDE_PROJECT_DIR` がリポジトリ `a` を指す環境で、`a` のworktreeに入って `make verify` を実行する
- **THEN** 検査はworktreeの用語集と追跡ファイルを使う

#### Scenario: 別のリポジトリの文書
- **WHEN** `cwd` がリポジトリ `a` のセッションで、`/add-dir` で足したリポジトリ `b` の文書を書く。その文書は、`b` の用語集にだけある語を含む
- **THEN** その語は指摘されない

## ADDED Requirements

### Requirement: リポジトリに属さないファイル
検査するファイルがどのgitリポジトリにも属さないとき、`terms-check` はそのファイルを検査してはならない（MUST NOT）。
hookでは何も出力せず、CLIではそのファイルの指摘を出さない。終了コードは、ほかのファイルの結果で決まる。

#### Scenario: 一時ディレクトリの文書
- **WHEN** gitリポジトリの外の `/tmp/x.md` に、用語集に無いカタカナ語を含む文書を書く
- **THEN** 出力は空

### Requirement: 検査から外すファイル
検査するファイルがgitルートの `.textlintignore` に一致するとき、`terms-check` はそのファイルを検査してはならない（MUST NOT）。
行の読み方はtextlintに合わせる。空の行と `#` で始まる行は読み飛ばす。
ほかの行は、gitルートからの相対パスに対するglobとして扱う。`**` は0個以上のディレクトリに一致する。
`/` で終わる行は、ファイルに一致しない。
hookとCLIの両方がこの除外に従い、`make verify` もCLIを通じて従う。

#### Scenario: 古い文書を外す
- **WHEN** `.textlintignore` が `docs/legacy/**` の行を持ち、`docs/legacy/a.md` に実在しない名前を書く
- **THEN** 出力は空

#### Scenario: 末尾が / の行
- **WHEN** `.textlintignore` が `docs/legacy/` の行だけを持ち、`docs/legacy/a.md` に実在しない名前を書く
- **THEN** その名前が指摘される

#### Scenario: make verify の除外
- **WHEN** 指摘のある文書が `.textlintignore` に一致する。その文書を `terms-check` のCLIに渡す
- **THEN** 指摘は出ず、終了コードは0
