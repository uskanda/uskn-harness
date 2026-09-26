## MODIFIED Requirements

### Requirement: 自作スキルの symlink
`sync` は `skills/**/SKILL.md` を持つ各ディレクトリについて `~/.claude/skills/<name>` へのsymlinkを張らなければならない（MUST）。`<name>` はディレクトリ名。既に同名の実ディレクトリ（symlinkでないもの）があるときは上書きせず、`conflict` として警告し、他の項目の処理を続ける。既にハーネス内を指すsymlinkなら `ok`。
`uskn-harness` はプラグインの名前なので、スキルの名前には使えない。

#### Scenario: chezmoi 管理の同名スキルがある
- **WHEN** `~/.claude/skills/commit` が実ディレクトリとして存在する
- **THEN** `commit` は `conflict` と報告され、symlinkは作られず、終了コードは0

#### Scenario: 名前の一意性
- **WHEN** `skills/` 配下の2つのディレクトリが同じ名前を持つ
- **THEN** `sync` は導入前にエラーで停止する

#### Scenario: 予約名
- **WHEN** `skills/` 配下に `uskn-harness` という名前のスキルがある
- **THEN** `sync` は何も書かずに終了コード2で停止する

## ADDED Requirements

### Requirement: 失敗の終了コード
手順のどれかが失敗したとき、`sync` は残りの手順を続けたうえで、終了コード1で終わらなければならない（MUST）。
失敗とは、miseやnode、jq、npm global、サードパーティスキルの導入と、sessionsリポジトリの `git init` の失敗である。
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
