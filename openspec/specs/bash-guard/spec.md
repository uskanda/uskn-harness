# bash-guard Specification

## Purpose
Bash経由で他のプロジェクトを書き換える典型（chezmoiの適用、他リポジトリへのgit操作）と、ハーネスの状態ファイルへの書き込みを拒否するhook。
それ以外のルートの外への書き込みは、Claude Codeのsandboxが制限する。誤検知よりも取りこぼしを許容する。

## Requirements

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

### Requirement: 失敗しても止めない
入力が読めない場合は何も出力せず終了コード0（MUST）。

#### Scenario: JSONでない入力
- **WHEN** stdinがJSONでない
- **THEN** 出力は空

### Requirement: chezmoi の拒否の解除
セッションの許可ファイルがchezmoiのsource directoryを覆うとき、hookはchezmoiの下位コマンドを拒否してはならない（MUST NOT）。
source directoryは次の順に決める。コマンドの `--source` か `-S` の値。無ければ `chezmoi source-path` の出力。
それも得られなければ `~/.local/share/chezmoi`。
プロジェクトルートや許可リストに含まれることでは解除しない。
拒否の理由には、解除に使う `/add-dir <path>` の `<path>` として、そのsource directoryを書く。

#### Scenario: dotfiles を許可したあと
- **WHEN** source directoryが `~/dotfiles` で、ユーザーが `/add-dir ~/dotfiles` を実行したあと `chezmoi apply` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: 許可が無い
- **WHEN** 許可ファイルが無い状態で `chezmoi apply` を実行しようとする
- **THEN** 拒否され、理由にsource directoryと `/add-dir` が含まれる

### Requirement: 許可ファイルの保護
コマンドが許可ファイル `sessions/<session_id>/allow` を名指しするとき、hookは `permissionDecision: deny` を返さなければならない（MUST）。
リダイレクト先や書く操作の対象の実体が許可ファイルのときも、同じく拒否する。symlinkや相対パスを通した場合を含む。
理由には、許可ファイルを書くのは `DirectoryAdded` のhookだけで、中身は `allow-repo.sh --list` で読める旨を書く。
許可ファイルに何が書かれていても、この拒否は解除しない。

#### Scenario: リダイレクトで許可を足す
- **WHEN** `echo ~/repos/b >> ~/.local/state/uskn-harness/sessions/<session_id>/allow` を実行しようとする
- **THEN** 拒否される

#### Scenario: allow-repo.sh の実行
- **WHEN** `allow-repo.sh --list --session <sid8>` を実行しようとする
- **THEN** 何も出力しない

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

### Requirement: 途中に出てくる外の道具の知らせ
sandboxの外に出す道具が、コマンド全体の先頭にないとき、hookは `additionalContext` で知らせなければならない（MUST）。
外に出す道具とは、liveの `sandbox.excludedCommands` のパターンに当たるものである。
先頭にないとは、コマンド全体が複数の単純なコマンドから成る（パイプ、`&&`、`;`、かっこを含む）か、その道具の前に代入や `sudo` などが付くことを言う。
`excludedCommands` がsandboxの外で動かすのは、1つの単純なコマンドだけから成り、その先頭がパターンと一致するコマンドだけであるため。
gitで、下位コマンドの前に、読むリポジトリや設定の場所を変える選択肢が付くときも、先頭にないものと同じに扱う。
その選択肢は、`-C`、`-c`、`--git-dir`、`--work-tree`、`--config-env`、`--exec-path` である。これらが付いたgitには、`excludedCommands` が当たらない（2026-11-01に実機で確認）。
知らせには、その道具がsandboxの中で動くことと、失敗したら単独で実行し直すことを書く。
パターンは、liveの `~/.claude/settings.json` から読む。`CLAUDE_CONFIG_DIR` があれば、その下から読む。
sandboxの中で動かない道具は、知らせずに拒否する（要件「途中に出てくるsandboxの中で動かない道具の拒否」）。
それ以外の道具では、拒否してはならない（MUST NOT）。denyパターンに当たるときは、拒否だけを返す。

#### Scenario: cd の後の log
- **WHEN** liveの `sandbox.excludedCommands` に `git *` がある状態で、`cd sub && git log --oneline -3` を実行しようとする
- **THEN** `additionalContext` に `git log` と、単独で実行し直すことが含まれ、拒否はされない

#### Scenario: -C の付いた log
- **WHEN** liveの `sandbox.excludedCommands` に `git *` がある状態で、`git -C sub log --oneline -3` を実行しようとする
- **THEN** `additionalContext` に `git log` が含まれ、拒否はされない

#### Scenario: パイプの前の gh
- **WHEN** liveの `sandbox.excludedCommands` に `gh *` がある状態で、`gh pr view 3 --json title | jq .title` を実行しようとする
- **THEN** `additionalContext` に `gh pr` が含まれ、拒否はされない

#### Scenario: cd の後の push
- **WHEN** liveの `sandbox.excludedCommands` に `git *` がある状態で、`cd sub && git push -u origin HEAD` を実行しようとする
- **THEN** この知らせは出さず、要件「途中に出てくるsandboxの中で動かない道具の拒否」の拒否だけを返す

#### Scenario: パイプの前の push
- **WHEN** 同じ状態で、`git push -u origin HEAD 2>&1 | tail -1` を実行しようとする
- **THEN** この知らせは出さず、拒否だけを返す

#### Scenario: 先頭の push
- **WHEN** liveの `sandbox.excludedCommands` に `git *` がある状態で、`git push -u origin HEAD` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: 一覧に無い道具
- **WHEN** 同じ状態で、`cd sub && make test` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: 設定が読めない
- **WHEN** liveの `~/.claude/settings.json` が無い
- **THEN** この知らせは出さない

### Requirement: 途中に出てくるsandboxの中で動かない道具の拒否
sandboxの外に出す道具のうち、sandboxの中で失敗すると分かっているものが、コマンド全体の先頭にないとき、hookは拒否しなければならない（MUST）。
外に出す道具と、先頭にないことの意味は、要件「途中に出てくる外の道具の知らせ」と同じである。
sandboxの中で失敗すると分かっているものは、次の2種類である。

- `.git/config` に書くか、ネットワークを使うgitの下位コマンド。`push`、`fetch`、`pull`、`clone`、`switch`、`checkout`、`branch`、`config`、`remote`、`submodule` の10個である
- sandboxの中では動かない道具。`glab`、`docker`、`ssh`、`scp`、`claude` の5つである

拒否の理由には、その形ではsandboxの中で動いて失敗することと、その道具を先頭に置いた単独のコマンドとして実行し直すことを書く。
gitでは、場所を変える選択肢を外すことも書く。作業ツリーの中なら、gitはどのディレクトリからでもリポジトリを見つける。別のディレクトリなら、先に `cd <dir>` だけを1回の呼び出しで実行する。
liveの `sandbox.excludedCommands` に当たらない道具は、拒否しない（MUST NOT）。単独で実行しても、sandboxの中で動くため。

#### Scenario: cd の後の fetch
- **WHEN** liveの `sandbox.excludedCommands` に `git *` がある状態で、`cd sub && git fetch origin` を実行しようとする
- **THEN** 拒否され、理由に `git fetch` と `-C` が含まれる

#### Scenario: パイプの前の switch
- **WHEN** 同じ状態で、`git switch -c topic 2>&1 | tail -1` を実行しようとする
- **THEN** 拒否される

#### Scenario: 代入の後の glab
- **WHEN** liveの `sandbox.excludedCommands` に `glab *` がある状態で、`R=nas/x; glab issue view 3 -R $R` を実行しようとする
- **THEN** 拒否される

#### Scenario: -C の付いた push
- **WHEN** liveの `sandbox.excludedCommands` に `git *` がある状態で、`git -C sub push -u origin HEAD` を実行しようとする
- **THEN** 拒否される

#### Scenario: 場所を変えない選択肢
- **WHEN** 同じ状態で、`git --no-pager push -u origin HEAD` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: 一覧から外した道具
- **WHEN** liveの `sandbox.excludedCommands` に `docker *` が無い状態で、`cd sub && docker ps` を実行しようとする
- **THEN** 拒否されず、何も出力しない

### Requirement: sandboxを外した呼び出しの知らせ
`tool_input.dangerouslyDisableSandbox` が `true` のとき、hookは `additionalContext` で知らせなければならない（MUST）。
知らせには、sandboxを外すのは、そのコマンドがsandboxの制限で失敗したのを見たときだけであることを書く。
あわせて、ルートの中のファイルの編集や読み取りは、sandboxの中で動くことも書く。
denyパターンに当たるときは、拒否だけを返す。
`dangerouslyDisableSandbox` が無いときと `false` のときは、この知らせを出してはならない（MUST NOT）。

#### Scenario: 編集をsandboxの外で動かす
- **WHEN** `tool_input.dangerouslyDisableSandbox` が `true` で、`sed -i 's/a/b/' README.md` を実行しようとする
- **THEN** `additionalContext` に、sandboxの制限による失敗を見たときだけ外すことが含まれ、拒否はされない

#### Scenario: sandboxの中の呼び出し
- **WHEN** `tool_input.dangerouslyDisableSandbox` が無い状態で、`sed -i 's/a/b/' README.md` を実行しようとする
- **THEN** 何も出力しない

### Requirement: 未archiveの変更を持った統合の操作の拒否
統合の操作をしようとしたとき、`uskn-archive-check` が該当ありを返すなら、hookは `permissionDecision: deny` を返さなければならない（MUST）。
理由には、該当した変更の名前と、`/archive-push <name>` を実行するか `.archive-later` で宣言するかの案内を含める。
統合の操作と比べる先は、次のとおりとする。作業ディレクトリは、それまでの `cd` とgitの `-C` で決まる。

- `gh pr merge` と `glab mr merge`：`origin/<統合ブランチ>`
- 送り先が既定ブランチか統合ブランチの `git push`：`origin/<送り先>`。送り先は、refspecがあればその送り先、無ければ上流のブランチ、上流も無ければ現在のブランチとする

#### Scenario: 未archiveの変更があるときの gh pr merge
- **WHEN** `origin/main` から分かれて変更 `add-x` を足したブランチで、`gh pr merge 12 --auto --merge` を実行しようとする
- **THEN** 拒否され、理由に `add-x` と `/archive-push` が含まれる

#### Scenario: main への git push
- **WHEN** 統合ブランチが `main` で、変更 `add-x` を足した `main` から `git push origin main` を実行しようとする
- **THEN** 拒否される

#### Scenario: 作業ブランチへの git push
- **WHEN** 同じ変更を足した `change/add-x` から `git push -u origin HEAD` を実行しようとする
- **THEN** この判定では何も出力しない

#### Scenario: archive保留の宣言
- **WHEN** 変更 `add-x` に `.archive-later` があり、`gh pr merge 12` を実行しようとする
- **THEN** この判定では何も出力しない

### Requirement: 判定できない統合の操作は止めない
`uskn-archive-check` が判定できないとき（終了コード2）、hookはその統合の操作を拒否してはならない（MUST NOT）。

#### Scenario: 比べる先が無い
- **WHEN** `origin/main` の無いリポジトリで、`gh pr merge 12` を実行しようとする
- **THEN** この判定では何も出力しない
