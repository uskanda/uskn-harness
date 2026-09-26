## ADDED Requirements

### Requirement: サードパーティスキルの ref の確認
`doctor` は、`via` が `skills` のサードパーティスキルごとに、lockファイルの `ref` とピンの差を報告しなければならない（MUST）。
同じなら `ok`、違うかlockの項目が `ref` を持たなければ `warn` とし、両方の値と `sync` の案内を含める。
lockに項目が無いときも `warn` とする。

#### Scenario: ref の不一致
- **WHEN** lockのgrillingの項目が `ref` を持たない
- **THEN** grillingは `warn` で、ピンの `ref` と `sync` の案内が含まれ、終了コードは0

#### Scenario: ピンと同じ
- **WHEN** lockのgrillingの `ref` が `deps.json` と同じ
- **THEN** grillingは `ok`

### Requirement: Impeccable の版の確認
Impeccableの `SKILL.md` の `version` がピンと違うとき、`doctor` は `warn` を報告しなければならない（MUST）。
`warn` には両方の版を含める。

#### Scenario: 版が古い
- **WHEN** 導入済みの `SKILL.md` が `version: 4.2.0` で、`deps.json` は4.3.1を指す
- **THEN** impeccableは `warn` で、4.2.0と4.3.1の両方が含まれる

### Requirement: Impeccable の agent の確認
`remove_agents` に挙げたagentのファイルが残っているとき、`doctor` は `warn` を報告しなければならない（MUST）。

#### Scenario: agent が残っている
- **WHEN** `~/.claude/agents/impeccable-documenter.md` がある
- **THEN** そのファイル名と `sync` の案内を含む `warn` が出る

### Requirement: 鮮度警告の設定の確認
環境変数 `IMPECCABLE_NO_STALENESS_CHECK=1` がどこにも設定されていないとき、`doctor` は `warn` を報告しなければならない（MUST）。
確かめる場所は、`~/.claude/settings.json` の `env` と、`doctor` 自身の環境の2つ。
この設定はdotfilesが管理するので、`sync` は書かない。

#### Scenario: 設定が無い
- **WHEN** `~/.claude/settings.json` の `env` に `IMPECCABLE_NO_STALENESS_CHECK` が無い
- **THEN** `warn` に変数の名前が含まれ、終了コードは0

#### Scenario: 設定がある
- **WHEN** `~/.claude/settings.json` の `env` で `IMPECCABLE_NO_STALENESS_CHECK` が `"1"`
- **THEN** その項目は `ok`
