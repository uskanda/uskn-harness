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

### Requirement: プラグインの symlink
`sync` は `~/.claude/skills/uskn-harness` を `plugins/uskn-harness` へのsymlinkにしなければならない（MUST）。

#### Scenario: 初回
- **WHEN** `~/.claude/skills/uskn-harness` が無い
- **THEN** symlinkが作られ、`claude plugin list` に `uskn-harness@skills-dir` が現れる

### Requirement: サードパーティスキル
`sync` は、`deps.json` の `skills` のうち `via` が `skills` の項目を導入しなければならない（MUST）。
対象は `mode` が `reference` の項目に限り、使うのはピンした版のskills CLI。
コマンドは `npx -y skills@<version> add '<source>#<ref>@<name>' -g -a claude-code -y`。
`<version>` は `deps.json` の `clis` にある `skills` の版、`<source>` と `<ref>` はその項目の値、`<name>` は項目の名前。
`~/.claude/skills/<name>` が無いときにこのコマンドで導入し、`created` と報告する。

#### Scenario: grilling が未導入
- **WHEN** `~/.claude/skills/grilling` が無い状態で `sync` を実行する
- **THEN** skills CLIが `mattpocock/skills#<ref>@grilling` を指定して実行され、`created` と報告される

### Requirement: OpenSpec のユーザー層コマンド
`sync` はopenspecがClaude Code向けに生成するコマンド（`/opsx:*`）を、一時ディレクトリで作らなければならない（MUST）。
生成の間だけ、`XDG_CONFIG_HOME` を別の一時ディレクトリに差し替える。そこに置く `openspec/config.json` はprofileを `core`、deliveryを `commands` とする。
ユーザー全体のOpenSpecの設定（`~/.config/openspec/config.json`）は変えない（MUST NOT）。
生成物の `.claude/commands/opsx/` は `~/.claude/commands/opsx/` にコピーする。
コピー先にはハーネス管理の印として `.uskn-harness-managed` ファイルを置く。
OpenSpecのスキル（`openspec-*`）はユーザー層にコピーしない（MUST NOT）。
コピー先に印の無い同名ディレクトリがあれば、上書きせず警告する。

#### Scenario: バージョン更新
- **WHEN** openspecのversionが上がり、生成されるコマンドの内容が変わった状態で `sync` を実行する
- **THEN** `~/.claude/commands/opsx/` が新しい内容に置き換わり、`updated` と報告される

#### Scenario: ユーザー全体の設定
- **WHEN** `~/.config/openspec/config.json` がdeliveryを持たない状態で `sync` を実行する
- **THEN** 実行の前後でファイルの内容は同じ。プロダクトリポジトリの `openspec update` は、これまでどおりその設定に従う

#### Scenario: スキルは作らない
- **WHEN** `~/.claude/skills` に `openspec-*` が無い状態で `sync` を実行する
- **THEN** `~/.claude/commands/opsx/` に6つのコマンドが置かれ、`~/.claude/skills/openspec-*` は作られない

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
`frontend-design` はほかのサードパーティスキルと同じく、skills CLIで入れる。
`impeccable` は、スキルのリリースのzipとImpeccableのCLIで入れる（後述の要件）。
`clis` の `@google/design.md` もピンの版でglobalに入れる。

#### Scenario: 未導入
- **WHEN** `~/.claude/skills/impeccable` と `~/.claude/skills/frontend-design` が無い状態で `sync` を実行する
- **THEN** どちらも `deps.json` のピンで導入され、`created` と報告される

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

### Requirement: OpenSpec の旧スキルの削除
`sync` は、`~/.claude/skills/openspec-*` のうち `.uskn-harness-managed` を持つディレクトリを削除しなければならない（MUST）。
印の無いディレクトリには触らない。
`--dry-run` のときは予定を出力するだけで、削除しない。

#### Scenario: 以前の sync が入れたスキル
- **WHEN** `~/.claude/skills/openspec-propose` が印を持つディレクトリとして存在する
- **THEN** `sync` はそれを削除し、`removed` と報告する

#### Scenario: 印の無いスキル
- **WHEN** `~/.claude/skills/openspec-explore` が印の無いディレクトリとして存在する
- **THEN** ディレクトリはそのまま残る

### Requirement: 実体の無い symlink の削除
`sync` は、`~/.claude/skills` の下のsymlinkのうち、ハーネスの `skills/` の下を指し、指す先が存在しないものを削除しなければならない（MUST）。
ハーネスの外を指すsymlink、指す先が存在するsymlink、実ディレクトリには触らない（MUST NOT）。
名前がハーネスの現存するスキルと同じsymlinkは削除せず、張り直す。
`--dry-run` のときは予定を出力するだけで、削除しない。`sync --remove` も同じ規則でこのsymlinkを削除する。

#### Scenario: ハーネスから削除したスキル
- **WHEN** `~/.claude/skills/nessun-dorma` が、もう存在しない `skills/git/nessun-dorma` を指している
- **THEN** `sync` はsymlinkを削除し、`removed` と報告する

#### Scenario: ハーネスの外を指す実体の無い symlink
- **WHEN** `~/.claude/skills/mine` が、存在しないハーネス外のパスを指している
- **THEN** symlinkはそのまま残る

#### Scenario: 移動したスキル
- **WHEN** `~/.claude/skills/pr` が、存在しない `skills/old-location/pr` を指している
- **THEN** symlinkは削除されず、`skills/git/pr` へ張り直されて `updated` と報告される

### Requirement: サードパーティスキルの ref の照合
`~/.claude/skills/<name>` があるとき、`sync` はlockファイルの `ref` を `deps.json` の `ref` と比べなければならない（MUST）。
lockファイルはskills CLIが導入を記録するファイルで、場所は `$XDG_STATE_HOME/skills/.skill-lock.json`。
`XDG_STATE_HOME` が無ければ `~/.agents/.skill-lock.json`。
同じなら何も実行せず `ok` と報告する。
違うとき、またはlockの項目が `ref` を持たないときは、導入と同じコマンドで入れ直し、`updated` と報告する。

#### Scenario: ピンと同じ
- **WHEN** lockのgrillingの `ref` が `deps.json` の `ref` と同じ
- **THEN** skills CLIは実行されず、grillingは `ok` と報告される

#### Scenario: ピンを上げた
- **WHEN** `deps.json` のhumanizerの `ref` を上げて `sync` を実行する
- **THEN** 新しい `ref` で入れ直され、`updated` と報告される

#### Scenario: ref を記録していない lock
- **WHEN** lockのgrillingの項目が `ref` を持たない
- **THEN** grillingは入れ直され、`updated` と報告される

### Requirement: lock に無いサードパーティスキル
`~/.claude/skills/<name>` があってlockファイルにその名前の項目が無いとき、`sync` はそのディレクトリを変更してはならない（MUST NOT）。
その項目は `conflict` と報告し、終了コードは0のまま。

#### Scenario: 手で置いたスキル
- **WHEN** `~/.claude/skills/grilling` が実ディレクトリとしてあり、lockにgrillingの項目が無い
- **THEN** skills CLIは実行されず、ディレクトリの中身は変わらず、`conflict` と報告される

### Requirement: Impeccable の導入
Impeccableの `SKILL.md` の `version` がピンと違うとき、`sync` はピンした版のスキルを入れなければならない（MUST）。
`SKILL.md` は `~/.claude/skills/impeccable/SKILL.md`、`version` はそのfrontmatterの値、ピンは `deps.json` の `version`。
リリースのzipは `https://github.com/<source>/releases/download/<ref>/<asset>` から取る。
入れるのはピンした版のImpeccableのCLIで、zipは環境変数 `IMPECCABLE_BUNDLE_PATH` で渡す。
CLIの引数は `install -y --providers=claude --scope=global --no-hooks`。
ディレクトリが無ければ `created`、版が違えば `updated`、同じなら何も実行せず `ok` と報告する。
ディレクトリがあって `SKILL.md` が `version` を持たないときは、触らずに `conflict` と報告する。

#### Scenario: 版が古い
- **WHEN** 導入済みの `SKILL.md` が `version: 4.2.0` で、`deps.json` の `version` が4.3.1
- **THEN** skill-v4.3.1のzipが取られ、ピンした版のCLIで入れ直され、`updated` と報告される

#### Scenario: 版が同じ
- **WHEN** 導入済みの `SKILL.md` の `version` が `deps.json` と同じ
- **THEN** ダウンロードとCLIは実行されず、`ok` と報告される

### Requirement: Impeccable の zip の検証
ダウンロードしたzipのsha256が `deps.json` の `sha256` と違うとき、`sync` はImpeccableのCLIを実行してはならない（MUST NOT）。
その手順は `fail` と報告し、`sync` は終了コード1で終わる。
CLIは手元のzipの署名を確かめないので、sha256がその代わりになる。

#### Scenario: 中身の違う zip
- **WHEN** ダウンロードしたzipのsha256が `deps.json` の値と違う
- **THEN** CLIは実行されず、`fail` と報告され、`sync` の終了コードは1

### Requirement: Impeccable の agent の削除
Impeccableの手順のあと、`sync` は `remove_agents` に挙げたagentのファイルを消さなければならない（MUST）。
`remove_agents` は `deps.json` の `impeccable` の項目にあり、ファイルは `~/.claude/agents/<name>.md`。
消したファイルは `removed` と報告する。挙げていないファイルは消さない。Impeccableの手順が `conflict` だったときは消さない。

#### Scenario: 導入のあと
- **WHEN** Impeccableの導入で `~/.claude/agents/impeccable-documenter.md` などの4つのファイルができた
- **THEN** 4つとも消され、`~/.claude/agents/` の他のファイルは残る

#### Scenario: 2 回目
- **WHEN** 4つのファイルが無い状態で `sync` を再実行する
- **THEN** 何も消さず、`removed` と報告しない

### Requirement: ピンの形式
`deps.json` の `ref` は、タグか40桁のcommit SHAでなければならない（MUST）。
skills CLIは `ref` を `git clone --branch` に渡すので、12桁などの短いSHAでは導入できない。
`make verify` のbatsがこの形を検査する。

#### Scenario: 短い SHA
- **WHEN** ある項目の `ref` を12桁のSHAにする
- **THEN** `make verify` のbatsが失敗し、その項目の名前が出力される

### Requirement: skills CLI の版の固定
`deps.json` の `clis` にある `skills` の版は、`latest` ではなく固定した版でなければならない（MUST）。
`make verify` のbatsがこの形を検査する。

#### Scenario: latest に戻す
- **WHEN** `clis` の `skills` の版を `latest` にする
- **THEN** `make verify` のbatsが失敗する
