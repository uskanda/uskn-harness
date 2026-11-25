# Spec Delta

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
知らせは、1つのセッションで1回だけ出さなければならない（MUST）。出したことは、状態ディレクトリの `sessions/<session_id>/sandbox-note` に記録する。
入力に `session_id` が無いときは、毎回知らせる。拒否と、要件「sandboxを外した呼び出しの知らせ」の知らせは、回数を絞らない。

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

#### Scenario: 同じセッションの2回目
- **WHEN** liveの `sandbox.excludedCommands` に `git *` がある。同じ `session_id` の入力で、`cd sub && git log --oneline -3` を2回実行しようとする
- **THEN** 1回目の `additionalContext` には `git log` が含まれ、2回目は何も出力しない

#### Scenario: 知らせの後の拒否
- **WHEN** 同じセッションで知らせを出した後に、`cd sub && git fetch origin` を実行しようとする
- **THEN** 拒否される

## ADDED Requirements

### Requirement: 閉じた環境の push と PR の作成の拒否
閉じた環境の間、hookは、pushとPRの作成のコマンドを拒否しなければならない（MUST）。
対象は、`git push`、`gh pr create`、`glab mr create` である。コマンド全体のどこに現れても拒否する。
理由には、閉じた環境のセッションはローカルのcommitまでを行い、pushとPRは外側が行うことを書く。
管理者の環境では、この拒否をしない（MUST NOT）。

#### Scenario: 閉じた環境の push
- **WHEN** 閉じた環境で、`git push -u origin HEAD` を実行しようとする
- **THEN** 拒否され、理由に「pushとPRは外側で行う」旨が含まれる

#### Scenario: 閉じた環境の PR の作成
- **WHEN** 閉じた環境で、`cd sub && gh pr create --draft` を実行しようとする
- **THEN** 拒否される

#### Scenario: 閉じた環境の commit
- **WHEN** 閉じた環境で、`git commit -m x` を実行しようとする
- **THEN** この要件では拒否されない

#### Scenario: 管理者の環境の push
- **WHEN** 管理者の環境で、liveの `sandbox.excludedCommands` に `git *` がある状態で、`git push -u origin HEAD` を実行しようとする
- **THEN** 何も出力しない
