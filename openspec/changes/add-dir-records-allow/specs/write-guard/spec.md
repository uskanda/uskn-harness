## MODIFIED Requirements

### Requirement: ルート外の拒否
プロジェクトルートは `CLAUDE_PROJECT_DIR` である。
`cwd` のgitルートは、`CLAUDE_PROJECT_DIR` と同じリポジトリのcheckoutであるときだけルートに加える。
同じリポジトリとは、`git rev-parse --path-format=absolute --git-common-dir` の結果が一致することを言う。どちらかが得られなければ加えない。
`CLAUDE_PROJECT_DIR` が無ければ `cwd` のgitルート、それも無ければ `cwd` をルートとする。
対象パスは `file_path` または `notebook_path` である。
対象パスの実体がどのルートの外にもあるとき、hookは `permissionDecision: deny` と理由を返さなければならない（MUST）。
理由にはルートと、ユーザーが `/add-dir <path>` を実行すれば解除できる旨を書く。
ルート内と許可リスト内は何も出力しない。
許可リストは `/tmp`、`$TMPDIR`、`~/.claude/projects/*/memory`、ハーネスの状態ディレクトリ、`$CLAUDE_PLUGIN_DATA`。
状態ディレクトリのうち、セッションの許可ファイル `sessions/<session_id>/allow` は許可リストに含めない。

#### Scenario: 他のリポジトリ
- **WHEN** ルートが `~/repos/a` のセッションで `~/repos/b/x.md` をWriteする
- **THEN** 拒否され、理由に `/add-dir` が含まれる

#### Scenario: scratchpad
- **WHEN** `/tmp/claude-1000/.../scratchpad/x` をWriteする
- **THEN** 何も出力しない

#### Scenario: symlink 経由のルート内
- **WHEN** ルートへのsymlinkを通したパスをEditする
- **THEN** 実体がルート内なので何も出力しない

#### Scenario: 状態ディレクトリのほかのファイル
- **WHEN** 状態ディレクトリの `sessions/<session_id>/notes` をWriteする
- **THEN** 何も出力しない

#### Scenario: journal の置き場だった場所
- **WHEN** `~/.ai-sessions/x/j.md` をWriteする
- **THEN** ほかのルート外と同じく拒否される

#### Scenario: ルートの外の worktree
- **WHEN** `CLAUDE_PROJECT_DIR` が `~/repos/a`、`cwd` がそのworktree `~/repos/a-wt` のセッションで、`~/repos/a-wt/x.md` をWriteする
- **THEN** 同じリポジトリのcheckoutなので何も出力しない

#### Scenario: 開始時のルート
- **WHEN** 同じセッションで `~/repos/a/y.md` をWriteする
- **THEN** `CLAUDE_PROJECT_DIR` の中なので何も出力しない

#### Scenario: cwd が別のリポジトリに移った
- **WHEN** `CLAUDE_PROJECT_DIR` が `~/repos/a` のセッションで `cwd` が別のリポジトリ `~/dotfiles` に移り、`~/dotfiles/x.md` をWriteする
- **THEN** `~/dotfiles` は `cwd` のgitルートだが、別のリポジトリなので拒否される

#### Scenario: ルートの下のディレクトリ
- **WHEN** `cwd` が `~/repos/a/src` のセッションで `~/repos/a/z.md` をWriteする
- **THEN** 何も出力しない

### Requirement: 許可ファイルの保護
対象パスの実体が状態ディレクトリの `sessions/<session_id>/allow` のとき、hookは `permissionDecision: deny` を返さなければならない（MUST）。
セッションの許可ファイルに何が書かれていても、この拒否は解除しない。
理由には、許可ファイルを書くのは `DirectoryAdded` のhookだけで、ユーザーが `/add-dir` を実行したときに限る旨を書く。

#### Scenario: エージェントが自分で許可を足す
- **WHEN** `~/.local/state/uskn-harness/sessions/<session_id>/allow` をWriteする
- **THEN** 拒否され、理由に `/add-dir` が含まれる

#### Scenario: symlink 経由
- **WHEN** 状態ディレクトリを指すsymlinkを通して許可ファイルをEditする
- **THEN** 実体が許可ファイルなので拒否される

#### Scenario: 状態ディレクトリを許可したあと
- **WHEN** セッションの許可ファイルに状態ディレクトリが書かれている状態で、許可ファイルをWriteする
- **THEN** 拒否される
