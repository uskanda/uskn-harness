## REMOVED Requirements

### Requirement: warn パターン
**Reason**: ルートの外への書き込みは、Claude Codeのsandboxが書き込み先をOSのレベルで制限して止める。コマンドの文字列から推測する警告は、間接の書き込みを見逃し、見つけても止めなかった。
**Migration**: 設定断片の `sandbox` で、Bashの書き込み先を作業ディレクトリ、一時ディレクトリ、追加したディレクトリに限る。ルートの外で作業するときは、ユーザーが `/allow-repo <path>` と `/add-dir <path>` を実行する。

## MODIFIED Requirements

### Requirement: ルートの範囲
hookは、write-guardと同じプロジェクトルートを使わなければならない（MUST）。
ルートは `CLAUDE_PROJECT_DIR` と、それと同じリポジトリ（同じgit common dir）のcheckoutであるときだけの `cwd` のgitルートである。
別のリポジトリのcheckoutは、`cwd` のgitルートであってもルートにならない。
denyパターンで言うルートの外とは、どのルートの外にもあることを指す。

#### Scenario: ルートの外の worktree での commit
- **WHEN** `CLAUDE_PROJECT_DIR` が `~/repos/a`、`cwd` がそのworktree `~/repos/a-wt` のセッションで、`git commit -m x` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: cwd が別のリポジトリに移った
- **WHEN** `CLAUDE_PROJECT_DIR` が `~/repos/a` のセッションで `cwd` が別のリポジトリ `~/dotfiles` に移り、`git commit -m x` を実行しようとする
- **THEN** 拒否される

#### Scenario: 開始時のルートへの書き込み
- **WHEN** 同じセッションで `cp x.md ~/repos/a/` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: どちらのルートでもない
- **WHEN** 同じセッションで `git -C ~/repos/b push` を実行しようとする
- **THEN** 拒否される

## ADDED Requirements

### Requirement: ルートの外への書き込みに何も出力しない
コマンドがルートの外のパスへ書くとき、hookは何も出力してはならない（MUST NOT）。
対象は、リダイレクトと、`cp|mv|rm|rmdir|ln|tee|mkdir|touch|rsync|install|sed -i` による書き込みである。
書き込み先が許可ファイルかverify gateの状態ファイルのときは、この要件の対象外とし、それぞれの保護の要件に従う。

#### Scenario: 外へのコピー
- **WHEN** `cp x.md ~/repos/b/` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: 外へのリダイレクト
- **WHEN** `echo hi > "/x/f"` を、ルート外の `/x` に対して実行しようとする
- **THEN** 何も出力しない

#### Scenario: 状態ファイルへのリダイレクト
- **WHEN** `echo x > ~/.local/state/uskn-harness/sessions/<session_id>/verified` を実行しようとする
- **THEN** 拒否される
