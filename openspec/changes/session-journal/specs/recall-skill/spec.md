## Purpose

過去のセッションの判断を、キーワードで素早く引く。

## ADDED Requirements

### Requirement: 検索
`recall <keywords>` は `~/.ai-sessions/<project>` を対象に、`--all` なら全プロジェクトを対象に、ripgrep（無ければ grep）でキーワードを検索し、一致した journal の title と該当行を新しい順に示さなければならない（MUST）。`recall <sid8>` は front matter の `session:` が一致する journal を開く。

#### Scenario: セッション id
- **WHEN** コミットの `Session: 3f2a9c1d` から `recall 3f2a9c1d` を実行する
- **THEN** その journal が表示される
