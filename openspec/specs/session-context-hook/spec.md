# session-context-hook Specification

## Purpose
セッション開始時に作業リポジトリのホスティングとブランチモデルを一度だけ判定し、スキルが再判定せずに使える前提知識としてエージェントへ渡す hook。

## Requirements

### Requirement: 作業リポジトリの特定
hook は stdin の JSON の `cwd` を作業ディレクトリとして使い、`cwd` が無いときは `$PWD` を使う。git リポジトリでない場合、hook は何も出力せず終了コード 0 で終わらなければならない（MUST）。

#### Scenario: git リポジトリ外
- **WHEN** `cwd` が git 管理下にないディレクトリを指す
- **THEN** 標準出力は空で、終了コードは 0

#### Scenario: stdin が空
- **WHEN** stdin に JSON が無い状態で hook が実行される
- **THEN** `$PWD` を作業ディレクトリとして扱い、処理を続ける

### Requirement: ホスティングの判定
hook は remote URL のホスト名、gh / glab の設定ファイル、リポジトリ内の CI ファイルの順で GitHub / GitLab / unknown を判定しなければならない（MUST）。判定根拠を出力に含める。

#### Scenario: github.com の remote
- **WHEN** `origin` の URL が `git@github.com:owner/repo.git`
- **THEN** platform は `github`、根拠は「既知のホスト名」

#### Scenario: セルフホスト GitLab
- **WHEN** ホスト名に `gitlab` を含む remote があり、既知のホストではない
- **THEN** platform は `gitlab`

#### Scenario: 判定できない
- **WHEN** remote が無く、`.github/workflows/` も `.gitlab-ci.yml` も無い
- **THEN** platform は `unknown` で、出力にはスキル側で判定するよう促す文を含む

### Requirement: ブランチモデルの注入
hook は `branch-model` の解決結果（default / integration / qa / release_tag と、それぞれの根拠）を `<repo-context>` ブロック内に含めなければならない（MUST）。

#### Scenario: develop と qa があるリポジトリ
- **WHEN** `origin/HEAD` が `main` を指し、`origin/develop` と `origin/qa` が存在する
- **THEN** 出力に `default: main`、`integration: develop`、`qa: qa` が含まれる

#### Scenario: main だけのリポジトリ
- **WHEN** `origin/HEAD` が `main` を指し、他の長寿命ブランチが無い
- **THEN** 出力に `integration: main` と `qa: (none)` が含まれる

### Requirement: 機械可読モード
`--plain hosting` は `github` / `gitlab` / `unknown` のいずれか 1 語を、`--plain branches` は `key=value` 形式の行（default, integration, qa, release_tag）を、`--json` は同じ内容を 1 つの JSON オブジェクトで出力しなければならない（MUST）。これらのモードでは `<repo-context>` ブロックを出力しない。

#### Scenario: スキルからの直接呼び出し
- **WHEN** `session-start.sh --plain branches` を git リポジトリ内で実行する
- **THEN** 標準出力は `default=…` `integration=…` `qa=…` `release_tag=…` の 4 行のみ

### Requirement: 失敗しても作業を止めない
gh / glab が未導入、ネットワーク不通、jq が無い、といった状況でも hook は終了コード 0 で終わり、判定できた範囲だけを出力しなければならない（MUST）。

#### Scenario: jq が無い
- **WHEN** PATH に `jq` が無い環境で hook が実行される
- **THEN** stdin の `cwd` は簡易な方法で取り出され、hook は終了コード 0 で終わる
