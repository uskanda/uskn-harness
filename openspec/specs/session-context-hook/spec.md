# session-context-hook Specification

## Purpose
セッション開始時に作業リポジトリのホスティングとブランチモデルを一度だけ判定し、スキルが再判定せずに使える前提知識としてエージェントへ渡すhook。

## Requirements

### Requirement: 作業リポジトリの特定
hookはstdinのJSONの `cwd` を作業ディレクトリとして使い、`cwd` が無いときは `$PWD` を使う。gitリポジトリでない場合、hookは何も出力せず終了コード0で終わらなければならない（MUST）。

#### Scenario: git リポジトリ外
- **WHEN** `cwd` がgit管理下にないディレクトリを指す
- **THEN** 標準出力は空で、終了コードは0

#### Scenario: stdin が空
- **WHEN** stdinにJSONが無い状態でhookが実行される
- **THEN** `$PWD` を作業ディレクトリとして扱い、処理を続ける

### Requirement: ホスティングの判定
hookはGitHub / GitLab / unknownを判定しなければならない（MUST）。
見る順序はremote URLのホスト名、gh / glabの設定ファイル、リポジトリ内のCIファイル。判定根拠を出力に含める。

#### Scenario: github.com の remote
- **WHEN** `origin` のURLが `git@github.com:owner/repo.git`
- **THEN** platformは `github`、根拠は「既知のホスト名」

#### Scenario: セルフホスト GitLab
- **WHEN** ホスト名に `gitlab` を含むremoteがあり、既知のホストではない
- **THEN** platformは `gitlab`

#### Scenario: 判定できない
- **WHEN** remoteが無く、`.github/workflows/` と `.gitlab-ci.yml` のどちらも無い
- **THEN** platformは `unknown` で、出力にはスキル側で判定するよう促す文を含む

### Requirement: ブランチモデルの注入
hookは `branch-model` の解決結果を `<repo-context>` ブロック内に含めなければならない（MUST）。
含めるのはdefault、integration、qa、release_tagと、それぞれの根拠。

#### Scenario: develop と qa があるリポジトリ
- **WHEN** `origin/HEAD` が `main` を指し、`origin/develop` と `origin/qa` が存在する
- **THEN** 出力に `default: main`、`integration: develop`、`qa: qa` が含まれる

#### Scenario: main だけのリポジトリ
- **WHEN** `origin/HEAD` が `main` を指し、他の長寿命ブランチが無い
- **THEN** 出力に `integration: main` と `qa: (none)` が含まれる

### Requirement: 機械可読モード
`--plain hosting` は `github` / `gitlab` / `unknown` のいずれか1語を出力しなければならない（MUST）。
`--plain branches` は `key=value` 形式の行を出力する。キーはdefault、integration、qa、release_tag。
`--json` は同じ内容を1つのJSONオブジェクトで出力する。
これらのモードでは `<repo-context>` ブロックを出力しない。

#### Scenario: スキルからの直接呼び出し
- **WHEN** `session-start.sh --plain branches` をgitリポジトリ内で実行する
- **THEN** 標準出力は `default=…` `integration=…` `qa=…` `release_tag=…` の4行のみ

### Requirement: 失敗しても作業を止めない
gh / glabが未導入、ネットワーク不通、jqが無い、といった状況でもhookは終了コード0で終わり、判定できた範囲だけを出力しなければならない（MUST）。

#### Scenario: jq が無い
- **WHEN** PATHに `jq` が無い環境でhookが実行される
- **THEN** stdinの `cwd` は簡易な方法で取り出され、hookは終了コード0で終わる
