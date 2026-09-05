## ADDED Requirements

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
