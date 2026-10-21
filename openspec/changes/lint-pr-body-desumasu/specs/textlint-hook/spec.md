## MODIFIED Requirements

### Requirement: 設定の選択
hookは `cwd` のgitルートに `.textlintrc*` があれば、それを使わなければならない（MUST）。
無ければハーネスの `skills/ja-writing/textlintrc.json` を使う。
`CLAUDE_PROJECT_DIR` がほかの場所を指していても、`cwd` のgitルートで探す。
名前が `<body>.pr.md` の形のファイルには、hookは敬体の設定を使わなければならない（MUST）。
敬体の設定はハーネスの `skills/ja-writing/textlintrc.desumasu.json` である。
gitルートに `.textlintrc*` があっても、この場合は敬体の設定を使う。

#### Scenario: リポジトリの設定
- **WHEN** プロジェクトルートに `.textlintrc.json` がある
- **THEN** `--config` を付けずにプロジェクトルートで実行し、その設定が使われる

#### Scenario: worktree の設定
- **WHEN** `CLAUDE_PROJECT_DIR` がリポジトリ `a` で、`cwd` が `a` のworktreeを指し、そのworktreeにだけ `.textlintrc.json` がある
- **THEN** worktreeの `.textlintrc.json` が使われる

#### Scenario: PRの本文
- **WHEN** プロジェクトルートに `.textlintrc.json` がある状態で、日本語の `<body>.pr.md` をWriteで書く
- **THEN** textlintは `--config` でハーネスの敬体の設定を指定して実行される
