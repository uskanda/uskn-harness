## ADDED Requirements

### Requirement: ルートの範囲
hookは、write-guardと同じプロジェクトルートを使わなければならない（MUST）。
ルートは `CLAUDE_PROJECT_DIR` と、それと同じリポジトリ（同じgit common dir）のcheckoutであるときだけの `cwd` のgitルートである。
別のリポジトリのcheckoutは、`cwd` のgitルートであってもルートにならない。
denyパターンとwarnパターンで言うルートの外とは、どのルートの外にもあることを指す。

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

### Requirement: verify gate の状態ファイルの保護
コマンドがverify gateの状態ファイルを名指しするとき、hookは `permissionDecision: deny` を返さなければならない（MUST）。
状態ファイルは、状態ディレクトリの `sessions/<session_id>/` にある `baseline`、`verified`、`verify-blocks` である。
リダイレクト先や書く操作の対象の実体が状態ファイルのときも、同じく拒否する。
書く操作の対象がセッションのディレクトリ `sessions/<session_id>` そのもののときも拒否する。
`rm`、`rmdir`、`mv` の対象が、状態ディレクトリ、その `sessions`、またはそれらの上位のディレクトリのときも拒否する。
理由には、状態ファイルはハーネスのhookだけが書くこと、検証を意図して飛ばすのはユーザーが `USKN_SKIP_VERIFY=1` を設定するときであることを書く。
許可ファイルに何が書かれていても、この拒否は解除しない。

#### Scenario: リダイレクトで検証済みにする
- **WHEN** `echo x > ~/.local/state/uskn-harness/sessions/<session_id>/verified` を実行しようとする
- **THEN** 拒否され、理由に `USKN_SKIP_VERIFY` が含まれる

#### Scenario: セッションのディレクトリを消す
- **WHEN** `rm -rf ~/.local/state/uskn-harness/sessions/<session_id>` を実行しようとする
- **THEN** 拒否される

#### Scenario: セッションのディレクトリへのコピー
- **WHEN** `cp /tmp/baseline ~/.local/state/uskn-harness/sessions/<session_id>/` を実行しようとする
- **THEN** 拒否される

#### Scenario: 検証のログを読む
- **WHEN** `tail ~/.local/state/uskn-harness/sessions/<session_id>/verify.log` を実行しようとする
- **THEN** 何も出力しない
