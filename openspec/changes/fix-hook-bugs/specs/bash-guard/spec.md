## MODIFIED Requirements

### Requirement: deny パターン
コマンドが次のいずれかを含むとき、hookは `permissionDecision: deny` と理由を返さなければならない（MUST）。

- chezmoiの下位コマンド `apply|add|update|edit|re-add|merge`。下位コマンドより前のオプション（`chezmoi -v apply`）も読み飛ばして判定する
- ルート外のリポジトリに対するgitの書き込み操作。対象のリポジトリは `git -C <path>`、`--git-dir`、`--work-tree`、環境変数 `GIT_DIR` と `GIT_WORK_TREE`、それまでの `cd` と `pushd` で決まる
- 書き込み操作とはgitの下位コマンドが `push`、`commit`、`reset`、`checkout`、`switch`、`rebase`、`merge`、`cherry-pick`、`apply`、`am` のいずれかであること

gitの下位コマンドは、`-c <key=value>` などのオプションを読み飛ばした最初の語とする。下位コマンドより後ろの引数（`git log --grep reset` の `reset`）は書き込み操作とみなさない。
パスは引用符を外し、`~` と `$HOME` を展開してから判定する。相対パスは、それまでの `cd` と `pushd` を反映した作業ディレクトリから解決する。
ルート内、許可リスト内、allowに列挙されたパスは対象外。heredocの本文はコマンドとして読まない。

#### Scenario: chezmoi apply
- **WHEN** `chezmoi apply --force` を実行しようとする
- **THEN** 拒否される

#### Scenario: 下位コマンドより前のオプション
- **WHEN** `chezmoi -v apply` を実行しようとする
- **THEN** 拒否される

#### Scenario: 他リポジトリへの push
- **WHEN** `cd ~/dotfiles && git push origin master` を実行しようとする
- **THEN** 拒否される

#### Scenario: 引用符付きのパスと pushd
- **WHEN** ルート外の `/x` に対して `git -C "/x" push`、`cd '/x' && git push`、`pushd /x && git commit` のいずれかを実行しようとする
- **THEN** 拒否される

#### Scenario: -C より前のオプションと --git-dir
- **WHEN** `git -c k=v -C ~/repos/b commit` または `git --git-dir=~/repos/b/.git commit` を実行しようとする
- **THEN** 拒否される

#### Scenario: 読み取り
- **WHEN** `git -C ~/dotfiles log --oneline -3` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: 書き込み操作の名前を含む読み取り
- **WHEN** `git -C ~/repos/b log --grep reset` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: heredoc の本文
- **WHEN** `git commit -F - <<'EOF'` の本文に `cd ~/dotfiles && git push` という行を含むコマンドを、ルート内で実行しようとする
- **THEN** 何も出力しない

### Requirement: warn パターン
コマンドがルート外の絶対パスへ書くとき、hookは警告を返さなければならない（MUST）。
書く操作とは、リダイレクト（`>`、`>>`、`&>` など）と、`cp|mv|rm|ln|tee|mkdir|touch|rsync|install|sed -i` である。
リダイレクト先のパスは引用符を外して判定する。`cp`、`install`、`rsync`、`ln` は書き込み先（最後の引数か `-t` の値）だけを見る。
`sed -i` は式を除いたファイルの引数だけを見る。式の中の `/` で始まる部分をパスとみなしてはならない（MUST NOT）。
警告は `hookSpecificOutput.additionalContext` に入れ、対象パスと、他リポジトリはPRかhandoffで扱う旨を書く。
このとき拒否してはならない（MUST NOT）。

#### Scenario: 外へのコピー
- **WHEN** `cp x.md ~/repos/b/` を実行しようとする
- **THEN** 警告が付き、拒否はされない

#### Scenario: 引用符付きのリダイレクト
- **WHEN** `echo hi > "/x/f"` を、ルート外の `/x` に対して実行しようとする
- **THEN** 警告が付く

#### Scenario: sed の式
- **WHEN** `sed -i -n '/,$p' file` や `sed 's/.*foo//' file` をルート内のファイルに対して実行しようとする
- **THEN** 何も出力しない

#### Scenario: 外からのコピー
- **WHEN** `cp ~/repos/b/x.md ./` を実行しようとする
- **THEN** 書き込み先はルート内なので何も出力しない

## ADDED Requirements

### Requirement: chezmoi の拒否の解除
セッションの許可ファイルがchezmoiのsource directoryを覆うとき、hookはchezmoiの下位コマンドを拒否してはならない（MUST NOT）。
source directoryは次の順に決める。コマンドの `--source` か `-S` の値。無ければ `chezmoi source-path` の出力。
それも得られなければ `~/.local/share/chezmoi`。
プロジェクトルートや許可リストに含まれることでは解除しない。
拒否の理由には、解除に使う `/allow-repo <path>` の `<path>` として、そのsource directoryを書く。

#### Scenario: dotfiles を許可したあと
- **WHEN** source directoryが `~/dotfiles` で、ユーザーの依頼で `/allow-repo ~/dotfiles` を実行したあと `chezmoi apply` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: 許可が無い
- **WHEN** 許可ファイルが無い状態で `chezmoi apply` を実行しようとする
- **THEN** 拒否され、理由にsource directoryと `/allow-repo` が含まれる

### Requirement: 許可ファイルの保護
コマンドが許可ファイル `sessions/<session_id>/allow` を名指しするとき、hookは `permissionDecision: deny` を返さなければならない（MUST）。
リダイレクト先や書く操作の対象の実体が許可ファイルのときも、同じく拒否する。symlinkや相対パスを通した場合を含む。
理由には、許可ファイルを書くのは `/allow-repo` だけで、中身は `allow-repo.sh --list` で読める旨を書く。
許可ファイルに何が書かれていても、この拒否は解除しない。

#### Scenario: リダイレクトで許可を足す
- **WHEN** `echo ~/repos/b >> ~/.local/state/uskn-harness/sessions/<session_id>/allow` を実行しようとする
- **THEN** 拒否される

#### Scenario: allow-repo.sh の実行
- **WHEN** `/allow-repo` スキルが `allow-repo.sh --session <sid8> <path>` を実行する
- **THEN** 何も出力しない
