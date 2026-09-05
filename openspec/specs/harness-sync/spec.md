# harness-sync Specification

## Purpose
ハーネスの正本を1コマンドで各マシンに導入・更新する手順。何度実行しても同じ状態に収束し、ユーザーが手で置いたものを壊さない。

## Requirements

### Requirement: 冪等性
`uskn-harness sync` を連続して2回実行したとき、2回目は何も変更せず、変更が無かったことを報告しなければならない（MUST）。

#### Scenario: 2 回目の実行
- **WHEN** 導入済みの環境で `sync` を再実行する
- **THEN** 新しいsymlinkやファイルは作られず、各項目が `ok` として報告される

### Requirement: 参照点の用意
`sync` は `~/.local/share/uskn-harness` を用意しなければならない（MUST）。導入元は `USKN_HARNESS_DIR`、無ければ `sync` 自身が置かれているcheckout。参照点がそのcheckoutへのsymlink（またはcheckout自身）でなければsymlinkを張る。既に別の場所を指すsymlinkや実ディレクトリがある場合は上書きせず警告する。checkoutが無いマシンでのcloneは `machine-bootstrap` の責務。

#### Scenario: 開発機
- **WHEN** `~/repos/uskn-harness` がgit checkoutで、参照点が未作成
- **THEN** `~/.local/share/uskn-harness` はそのcheckoutへのsymlinkになる

#### Scenario: managed clone から実行
- **WHEN** `~/.local/share/uskn-harness` が実ディレクトリのcloneで、その中の `bin/uskn-harness sync` を実行する
- **THEN** 参照点は `ok`（managed clone）として報告され、symlinkは作られない

### Requirement: ランタイムと CLI
`sync` はmiseが無ければ `~/.local/bin/mise` に導入しなければならない（MUST）。
続けてグローバル既定として `node@24` と `jq` を設定する。
`deps.json` の `clis` のうち `global` が真のものを、ピンの版でnpmのglobalに導入する。
既に一致していれば何もしない。

#### Scenario: openspec が古い
- **WHEN** 導入済みのopenspecが `deps.json` のversionと異なる
- **THEN** 指定versionが導入され、`openspec --version` がその値を返す

### Requirement: 自作スキルの symlink
`sync` は `skills/**/SKILL.md` を持つ各ディレクトリについて `~/.claude/skills/<name>` へのsymlinkを張らなければならない（MUST）。`<name>` はディレクトリ名。既に同名の実ディレクトリ（symlinkでないもの）があるときは上書きせず、`conflict` として警告し、他の項目の処理を続ける。既にハーネス内を指すsymlinkなら `ok`。

#### Scenario: chezmoi 管理の同名スキルがある
- **WHEN** `~/.claude/skills/commit` が実ディレクトリとして存在する
- **THEN** `commit` は `conflict` と報告され、symlinkは作られず、終了コードは0

#### Scenario: 名前の一意性
- **WHEN** `skills/` 配下の2つのディレクトリが同じ名前を持つ
- **THEN** `sync` は導入前にエラーで停止する

### Requirement: プラグインの symlink
`sync` は `~/.claude/skills/uskn-harness` を `plugins/uskn-harness` へのsymlinkにしなければならない（MUST）。

#### Scenario: 初回
- **WHEN** `~/.claude/skills/uskn-harness` が無い
- **THEN** symlinkが作られ、`claude plugin list` に `uskn-harness@skills-dir` が現れる

### Requirement: サードパーティスキル
`sync` は `deps.json` の `skills` のうち、`mode` が `reference` で `install` を持つものを導入しなければならない（MUST）。
導入するのは `~/.claude/skills/<name>` が無いときだけで、コマンドは `install` の値を使う。既にあるものは触らない。

#### Scenario: grilling が未導入
- **WHEN** `~/.claude/skills/grilling` が無い
- **THEN** `npx skills add mattpocock/skills --skill=grilling -g -a claude-code` 相当が実行され、導入後に `SKILL.md` が存在する

### Requirement: OpenSpec のユーザー層スキル
`sync` はopenspecがClaude Code向けに生成するスキルとコマンドを、一時ディレクトリで作らなければならない（MUST）。
生成物は `~/.claude/skills/openspec-*` と `~/.claude/commands/opsx/` にコピーする。
各ディレクトリにはハーネス管理の印として `.uskn-harness-managed` ファイルを置く。
コピー先に印の無い同名ディレクトリがあれば、上書きせず警告する。
`generatedBy` はchezmoi管理の旧コピーにも含まれるため、印には使わない。

#### Scenario: バージョン更新
- **WHEN** openspecのversionが上がった状態で `sync` を実行する
- **THEN** ユーザー層のスキルの `generatedBy` が新しいversionになる

### Requirement: ユーザー層の指示
`sync` は `templates/user/CLAUDE.md` を `~/.claude/CLAUDE.md` に配置しなければならない（MUST）。配置先が存在し、先頭に「managed by uskn-harness」の印が無い場合は上書きせず警告する。

#### Scenario: ユーザーが手で書いたファイルがある
- **WHEN** `~/.claude/CLAUDE.md` が印の無いファイルとして存在する
- **THEN** ファイルはそのまま残り、`conflict` として報告される

### Requirement: 実行ファイルの公開
`sync` は `~/.local/bin/uskn-harness` を `bin/uskn-harness` へのsymlinkにしなければならない（MUST）。

#### Scenario: PATH から呼べる
- **WHEN** `sync` 後に新しいシェルを開く
- **THEN** `uskn-harness doctor` が実行できる

### Requirement: dry-run と報告
`--dry-run` を付けたとき、`sync` はファイルシステムを変更せず、行う予定の操作を1行ずつ出力しなければならない（MUST）。通常実行では各項目を `ok` / `created` / `updated` / `conflict` / `skipped` のいずれかで報告する。

#### Scenario: dry-run
- **WHEN** 未導入の環境で `sync --dry-run` を実行する
- **THEN** 出力に予定操作が並び、`~/.claude/skills` に変化が無い

### Requirement: OpenSpec schema の symlink
`sync` は `~/.local/share/openspec/schemas/uskn` をハーネスの `schemas/uskn` へのsymlinkにしなければならない（MUST）。衝突時の扱いは他のsymlinkと同じ。`sync --remove` はこのsymlinkも取り除く。

#### Scenario: 初回
- **WHEN** 未導入の環境で `sync` を実行する
- **THEN** symlinkが作られ、`openspec schema which uskn` がuserレベルを返す

### Requirement: sessions リポジトリの clone
`sync` は `~/.ai-sessions` が無いとき `deps.json` の `repos.sessions.url` からcloneしなければならない（MUST）。既にあれば触らない。

#### Scenario: 既存
- **WHEN** `~/.ai-sessions` がgitリポジトリとして存在する
- **THEN** `ok` として報告される

### Requirement: npm global CLI のピン
`sync` は `deps.json` の `clis` のうち `global` が真の項目を、miseのNodeでglobalに入れなければならない（MUST）。
対象はopenspec、textlintとそのプリセット、agent-style、design.md。版はピンに従う。
同じ版が入っていれば何もしない。`bundle` に列挙されたパッケージは同じコマンドで一緒に入れる。

#### Scenario: 未導入
- **WHEN** textlintが入っていない状態で `sync` を実行する
- **THEN** `npm install -g textlint@<version> <bundle...>` が実行され、`created` と報告される

#### Scenario: 版が一致
- **WHEN** ピンと同じ版が入っている
- **THEN** インストールは実行されず `ok` と報告される

### Requirement: UI 系の参照スキルと CLI
`sync` は `deps.json` の `skills` にある `impeccable` と `frontend-design` を入れなければならない（MUST）。
入れるのは無いときだけで、コマンドは `install` の値を使う。
`clis` の `@google/design.md` もピンの版でglobalに入れる。

#### Scenario: 未導入
- **WHEN** `~/.claude/skills/impeccable` が無い状態で `sync` を実行する
- **THEN** `deps.json` のinstallコマンドが実行され、`created` と報告される

### Requirement: 道具だけの導入（--tools）
`uskn-harness sync --tools` は3つだけを用意しなければならない（MUST）。ランタイム（mise、node、jq）、`deps.json` でピンしたnpm globalのCLI、OpenSpec schemaのsymlink。
参照点、実行ファイル、スキルとプラグインのsymlink、サードパーティスキル、sessionsリポジトリ、OpenSpecのユーザー層、ユーザー層CLAUDE.mdには触らない。
`--dry-run` と組み合わせられる。`--remove` と組み合わせたときは終了コード2で止まる。

#### Scenario: CI の runner
- **WHEN** 何も導入されていないマシンで `sync --tools` を実行する
- **THEN** miseの道具とnpm globalの導入が実行され、schemaのsymlinkが作られる。`~/.claude/skills`、`~/.ai-sessions`、`~/.claude/CLAUDE.md` は作られない

#### Scenario: 2 回目
- **WHEN** 導入済みの環境で `sync --tools` を再実行する
- **THEN** 何も変更せず、各項目が `ok` として報告される

#### Scenario: --remove との併用
- **WHEN** `sync --tools --remove` を実行する
- **THEN** 何もせず終了コード2で止まる

### Requirement: checkout の更新
`sync` は導入を始める前に、ハーネスのcheckoutをfast-forwardしなければならない（MUST）。
実行するのは次のすべてを満たすときに限る。gitの作業ツリーであること。HEADがbranchを指し、そのbranchにupstreamがあること。追跡ファイルと未追跡ファイルのどちらにも変更が無いこと。
mergeとrebaseは行わない（MUST NOT）。fast-forwardできないときは何もしない。
満たさない条件があるときは、その理由を1行で報告して更新を飛ばし、導入は続行する。

`--tools`、`--remove`、`--no-pull` のときは更新しない（MUST NOT）。`--dry-run` は予定を出力するだけで実行しない。
ネットワークや認証で待ち続けないよう、時間の上限と非対話の設定を付ける。更新の失敗はそのまま報告し、導入は続行する。

#### Scenario: 別マシンで遅れている
- **WHEN** cleanなcheckoutで `sync` を実行し、upstreamのほうが進んでいる
- **THEN** checkoutはupstreamまでfast-forwardされ、更新が報告される

#### Scenario: 作業中の checkout
- **WHEN** 変更を抱えたcheckoutで `sync` を実行する
- **THEN** 更新は行われない。未コミットの変更があると報告し、導入を続ける

#### Scenario: fast-forward できない
- **WHEN** checkoutがupstreamと分岐している
- **THEN** 更新は行われず、失敗が報告され、終了コードは0

#### Scenario: CI
- **WHEN** `sync --tools` を実行する
- **THEN** 更新は行われない

### Requirement: 更新後の再実行
更新でHEADが動いたとき、`sync` は新しい `bin/uskn-harness` を同じ引数で実行し直さなければならない（MUST）。
走行中のスクリプトが入れ替わることを避け、残りの導入を新しい版のロジックで行うため。
再実行は1回に限り、実行し直した側はcheckoutを更新しない。

#### Scenario: 更新があった
- **WHEN** `sync` の更新でHEADが動く
- **THEN** 新しい `bin/uskn-harness` が同じ引数で実行され、そちらは更新を試みずに導入を続ける

#### Scenario: 更新が無かった
- **WHEN** checkoutが既にupstreamと同じ
- **THEN** 実行し直さず、そのまま導入を続ける
