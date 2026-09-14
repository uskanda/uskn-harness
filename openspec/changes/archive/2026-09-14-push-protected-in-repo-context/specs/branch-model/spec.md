## MODIFIED Requirements

### Requirement: AGENTS.md による上書き
リポジトリ直下の `AGENTS.md` に見出し `## Branch model` があるとする。
その直後に言語 `yaml` のfenced code blockが続くとき、hookはそれを読まなければならない（MUST）。
`default` `integration` `qa` `release_tag` `protected` のいずれかのキーがあれば、その値が自動検出より優先される。
書かれていないキーは自動検出の値を使う。`qa: none` は「QAブランチ無し」を意味する。

#### Scenario: 統合ブランチだけを上書き
- **WHEN** AGENTS.mdの `## Branch model` に `integration: trunk` だけが書かれている
- **THEN** integrationは `trunk`、defaultとqaは自動検出の値

#### Scenario: 見出しが無い
- **WHEN** AGENTS.mdに `## Branch model` が無い
- **THEN** すべて自動検出の値で、保護ブランチは宣言無し

## ADDED Requirements

### Requirement: 保護ブランチの宣言
`## Branch model` のyamlに `protected` キーがあるとき、hookはその値を保護ブランチの宣言として解決しなければならない（MUST）。
値 `none` は保護ブランチが無いという宣言である。
それ以外の値は、保護ブランチのglobパターンを `,` で区切った並びであり、各パターンの前後の空白を除いて扱う。

#### Scenario: 保護ブランチ無し
- **WHEN** `## Branch model` に `protected: none` と書かれている
- **THEN** 保護ブランチの宣言は `none`

#### Scenario: パターンの並び
- **WHEN** `## Branch model` に `protected: main ,release/*` と書かれている
- **THEN** 保護ブランチの宣言は `main` と `release/*` の2つのパターン

### Requirement: 保護ブランチを自動検出しない
`protected` キーが無いか値が空のとき、hookは保護ブランチを宣言無しとしなければならない（MUST）。
hookはホストのAPIやブランチ名から保護ブランチを推定してはならない（MUST NOT）。

#### Scenario: キーが無い
- **WHEN** `## Branch model` に `integration: develop` だけが書かれている
- **THEN** 保護ブランチは宣言無し
