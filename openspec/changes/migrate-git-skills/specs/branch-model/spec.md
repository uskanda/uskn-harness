## Purpose

リポジトリごとに異なる長寿命ブランチ（既定、統合、QA）とリリースタグ形式を、固定名に頼らず一貫した規則で解決するための契約。hook とスキルの両方がこの規則に従う。

## ADDED Requirements

### Requirement: 自動検出の規則
明示的な設定が無いとき、システムは次の規則で解決しなければならない（MUST）。default は `origin/HEAD` が指すブランチ（取得できなければ `main`、それも無ければ `master`）。integration は `origin/develop` が存在すれば `develop`、無ければ default。qa は `origin/qa` が存在すれば `qa`、無ければ無し。release_tag は `calver`（`vYY.MM.X`）。

#### Scenario: origin/HEAD が master
- **WHEN** リポジトリの `origin/HEAD` が `master` を指し、`develop` が無い
- **THEN** default と integration はともに `master`

#### Scenario: origin/HEAD が未設定
- **WHEN** `origin/HEAD` が無く、`origin/main` が存在する
- **THEN** default は `main`

### Requirement: AGENTS.md による上書き
リポジトリ直下の `AGENTS.md` に見出し `## Branch model` があり、その直後の fenced code block（言語 `yaml`）に `default` `integration` `qa` `release_tag` のいずれかのキーがあれば、その値が自動検出より優先されなければならない（MUST）。書かれていないキーは自動検出の値を使う。`qa: none` は「QA ブランチ無し」を意味する。

#### Scenario: 統合ブランチだけを上書き
- **WHEN** AGENTS.md の `## Branch model` に `integration: trunk` だけが書かれている
- **THEN** integration は `trunk`、default と qa は自動検出の値

#### Scenario: 見出しが無い
- **WHEN** AGENTS.md に `## Branch model` が無い
- **THEN** すべて自動検出の値

### Requirement: 根拠の明示
解決結果を人に見せるときは、各値について「AGENTS.md」か「自動検出（origin/HEAD、ブランチの存在、既定値）」のどちらで決まったかを示さなければならない（MUST）。

#### Scenario: 混在
- **WHEN** integration が AGENTS.md、default が自動検出で決まった
- **THEN** 出力に `integration: develop (AGENTS.md)` と `default: main (origin/HEAD)` のように根拠が並ぶ
