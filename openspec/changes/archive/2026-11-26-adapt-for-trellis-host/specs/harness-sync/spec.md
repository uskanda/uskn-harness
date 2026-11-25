# Spec Delta

## MODIFIED Requirements

### Requirement: ランタイムと CLI
管理者の環境の間、`sync` はmiseが無ければ `~/.local/bin/mise` に導入しなければならない（MUST）。
続けてグローバル既定として `node@24` と `jq` を設定する。
`deps.json` の `clis` のうち `global` が真のものを、ピンの版でnpmのglobalに導入する。
既に一致していれば何もしない。
閉じた環境での扱いは、要件「閉じた環境の道具」が決める。

#### Scenario: openspec が古い
- **WHEN** 管理者の環境で、導入済みのopenspecが `deps.json` のversionと異なる
- **THEN** 指定versionが導入され、`openspec --version` がその値を返す

### Requirement: 自作スキルの symlink
`sync` は `skills/**/SKILL.md` を持つ各ディレクトリについて `~/.claude/skills/<name>` へのsymlinkを張らなければならない（MUST）。`<name>` はディレクトリ名。既に同名の実ディレクトリ（symlinkでないもの）があるときは上書きせず、`conflict` として警告し、他の項目の処理を続ける。既にハーネス内を指すsymlinkなら `ok`。
ただし閉じた環境の間は、管理者の環境だけのスキルを除く。管理者の環境だけのスキルとは、`SKILL.md` のfrontmatterの `metadata` に `uskn-environment: admin` を持つスキルである。
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

#### Scenario: 閉じた環境の画面向けのスキル
- **WHEN** 閉じた環境で `sync` を実行する
- **THEN** `set-workspace-theme` と `cleanup` のsymlinkは作られない。`~/.claude/skills/commit` は作られる

#### Scenario: 閉じた環境に残った画面向けのスキル
- **WHEN** 閉じた環境で、`~/.claude/skills/cleanup` がハーネスを指すsymlinkとしてある状態で `sync` を実行する
- **THEN** そのsymlinkは消され、`removed` と報告される

### Requirement: プラグインの symlink
`sync` は、`plugins/` の下の各プラグインについて、`~/.claude/skills/<name>` をそのディレクトリへのsymlinkにしなければならない（MUST）。
プラグインとは `.claude-plugin/plugin.json` を持つディレクトリで、`<name>` はディレクトリ名。
同名の実ディレクトリがあるときは上書きせず、`conflict` と報告する。
ただし閉じた環境の間は、読み上げ通知のプラグイン `uskn-notify` を除き、ハーネスを指すそのsymlinkがあれば消す。

#### Scenario: 初回
- **WHEN** `~/.claude/skills/uskn-harness` が無い
- **THEN** symlinkが作られ、`claude plugin list` に `uskn-harness@skills-dir` が現れる

#### Scenario: 通知のプラグイン
- **WHEN** 管理者の環境で、`~/.claude/skills/uskn-notify` が無い状態で `sync` を実行する
- **THEN** `~/.claude/skills/uskn-notify` が `plugins/uskn-notify` へのsymlinkとして作られ、`created` と報告される

#### Scenario: 閉じた環境の通知のプラグイン
- **WHEN** 閉じた環境で、`~/.claude/skills/uskn-notify` が無い状態で `sync` を実行する
- **THEN** `~/.claude/skills/uskn-notify` は作られず、`~/.claude/skills/uskn-harness` は作られる

#### Scenario: 取り除く
- **WHEN** `sync --remove` を実行する
- **THEN** `~/.claude/skills/uskn-harness` と `~/.claude/skills/uskn-notify` のsymlinkが消える

### Requirement: サードパーティスキル
管理者の環境の間、`sync` は、`deps.json` の `skills` のうち `via` が `skills` の項目を導入しなければならない（MUST）。
対象は `mode` が `reference` の項目に限り、使うのはピンした版のskills CLI。
コマンドは `npx -y skills@<version> add '<source>#<ref>@<name>' -g -a claude-code -y`。
`<version>` は `deps.json` の `clis` にある `skills` の版、`<source>` と `<ref>` はその項目の値、`<name>` は項目の名前。
`~/.claude/skills/<name>` が無いときにこのコマンドで導入し、`created` と報告する。
閉じた環境での扱いは、要件「閉じた環境のサードパーティスキル」が決める。

#### Scenario: grilling が未導入
- **WHEN** 管理者の環境で、`~/.claude/skills/grilling` が無い状態で `sync` を実行する
- **THEN** skills CLIが `mattpocock/skills#<ref>@grilling` を指定して実行され、`created` と報告される

### Requirement: npm global CLI のピン
管理者の環境の間、`sync` は `deps.json` の `clis` のうち `global` が真の項目を、miseのNodeでglobalに入れなければならない（MUST）。
対象はopenspec、textlintとそのプリセット、agent-style、design.md。版はピンに従う。
同じ版が入っていれば何もしない。`bundle` に列挙されたパッケージは同じコマンドで一緒に入れる。

#### Scenario: 未導入
- **WHEN** 管理者の環境で、textlintが入っていない状態で `sync` を実行する
- **THEN** `npm install -g textlint@<version> <bundle...>` が実行され、`created` と報告される

#### Scenario: 版が一致
- **WHEN** ピンと同じ版が入っている
- **THEN** インストールは実行されず `ok` と報告される

#### Scenario: 閉じた環境
- **WHEN** 閉じた環境で、textlintが入っていない状態で `sync` を実行する
- **THEN** `npm install -g` は実行されない

### Requirement: UI 系の参照スキルと CLI
管理者の環境の間、`sync` は `deps.json` の `skills` にある `impeccable` と `frontend-design` を入れなければならない（MUST）。
`frontend-design` はほかのサードパーティスキルと同じく、skills CLIで入れる。
`impeccable` は、スキルのリリースのzipとImpeccableのCLIで入れる（後述の要件）。
`clis` の `@google/design.md` もピンの版でglobalに入れる。

#### Scenario: 未導入
- **WHEN** 管理者の環境で、`~/.claude/skills/impeccable` と `~/.claude/skills/frontend-design` が無い状態で `sync` を実行する
- **THEN** どちらも `deps.json` のピンで導入され、`created` と報告される

### Requirement: checkout の更新
管理者の環境の間、`sync` は導入を始める前に、ハーネスのcheckoutをfast-forwardしなければならない（MUST）。
実行するのは次のすべてを満たすときに限る。gitの作業ツリーであること。HEADがbranchを指し、そのbranchにupstreamがあること。追跡ファイルと未追跡ファイルのどちらにも変更が無いこと。
mergeとrebaseは行わない（MUST NOT）。fast-forwardできないときは何もしない。
満たさない条件があるときは、その理由を1行で報告して更新を飛ばし、導入は続行する。

`--tools`、`--remove`、`--no-pull` のときは更新しない（MUST NOT）。`--dry-run` は予定を出力するだけで実行しない。
閉じた環境の間も更新しない（MUST NOT）。checkoutを更新するのは管理者であり、その理由を1行で報告する。
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

#### Scenario: 閉じた環境
- **WHEN** 閉じた環境で、upstreamのほうが進んだcheckoutから `sync` を実行する
- **THEN** 更新は行われず、閉じた環境であることが理由として報告され、導入を続ける

### Requirement: サードパーティスキルの ref の照合
管理者の環境の間、`~/.claude/skills/<name>` があるとき、`sync` はlockファイルの `ref` を `deps.json` の `ref` と比べなければならない（MUST）。
lockファイルはskills CLIが導入を記録するファイルで、場所は `$XDG_STATE_HOME/skills/.skill-lock.json`。
`XDG_STATE_HOME` が無ければ `~/.agents/.skill-lock.json`。
同じなら何も実行せず `ok` と報告する。
違うとき、またはlockの項目が `ref` を持たないときは、導入と同じコマンドで入れ直し、`updated` と報告する。

#### Scenario: ピンと同じ
- **WHEN** lockのgrillingの `ref` が `deps.json` の `ref` と同じ
- **THEN** skills CLIは実行されず、grillingは `ok` と報告される

#### Scenario: ピンを上げた
- **WHEN** 管理者の環境で、`deps.json` のhumanizerの `ref` を上げて `sync` を実行する
- **THEN** 新しい `ref` で入れ直され、`updated` と報告される

#### Scenario: ref を記録していない lock
- **WHEN** 管理者の環境で、lockのgrillingの項目が `ref` を持たない
- **THEN** grillingは入れ直され、`updated` と報告される

### Requirement: Impeccable の導入
管理者の環境の間、Impeccableの `SKILL.md` の `version` がピンと違うとき、`sync` はピンした版のスキルを入れなければならない（MUST）。
`SKILL.md` は `~/.claude/skills/impeccable/SKILL.md`、`version` はそのfrontmatterの値、ピンは `deps.json` の `version`。
リリースのzipは `https://github.com/<source>/releases/download/<ref>/<asset>` から取る。
入れるのはピンした版のImpeccableのCLIで、zipは環境変数 `IMPECCABLE_BUNDLE_PATH` で渡す。
CLIの引数は `install -y --providers=claude --scope=global --no-hooks`。
ディレクトリが無ければ `created`、版が違えば `updated`、同じなら何も実行せず `ok` と報告する。
ディレクトリがあって `SKILL.md` が `version` を持たないときは、触らずに `conflict` と報告する。

#### Scenario: 版が古い
- **WHEN** 管理者の環境で、導入済みの `SKILL.md` が `version: 4.2.0` で、`deps.json` の `version` が4.3.1
- **THEN** skill-v4.3.1のzipが取られ、ピンした版のCLIで入れ直され、`updated` と報告される

#### Scenario: 版が同じ
- **WHEN** 導入済みの `SKILL.md` の `version` が `deps.json` と同じ
- **THEN** ダウンロードとCLIは実行されず、`ok` と報告される

### Requirement: sandbox の外で動かすコマンドの追加
管理者の環境の間、`uskn-harness sandbox-exclude <pattern>` は、端末別設定にパターンを1つ足さなければならない（MUST）。
足す先は、端末別設定の `sandbox.excludedCommands` である。
端末別設定の置き場は `~/.config/uskn-harness/settings.json` である。
既にあるパターンは足さない。端末別設定が無ければ作る。
続けて、ユーザー層の設定の手順だけをsyncと同じ規則で実行し、liveに反映する。
`<pattern>` が空のときと、`*` だけのときは、何も変えずに終了コード2で終える。

#### Scenario: terraform を足す
- **WHEN** 管理者の環境で `uskn-harness sandbox-exclude 'terraform *'` を実行する
- **THEN** 端末別設定とliveの `sandbox.excludedCommands` に `terraform *` があり、設定断片の要素もliveに残る

#### Scenario: すべてを外に出そうとする
- **WHEN** `uskn-harness sandbox-exclude '*'` を実行する
- **THEN** 端末別設定は変わらず、終了コードは2

### Requirement: sandbox の外で動かすコマンドの一覧と削除
`uskn-harness sandbox-exclude --list` は、liveの `sandbox.excludedCommands` を1行ずつ出力しなければならない（MUST）。
各行には、設定断片の要素か端末別設定の要素かを示す。
設定断片の要素とは、端末別設定を重ねる前の3段の合成にある要素である。
管理者の環境の間、`uskn-harness sandbox-exclude --remove <pattern>` は、端末別設定からそのパターンを消し、liveに反映しなければならない（MUST）。
設定断片の要素は `--remove` で消してはならない（MUST NOT）。消そうとしたときは、設定断片を直すPRが要ることを出力し、終了コード2で終える。

#### Scenario: 端末で足したものを外す
- **WHEN** `terraform *` を足した後に `uskn-harness sandbox-exclude --remove 'terraform *'` を実行する
- **THEN** 端末別設定とliveの `sandbox.excludedCommands` から `terraform *` が消える

#### Scenario: 既定値を外そうとする
- **WHEN** 管理者の環境で `uskn-harness sandbox-exclude --remove 'git *'` を実行する
- **THEN** 何も変わらず、出力に設定断片を直すPRの案内が含まれ、終了コードは2

### Requirement: sandbox の接続先の追加
管理者の環境の間、`uskn-harness sandbox-allow-host <host>` は、sandboxの接続先にホストを足さなければならない（MUST）。足す先は、端末別設定の `sandbox.network.allowedDomains` である。
端末別設定の置き場は `~/.config/uskn-harness/settings.json` である。
既にあるホストは足さない。端末別設定が無ければ作る。
続けて、ユーザー層の設定の手順だけをsyncと同じ規則で実行し、liveに反映する。
`<host>` が空のときと、`*` を含むときは、何も変えずに終了コード2で終える。
URLの形（`https://` で始まる、または `/` を含む）のときも、何も変えずに終了コード2で終える。

#### Scenario: 自前の GitLab を足す
- **WHEN** 管理者の環境で `uskn-harness sandbox-allow-host <gl.example.test>` を実行する
- **THEN** 端末別設定とliveの `sandbox.network.allowedDomains` に `<gl.example.test>` がある

#### Scenario: すべてのホストを足そうとする
- **WHEN** `uskn-harness sandbox-allow-host '*'` を実行する
- **THEN** 端末別設定は変わらず、終了コードは2

#### Scenario: URL を渡す
- **WHEN** `uskn-harness sandbox-allow-host https://gl.example.test/api` を実行する
- **THEN** 端末別設定は変わらず、出力にホストの名前だけを渡すことが含まれ、終了コードは2

### Requirement: sandbox の接続先の一覧と削除
`uskn-harness sandbox-allow-host --list` は、liveの `sandbox.network.allowedDomains` を1行ずつ出さなければならない（MUST）。
各行には、設定断片の要素か端末別設定の要素かを示す。
設定断片の要素とは、端末別設定を重ねる前の3段の合成にある要素である。
管理者の環境の間、`uskn-harness sandbox-allow-host --remove <host>` は、端末別設定からホストを消し、liveに反映しなければならない（MUST）。
設定断片の要素は `--remove` で消してはならない（MUST NOT）。消そうとしたときは、設定断片を直すPRが要ることを出力し、終了コード2で終える。

#### Scenario: 端末で足したものを外す
- **WHEN** `<gl.example.test>` を足した後に `uskn-harness sandbox-allow-host --remove <gl.example.test>` を実行する
- **THEN** 端末別設定とliveの `sandbox.network.allowedDomains` から `<gl.example.test>` が消える

## ADDED Requirements

### Requirement: 閉じた環境の道具
閉じた環境の間、`sync` は、mise、node、jq、npmのglobalのCLIを導入してはならない（MUST NOT）。
代わりに、環境の印の `tools` が指す共有の置き場の `installed.json` を読み、各項目の版を `deps.json` のピンと比べて報告する。
同じなら `ok`、違うか無いときは `warn` とし、`warn` には管理者が `install-shared` を実行する案内を含める。
`tools` が印に無いか、その置き場が無いときは、その手順を `fail` と報告し、残りの手順を続ける。

#### Scenario: 共有の置き場が新しい
- **WHEN** 閉じた環境で、共有の置き場の記録がすべて `deps.json` のピンと同じ状態で `sync` を実行する
- **THEN** miseとnpmは実行されず、各CLIが `ok` と報告される

#### Scenario: 共有の置き場が無い
- **WHEN** 閉じた環境で、印の `tools` の値のディレクトリが無い状態で `sync` を実行する
- **THEN** 道具の手順が `fail` と報告され、ほかの手順は続き、終了コードは1

### Requirement: 閉じた環境のサードパーティスキル
閉じた環境の間、`sync` は、サードパーティスキルを導入してはならず、入れ直してもならない（MUST NOT）。
代わりに、`~/.claude/skills/<name>` を、共有の置き場の `skills/<name>` へのsymlinkにしなければならない（MUST）。
対象は、`deps.json` の `skills` のうち `mode` が `reference` の項目である。
同名の実ディレクトリがあるときは上書きせず、`conflict` と報告する。
共有の置き場に `skills/<name>` が無いときは `warn` とし、管理者が `install-shared` を実行する案内を含める。

#### Scenario: 初回
- **WHEN** 閉じた環境で、共有の置き場に `skills/grilling` がある状態で `sync` を実行する
- **THEN** `~/.claude/skills/grilling` が共有の置き場の `skills/grilling` へのsymlinkになり、skills CLIは実行されない

### Requirement: 閉じた環境の OpenSpec のコマンド
閉じた環境の間、`sync` は、OpenSpecのユーザー層のコマンドを、共有の置き場の `bin/` のopenspecで生成しなければならない（MUST）。
ホームの下のopenspecを使ってはならない（MUST NOT）。

#### Scenario: ホームにも openspec がある
- **WHEN** 閉じた環境で、`~/.local/bin/openspec` と共有の置き場の `bin/openspec` の両方がある状態で `sync` を実行する
- **THEN** `/opsx:*` のコマンドは共有の置き場のopenspecで生成される

### Requirement: 閉じた環境の通知
閉じた環境の間、`sync` は、`~/.local/bin` に通知のコマンドのsymlinkを置いてはならない（MUST NOT）。
ハーネスを指す通知のコマンドのsymlinkが既にあれば消す。
通知のLaunchAgentの手順も実行しない。

#### Scenario: 閉じた環境の macOS
- **WHEN** 閉じた環境のmacOSで `sync` を実行する
- **THEN** `~/.local/bin/claude-notify` は作られず、LaunchAgentの手順は出力に現れない

### Requirement: 閉じた環境での sandbox の緩和の拒否
閉じた環境の間、`sandbox-exclude` と `sandbox-allow-host` は、端末別設定とliveを変えてはならない（MUST NOT）。
`--list` 以外の呼び出しでは、閉じた環境ではsandboxを緩める値を端末別設定から持ち込まないことと、接続先と外に出すコマンドは端末の土台が決めることを標準エラーに出し、終了コード2で終える。
`--list` は今までどおり一覧を出す。

#### Scenario: 閉じた環境で外へ出そうとする
- **WHEN** 閉じた環境で `uskn-harness sandbox-exclude 'terraform *'` を実行する
- **THEN** 端末別設定は作られず、標準エラーに閉じた環境である旨が出て、終了コードは2

#### Scenario: 閉じた環境で接続先を足そうとする
- **WHEN** 閉じた環境で `uskn-harness sandbox-allow-host <gl.example.test>` を実行する
- **THEN** 端末別設定は変わらず、終了コードは2
