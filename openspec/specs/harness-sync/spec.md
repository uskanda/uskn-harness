# harness-sync Specification

## Purpose
ハーネスの正本を 1 コマンドで各マシンに導入・更新する手順。何度実行しても同じ状態に収束し、ユーザーが手で置いたものを壊さない。

## Requirements

### Requirement: 冪等性
`uskn-harness sync` を連続して 2 回実行したとき、2 回目は何も変更せず、変更が無かったことを報告しなければならない（MUST）。

#### Scenario: 2 回目の実行
- **WHEN** 導入済みの環境で `sync` を再実行する
- **THEN** 新しい symlink やファイルは作られず、各項目が `ok` として報告される

### Requirement: 参照点の用意
`sync` は `~/.local/share/uskn-harness` を用意しなければならない（MUST）。導入元は `USKN_HARNESS_DIR`、無ければ `sync` 自身が置かれている checkout。参照点がその checkout への symlink（または checkout 自身）でなければ symlink を張る。既に別の場所を指す symlink や実ディレクトリがある場合は上書きせず警告する。checkout が無いマシンでの clone は `machine-bootstrap` の責務。

#### Scenario: 開発機
- **WHEN** `~/repos/uskn-harness` が git checkout で、参照点が未作成
- **THEN** `~/.local/share/uskn-harness` はその checkout への symlink になる

#### Scenario: managed clone から実行
- **WHEN** `~/.local/share/uskn-harness` が実ディレクトリの clone で、その中の `bin/uskn-harness sync` を実行する
- **THEN** 参照点は `ok`（managed clone）として報告され、symlink は作られない

### Requirement: ランタイムと CLI
`sync` は mise が無ければ `~/.local/bin/mise` に導入しなければならない（MUST）。
続けてグローバル既定として `node@24` と `jq` を設定する。
`deps.json` の `clis` のうち `global` が真のものを、ピンの版で npm の global に導入する。
既に一致していれば何もしない。

#### Scenario: openspec が古い
- **WHEN** 導入済みの openspec が `deps.json` の version と異なる
- **THEN** 指定 version が導入され、`openspec --version` がその値を返す

### Requirement: 自作スキルの symlink
`sync` は `skills/**/SKILL.md` を持つ各ディレクトリについて `~/.claude/skills/<name>` への symlink を張らなければならない（MUST）。`<name>` はディレクトリ名。既に同名の実ディレクトリ（symlink でないもの）があるときは上書きせず、`conflict` として警告し、他の項目の処理を続ける。既にハーネス内を指す symlink なら `ok`。

#### Scenario: chezmoi 管理の同名スキルがある
- **WHEN** `~/.claude/skills/commit` が実ディレクトリとして存在する
- **THEN** `commit` は `conflict` と報告され、symlink は作られず、終了コードは 0

#### Scenario: 名前の一意性
- **WHEN** `skills/` 配下の 2 つのディレクトリが同じ名前を持つ
- **THEN** `sync` は導入前にエラーで停止する

### Requirement: プラグインの symlink
`sync` は `~/.claude/skills/uskn-harness` を `plugins/uskn-harness` への symlink にしなければならない（MUST）。

#### Scenario: 初回
- **WHEN** `~/.claude/skills/uskn-harness` が無い
- **THEN** symlink が作られ、`claude plugin list` に `uskn-harness@skills-dir` が現れる

### Requirement: サードパーティスキル
`sync` は `deps.json` の `skills` のうち、`mode` が `reference` で `install` を持つものを導入しなければならない（MUST）。
導入するのは `~/.claude/skills/<name>` が無いときだけで、コマンドは `install` の値を使う。既にあるものは触らない。

#### Scenario: grilling が未導入
- **WHEN** `~/.claude/skills/grilling` が無い
- **THEN** `npx skills add mattpocock/skills --skill=grilling -g -a claude-code` 相当が実行され、導入後に `SKILL.md` が存在する

### Requirement: OpenSpec のユーザー層スキル
`sync` は openspec が Claude Code 向けに生成するスキルとコマンドを、一時ディレクトリで作らなければならない（MUST）。
生成物は `~/.claude/skills/openspec-*` と `~/.claude/commands/opsx/` にコピーする。
各ディレクトリにはハーネス管理の印として `.uskn-harness-managed` ファイルを置く。
コピー先に印の無い同名ディレクトリがあれば、上書きせず警告する。
`generatedBy` は chezmoi 管理の旧コピーにも含まれるため、印には使わない。

#### Scenario: バージョン更新
- **WHEN** openspec の version が上がった状態で `sync` を実行する
- **THEN** ユーザー層のスキルの `generatedBy` が新しい version になる

### Requirement: ユーザー層の指示
`sync` は `templates/user/CLAUDE.md` を `~/.claude/CLAUDE.md` に配置しなければならない（MUST）。配置先が存在し、先頭に「managed by uskn-harness」の印が無い場合は上書きせず警告する。

#### Scenario: ユーザーが手で書いたファイルがある
- **WHEN** `~/.claude/CLAUDE.md` が印の無いファイルとして存在する
- **THEN** ファイルはそのまま残り、`conflict` として報告される

### Requirement: 実行ファイルの公開
`sync` は `~/.local/bin/uskn-harness` を `bin/uskn-harness` への symlink にしなければならない（MUST）。

#### Scenario: PATH から呼べる
- **WHEN** `sync` 後に新しいシェルを開く
- **THEN** `uskn-harness doctor` が実行できる

### Requirement: dry-run と報告
`--dry-run` を付けたとき、`sync` はファイルシステムを変更せず、行う予定の操作を 1 行ずつ出力しなければならない（MUST）。通常実行では各項目を `ok` / `created` / `updated` / `conflict` / `skipped` のいずれかで報告する。

#### Scenario: dry-run
- **WHEN** 未導入の環境で `sync --dry-run` を実行する
- **THEN** 出力に予定操作が並び、`~/.claude/skills` に変化が無い

### Requirement: OpenSpec schema の symlink
`sync` は `~/.local/share/openspec/schemas/uskn` をハーネスの `schemas/uskn` への symlink にしなければならない（MUST）。衝突時の扱いは他の symlink と同じ。`sync --remove` はこの symlink も取り除く。

#### Scenario: 初回
- **WHEN** 未導入の環境で `sync` を実行する
- **THEN** symlink が作られ、`openspec schema which uskn` が user レベルを返す

### Requirement: sessions repo の clone
`sync` は `~/.ai-sessions` が無いとき `deps.json` の `repos.sessions.url` から clone しなければならない（MUST）。既にあれば触らない。

#### Scenario: 既存
- **WHEN** `~/.ai-sessions` が git リポジトリとして存在する
- **THEN** `ok` として報告される

### Requirement: npm global CLI のピン
`sync` は `deps.json` の `clis` のうち `global` が真の項目を、mise の Node で global に入れなければならない（MUST）。
対象は openspec、textlint とそのプリセット、agent-style、design.md。版はピンに従う。
同じ版が入っていれば何もしない。`bundle` に列挙されたパッケージは同じコマンドで一緒に入れる。

#### Scenario: 未導入
- **WHEN** textlint が入っていない状態で `sync` を実行する
- **THEN** `npm install -g textlint@<version> <bundle...>` が実行され、`created` と報告される

#### Scenario: 版が一致
- **WHEN** ピンと同じ版が入っている
- **THEN** インストールは実行されず `ok` と報告される

### Requirement: UI 系の参照スキルと CLI
`sync` は `deps.json` の `skills` にある `impeccable` と `frontend-design` を入れなければならない（MUST）。
入れるのは無いときだけで、コマンドは `install` の値を使う。
`clis` の `@google/design.md` もピンの版で global に入れる。

#### Scenario: 未導入
- **WHEN** `~/.claude/skills/impeccable` が無い状態で `sync` を実行する
- **THEN** `deps.json` の install コマンドが実行され、`created` と報告される

### Requirement: 道具だけの導入（--tools）
`uskn-harness sync --tools` は 3 つだけを用意しなければならない（MUST）。ランタイム（mise、node、jq）、`deps.json` でピンした npm global の CLI、OpenSpec schema の symlink。
参照点、実行ファイル、スキルとプラグインの symlink、サードパーティスキル、sessions repo、OpenSpec のユーザー層、ユーザー層 CLAUDE.md には触らない。
`--dry-run` と組み合わせられる。`--remove` と組み合わせたときは終了コード 2 で止まる。

#### Scenario: CI の runner
- **WHEN** 何も導入されていないマシンで `sync --tools` を実行する
- **THEN** mise の道具と npm global の導入が実行され、schema の symlink が作られる。`~/.claude/skills`、`~/.ai-sessions`、`~/.claude/CLAUDE.md` は作られない

#### Scenario: 2 回目
- **WHEN** 導入済みの環境で `sync --tools` を再実行する
- **THEN** 何も変更せず、各項目が `ok` として報告される

#### Scenario: --remove との併用
- **WHEN** `sync --tools --remove` を実行する
- **THEN** 何もせず終了コード 2 で止まる
