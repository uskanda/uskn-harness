## MODIFIED Requirements

### Requirement: ブランチモデルの注入
hookは `branch-model` の解決結果を `<repo-context>` ブロック内に含めなければならない（MUST）。
含めるのはdefault、integration、qa、release_tag、保護ブランチの宣言と、それぞれの根拠。
保護ブランチが宣言無しのとき、hookはその旨と、`push` が自身の判定手順を使うことを出力しなければならない（MUST）。

#### Scenario: develop と qa があるリポジトリ
- **WHEN** `origin/HEAD` が `main` を指し、`origin/develop` と `origin/qa` が存在する
- **THEN** 出力に `default: main`、`integration: develop`、`qa: qa` が含まれる

#### Scenario: main だけのリポジトリ
- **WHEN** `origin/HEAD` が `main` を指し、他の長寿命ブランチが無い
- **THEN** 出力に `integration: main` と `qa: (none)` が含まれる

#### Scenario: 保護ブランチの宣言がある
- **WHEN** AGENTS.mdの `## Branch model` に `protected: main, release/*` が書かれている
- **THEN** 出力に `protected: main, release/* (AGENTS.md)` が含まれる

#### Scenario: 保護ブランチの宣言が無い
- **WHEN** AGENTS.mdに `protected` キーが無い
- **THEN** 出力に `protected: (not declared)` が含まれる

### Requirement: 機械可読モード
`--plain hosting` は `github` / `gitlab` / `unknown` のいずれか1語を出力しなければならない（MUST）。
`--plain branches` は `key=value` 形式の行を出力する。キーはdefault、integration、qa、release_tag。
`--json` は同じ内容に保護ブランチの宣言を加え、1つのJSONオブジェクトで出力する。宣言無しは空文字列で表す。
これらのモードでは `<repo-context>` ブロックを出力しない。

#### Scenario: スキルからの直接呼び出し
- **WHEN** `session-start.sh --plain branches` をgitリポジトリ内で実行する
- **THEN** 標準出力は `default=…` `integration=…` `qa=…` `release_tag=…` の4行のみ

#### Scenario: JSON の保護ブランチ
- **WHEN** `protected: none` が書かれたリポジトリで `session-start.sh --json` を実行する
- **THEN** オブジェクトの `protected` は `none`、`<sources.protected>` は `AGENTS.md`
