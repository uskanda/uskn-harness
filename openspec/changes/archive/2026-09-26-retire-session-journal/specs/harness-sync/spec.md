## ADDED Requirements

### Requirement: 古いセッションの状態の削除
`sync` は、状態ディレクトリの `sessions/` の下にあるセッションのディレクトリのうち、30日より長く更新されていないものを削除しなければならない（MUST）。
状態ディレクトリはhookと同じ `${XDG_STATE_HOME:-~/.local/state}/uskn-harness` で、`USKN_STATE_DIR` があればそれを使う。
更新の有無は、ディレクトリそのものと中のファイルのうち、最も新しい更新時刻で判断する。
削除したときは数を `removed` として報告し、消せなかったディレクトリは `warn` として報告する。`sessions/` の外には触れない。

#### Scenario: 古いセッションと新しいセッション
- **WHEN** 40日前から更新の無いセッションと、昨日更新したセッションがある状態で `sync` を実行する
- **THEN** 前者だけが削除され、`removed` と報告される

#### Scenario: 古いディレクトリの中の新しいファイル
- **WHEN** ディレクトリの更新時刻は40日前だが、中の `verify.log` は昨日更新されている
- **THEN** そのディレクトリは削除されない

#### Scenario: dry-run
- **WHEN** 古いセッションがある状態で `sync --dry-run` を実行する
- **THEN** 削除の予定が出力され、ディレクトリは残る

### Requirement: journal の置き場に触れない
`sync` は `~/.ai-sessions` を作ってはならず、既にあれば中身を変えてはならない（MUST NOT）。

#### Scenario: 新しいマシン
- **WHEN** `~/.ai-sessions` が無い状態で `sync` を実行する
- **THEN** `~/.ai-sessions` は作られない

#### Scenario: journal を使っていたマシン
- **WHEN** `~/.ai-sessions` がgitリポジトリとして存在する状態で `sync` を実行する
- **THEN** 中身は変わらず、`sync` の出力に `~/.ai-sessions` は現れない

## MODIFIED Requirements

### Requirement: 道具だけの導入（--tools）
`uskn-harness sync --tools` は3つだけを用意しなければならない（MUST）。ランタイム（mise、node、jq）、`deps.json` でピンしたnpm globalのCLI、OpenSpec schemaのsymlink。
参照点、実行ファイル、スキルとプラグインのsymlink、サードパーティスキル、OpenSpecのユーザー層、ユーザー層CLAUDE.mdには触らない。古いセッションの状態も削除しない。
`--dry-run` と組み合わせられる。`--remove` と組み合わせたときは終了コード2で止まる。

#### Scenario: CI の runner
- **WHEN** 何も導入されていないマシンで `sync --tools` を実行する
- **THEN** miseの道具とnpm globalの導入が実行され、schemaのsymlinkが作られる。`~/.claude/skills` と `~/.claude/CLAUDE.md` は作られない

#### Scenario: 2 回目
- **WHEN** 導入済みの環境で `sync --tools` を再実行する
- **THEN** 何も変更せず、各項目が `ok` として報告される

#### Scenario: --remove との併用
- **WHEN** `sync --tools --remove` を実行する
- **THEN** 何もせず終了コード2で止まる

### Requirement: 失敗の終了コード
手順のどれかが失敗したとき、`sync` は残りの手順を続けたうえで、終了コード1で終わらなければならない（MUST）。
失敗とは、miseやnode、jq、npm global、サードパーティスキルの導入の失敗である。
このとき、失敗した手順の数と `sync` を再実行する旨を標準エラーに出力する。
`conflict` と警告だけのとき、およびcheckoutの更新の失敗では、終了コードは0のまま。
`--tools` でも同じ規則に従う。

#### Scenario: npm global の導入に失敗
- **WHEN** ネットワークが無く、`npm install -g` が失敗する
- **THEN** 他の手順は続き、`sync` は終了コード1で終わる。chezmoiのrun_onceスクリプトも非ゼロで終わり、次回の `chezmoi apply` で再実行される

#### Scenario: CI の runner
- **WHEN** `sync --tools` でピンしたCLIの導入が失敗する
- **THEN** 終了コードは1で、workflowはその時点で失敗する

#### Scenario: conflict だけ
- **WHEN** 実ディレクトリの同名スキルがあるだけで、他の手順は成功する
- **THEN** 終了コードは0

## REMOVED Requirements

### Requirement: sessions リポジトリの初期化
**Reason**: セッションjournalの仕組みを廃止し、journalを貯める場所が要らなくなる。
**Migration**: `sync` は `~/.ai-sessions` を作らない。既存のものは残り、消すかはユーザーが決める。中身は、この差分で足したjournalの置き場の要件が守る。
