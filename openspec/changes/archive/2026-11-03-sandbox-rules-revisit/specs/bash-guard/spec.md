## MODIFIED Requirements

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

## ADDED Requirements

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
