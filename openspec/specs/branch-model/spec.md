# branch-model Specification

## Purpose
リポジトリごとに異なる長寿命ブランチ（既定、統合、QA）とリリースタグ形式を、固定名に頼らず一貫した規則で解決するための契約。hookとスキルの両方がこの規則に従う。

## Requirements

### Requirement: 自動検出の規則
明示的な設定が無いとき、システムは次の規則で解決しなければならない（MUST）。defaultは `origin/HEAD` が指すブランチ（取得できなければ `main`、それも無ければ `master`）。integrationは `origin/develop` が存在すれば `develop`、無ければdefault。qaは `origin/qa` が存在すれば `qa`、無ければ無し。release_tagは `calver`（`vYY.MM.X`）。

#### Scenario: origin/HEAD が master
- **WHEN** リポジトリの `origin/HEAD` が `master` を指し、`develop` が無い
- **THEN** defaultとintegrationはともに `master`

#### Scenario: origin/HEAD が未設定
- **WHEN** `origin/HEAD` が無く、`origin/main` が存在する
- **THEN** defaultは `main`

### Requirement: AGENTS.md による上書き
リポジトリ直下の `AGENTS.md` に見出し `## Branch model` があるとする。
その直後に言語 `yaml` のfenced code blockが続くとき、hookはそれを読まなければならない（MUST）。
`default` `integration` `qa` `release_tag` のいずれかのキーがあれば、その値が自動検出より優先される。
書かれていないキーは自動検出の値を使う。`qa: none` は「QAブランチ無し」を意味する。

#### Scenario: 統合ブランチだけを上書き
- **WHEN** AGENTS.mdの `## Branch model` に `integration: trunk` だけが書かれている
- **THEN** integrationは `trunk`、defaultとqaは自動検出の値

#### Scenario: 見出しが無い
- **WHEN** AGENTS.mdに `## Branch model` が無い
- **THEN** すべて自動検出の値

### Requirement: 根拠の明示
解決結果を人に見せるときは、各値について「AGENTS.md」か「自動検出（origin/HEAD、ブランチの存在、既定値）」のどちらで決まったかを示さなければならない（MUST）。

#### Scenario: 混在
- **WHEN** integrationがAGENTS.md、defaultが自動検出で決まった
- **THEN** 出力に `integration: develop (AGENTS.md)` と `default: main (origin/HEAD)` のように根拠が並ぶ
