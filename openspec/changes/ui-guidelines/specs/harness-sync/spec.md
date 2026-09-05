## ADDED Requirements

### Requirement: UI 系の参照スキルと CLI
`sync` は `deps.json` の `skills` にある `impeccable` と `frontend-design` を入れなければならない（MUST）。
入れるのは無いときだけで、コマンドは `install` の値を使う。
`clis` の `@google/design.md` もピンの版で global に入れる。

#### Scenario: 未導入
- **WHEN** `~/.claude/skills/impeccable` が無い状態で `sync` を実行する
- **THEN** `deps.json` の install コマンドが実行され、`created` と報告される
