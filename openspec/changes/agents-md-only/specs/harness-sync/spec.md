## ADDED Requirements

### Requirement: Claude Code を入れない
`sync` はClaude Codeをインストールしてはならず、版をピンしてもならない（MUST NOT）。
`deps.json` の `runtimes` にある `claude-code` は `doctor` が比べる最低版で、`sync` が入れるものではない。
ハーネスは、Claude Codeの最新版を使うことを妨げない。

#### Scenario: 新しいマシン
- **WHEN** Claude Codeの無いマシンで `sync` を実行する
- **THEN** Claude Codeのインストールは実行されず、stubの記録にも現れない
