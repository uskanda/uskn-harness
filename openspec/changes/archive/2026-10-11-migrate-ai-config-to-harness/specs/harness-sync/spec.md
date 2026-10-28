## MODIFIED Requirements

### Requirement: 自作スキルの symlink
`sync` は `skills/**/SKILL.md` を持つ各ディレクトリについて `~/.claude/skills/<name>` へのsymlinkを張らなければならない（MUST）。`<name>` はディレクトリ名。既に同名の実ディレクトリ（symlinkでないもの）があるときは上書きせず、`conflict` として警告し、他の項目の処理を続ける。既にハーネス内を指すsymlinkなら `ok`。
`plugins/` の下のプラグインの名前は、スキルの名前には使えない。

#### Scenario: chezmoi 管理の同名スキルがある
- **WHEN** `~/.claude/skills/commit` が実ディレクトリとして存在する
- **THEN** `commit` は `conflict` と報告され、symlinkは作られず、終了コードは0

#### Scenario: 名前の一意性
- **WHEN** `skills/` 配下の2つのディレクトリが同じ名前を持つ
- **THEN** `sync` は導入前にエラーで停止する

#### Scenario: 予約名
- **WHEN** `skills/` 配下に `uskn-harness` という名前のスキルがある
- **THEN** `sync` は何も書かずに終了コード2で停止する

#### Scenario: 通知のプラグインの名前
- **WHEN** `skills/` 配下に `uskn-notify` という名前のスキルがある
- **THEN** `sync` は何も書かずに終了コード2で停止する

### Requirement: プラグインの symlink
`sync` は、`plugins/` の下の各プラグインについて、`~/.claude/skills/<name>` をそのディレクトリへのsymlinkにしなければならない（MUST）。
プラグインとは `.claude-plugin/plugin.json` を持つディレクトリで、`<name>` はディレクトリ名。
同名の実ディレクトリがあるときは上書きせず、`conflict` と報告する。

#### Scenario: 初回
- **WHEN** `~/.claude/skills/uskn-harness` が無い
- **THEN** symlinkが作られ、`claude plugin list` に `uskn-harness@skills-dir` が現れる

#### Scenario: 通知のプラグイン
- **WHEN** `~/.claude/skills/uskn-notify` が無い状態で `sync` を実行する
- **THEN** `~/.claude/skills/uskn-notify` が `plugins/uskn-notify` へのsymlinkとして作られ、`created` と報告される

#### Scenario: 取り除く
- **WHEN** `sync --remove` を実行する
- **THEN** `~/.claude/skills/uskn-harness` と `~/.claude/skills/uskn-notify` のsymlinkが消える

### Requirement: 道具だけの導入（--tools）
`uskn-harness sync --tools` は3つだけを用意しなければならない（MUST）。ランタイム（mise、node、jq）、`deps.json` でピンしたnpm globalのCLI、OpenSpec schemaのsymlink。
参照点、実行ファイル、スキルとプラグインのsymlink、サードパーティスキル、OpenSpecのユーザー層、ユーザー層CLAUDE.mdには触らない。
ユーザー層のsettings.jsonと適用記録、`~/.local/bin` の通知のコマンドにも触らない。古いセッションの状態も削除しない。
`--dry-run` と組み合わせられる。`--remove` と組み合わせたときは終了コード2で止まる。

#### Scenario: CI の runner
- **WHEN** 何も導入されていないマシンで `sync --tools` を実行する
- **THEN** miseの道具とnpm globalの導入が実行され、schemaのsymlinkが作られる。`~/.claude/skills`、`~/.claude/CLAUDE.md`、`~/.claude/settings.json` は作られない

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
- **THEN** 他の手順は続き、`sync` は終了コード1で終わる。dotfilesの `run_after_` のスクリプトも非ゼロで終わり、`chezmoi apply` が失敗を報告する

#### Scenario: CI の runner
- **WHEN** `sync --tools` でピンしたCLIの導入が失敗する
- **THEN** 終了コードは1で、workflowはその時点で失敗する

#### Scenario: conflict だけ
- **WHEN** 実ディレクトリの同名スキルがあるだけで、他の手順は成功する
- **THEN** 終了コードは0
