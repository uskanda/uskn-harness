## MODIFIED Requirements

### Requirement: ブランチ名の固定を持たない
スキル本文は `develop` `main` `qa` などの具体名を規則として持ってはならない（MUST NOT）。
対象ブランチはセッションに注入された `<repo-context>` を使い、無ければ `uskn-repo-context --plain branches` を実行して得る。

#### Scenario: repo-context が無いセッション
- **WHEN** `<repo-context>` が注入されていないセッションで `sync-base` を実行する
- **THEN** スキルは `uskn-repo-context --plain branches` を実行してintegrationを得てから進める
