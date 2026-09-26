## MODIFIED Requirements

### Requirement: サードパーティスキル
`sync` は、`deps.json` の `skills` のうち `via` が `skills` の項目を導入しなければならない（MUST）。
対象は `mode` が `reference` の項目に限り、使うのはピンした版のskills CLI。
コマンドは `npx -y skills@<version> add '<source>#<ref>@<name>' -g -a claude-code -y`。
`<version>` は `deps.json` の `clis` にある `skills` の版、`<source>` と `<ref>` はその項目の値、`<name>` は項目の名前。
`~/.claude/skills/<name>` が無いときにこのコマンドで導入し、`created` と報告する。

#### Scenario: grilling が未導入
- **WHEN** `~/.claude/skills/grilling` が無い状態で `sync` を実行する
- **THEN** skills CLIが `mattpocock/skills#<ref>@grilling` を指定して実行され、`created` と報告される

### Requirement: UI 系の参照スキルと CLI
`sync` は `deps.json` の `skills` にある `impeccable` と `frontend-design` を入れなければならない（MUST）。
`frontend-design` はほかのサードパーティスキルと同じく、skills CLIで入れる。
`impeccable` は、スキルのリリースのzipとImpeccableのCLIで入れる（後述の要件）。
`clis` の `@google/design.md` もピンの版でglobalに入れる。

#### Scenario: 未導入
- **WHEN** `~/.claude/skills/impeccable` と `~/.claude/skills/frontend-design` が無い状態で `sync` を実行する
- **THEN** どちらも `deps.json` のピンで導入され、`created` と報告される

## ADDED Requirements

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
